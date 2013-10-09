//
//  GDLocalFileServiceSession.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 26/08/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDLocalFileServiceSession.h"
#import "GDFileService.h"
#import "GDLocalURLMetadata.h"
#import "GDURLMetadata_Private.h"

@interface GDLocalFileServiceSession ()

@property (nonatomic, copy, readonly) NSURL *localRootURL;
@property (nonatomic, copy, readonly) NSString *localRootPath;
@property (nonatomic, readonly, strong) NSFileManager *fileManager;

@end

static NSArray *GDLocalFileServiceSessionURLKeys;

@implementation GDLocalFileServiceSession

+ (void)initialize
{
    if (self == [GDLocalFileServiceSession class]) {
        GDLocalFileServiceSessionURLKeys = @[NSURLIsDirectoryKey, NSURLContentModificationDateKey, NSURLFileResourceTypeKey, NSURLIsWritableKey, NSURLNameKey, NSURLTypeIdentifierKey, NSURLFileSizeKey];
    }
}

- (id)initWithBaseURL:(NSURL *)baseURL fileService:(GDFileService *)fileService
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (id)initWithName:(NSString *)sessionName localRootURL:(NSURL *)localRootURL fileService:(GDFileService *)fileService
{
    NSString *baseURLString = [NSString stringWithFormat:@"%@://%@/", [fileService urlScheme], sessionName];
    NSURL *baseURL = [NSURL URLWithString:baseURLString];
    
    if ((self = [super initWithBaseURL:baseURL fileService:fileService])) {
        _localRootURL = [localRootURL URLByStandardizingPath];
        _fileManager = [NSFileManager new];
    }
    
    return self;
}


- (void)validateAccessWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure
{
    BOOL isDirectory = NO;
    if ([self.fileManager fileExistsAtPath:self.localRootPath isDirectory:&isDirectory]) {
        if (isDirectory) {
            if (success) success();
            return;
        }
    }
    if (failure) failure(nil);
}

- (void)getMetadataForURL:(NSURL *)url metadataCache:(id <GDMetadataCache>)metadataCache cachedMetadata:(id<GDURLMetadata>)cachedMetadataOrNil
                  success:(void (^)(GDURLMetadata *metadata))success failure:(void (^)(NSError *error))failure
{
    NSURL *fileURL = [self fileURLFromCanonicalURL:url];
    
    NSError *error = nil;
    NSDictionary *metadataDictionary = [fileURL resourceValuesForKeys:GDLocalFileServiceSessionURLKeys error:&error];
    if (!metadataDictionary) {
        if (failure) failure(error);
        return;
    }
    GDURLMetadata *metadata = [self clientMetadataForMetadataDictionary:metadataDictionary url:url];
    if (success) success(metadata);
    
}

- (void)getContentsOfDirectoryAtURL:(NSURL *)url metadataCache:(id<GDMetadataCache>)metadataCache
                     cachedMetadata:(id<GDURLMetadata>)cachedMetadataOrNil cachedContents:(NSArray *)contentsOrNil
                            success:(void (^)(NSArray *))success failure:(void (^)(NSError *))failure
{
    NSURL *directoryURL = [self fileURLFromCanonicalURL:url];
    
    NSError *error = nil;
    NSArray *directoryContents = [self.fileManager contentsOfDirectoryAtURL:directoryURL
                                                 includingPropertiesForKeys:GDLocalFileServiceSessionURLKeys
                                                                    options:NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                                                      error:&error];
    if (!directoryContents) {
        if (failure) failure(error);
        return;
    }
    NSMutableArray *metadataArray = [NSMutableArray arrayWithCapacity:[directoryContents count]];
    for (NSURL *childURL in directoryContents) {
        GDURLMetadata *urlMetadata = [self clientMetadataFromFileURL:childURL parentURL:url];
        if (urlMetadata) {
            [metadataArray addObject:urlMetadata];
        }
    }
    if (success) success([metadataArray copy]);
}

- (void)deleteURL:(NSURL *)url success:(void (^)())success failure:(void (^)(NSError *))failure
{
    NSError *error = nil;
    NSURL *localURL = [self fileURLFromCanonicalURL:url];
    
    if (![self.fileManager removeItemAtURL:localURL error:&error]) {
        if (failure) failure(error);
        return;
    }
    if (success) success();
}

- (void)copyFileAtURL:(NSURL *)sourceURL toParentURL:(NSURL *)destinationParentURL name:(NSString *)name success:(void (^)(GDURLMetadata *))success failure:(void (^)(NSError *))failure
{
    NSURL *sourceLocalURL = [self fileURLFromCanonicalURL:sourceURL];
    NSURL *destinationLocalParentURL = [self fileURLFromCanonicalURL:destinationParentURL];
    NSURL *destinationLocalURL = [destinationLocalParentURL URLByAppendingPathComponent:name];
    
    NSError *error = nil;
    if (![self.fileManager copyItemAtURL:sourceLocalURL toURL:destinationLocalURL error:&error]) {
        if (failure) failure(error);
        return;
    }
    GDURLMetadata *urlMetadata = [self clientMetadataFromFileURL:destinationLocalURL parentURL:destinationParentURL];
    if (success) success(urlMetadata);
}

- (void)moveFileAtURL:(NSURL *)sourceURL toParentURL:(NSURL *)destinationParentURL name:(NSString *)name success:(void (^)(GDURLMetadata *))success failure:(void (^)(NSError *))failure
{
    NSURL *sourceLocalURL = [self fileURLFromCanonicalURL:sourceURL];
    NSURL *destinationLocalParentURL = [self fileURLFromCanonicalURL:destinationParentURL];
    NSURL *destinationLocalURL = [destinationLocalParentURL URLByAppendingPathComponent:name];
    
    NSError *error = nil;
    if (![self.fileManager moveItemAtURL:sourceLocalURL toURL:destinationLocalURL error:&error]) {
        if (failure) failure(error);
        return;
    }
    GDURLMetadata *urlMetadata = [self clientMetadataFromFileURL:destinationLocalURL parentURL:destinationParentURL];
    if (success) success(urlMetadata);
}

- (NSOperation *)downloadURL:(NSURL *)url intoFileURL:(NSURL *)localURL fileVersion:(NSString *)fileVersionIdentifier
                    progress:(void (^)(NSUInteger, long long, long long))progress
                     success:(void (^)(NSURL *, GDURLMetadata *))success
                     failure:(void (^)(NSError *))failure
{
    GDParentOperation *trivialOperation = [GDParentOperation new]; [trivialOperation finish];
    NSURL *sourceLocalURL = [self fileURLFromCanonicalURL:url];
    
    NSError *error = nil;
    if (![self.fileManager copyItemAtURL:sourceLocalURL toURL:localURL error:&error]) {
        if (failure) failure(error);
        return trivialOperation;
    }
    
    GDURLMetadata *urlMetadata = [self clientMetadataFromFileURL:sourceLocalURL clientURL:url];
    if (success) success(localURL, urlMetadata);
    
    return trivialOperation;
}

- (NSOperation *)uploadFileURL:(NSURL *)localURL mimeType:mimeType toDestinationURL:(NSURL *)destinationURL parentVersionID:(NSString *)parentVersionID
           internalUploadState:(id <NSCoding>)internalUploadState uploadStateHandler:(void (^)(GDFileManagerUploadState * uploadState))uploadStateHandler
                      progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress
                       success:(void (^)(GDURLMetadata *metadata, NSArray *conflicts))success
                       failure:(void (^)(NSError *error))failure
{
    return [self uploadFileURL:localURL toDestinationURL:destinationURL filename:nil mimeType:mimeType parentVersionID:parentVersionID
           internalUploadState:internalUploadState uploadStateHandler:uploadStateHandler
                      progress:progress
                       success:success
                       failure:failure];
}

- (NSOperation *)uploadFileURL:(NSURL *)localURL filename:(NSString *)filename mimeType:(NSString *)mimeType toParentFolderURL:(NSURL *)parentFolderURL
            uploadStateHandler:(void (^)(GDFileManagerUploadState * uploadState))uploadStateHandler
                      progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress
                       success:(void (^)(GDURLMetadata *metadata, NSArray *conflicts))success
                       failure:(void (^)(NSError *error))failure
{
    NSURL *destinationURL = [parentFolderURL URLByAppendingPathComponent:filename];
    
    return [self uploadFileURL:localURL toDestinationURL:destinationURL filename:filename mimeType:mimeType parentVersionID:nil internalUploadState:nil
            uploadStateHandler:uploadStateHandler
                      progress:progress
                       success:success
                       failure:failure];
}


- (NSOperation *)uploadFileURL:(NSURL *)localURL toDestinationURL:(NSURL *)destinationURL
                      filename:(NSString *)filename mimeType:(NSString *)mimeType parentVersionID:(NSString *)parentVersionID
           internalUploadState:(id <NSCoding>)internalUploadState uploadStateHandler:(void (^)(GDFileManagerUploadState * uploadState))uploadStateHandler
                      progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress
                       success:(void (^)(GDURLMetadata *metadata, NSArray *conflicts))success
                       failure:(void (^)(NSError *error))failure
{
    GDParentOperation *trivialOperation = [GDParentOperation new]; [trivialOperation finish];
    NSURL *destinationLocalURL = [self fileURLFromCanonicalURL:destinationURL];
    
    NSError *error = nil;
    if (![self.fileManager copyItemAtURL:localURL toURL:destinationLocalURL error:&error]) {
        if (failure) failure(error);
        return trivialOperation;
    }
    
    GDURLMetadata *urlMetadata = [self clientMetadataFromFileURL:destinationLocalURL clientURL:destinationURL];
    if (success) success(urlMetadata, @[]);
    
    return trivialOperation;
}

#pragma mark 'cache' urls

- (NSURL *)cacheURLForURL:(NSURL *)canonicalURL versionIdentifier:(NSString *)versionIdentifier cachedMetadata:(GDURLMetadata *__autoreleasing *)cachedMetadata
{
    NSURL *fileURL = [self fileURLFromCanonicalURL:canonicalURL];
    if (!fileURL) return nil;
    
    if (!versionIdentifier && !cachedMetadata) return fileURL;
    
    NSError *error = nil;
    NSDictionary *metadataDictionary = [fileURL resourceValuesForKeys:GDLocalFileServiceSessionURLKeys error:&error];
    GDURLMetadata *metadata = [self clientMetadataForMetadataDictionary:metadataDictionary url:canonicalURL];
    if (versionIdentifier && ![metadata.fileVersionIdentifier isEqualToString:versionIdentifier])
        return nil;
    
    if (cachedMetadata) {
        *cachedMetadata = metadata;
    }
    
    return fileURL;
}


#pragma mark - URL / path support

- (NSString *)absolutePathFromCanonicalURL:(NSURL *)url
{
    return [[self fileURLFromCanonicalURL:url] path];
}

- (NSURL *)fileURLFromCanonicalURL:(NSURL *)url
{
    return [[self.localRootURL URLByAppendingPathComponent:[url path]] URLByStandardizingPath];
}

- (NSString *)filenameFromCanonicalURL:(NSURL *)url
{
    return [url lastPathComponent];
}

- (NSString *)localRootPath
{
    return [self.localRootURL path];
}

- (GDURLMetadata *)clientMetadataForMetadataDictionary:(NSDictionary *)metadataDictionary url:(NSURL *)url
{
    url = [self canonicalURLForURL:url];
    GDLocalURLMetadata *localURLMetadata = [[GDLocalURLMetadata alloc] initWithMetadataDictionary:metadataDictionary];
    return [[GDURLMetadata alloc] initWithURLMetadata:localURLMetadata clientURL:url canonicalURL:url];
}

- (GDURLMetadata *)clientMetadataFromFileURL:(NSURL *)fileURL clientURL:(NSURL *)clientURL
{
    return [self clientMetadataFromFileURL:fileURL parentURL:nil clientURL:clientURL];
}


- (GDURLMetadata *)clientMetadataFromFileURL:(NSURL *)fileURL parentURL:(NSURL *)parentURL
{
    return [self clientMetadataFromFileURL:fileURL parentURL:parentURL clientURL:nil];
}


- (GDURLMetadata *)clientMetadataFromFileURL:(NSURL *)fileURL parentURL:(NSURL *)parentURL clientURL:(NSURL *)clientURL
{
    NSParameterAssert(parentURL || clientURL);
    
    NSError *error = nil;
    NSDictionary *metadataDictionary = [fileURL resourceValuesForKeys:GDLocalFileServiceSessionURLKeys error:&error];
    if (!metadataDictionary) {
        NSLog(@"Error getting child metadata: %@", error);
        return nil;
    }
    GDLocalURLMetadata *localURLMetadata = [[GDLocalURLMetadata alloc] initWithMetadataDictionary:metadataDictionary];
    if (!clientURL)
        clientURL = [self canonicalURLForURL:[parentURL URLByAppendingPathComponent:[localURLMetadata filename]]];
    return [[GDURLMetadata alloc] initWithURLMetadata:localURLMetadata clientURL:clientURL canonicalURL:clientURL];
}

@end
