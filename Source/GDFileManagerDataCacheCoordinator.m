//
//  GDFileManagerDataCacheManager.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 1/08/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDFileManagerDataCacheCoordinator.h"

#import <CoreData/CoreData.h>
#import <sys/xattr.h>

#import "GDHTTPClient.h"
#import "GDFileManagerCachedFile.h"
#import "GDURLMetadata.h"
#import "GDURLMetadata_Private.h"
#import "GDFileManagerPersistentUploadOperation_Private.h"
#import "GDFileManager.h"
#import "GDFileManagerUploadOperation_Private.h"
#import "GDPersistentUploadDestination.h"

#import "GDFileManagerResourceBundle.h"

#define DDLogError NSLog
#define DDLogWarn  NSLog
#define DDLogInfo  NSLog

static NSString *const CacheSizeMetadataKey = @"CacheSizeInBytes";
static NSString *const MaximumCacheSizeMetadataKey = @"MaximumCacheSizeInBytes";
NSString *const GDFileManagerNewCacheFileNotification = @"GDFileManagerNewCacheFileNotification";

@interface GDFileManagerDataCacheCoordinator ()

@property (nonatomic, strong, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, strong, readonly) NSPredicate *sourceAndVersionIdentiferPredicateTemplate;
@property (nonatomic, strong, readonly) NSPredicate *sourcePredicateTemplate;

@property (nonatomic, strong) NSNumber *cacheSize;

- (void)deleteCachedFile:(GDFileManagerCachedFile *)cachedFile;

- (void)saveContext;
- (void)asyncSaveContext;
- (void)_saveContext;

- (BOOL)createCacheDirectory;

- (void)asyncTrimCacheIfNeeded;
- (void)_trimCache;

- (id)objectForMetadataKey:(NSString *)key;
- (void)setObject:(id)object forMetadataKey:(NSString *)key;

@end

@implementation GDFileManagerDataCacheCoordinator

@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;
@synthesize managedObjectContext = __managedObjectContext;

@synthesize fileCacheDirectoryURL = _fileCacheDirectoryURL;

@synthesize sourceAndVersionIdentiferPredicateTemplate = _sourceAndVersionIdentifierPredicateTemplate;
@synthesize sourcePredicateTemplate = _sourcePredicateTemplate;

+ (instancetype)sharedCacheCoordinator
{
    static GDFileManagerDataCacheCoordinator *cacheCoordinator = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cacheCoordinator = [GDFileManagerDataCacheCoordinator new];
    });
    return cacheCoordinator;
}

- (id)init
{
    if ((self = [super init])) {
        _sourceAndVersionIdentifierPredicateTemplate = [NSPredicate predicateWithFormat:@"sourceURLString == $sourceURLString AND versionIdentifier == $versionIdentifier"];
        _sourcePredicateTemplate = [NSPredicate predicateWithFormat:@"sourceURLString == $sourceURLString"];
        
    }
    return self;
}

- (NSURL *)cacheURLForURL:(NSURL *)url cachedMetadata:(__autoreleasing id<GDURLMetadata> *)cachedMetadata
{
    return [self cacheURLForURL:url versionIdentifier:nil cachedMetadata:cachedMetadata];
}

- (NSURL *)cacheURLForURL:(NSURL *)url versionIdentifier:(NSString *)versionIdentifier cachedMetadata:(__autoreleasing id<GDURLMetadata> *)cachedMetadata
{
    NSParameterAssert(url);
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = [GDFileManagerCachedFile entityInManagedObjectContext:self.managedObjectContext];
    
    NSDictionary *substitutions = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [url absoluteString], GDFileManagerCachedFileAttributes.sourceURLString,
                                   versionIdentifier, GDFileManagerCachedFileAttributes.versionIdentifier,
                                   nil];
    
    if (versionIdentifier)
        fetchRequest.predicate = [self.sourceAndVersionIdentiferPredicateTemplate predicateWithSubstitutionVariables:substitutions];
    else {
        // If we aren't given a version hash, just grab what we have.
        fetchRequest.predicate = [self.sourcePredicateTemplate predicateWithSubstitutionVariables:substitutions];
    }
    
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:GDFileManagerCachedFileAttributes.downloadDate ascending:NO]];
    fetchRequest.fetchLimit = 1;
    
    __block NSURL *result = nil;
    __block id <GDURLMetadata> urlMetadata = nil;
    
    [self.managedObjectContext performBlockAndWait:^{
        @autoreleasepool {
            NSError *error = nil;
            NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest
                                                                        error:&error];
            if (!results) {
                DDLogError(@"Error fetching cached URL: %@", error);
            }
            if ([results count] > 1) {
                DDLogWarn(@"An unusual number of cached results found: %@", results);
            }
            if ([results count] == 0)
                return;
            
            GDFileManagerCachedFile *cachedFile = [results lastObject];
            result = [self.fileCacheDirectoryURL URLByAppendingPathComponent:cachedFile.cacheFilePath];
            cachedFile.lastAccess = [NSDate date];
            NSDictionary *metadataDictionary = cachedFile.metadataDictionary;
            Class <GDURLMetadata> metadataClass = NSClassFromString(cachedFile.metadataClassName);
            if (metadataClass && metadataClass != [GDURLMetadata class]) {
                urlMetadata = [[metadataClass alloc] initWithMetadataDictionary:metadataDictionary];
            }
            
            if (result && ![[NSFileManager defaultManager] fileExistsAtPath:[result path]]) {
                DDLogWarn(@"Missing file for cached file: %@", result);
                [self.managedObjectContext deleteObject:cachedFile];
                [self asyncSaveContext];
            }
        }
    }];

    if (cachedMetadata)
        *cachedMetadata = urlMetadata;

    // Only return the result if it actually exists.
    if ([[NSFileManager defaultManager] fileExistsAtPath:[result path]])
        return result;
    
    return nil;
}

// Implicit as part of this operation is the removal of old items with different versions.
// Also implicit is scheduling a potential cleanup of files to get back below the cache size limit.
- (NSURL *)moveLocalURL:(NSURL *)localURL intoCacheForURL:(NSURL *)url metadata:(id<GDURLMetadata>)metadata
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:[localURL path]])
        return nil;
    
    metadata = [metadata cacheableMetadata];
    
    NSString *cacheFilePath = nil;
    NSError *error = nil;
    if (![self moveLocalURLIntoFileCache:localURL filename:metadata.filename cacheFilePath:&cacheFilePath error:&error]) {
        DDLogError(@"Failed to move file %@ into cache due to error: %@", localURL, error);
        return nil;
    }
    NSURL *cacheFileURL = [self.fileCacheDirectoryURL URLByAppendingPathComponent:cacheFilePath];
    
    [self addCacheFilePath:cacheFilePath intoCacheForURL:url metadata:metadata];
    
    return cacheFileURL;
}

- (void)addCacheFilePath:(NSString *)cacheFilePath intoCacheForURL:(NSURL *)url metadata:(id<GDURLMetadata>)metadata
{
    NSString *cacheDirectoryPath = [cacheFilePath stringByDeletingLastPathComponent];
    NSURL *cacheFileURL = [self.fileCacheDirectoryURL URLByAppendingPathComponent:cacheFilePath];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[cacheFileURL path]]) return;
    
    metadata = [metadata cacheableMetadata];
    
    [self.managedObjectContext performBlock:^{
        NSError *error = nil;
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        fetchRequest.entity = [GDFileManagerCachedFile entityInManagedObjectContext:self.managedObjectContext];
        
        NSDictionary *substitutions = [NSDictionary dictionaryWithObjectsAndKeys:
                                       [url absoluteString], GDFileManagerCachedFileAttributes.sourceURLString,
                                       nil];
        
        fetchRequest.predicate = [self.sourcePredicateTemplate predicateWithSubstitutionVariables:substitutions];
        
        NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest
                                                                    error:&error];
        if (!results) {
            DDLogError(@"Error fetching redundant cache entries! Error: %@", error);
            return;
        }
        if ([results count] > 1) {
            DDLogWarn(@"An unusual number of redundant cache entries: %@", results);
        }
        
        NSInteger changeInCacheSize = 0;
        
        for (GDFileManagerCachedFile *redundantCacheFile in results) {
            // Don't delete another file associated with the metadata version identifier.
            if ([redundantCacheFile.versionIdentifier isEqualToString:metadata.fileVersionIdentifier])
                continue;
            changeInCacheSize -= redundantCacheFile.fileSizeValue;
            [self deleteCachedFile:redundantCacheFile];
        }
        
        GDFileManagerCachedFile *cachedFile = [GDFileManagerCachedFile insertInManagedObjectContext:self.managedObjectContext];
        cachedFile.cacheFilePath = cacheFilePath;
        cachedFile.versionIdentifier = metadata.fileVersionIdentifier;
        cachedFile.metadataClassName = NSStringFromClass([metadata class]);
        cachedFile.metadataDictionary = metadata.jsonDictionary;
        cachedFile.sourceURL = url;
        cachedFile.lastAccess = [NSDate date];
        cachedFile.cacheDirectoryPath = cacheDirectoryPath;
        cachedFile.downloadDate = [NSDate date];
        
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[cacheFileURL path]
                                                                                        error:&error];
        if (!fileAttributes) {
            DDLogError(@"Unable to obtain attributes of cache file: %@. Error: %@", cacheFileURL, error);
        }
        
        cachedFile.fileSizeValue = [fileAttributes fileSize];
        
        changeInCacheSize += [fileAttributes fileSize];
        
        self.cacheSize = [NSNumber numberWithInteger:self.cacheSize.integerValue + changeInCacheSize];
        
        [self asyncSaveContext];
        [self asyncTrimCacheIfNeeded];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:GDFileManagerNewCacheFileNotification object:url];
        });

    }];
}

- (void)removeAllItems
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:[self.fileCacheDirectoryURL path]])
        return;
    
    NSError *error = nil;
    if (![[NSFileManager defaultManager] removeItemAtURL:self.fileCacheDirectoryURL
                                                   error:&error]) {
        DDLogError(@"Failed to delete cache directory: %@", error);
    }
    
    self.managedObjectContext = nil;
    self.persistentStoreCoordinator = nil;
}

#pragma mark - Private methods

- (NSString *)createFileCachePathForFilename:(NSString *)filename error:(NSError **)outError
{
    NSString *uuidString = nil;
    
    {
        CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
        uuidString = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
        CFRelease(uuid);
    }
    
    NSString *cacheDirectoryPath = uuidString;
    NSURL *cacheDirectoryURL = [self.fileCacheDirectoryURL URLByAppendingPathComponent:cacheDirectoryPath isDirectory:YES];
    
    NSError *error = nil;
    if (![[NSFileManager defaultManager] createDirectoryAtURL:cacheDirectoryURL
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error]) {
        DDLogError(@"Failed to create cache directory \"%@\" due to error %@", cacheDirectoryURL, error);
        if (outError) *outError = error;
        return nil;
    }
    
    NSString *uuidPart = [[uuidString stringByReplacingOccurrencesOfString:@"-" withString:@""] substringToIndex:4];
    NSString *taggedFilename = [NSString stringWithFormat:@"%@-%@.%@", [filename stringByDeletingPathExtension], uuidPart, [filename pathExtension]];
    NSString *cacheFilePath = [uuidString stringByAppendingPathComponent:taggedFilename];
    
    return cacheFilePath;
}

- (BOOL)copyLocalURLIntoFileCache:(NSURL *)localURL filename:(NSString *)filename cacheFilePath:(NSString**)outCacheFilePath error:(NSError **)outError
{
    NSString *cacheFilePath = [self createFileCachePathForFilename:filename error:outError];
    if (!cacheFilePath) {
        return NO;
    }
    if (outCacheFilePath) *outCacheFilePath = cacheFilePath;
    NSURL *cacheFileURL = [self.fileCacheDirectoryURL URLByAppendingPathComponent:cacheFilePath];
    
    return [[NSFileManager defaultManager] copyItemAtURL:localURL toURL:cacheFileURL error:outError];
}

- (BOOL)moveLocalURLIntoFileCache:(NSURL *)localURL filename:(NSString *)filename cacheFilePath:(NSString**)outCacheFilePath error:(NSError **)outError
{
    NSString *cacheFilePath = [self createFileCachePathForFilename:filename error:outError];
    if (!cacheFilePath) {
        return NO;
    }
    if (outCacheFilePath) *outCacheFilePath = cacheFilePath;
    NSURL *cacheFileURL = [self.fileCacheDirectoryURL URLByAppendingPathComponent:cacheFilePath];
    
    return [[NSFileManager defaultManager] moveItemAtURL:localURL toURL:cacheFileURL error:outError];
}

- (BOOL)createCacheDirectory
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self.fileCacheDirectoryURL path]])
        return YES;
    
    // Create the cache directory if it doesn't exist
    NSError *error = nil;
    if (![[NSFileManager defaultManager] createDirectoryAtURL:self.fileCacheDirectoryURL
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error]) {
        DDLogError(@"Failed to create file cache directory: %@", error);
        return NO;
    }
    const char* filePath = [[self.fileCacheDirectoryURL path] fileSystemRepresentation];
    
    const char* attrName = "com.apple.MobileBackup";
    u_int8_t attrValue = 1;
    
    int result = setxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);
    if (result) {
        DDLogError(@"Failed to set \"do not backup attribute\" on offline documents directory. error = %s", strerror(errno));
        return NO;
    }
    
    return YES;
}

- (void)deleteCachedFile:(GDFileManagerCachedFile *)cachedFile
{
    NSURL *cacheDirectoryURL = [self.fileCacheDirectoryURL URLByAppendingPathComponent:cachedFile.cacheDirectoryPath isDirectory:YES];
    
    NSError *error = nil;
    if (![[NSFileManager defaultManager] removeItemAtURL:cacheDirectoryURL error:&error]) {
        NSLog(@"Failed to remove cached file %@ due to error %@", cachedFile, error);
    }
    
    [self.managedObjectContext deleteObject:cachedFile];
}

- (NSNumber *)cacheSize
{
    return [self objectForMetadataKey:CacheSizeMetadataKey];
}

- (void)setCacheSize:(NSNumber *)cacheSize
{
    [self setObject:cacheSize forMetadataKey:CacheSizeMetadataKey];
}

- (NSNumber *)maximumCacheSize
{
    NSNumber *maximumCacheSize = [self objectForMetadataKey:MaximumCacheSizeMetadataKey];
    if (!maximumCacheSize) {
        maximumCacheSize = @(100*1024*1024);
        [self setMaximumCacheSize:maximumCacheSize];
    }
    return maximumCacheSize;
}

- (void)setMaximumCacheSize:(NSNumber *)maximumCacheSize
{
    [self setObject:maximumCacheSize forMetadataKey:MaximumCacheSizeMetadataKey];
    
    [self asyncTrimCacheIfNeeded];
}

- (id)objectForMetadataKey:(NSString *)key
{
    id result = nil;
    for (NSPersistentStore *store in self.persistentStoreCoordinator.persistentStores) {
        if ((result = [[store metadata] objectForKey:key])) {
            break;
        }
    }
    return result;
}

- (void)setObject:(id)object forMetadataKey:(NSString *)key
{
    for (NSPersistentStore *store in self.persistentStoreCoordinator.persistentStores) {
        NSMutableDictionary *metadata = [[store metadata] mutableCopy];
        if (object)
            [metadata setObject:object forKey:key];
        else
            [metadata removeObjectForKey:key];
        [self.persistentStoreCoordinator setMetadata:metadata forPersistentStore:store];
    }
}

- (void)asyncTrimCacheIfNeeded
{
    if (!self.maximumCacheSize || !self.cacheSize || [self.maximumCacheSize compare:self.cacheSize] == NSOrderedDescending || self.maximumCacheSize.integerValue < 0)
        return;
    
    [self _trimCache];
}

#pragma mark - Cache trim

- (void)_trimCache
{
    // maximum size of less than zero means infinite.
    if (!self.maximumCacheSize || self.maximumCacheSize.integerValue < 0)
        return;
    
    DDLogInfo(@"Cleaning the cache");
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = [GDFileManagerCachedFile entityInManagedObjectContext:self.managedObjectContext];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:GDFileManagerCachedFileAttributes.lastAccess
                                                                     ascending:YES];
    
    fetchRequest.sortDescriptors = @[sortDescriptor];
    fetchRequest.returnsObjectsAsFaults = NO;
    
    [self.managedObjectContext performBlock:^{
        NSError *error = nil;
        NSMutableArray *sortedCachedFiles = [[self.managedObjectContext executeFetchRequest:fetchRequest
                                                                                      error:&error] mutableCopy];
        if (!sortedCachedFiles) {
            DDLogError(@"Failed fetching cache entries while trimming. Error: %@", error);
        }
        
        if ([sortedCachedFiles count] <= 1)
            return;
        
        // We don't want to delete the last object
        [sortedCachedFiles removeLastObject];
        
        __block NSInteger excessCacheSize = self.cacheSize.integerValue - self.maximumCacheSize.integerValue;
        
        [sortedCachedFiles enumerateObjectsUsingBlock:^(GDFileManagerCachedFile *cachedFile, NSUInteger idx, BOOL *stop) {
            DDLogInfo(@"Removing cached item for URL: %@", cachedFile.sourceURL);
            
            excessCacheSize -= cachedFile.fileSizeValue;
            [self.managedObjectContext deleteObject:cachedFile];
            if (excessCacheSize < 0)
                *stop = YES;
        }];
        
        self.cacheSize = [NSNumber numberWithInteger:self.cacheSize.integerValue + excessCacheSize];
        
        [self _saveContext];
    }];
}

#pragma mark - Uploads

- (void)registerPersistentUploadOperation:(GDFileManagerPersistentUploadOperation *)uploadOperation
{
    NSURL *localURL = uploadOperation.sourceURL;
    GDPersistentUploadDestination *uploadDestination = uploadOperation.uploadDestination;
    
    NSString *filename = uploadDestination.filename ?: [localURL lastPathComponent];
    
    NSString *fileCachePath = nil;
    NSError *error = nil;
    if (![self copyLocalURLIntoFileCache:localURL filename:filename cacheFilePath:&fileCachePath error:&error]) {
        DDLogError(@"Failed to copy local URL %@ into file cache due to error: %@", localURL, error);
        return;
    }
    NSURL *fileCacheURL = [self.fileCacheDirectoryURL URLByAppendingPathComponent:fileCachePath];
    
    if (uploadOperation.options & GDFileManagerUploadDeleteOnSuccess) {
        if (![[NSFileManager defaultManager] removeItemAtURL:localURL error:&error]) {
            NSLog(@"Failed to clean up file at URL: %@ due to error: %@", localURL, error);
        }
        // Clear delete-on-success because we've now done it.
        uploadOperation.options ^= GDFileManagerUploadDeleteOnSuccess;
    }
    
    uploadOperation.sourceURL = fileCacheURL;
    GDFileManagerUploadState *uploadState = uploadOperation.uploadState;
    GDFileManagerUploadOptions options = uploadOperation.options;
    
    [self.managedObjectContext performBlock:^{
        if (options & GDFileManagerUploadNewVersionsCancelOld) {
            NSFetchRequest *fetchRequest = [NSFetchRequest new];
            fetchRequest.entity = [GDFileManagerPendingUpload entityInManagedObjectContext:self.managedObjectContext];
            fetchRequest.predicate = [NSPredicate predicateWithFormat:@"uploadDestination == %@", uploadDestination];
            fetchRequest.includesPendingChanges = YES;
            
            NSError *error = nil;
            NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
            if (!results) {
                NSLog(@"Failed to fetch old uploads");
            } else {
                for (GDFileManagerPendingUpload *oldPendingUpload in results) {
                    NSLog(@"Cancelling an old pending upload: %@; operation: %@", oldPendingUpload, oldPendingUpload.uploadOperation);
                    [self.managedObjectContext deleteObject:oldPendingUpload];
                }
            }
        }
        GDFileManagerPendingUpload *pendingUpload = [GDFileManagerPendingUpload insertInManagedObjectContext:self.managedObjectContext];
     
        pendingUpload.uploadDestination = uploadDestination;
        pendingUpload.uploadState = uploadState;
        pendingUpload.sourceFilePath = fileCachePath;
        pendingUpload.uploadOperation = uploadOperation;
        pendingUpload.uploadOptions = @(uploadOperation.options);
        
        [self _saveContext];
        
        uploadOperation.pendingUpload = pendingUpload;
        
        if (uploadOperation.destinationURL) {
            [uploadOperation.fileManager getMetadataForURL:uploadOperation.destinationURL
                                                   success:^(GDURLMetadata *metadata) {
                                                       if (!metadata) return;
                                                       [self addCacheFilePath:fileCachePath intoCacheForURL:metadata.canonicalURL metadata:metadata];
                                                   } failure:nil];
        }
        
    }];
}

- (void)persistentUploadOperation:(GDFileManagerPersistentUploadOperation *)uploadOperation newUploadState:(GDFileManagerUploadState *)uploadState
{
    [self.managedObjectContext performBlock:^{
        if (!uploadOperation.pendingUpload) {
            return;
        }
        GDFileManagerPendingUpload *pendingUpload = uploadOperation.pendingUpload;
        if ([pendingUpload isDeleted]) {
            return;
        }
        
        pendingUpload.uploadState = uploadState;
        
        [self asyncSaveContext];
    }];
}

- (void)persistentUploadOperation:(GDFileManagerPersistentUploadOperation *)uploadOperation completedSuccessfullyWithMetadata:(GDURLMetadata *)metadata
{
    NSURL *destinationURL = metadata.canonicalURL;
    NSURL *sourceURL = uploadOperation.sourceURL;
    NSURL *cacheDirectoryURL = [sourceURL URLByDeletingLastPathComponent];
    
    [self moveLocalURL:sourceURL intoCacheForURL:destinationURL metadata:metadata];
    
    [self.managedObjectContext performBlock:^{
        
        GDFileManagerPendingUpload *pendingUpload = uploadOperation.pendingUpload;
        
        if (pendingUpload && ![pendingUpload isDeleted]) {
            [self.managedObjectContext deleteObject:pendingUpload];
        }
        
        [self asyncSaveContext];
    }];
    
    // Delete the upload directory
    [[NSFileManager defaultManager] removeItemAtURL:cacheDirectoryURL error:nil];
}

- (void)persistentUploadOperation:(GDFileManagerPersistentUploadOperation *)uploadOperation failedWithError:(NSError *)error
{
    [self.managedObjectContext performBlock:^{
        GDFileManagerPendingUpload *pendingUpload = uploadOperation.pendingUpload;
        if (pendingUpload && ![pendingUpload isDeleted]) {
            pendingUpload.uploadOperation = nil;
            uploadOperation.pendingUpload = nil;
            if (GDIsErrorPermanentlyFatal(error)) {
                NSLog(@"Pending upload failed permanently with error: %@", error);
                
                NSURL *cacheDirectoryURL = [self.fileCacheDirectoryURL URLByAppendingPathComponent:[pendingUpload.sourceFilePath stringByDeletingLastPathComponent]];
                [[NSFileManager defaultManager] removeItemAtURL:cacheDirectoryURL error:nil];
                [self.managedObjectContext deleteObject:pendingUpload];
            }
        }
        
    }];
}

- (void)resumePendingUploads
{
    [self.managedObjectContext performBlock:^{
        NSFetchRequest *fetchRequest = [NSFetchRequest new];
        fetchRequest.entity = [GDFileManagerPendingUpload entityInManagedObjectContext:self.managedObjectContext];
        NSError *error = nil;
        NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        if (!results) {
            DDLogError(@"Unable to fetch pending uploads due to error: %@", error);
            return;
        }
        for (GDFileManagerPendingUpload *pendingUpload in results) {
            if ([pendingUpload uploadOperation]) continue;
            GDFileManagerPersistentUploadOperation *persistentUploadOperation = nil;
            NSURL *sourceURL = [self.fileCacheDirectoryURL URLByAppendingPathComponent:pendingUpload.sourceFilePath];
            GDFileManagerUploadOptions options = (GDFileManagerUploadOptions)pendingUpload.uploadOptionsValue;
            
            persistentUploadOperation = [[GDFileManagerPersistentUploadOperation alloc] initWithFileManager:[GDFileManager sharedManager]
                                                                                              sourceFileURL:sourceURL
                                                                                                    options:options
                                                                                                    success:nil
                                                                                                    failure:nil];
            GDPersistentUploadDestination *uploadDestination = pendingUpload.uploadDestination;
            [uploadDestination applyToUploadOperation:persistentUploadOperation];
            persistentUploadOperation.uploadState = pendingUpload.uploadState;
            persistentUploadOperation.pendingUpload = pendingUpload;
            pendingUpload.uploadOperation = persistentUploadOperation;
            
            [GDFileManager enqueueLowPriorityFileManagerOperation:persistentUploadOperation];
        }
    }];
}

#pragma mark - Core Data

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext
{
    if (!__managedObjectContext) {
        static NSLock *lock;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            lock = [NSLock new];
        });
        [lock lock];
        if (!__managedObjectContext) {
            NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
            if (coordinator != nil)
            {
                __managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
                [__managedObjectContext setPersistentStoreCoordinator:coordinator];
            }
        }
        [lock unlock];
    }
    
    return __managedObjectContext;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *modelURL = [GDFileManagerResourcesBundle() URLForResource:@"GDFileManagerDataCache" withExtension:@"momd"];
        __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    });
    return __managedObjectModel;
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (!__persistentStoreCoordinator) {
        static NSLock *lock;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            lock = [NSLock new];
        });
        [lock lock];
        
        if (!__persistentStoreCoordinator) {
            [self createCacheDirectory];
            
            NSURL *storeURL = [[self fileCacheDirectoryURL] URLByAppendingPathComponent:@"Cache.db"];
            
            NSError *error = nil;
            __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
            
            NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                                     [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
                                     nil];
            
            NSUInteger failedAttempts = 0;
            
            while (failedAttempts < 2 &&
                   ![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                               configuration:nil
                                                                         URL:storeURL
                                                                     options:options
                                                                       error:&error]) {
                       /*
                        Replace this implementation with code to handle the error appropriately.
                        
                        abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                        
                        Typical reasons for an error here include:
                        * The persistent store is not accessible;
                        * The schema for the persistent store is incompatible with current managed object model.
                        Check the error message to determine what the actual problem was.
                        
                        
                        If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
                        
                        If you encounter schema incompatibility errors during development, you can reduce their frequency by:
                        * Simply deleting the existing store:
                        [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
                        
                        * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
                        [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
                        
                        Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
                        
                        */
                       failedAttempts++;
                       
                       DDLogWarn(@"Error encountered while trying to load cache: %@, %@", error, [error userInfo]);
                       
                       // Only retry once.
                       if (failedAttempts >= 2) {
                           __persistentStoreCoordinator = nil;
                           break;
                       }
                       
                       error = nil;
                       [self removeAllItems];
                       [self createCacheDirectory];
                       // Create it again.
                       __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
                   }
        }
        [lock unlock];
    }
    
    return __persistentStoreCoordinator;
}

- (void)saveContext
{
    [self.managedObjectContext performBlockAndWait:^{
        [self _saveContext];
    }];
}

- (void)asyncSaveContext
{
    [self.managedObjectContext performBlock:^{
        [self _saveContext];
    }];
}

- (void)_saveContext
{
    if (![self.managedObjectContext hasChanges]) return;
    
    NSError *error = nil;
    if (![self.managedObjectContext save:&error])
    {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         */
        DDLogError(@"Unresolved error %@, %@", error, [error userInfo]);
        error = nil;
        [self removeAllItems];
        [self createCacheDirectory];
        
    }
    
}

#pragma mark - Paths

- (NSURL *)fileCacheDirectoryURL
{
    if (!_fileCacheDirectoryURL) {
        NSArray *libraryURLs = [[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory
                                                                      inDomains:NSUserDomainMask];
        NSURL *libraryURL = [libraryURLs lastObject];
        
        _fileCacheDirectoryURL = [libraryURL URLByAppendingPathComponent:@"me.grahamdennis.GDFileManager.CachedDocuments"
                                                             isDirectory:YES];
    }
    
    return _fileCacheDirectoryURL;
}

- (void)setFileCacheDirectoryURL:(NSURL *)fileCacheDirectoryURL
{
    if ([_fileCacheDirectoryURL isEqual:fileCacheDirectoryURL]) return;
    
    _fileCacheDirectoryURL = fileCacheDirectoryURL;
    __managedObjectContext = nil;
    __persistentStoreCoordinator = nil;
}


@end
