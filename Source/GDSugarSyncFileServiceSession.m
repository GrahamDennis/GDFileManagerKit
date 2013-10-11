//
//  GDSugarSyncFileServiceSession.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 29/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDSugarSyncFileServiceSession.h"
#import "GDSugarSyncURLMetadata.h"
#import "GDSugarSyncURLMetadata_Private.h"
#import "GDSugarSync.h"
#import "GDFileService.h"

#import "GDURLMetadata_Private.h"
#import "GDFileManagerUploadState.h"
#import "GDHTTPOperation.h"

#import "AsyncSequentialEnumeration.h"

@interface GDSugarSyncFileServiceSession ()

@property (nonatomic, strong, readonly) GDURLMetadata *workspacesMetadata;
@property (nonatomic, strong, readonly) GDURLMetadata *syncFoldersMetadata;
@property (nonatomic, strong, readonly) GDURLMetadata *rootMetadata;
@property (nonatomic, strong, readonly) NSArray *rootFolderContents;

@end

@implementation GDSugarSyncFileServiceSession

@dynamic client;

@synthesize workspacesMetadata = _workspacesMetadata;
@synthesize syncFoldersMetadata = _syncFoldersMetadata;
@synthesize rootMetadata = _rootMetadata;
@synthesize rootFolderContents = _rootFolderContents;

- (void)validateAccessWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure
{
    [self.client getAccountInfoWithSuccess:^(GDSugarSyncAccountInfo *accountInfo) {
        if (success) {
            success();
        }
    } failure:failure];
}

- (void)getMetadataForURL:(NSURL *)url metadataCache:(id <GDMetadataCache>)metadataCache cachedMetadata:(id<GDURLMetadata>)cachedMetadataOrNil
                  success:(void (^)(GDURLMetadata *metadata))success failure:(void (^)(NSError *error))failure
{
    if ([[url path] isEqualToString:@"/"] || ![url path]) {
        if (success) success([self rootMetadata]);
        return;
    }
    
    NSString *objectID = [self objectIDFromURL:url];
    
    [self.client getMetadataForObjectID:objectID
                                success:^(GDSugarSyncMetadata *metadata) {
                                    GDURLMetadata *urlMetadata = [self clientMetadataForSugarSyncMetadata:metadata clientURL:url];
                                    [metadataCache setMetadata:urlMetadata forURL:urlMetadata.canonicalURL];
                                    
                                    if (success) success(urlMetadata);
                                } failure:failure];
}

- (void)getLatestVersionIdentifierForURL:(NSURL *)url metadataCache:(id <GDMetadataCache>)metadataCache cachedMetadata:(id <GDURLMetadata>)cachedMetadataOrNil
                                 success:(void (^)(NSString *fileVersionIdentifier))success failure:(void (^)(NSError *error))failure
{
    NSString *objectID = [self objectIDFromURL:url];
    
    [self.client getVersionHistoryForObjectID:objectID
                                      success:^(NSArray *history) {
                                          for (GDSugarSyncMetadata *metadata in history) {
                                              NSString *fileVersionID = metadata.objectID;
                                              if (cachedMetadataOrNil) {
                                                  GDURLMetadata *clientMetadata = [self clientMetadataForSugarSyncMetadata:[(GDSugarSyncURLMetadata *)cachedMetadataOrNil metadata]
                                                                                                                 parentURL:nil
                                                                                                                 clientURL:url
                                                                                                             fileVersionID:fileVersionID];
                                                  [metadataCache setMetadata:clientMetadata forURL:url];
                                              }
                                              if (success) success(metadata.objectID);
                                              return;
                                          }
                                          if (failure) failure(nil);
                                      } failure:failure];
}



- (void)getContentsOfDirectoryAtURL:(NSURL *)url metadataCache:(id<GDMetadataCache>)metadataCache
                     cachedMetadata:(id<GDURLMetadata>)cachedMetadataOrNil cachedContents:(NSArray *)contentsOrNil
                         success:(void (^)(NSArray *))success failure:(void (^)(NSError *))failure
{
    NSString *objectID = [self objectIDFromURL:url];
    if ([objectID isEqualToString:@"/"] || [objectID isEqualToString:@""]) {
        if (success) success(self.rootFolderContents);
        return;
    }
    
    [self.client getContentsOfCollectionID:objectID
                                success:^(NSArray *contents) {
                                    [self addMetadata:contents parentURL:url toCache:metadataCache
                                         continuation:^(GDURLMetadata *metadata, NSArray *metadataContents) {
                                             if (success)
                                                 success(metadataContents);
                                         }];
                                } failure:failure];
    
}

- (void)deleteURL:(NSURL *)url success:(void (^)())success failure:(void (^)(NSError *))failure
{
    NSString *objectID = [self objectIDFromURL:url];
    if (!objectID || [objectID isEqualToString:@"/"] || [objectID isEqualToString:@""]) {
        if (failure) failure(nil);
        return;
    }
    
    [self.client trashObjectID:objectID success:success failure:failure];
}

- (void)copyFileAtURL:(NSURL *)sourceURL toParentURL:(NSURL *)destinationParentURL name:(NSString *)name success:(void (^)(GDURLMetadata *))success failure:(void (^)(NSError *))failure
{
    NSParameterAssert(name);
    NSString *sourceFileID = [self objectIDFromURL:sourceURL];
    NSString *destinationFolderID = [self objectIDFromURL:destinationParentURL];
    if (![sourceFileID hasPrefix:@"/file"] || ![destinationFolderID hasPrefix:@"/folder"]) {
        if (failure) failure(GDFileManagerError(GDFileManagerUnsupportedOperationError));
        return;
    }
    
    [self.client copyFileID:sourceFileID toFolderID:destinationFolderID name:name success:^(NSString *newFileID){
        NSURL *newFileURL = [self clientURLByAppendingObjectID:newFileID toClientURL:destinationParentURL];
        [self getMetadataForURL:newFileURL metadataCache:nil cachedMetadata:nil success:success failure:failure];
    } failure:failure];
}

- (void)moveFileAtURL:(NSURL *)sourceURL toParentURL:(NSURL *)destinationParentURL name:(NSString *)name success:(void (^)(GDURLMetadata *))success failure:(void (^)(NSError *))failure
{
    NSParameterAssert(name);
    NSString *sourceFileID = [self objectIDFromURL:sourceURL];
    NSString *destinationFolderID = [self objectIDFromURL:destinationParentURL];
    
    [self.client moveObjectID:sourceFileID toFolderID:destinationFolderID name:name success:^(NSString *newFileID){
        NSURL *newFileURL = [self clientURLByAppendingObjectID:newFileID toClientURL:destinationParentURL];
        [self getMetadataForURL:newFileURL metadataCache:nil cachedMetadata:nil success:success failure:failure];
    } failure:failure];
}

- (NSOperation *)downloadURL:(NSURL *)url intoFileURL:(NSURL *)localURL fileVersion:(NSString *)fileVersionIdentifier
                    progress:(void (^)(NSUInteger, long long, long long))progress
                     success:(void (^)(NSURL *, GDURLMetadata *metadata))success
                     failure:(void (^)(NSError *))failure
{
    NSString *fileID = [self objectIDFromURL:url];
    
    return [self.client downloadFileID:fileID intoPath:[localURL path] fileVersionID:fileVersionIdentifier
                              progress:progress
                               success:^(NSString *localPath, GDSugarSyncMetadata *metadata, NSString *fileVersionID) {
                                   GDURLMetadata *urlMetadata = [self clientMetadataForSugarSyncMetadata:metadata parentURL:nil clientURL:url fileVersionID:fileVersionID];
                                   if (success) success([NSURL fileURLWithPath:localPath], urlMetadata);
                               } failure:failure];
}

- (NSOperation *)uploadFileURL:(NSURL *)localURL mimeType:mimeType toDestinationURL:(NSURL *)destinationURL parentVersionID:(NSString *)parentVersionID
           internalUploadState:(GDSugarSyncUploadState *)internalUploadState uploadStateHandler:(void (^)(GDFileManagerUploadState * uploadState))uploadStateHandler
                      progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress
                       success:(void (^)(GDURLMetadata *metadata, NSArray *conflicts))success
                       failure:(void (^)(NSError *error))failure
{
    NSString *localPath = [localURL path];
    NSString *destinationFileID = [self objectIDFromURL:destinationURL];
    
    return [self.client uploadFile:localPath toFileID:destinationFileID parentVersionID:parentVersionID
                       uploadState:internalUploadState
                uploadStateHandler:^(GDSugarSyncUploadState *uploadState) {
                    if (uploadStateHandler) {
                        GDFileManagerUploadState *clientUploadState = [[GDFileManagerUploadState alloc] initWithUploadState:uploadState
                                                                                                                   mimeType:mimeType
                                                                                                                  uploadURL:destinationURL
                                                                                                            parentVersionID:parentVersionID];
                        uploadStateHandler(clientUploadState);
                    }
                } progress:progress
                           success:^(GDSugarSyncMetadata *metadata, NSString *fileVersionID, NSArray *conflictingVersionIDs) {
                               GDURLMetadata *urlMetadata = [self clientMetadataForSugarSyncMetadata:metadata parentURL:nil clientURL:destinationURL fileVersionID:fileVersionID];
                               if (success) success(urlMetadata, conflictingVersionIDs);
                           } failure:failure];
}

- (NSOperation *)uploadFileURL:(NSURL *)localURL filename:(NSString *)filename mimeType:mimeType toParentFolderURL:(NSURL *)parentFolderURL
            uploadStateHandler:(void (^)(GDFileManagerUploadState * uploadState))uploadStateHandler
                      progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress
                       success:(void (^)(GDURLMetadata *metadata, NSArray *conflicts))success_
                       failure:(void (^)(NSError *error))failure_
{
    __block GDParentOperation *parentOperation = [GDParentOperation new];
    dispatch_block_t cleanup = ^{[parentOperation finish]; parentOperation = nil; };
    typeof(success_) success = ^(GDURLMetadata *metadata, NSArray *conflicts){
        dispatch_async(parentOperation.successCallbackQueue, ^{
            if (success_) success_(metadata, conflicts);
            cleanup();
        });
    };
    typeof(failure_) failure = ^(NSError *error){
        dispatch_async(parentOperation.failureCallbackQueue, ^{
            if (failure_) failure_(error);
            cleanup();
        });
    };
    
    NSString *parentCollectionID = [self objectIDFromURL:parentFolderURL];
    
    [self.client createFileWithName:filename mimeType:mimeType inCollectionID:parentCollectionID
                            success:^(NSString *fileID) {
                                if (!parentOperation || ![parentOperation isExecuting]) {
                                    return failure(GDOperationCancelledError);
                                }
                                NSURL *destinationURL = [self clientURLByAppendingObjectID:fileID toClientURL:parentFolderURL];
                                NSOperation *childOperation = [self uploadFileURL:localURL mimeType:mimeType toDestinationURL:destinationURL parentVersionID:nil
                                                              internalUploadState:nil uploadStateHandler:uploadStateHandler
                                                                         progress:progress
                                                                          success:success
                                                                          failure:failure];
                                [parentOperation addChildOperation:childOperation];
                            } failure:failure];
    
    [parentOperation start];
    
    return parentOperation;
}

#pragma mark - URL support

- (NSString *)objectIDFromURL:(NSURL *)url
{
    NSString *escapedObjectID = [url lastPathComponent];
    
    return [escapedObjectID stringByReplacingOccurrencesOfString:@"+" withString:@"/"];
}

- (NSURL *)clientURLByAppendingObjectID:(NSString *)objectID toClientURL:(NSURL *)parentURL
{
    NSString *escapedObjectID = [objectID stringByReplacingOccurrencesOfString:@"/" withString:@"+"];
    if (!escapedObjectID) return nil;
    
    return [parentURL URLByAppendingPathComponent:escapedObjectID];
}

- (NSURL *)_canonicalURLForURL:(NSURL *)url
{
    if ([[url pathComponents] count] <= 2) return url;
    return [self.baseURL URLByAppendingPathComponent:[url lastPathComponent]];
}

- (GDURLMetadata *)clientMetadataForSugarSyncMetadata:(GDSugarSyncMetadata *)metadata parentURL:(NSURL *)parentURL
{
    return [self clientMetadataForSugarSyncMetadata:metadata parentURL:parentURL clientURL:nil fileVersionID:nil];
}

- (GDURLMetadata *)clientMetadataForSugarSyncMetadata:(GDSugarSyncMetadata *)metadata clientURL:(NSURL *)clientURL
{
    return [self clientMetadataForSugarSyncMetadata:metadata parentURL:nil clientURL:clientURL fileVersionID:nil];
}

- (GDURLMetadata *)clientMetadataForSugarSyncMetadata:(GDSugarSyncMetadata *)metadata parentURL:(NSURL *)parentURL clientURL:(NSURL *)clientURL fileVersionID:(NSString *)fileVersionID
{
    if (!clientURL && !parentURL) return nil;
    GDSugarSyncURLMetadata *ssURLMetadata = [[GDSugarSyncURLMetadata alloc] initWithSugarSyncMetadata:metadata fileVersionID:fileVersionID];
    
    if (!clientURL)
        clientURL = [self clientURLByAppendingObjectID:metadata.objectID toClientURL:parentURL];
    
    return [[GDURLMetadata alloc] initWithURLMetadata:ssURLMetadata
                                            clientURL:clientURL
                                         canonicalURL:[self canonicalURLForURL:clientURL]];
}

- (GDURLMetadata *)clientMetadataWithCachedMetadata:(id<GDURLMetadata>)urlMetadata parentURL:(NSURL *)url
{
    NSURL *clientURL = [self clientURLByAppendingObjectID:[(GDSugarSyncURLMetadata *)urlMetadata objectID] toClientURL:url];
    if (!clientURL) return nil;
    
    return [[GDURLMetadata alloc] initWithURLMetadata:urlMetadata
                                            clientURL:clientURL
                                         canonicalURL:[self canonicalURLForURL:clientURL]];
}

#pragma mark - Support

- (void)addMetadata:(NSArray *)metadataArray parentURL:(NSURL *)parentURL toCache:(id<GDMetadataCache>)cache continuation:(void (^)(GDURLMetadata*, NSArray *))continuation
{
    NSMutableArray *urlMetadataArray = [NSMutableArray arrayWithCapacity:[metadataArray count]];
    NSMutableDictionary *keyedMetadataToCache = [NSMutableDictionary dictionaryWithCapacity:[metadataArray count]];
    
    for (GDSugarSyncMetadata *metadata in metadataArray) {
        GDURLMetadata *urlMetadata = [self clientMetadataForSugarSyncMetadata:metadata parentURL:parentURL];
        if (urlMetadata) {
            NSURL *canonicalURL = urlMetadata.canonicalURL;
            keyedMetadataToCache[canonicalURL] = urlMetadata;
            [urlMetadataArray addObject:urlMetadata];
        }
    }
    [cache setDirectoryContents:keyedMetadataToCache forURL:[self canonicalURLForURL:parentURL]];
    
    return continuation(nil, [urlMetadataArray copy]);
}

- (GDURLMetadata *)workspacesMetadata
{
    if (!_workspacesMetadata) {
        GDSugarSyncMetadata *metadata = [self.client workspacesMetadata];
        _workspacesMetadata = [self clientMetadataForSugarSyncMetadata:metadata parentURL:self.baseURL];
    }
    
    return _workspacesMetadata;
}

- (GDURLMetadata *)syncFoldersMetadata
{
    if (!_syncFoldersMetadata) {
        GDSugarSyncMetadata *metadata = [self.client syncFoldersMetadata];
        _syncFoldersMetadata = [self clientMetadataForSugarSyncMetadata:metadata parentURL:self.baseURL];
    }
    
    return _syncFoldersMetadata;
}

- (GDURLMetadata *)rootMetadata
{
    if (!_rootMetadata) {
        GDSugarSyncMetadata *metadata = [self.client rootMetadata];
        _rootMetadata = [self clientMetadataForSugarSyncMetadata:metadata clientURL:self.baseURL];
    }
    
    return _rootMetadata;
}

- (NSArray *)rootFolderContents
{
    if (!_rootFolderContents) {
        _rootFolderContents = @[self.syncFoldersMetadata, self.workspacesMetadata];
    }
    return _rootFolderContents;
}

@end
