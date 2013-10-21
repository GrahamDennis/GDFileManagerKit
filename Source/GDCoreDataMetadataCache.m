//
//  GDCoreDataMetadataCache.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 18/07/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDCoreDataMetadataCache.h"
#import <CoreData/CoreData.h>

#import "GDCoreDataFileNode.h"
#import "GDCoreDataMetadata.h"

#import "GDURLMetadata.h"
#import "GDURLMetadataInternal.h"

#import "GDFileManagerResourceBundle.h"

@interface GDCoreDataMetadataCache ()

@property (nonatomic, strong, readonly) NSURL *persistentStoreURL;
@property (nonatomic, strong, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;
@property (atomic, strong) NSTimer *saveTimer;
@property (atomic, strong) NSTimer *discardTimer;

@property (nonatomic, strong, readonly) NSPredicate *prefetchChildrenPredicateTemplate;
@property (nonatomic, strong, readonly) NSPredicate *fetchChildrenFromParentPredicateTemplate;
@property (nonatomic, strong, readonly) NSPredicate *fetchNodeFromURLStringPredicateTemplate;
@property (nonatomic, strong, readonly) NSPredicate *fetchNodesFromURLStringsPredicateTemplate;

@property (nonatomic) dispatch_queue_t workQueue;

@end

@implementation GDCoreDataMetadataCache

@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;
@synthesize managedObjectContext = __managedObjectContext;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
#if !OS_OBJECT_USE_OBJC
    if (self.workQueue) {
        dispatch_release(self.workQueue);
        self.workQueue = NULL;
    }
#endif
}

- (id)init
{
    return [self initWithCacheDirectory:nil];
}

- (id)initWithCacheDirectory:(NSURL *)url
{
    if ((self = [super init])) {
        if (!url) {
            NSArray *urls = [[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask];
            url = [urls lastObject];
        }
        if (!url)
            return nil;
        _persistentStoreURL = [url URLByAppendingPathComponent:@"GDFileManagerCache.sqlite"];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveOnNotification:) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveOnNotification:) name:UIApplicationWillTerminateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(discardInMemoryCache:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        
        self.workQueue = dispatch_queue_create("me.grahamdennis.GDCoreDataMetadataCache", DISPATCH_QUEUE_CONCURRENT);
        
        _prefetchChildrenPredicateTemplate = [NSPredicate predicateWithFormat:@"fileNode in $children"];
        _fetchChildrenFromParentPredicateTemplate = [NSPredicate predicateWithFormat:@"ANY parents == $parent"];
        _fetchNodeFromURLStringPredicateTemplate = [NSPredicate predicateWithFormat:@"urlString == $urlString"];
        _fetchNodesFromURLStringsPredicateTemplate = [NSPredicate predicateWithFormat:@"urlString in $urlStrings"];
    }
    
    return self;
}

- (id <GDURLMetadata>)metadataForURL:(NSURL *)url { return [self metadataForURL:url directoryContents:NULL]; }
- (void)setMetadata:(id <GDURLMetadata>)metadata forURL:(NSURL *)url { return [self setMetadata:metadata directoryContents:nil forURL:url addToParent:nil]; }
- (void)setMetadata:(id<GDURLMetadata>)metadata forURL:(NSURL *)url addToParent:(NSURL *)parentURL
{
    return [self setMetadata:metadata directoryContents:nil forURL:url addToParent:parentURL];
}

- (void)removeMetadataForURL:(NSURL *)url removeFromParent:(NSURL *)parentURL
{
    NSParameterAssert(url);
    
    [self.managedObjectContext performBlock:^{
        GDCoreDataFileNode *fileNode = [self fileNodeForURL:url createIfNeeded:NO];
        
        if (fileNode) {
            [self.managedObjectContext deleteObject:fileNode];
        }
        
        [self triggerPendingSave];
    }];
}

- (void)setDirectoryContents:(NSDictionary *)contents forURL:(NSURL *)url { return [self setMetadata:NULL directoryContents:contents forURL:url addToParent:nil]; }

- (NSArray *)directoryContentsForURL:(NSURL *)url
{
    NSArray *directoryContents = NULL;
    [self metadataForURL:url directoryContents:&directoryContents];
    return directoryContents;
}

- (NSArray *)directoryContentsMetadataArrayForURL:(NSURL *)url
{
    __block NSArray *metadataArray = nil;
    
    [self.managedObjectContext performBlockAndWait:^{
        @autoreleasepool {
            GDCoreDataFileNode *fileNode = [self fileNodeForURL:url createIfNeeded:NO];
            if (!fileNode || [fileNode childrenAreUnknownValue]) return;
            
            NSFetchRequest *fetchRequest = [NSFetchRequest new];
            fetchRequest.entity = [GDCoreDataMetadata entityInManagedObjectContext:self.managedObjectContext];
            fetchRequest.predicate = [self.prefetchChildrenPredicateTemplate predicateWithSubstitutionVariables:@{@"children": fileNode.children}];
            fetchRequest.returnsObjectsAsFaults = NO;
            fetchRequest.includesPendingChanges = YES;
            
            NSError *error = nil;
            NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
            if (!results) {
                NSLog(@"Unable to fetch metadata objects. Error = %@", error);
                return;
            }
            if ([results count] != [fileNode.children count]) return;
            
            NSMutableArray *mutableMetadataArray = [NSMutableArray arrayWithCapacity:[results count]];
            for (GDCoreDataMetadata *storeMetadata in results) {
                id <GDURLMetadata> metadata = [self urlMetadataForStoreMetadata:storeMetadata];
                if (!metadata) return;
                [mutableMetadataArray addObject:metadata];
            }
            metadataArray = [mutableMetadataArray copy];
            
            [self triggerPendingDiscard];
        }
    }];
    
    return metadataArray;
}

- (id <GDURLMetadata>)metadataForURL:(NSURL *)url directoryContents:(NSArray **)contents
{
    id <GDURLMetadata> metadata = nil;
    [self getForURL:url metadata:&metadata directoryContents:contents];
    return metadata;
}


- (void)setMetadata:(id<GDURLMetadata>)metadata directoryContents:(NSDictionary *)contents forURL:(NSURL *)url addToParent:(NSURL *)parentURL
{
    NSParameterAssert(url);
    if (!contents && !metadata) return;
    
    metadata = [metadata cacheableMetadata];
    
    [self.managedObjectContext performBlock:^{
        GDCoreDataFileNode *fileNode = [self fileNodeForURL:url createIfNeeded:YES];

        if (metadata && [metadata isValid]) {
            GDCoreDataMetadata *storeMetadata = fileNode.metadata;
            if (!storeMetadata) {
                storeMetadata = [GDCoreDataMetadata insertInManagedObjectContext:self.managedObjectContext];
                fileNode.metadata = storeMetadata;
            }
            storeMetadata.jsonDictionary = metadata.jsonDictionary;
            storeMetadata.metadataClassName = NSStringFromClass([metadata class]);
            if (![metadata isDirectory])
                fileNode.childrenAreUnknownValue = NO;
        }
        
        if (contents) {
            NSMutableSet *childNodes = [NSMutableSet setWithCapacity:[contents count]];
            NSNull *null = [NSNull null];
            NSDictionary *existingFileNodes = [self bulkFetchFileNodesForURLs:[contents allKeys]];
            
            [contents enumerateKeysAndObjectsUsingBlock:^(NSURL *childURL, id <GDURLMetadata> childMetadata, BOOL *stop) {
                GDCoreDataFileNode *childNode = existingFileNodes[childURL];
                if (!childNode) {
                    childNode = [self createFileNodeForURL:childURL];
                }
                [childNodes addObject:childNode];
                if ([childMetadata isEqual:null]) return;
                childMetadata = [childMetadata cacheableMetadata];
                
                GDCoreDataMetadata *storeMetadata = childNode.metadata;
                if (!storeMetadata) {
                    storeMetadata = [GDCoreDataMetadata insertInManagedObjectContext:self.managedObjectContext];
                    childNode.metadata = storeMetadata;
                }
                storeMetadata.jsonDictionary = childMetadata.jsonDictionary;
                storeMetadata.metadataClassName = NSStringFromClass([childMetadata class]);
                if (![childMetadata isDirectory])
                    childNode.childrenAreUnknownValue = NO;
            }];
            fileNode.children = [childNodes copy];
            fileNode.childrenAreUnknownValue = NO;
        }
        
        if (parentURL) {
            GDCoreDataFileNode *parentFileNode = [self fileNodeForURL:url createIfNeeded:NO];
            [parentFileNode addChildrenObject:fileNode];
        }
        
        [self triggerPendingSave];
    }];
}

- (void)getForURL:(NSURL *)url metadata:(id <GDURLMetadata>*)outMetadata directoryContents:(NSArray **)contents
{
    __block NSMutableArray *directoryContents = nil;
    __block id <GDURLMetadata> metadata = nil;
    [self.managedObjectContext performBlockAndWait:^{
        @autoreleasepool {
            GDCoreDataFileNode *fileNode = [self fileNodeForURL:url createIfNeeded:NO];
            
            if (!fileNode) return;
            if (fileNode.metadata) {
                metadata = [self urlMetadataForStoreMetadata:fileNode.metadata];
            }
            
            if (contents) {
                NSFetchRequest *fetchRequest = [NSFetchRequest new];
                fetchRequest.entity = [GDCoreDataFileNode entityInManagedObjectContext:self.managedObjectContext];
                fetchRequest.predicate = [self.fetchChildrenFromParentPredicateTemplate predicateWithSubstitutionVariables:@{@"parent": fileNode}];
                fetchRequest.propertiesToFetch = @[GDCoreDataFileNodeAttributes.urlString];
                fetchRequest.includesPendingChanges = YES;
                
                NSError *error = nil;
                NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
                if (!results) {
                    NSLog(@"Failed to fetch child file nodes: %@", error);
                    return;
                }
                
                directoryContents = [NSMutableArray new];
                for (NSDictionary *result in results) {
                    NSString *urlString = result[GDCoreDataFileNodeAttributes.urlString];
                    NSURL *url = [NSURL URLWithString:urlString];
                    [directoryContents addObject:url];
                }
            }
            
            [self triggerPendingDiscard];
        }
    }];
    
    if (outMetadata)
        *outMetadata = metadata;
    if (contents)
        *contents = [directoryContents copy];
}

- (id <GDURLMetadata>)urlMetadataForStoreMetadata:(GDCoreDataMetadata *)storeMetadata
{
    id <GDURLMetadata> urlMetadata = nil;
    NSDictionary *metadataDictionary = storeMetadata.jsonDictionary;
    Class <GDURLMetadata> metadataClass = NSClassFromString(storeMetadata.metadataClassName);
    if (metadataClass) {
        urlMetadata = [[metadataClass alloc] initWithMetadataDictionary:metadataDictionary];
    }
    if (![urlMetadata isValid]) return nil;
    
    return urlMetadata;
}

- (GDCoreDataFileNode *)fileNodeForURL:(NSURL *)url createIfNeeded:(BOOL)createIfNeeded
{
    NSParameterAssert(url);
    
    NSString *urlString = [url absoluteString];
    
    NSFetchRequest *fetchRequest = [NSFetchRequest new];
    fetchRequest.entity = [GDCoreDataFileNode entityInManagedObjectContext:self.managedObjectContext];
    
    fetchRequest.predicate = [self.fetchNodeFromURLStringPredicateTemplate predicateWithSubstitutionVariables:@{@"urlString": urlString}];
    fetchRequest.fetchLimit = 1;
    fetchRequest.returnsObjectsAsFaults = NO;
    fetchRequest.includesPendingChanges = YES;
    
//    fetchRequest.relationshipKeyPathsForPrefetching = @[GDCoreDataFileNodeRelationships.metadata];
    
    NSError *error = nil;
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (!results) {
        NSLog(@"Failed to fetch matching file nodes: %@", error);
        return nil;
    }
    
    GDCoreDataFileNode *fileNode = [results lastObject];
    if (!fileNode && createIfNeeded) {
        fileNode = [self createFileNodeForURL:url];
    }
    
    return fileNode;
}

- (GDCoreDataFileNode *)createFileNodeForURL:(NSURL *)url
{
    GDCoreDataFileNode *fileNode = [GDCoreDataFileNode insertInManagedObjectContext:self.managedObjectContext];
    fileNode.urlString = [url absoluteString];
    if ([[url path] isEqualToString:@"/"])
        fileNode.rootValue = YES;
    
    return fileNode;
}

- (NSDictionary *)bulkFetchFileNodesForURLs:(NSArray *)urls
{
    NSParameterAssert(urls);
    
    NSArray *urlStrings = [urls valueForKeyPath:@"absoluteString"];
    
    NSFetchRequest *fetchRequest = [NSFetchRequest new];
    fetchRequest.entity = [GDCoreDataFileNode entityInManagedObjectContext:self.managedObjectContext];
    
    fetchRequest.predicate = [self.fetchNodesFromURLStringsPredicateTemplate predicateWithSubstitutionVariables:@{@"urlStrings": urlStrings}];
    fetchRequest.includesPendingChanges = YES;
    fetchRequest.relationshipKeyPathsForPrefetching = @[GDCoreDataFileNodeRelationships.metadata];
    
    NSError *error = nil;
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (!results) {
        NSLog(@"failed to fetch matching file nodes: %@", error);
        return nil;
    }
    
    NSMutableDictionary *keyedFileNodes = [NSMutableDictionary dictionaryWithCapacity:[results count]];
    for (GDCoreDataFileNode *fileNode in results) {
        NSURL *url = [NSURL URLWithString:fileNode.urlString];
        keyedFileNodes[url] = fileNode;
    }
    
    return [keyedFileNodes copy];
}

- (void)reset
{
    [self doesNotRecognizeSelector:_cmd];
}

- (void)triggerPendingSave
{
    if (self.saveTimer) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.saveTimer invalidate];
        self.saveTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(saveOnNotification:) userInfo:nil repeats:NO];
    });
}

- (void)triggerPendingDiscard
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.discardTimer invalidate];
        self.discardTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(discardInMemoryCache:) userInfo:nil repeats:NO];
    });
}

#pragma mark - Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext
{
    if (__managedObjectContext != nil)
    {
        return __managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil)
    {
        __managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [__managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    
    __managedObjectContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
    return __managedObjectContext;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel
{
    if (__managedObjectModel != nil)
    {
        return __managedObjectModel;
    }
    NSURL *modelURL = [GDFileManagerResourcesBundle() URLForResource:@"GDFileManagerMetadataCache" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return __managedObjectModel;
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (__persistentStoreCoordinator != nil)
    {
        return __persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [self persistentStoreURL];
    
    NSManagedObjectModel *mom = [self managedObjectModel];
    
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    
    NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES};
    
    BOOL secondFailure = NO;
    NSError *error = nil;
    
    while (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                     configuration:nil
                                                               URL:storeURL
                                                           options:options
                                                             error:&error]) {
        if (secondFailure) {
            return nil;
        }
        [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
        NSLog(@"Unresolved error creating persistent store coordinator, deleting. %@, %@", error, [error userInfo]);
        secondFailure = YES;
    }
    
    __persistentStoreCoordinator = persistentStoreCoordinator;
    
    return __persistentStoreCoordinator;
}

- (void)saveWithContinuation:(void (^)(NSError *error))continuation
{
    [self.managedObjectContext performBlock:^{
        if (![self.managedObjectContext hasChanges]) return;
        NSError *error = nil;
        if (![self.managedObjectContext save:&error]) {
            NSLog(@"Error saving: %@", error);
        }
        
        [self.saveTimer invalidate];
        self.saveTimer = nil;
        
        if (continuation) continuation(error);
    }];
}

#pragma mark - Notification handlers

- (void)saveOnNotification:(NSNotification *)notification
{
    __block UIBackgroundTaskIdentifier task = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:task];
        task = UIBackgroundTaskInvalid;
    }];
    
    [self saveWithContinuation:^(NSError *error) {
        if (task != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:task];
        }
    }];
}

- (void)discardInMemoryCache:(id)sender
{
    [self.managedObjectContext performBlock:^{
        if ([self.managedObjectContext hasChanges]) {
            [self saveWithContinuation:NULL];
        } else {
            [self.managedObjectContext reset];
        }
        NSFetchRequest *fetchRequest = [NSFetchRequest new];
        fetchRequest.entity = [GDCoreDataFileNode entityInManagedObjectContext:self.managedObjectContext];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"(root == FALSE) AND parents.@count == 0"];
        
        NSError *error = nil;
        NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        if (!results) {
            NSLog(@"Failed to fetch cache items needing deletion due to error: %@", error);
        }
        if ([results count]) {
            for (GDCoreDataFileNode *node in results) {
                [self.managedObjectContext deleteObject:node];
            }
            [self triggerPendingSave];
        }
        
    }];
}

@end
