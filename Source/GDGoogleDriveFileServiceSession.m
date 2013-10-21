//
//  GDGoogleDriveFileServiceSession.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 29/06/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDGoogleDriveFileServiceSession.h"
#import "GDGoogleDriveFileService.h"
#import "GDGoogleDriveURLMetadata.h"

#import "GDURLMetadata_Private.h"
#import "GDFileManagerUploadState.h"

#import "AsyncSequentialEnumeration.h"

@implementation GDGoogleDriveFileServiceSession

@dynamic client;

- (id)initWithFileService:(GDFileService *)fileService client:(GDHTTPClient *)client
{
    if (([super initWithFileService:fileService client:client])) {
        [(GDGoogleDriveClient *)client setDefaultMetadataFields:@"id,etag,title,mimeType,md5Checksum,fileSize,headRevisionId,editable,parents"];
    }
    
    return self;
}

- (void)validateAccessWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure
{
    [self.client getAccountInfoWithSuccess:^(GDGoogleDriveAccountInfo *accountInfo) {
        if (success) {
            success();
        }
    } failure:failure];
}

- (void)getMetadataForURL:(NSURL *)url metadataCache:(id <GDMetadataCache>)metadataCache cachedMetadata:(id<GDURLMetadata>)cachedMetadata
                  success:(void (^)(GDURLMetadata *metadata))success failure:(void (^)(NSError *error))failure
{
    NSString *fileID = [self fileIDFromURL:url];
    NSURL *canonicalURL = [self canonicalURLForURL:url];
    if (!cachedMetadata)
        cachedMetadata = [metadataCache metadataForURL:canonicalURL];
    
    [self.client getMetadataForFileID:fileID etag:[(GDGoogleDriveURLMetadata *)cachedMetadata etag]
                              success:^(GDGoogleDriveMetadata *metadata) {
                                  GDURLMetadata *urlMetadata = nil;
                                  if (!metadata) {
                                      urlMetadata = [[GDURLMetadata alloc] initWithURLMetadata:cachedMetadata clientURL:url canonicalURL:canonicalURL];
                                  } else {
                                      urlMetadata = [self clientMetadataForGoogleDriveMetadata:metadata clientURL:url];
                                  }
                                  [metadataCache setMetadata:urlMetadata forURL:urlMetadata.canonicalURL];
                                  if (success) success(urlMetadata);
                              } failure:failure];
}

- (void)getContentsOfDirectoryAtURL:(NSURL *)url metadataCache:(id<GDMetadataCache>)metadataCache
                     cachedMetadata:(id<GDURLMetadata>)cachedMetadata cachedContents:(NSArray *)contents
                            success:(void (^)(NSArray *))success failure:(void (^)(NSError *))failure
{
    NSString *fileID = [self fileIDFromURL:url];
    
    [self.client getContentsOfFileID:fileID
                             success:^(NSArray *contents, NSString *etag) {
                                 return [self addMetadata:contents parentURL:url toCache:metadataCache
                                             continuation:^(GDURLMetadata *metadata, NSArray *metadataContents) {
                                                 if (success) success(metadataContents);
                                             }];
                             } failure:failure];
}

- (void)deleteURL:(NSURL *)url success:(void (^)())success failure:(void (^)(NSError *))failure
{
    NSString *fileID = [self fileIDFromURL:url];
    
    [self.client trashFileID:fileID
                     success:^(GDGoogleDriveMetadata *metadata) {
                         if (success) success();
                     } failure:failure];
}

- (void)copyFileAtURL:(NSURL *)sourceURL toParentURL:(NSURL *)destinationParentURL name:(NSString *)name success:(void (^)(GDURLMetadata *))success failure:(void (^)(NSError *))failure
{
    NSString *sourceFileID = [self fileIDFromURL:sourceURL];
    NSString *destinationFolderID = [self fileIDFromURL:destinationParentURL];
    
    [self.client copyFileID:sourceFileID toParentIDs:@[destinationFolderID] name:name success:^(GDGoogleDriveMetadata *metadata) {
        if (success) success([self clientMetadataForGoogleDriveMetadata:metadata parentURL:destinationParentURL]);
    } failure:failure];
}

- (void)moveFileAtURL:(NSURL *)sourceURL toParentURL:(NSURL *)destinationParentURL name:(NSString *)name success:(void (^)(GDURLMetadata *))success failure:(void (^)(NSError *))failure
{
    NSString *sourceFileID = [self fileIDFromURL:sourceURL];
    NSString *destinationFolderID = [self fileIDFromURL:destinationParentURL];
    
    [self.client moveFileID:sourceFileID toParentIDs:@[destinationFolderID] name:name success:^(GDGoogleDriveMetadata *metadata) {
        if (success) success([self clientMetadataForGoogleDriveMetadata:metadata parentURL:destinationParentURL]);
    } failure:failure];
}

- (NSOperation *)downloadURL:(NSURL *)url intoFileURL:(NSURL *)localURL fileVersion:(NSString *)fileVersionIdentifier
                    progress:(void (^)(NSUInteger, long long, long long))progress
                     success:(void (^)(NSURL *localURL, GDURLMetadata *metadata))success failure:(void (^)(NSError *))failure
{
    NSString *fileID = [self fileIDFromURL:url];
    
    return [self.client downloadFileID:fileID intoPath:[localURL path]
                              progress:progress
                               success:^(NSString *localPath, GDGoogleDriveMetadata *metadata) {
                                   GDURLMetadata *urlMetadata = [self clientMetadataForGoogleDriveMetadata:metadata clientURL:url];
                                   if (success) success([NSURL fileURLWithPath:localPath], urlMetadata);
                               } failure:failure];

}

- (NSOperation *)uploadFileURL:(NSURL *)localURL mimeType:mimeType toDestinationURL:(NSURL *)destinationURL parentVersionID:(NSString *)parentVersionID
           internalUploadState:(GDGoogleDriveUploadState *)internalUploadState uploadStateHandler:(void (^)(GDFileManagerUploadState * uploadState))uploadStateHandler
                      progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress
                       success:(void (^)(GDURLMetadata *metadata, NSArray *conflicts))success
                       failure:(void (^)(NSError *error))failure
{
    NSString *localPath = [localURL path];
    NSString *destinationFileID = [self fileIDFromURL:destinationURL];
    
    return [self.client uploadFile:localPath toFileID:destinationFileID parentVersionID:parentVersionID
                       uploadState:internalUploadState
                uploadStateHandler:^(GDGoogleDriveUploadState *uploadState) {
                    if (uploadStateHandler) {
                        GDFileManagerUploadState *clientUploadState = [[GDFileManagerUploadState alloc] initWithUploadState:uploadState
                                                                                                                               mimeType:mimeType
                                                                                                                              uploadURL:destinationURL
                                                                                                                        parentVersionID:parentVersionID];
                        uploadStateHandler(clientUploadState);
                    }
                } progress:progress
                           success:^(GDGoogleDriveMetadata *metadata, NSArray *conflictingVersionIDs) {
                               GDURLMetadata *urlMetadata = [self clientMetadataForGoogleDriveMetadata:metadata clientURL:destinationURL];
                               if (success) success(urlMetadata, conflictingVersionIDs);
                           } failure:failure];
}

static NSString *const kFilenameKey = @"Filename";

- (NSOperation *)uploadFileURL:(NSURL *)localURL filename:(NSString *)filename mimeType:mimeType toParentFolderURL:(NSURL *)parentFolderURL
            uploadStateHandler:(void (^)(GDFileManagerUploadState * uploadState))uploadStateHandler
                      progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress
                       success:(void (^)(GDURLMetadata *metadata, NSArray *conflicts))success
                       failure:(void (^)(NSError *error))failure
{
    return [self uploadFileURL:localURL filename:filename mimeType:mimeType toParentFolderURL:parentFolderURL
           internalUploadState:nil uploadStateHandler:uploadStateHandler
                      progress:progress success:success failure:failure];
}

- (NSOperation *)uploadFileURL:(NSURL *)localURL filename:(NSString *)filename mimeType:mimeType toParentFolderURL:(NSURL *)parentFolderURL
           internalUploadState:(GDGoogleDriveUploadState *)internalUploadState uploadStateHandler:(void (^)(GDFileManagerUploadState * uploadState))uploadStateHandler
                      progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress
                       success:(void (^)(GDURLMetadata *metadata, NSArray *conflicts))success
                       failure:(void (^)(NSError *error))failure
{
    NSString *parentFolderID = [self fileIDFromURL:parentFolderURL];
    NSString *localPath = [localURL path];

    return [self.client uploadFile:localPath destinationFilename:filename mimeType:mimeType parentFolderID:parentFolderID
                       uploadState:internalUploadState
                uploadStateHandler:^(GDGoogleDriveUploadState *uploadState) {
                    if (uploadStateHandler) {
                        GDFileManagerUploadState *clientUploadState = [[GDFileManagerUploadState alloc] initWithUploadState:uploadState
                                                                                                                   mimeType:mimeType
                                                                                                                  uploadURL:parentFolderURL
                                                                                                            parentVersionID:nil
                                                                                                                 extraState:@{kFilenameKey: filename}];
                        uploadStateHandler(clientUploadState);
                    }
                } progress:progress
                           success:^(GDGoogleDriveMetadata *metadata, NSArray *conflicts) {
                               GDURLMetadata *urlMetadata = [self clientMetadataForGoogleDriveMetadata:metadata parentURL:parentFolderURL];
                               if (success) success(urlMetadata, conflicts);
                           } failure:failure];
}

- (NSOperation *)resumeUploadWithUploadState:(GDFileManagerUploadState *)uploadState fromFileURL:(NSURL *)localURL
                          uploadStateHandler:(void (^)(GDFileManagerUploadState *))uploadStateHandler
                                    progress:(void (^)(NSUInteger, long long, long long))progress
                                     success:(void (^)(GDURLMetadata *, NSArray *))success
                                     failure:(void (^)(NSError *))failure
{
    if (![uploadState isKindOfClass:[GDFileManagerUploadState class]]) {
        if (failure) failure(nil);
        return nil;
    }
    GDFileManagerUploadState *simpleUploadState = uploadState;
    NSString *mimeType = simpleUploadState.mimeType;
    GDGoogleDriveUploadState *internalUploadState = (GDGoogleDriveUploadState *)simpleUploadState.uploadState;
    if (simpleUploadState.extraState[kFilenameKey]) {
        NSString *filename = simpleUploadState.extraState[kFilenameKey];
        NSURL *parentURL = simpleUploadState.uploadURL;
        return [self uploadFileURL:localURL filename:filename mimeType:mimeType toParentFolderURL:parentURL
               internalUploadState:internalUploadState uploadStateHandler:uploadStateHandler
                          progress:progress success:success failure:failure];
        
    } else {
        NSURL *destinationURL = simpleUploadState.uploadURL;
        return [self uploadFileURL:localURL mimeType:mimeType toDestinationURL:destinationURL parentVersionID:simpleUploadState.parentVersionID
               internalUploadState:internalUploadState uploadStateHandler:uploadStateHandler
                          progress:progress success:success failure:failure];
    }
}


#pragma mark - URL / path support

- (NSString *)fileIDFromURL:(NSURL *)canonicalURL
{
    NSString *lastPathComponent = [canonicalURL lastPathComponent];
    if ([lastPathComponent isEqualToString:@"/"])
        return @"root";
    return lastPathComponent;
}

- (NSURL *)clientURLByAppendingFileID:(NSString *)fileID toClientURL:(NSURL *)parentURL
{
    return [parentURL URLByAppendingPathComponent:fileID];
}

- (NSURL *)_canonicalURLForURL:(NSURL *)url
{
    if ([[url lastPathComponent] isEqualToString:@"/"])
        return self.baseURL;
    return [self.baseURL URLByAppendingPathComponent:[url lastPathComponent]];
}

- (GDURLMetadata *)clientMetadataForGoogleDriveMetadata:(GDGoogleDriveMetadata *)metadata parentURL:(NSURL *)parentURL
{
    return [self clientMetadataForGoogleDriveMetadata:metadata parentURL:parentURL clientURL:nil];
}

- (GDURLMetadata *)clientMetadataForGoogleDriveMetadata:(GDGoogleDriveMetadata *)metadata clientURL:(NSURL *)clientURL
{
    return [self clientMetadataForGoogleDriveMetadata:metadata parentURL:nil clientURL:clientURL];
}

- (GDURLMetadata *)clientMetadataForGoogleDriveMetadata:(GDGoogleDriveMetadata *)metadata parentURL:(NSURL *)parentURL clientURL:(NSURL *)clientURL
{
    if (!parentURL && !clientURL) return nil;
    if (!clientURL)
        clientURL = [self clientURLByAppendingFileID:metadata.identifier toClientURL:parentURL];
    return [[GDURLMetadata alloc] initWithURLMetadata:[[GDGoogleDriveURLMetadata alloc] initWithGoogleDriveMetadata:metadata]
                                            clientURL:clientURL
                                         canonicalURL:[self canonicalURLForURL:clientURL]];
}

- (GDURLMetadata *)clientMetadataWithCachedMetadata:(id<GDURLMetadata>)urlMetadata parentURL:(NSURL *)url
{
    NSURL *clientURL = [self clientURLByAppendingFileID:[(GDGoogleDriveURLMetadata *)urlMetadata fileID] toClientURL:url];
    
    return [[GDURLMetadata alloc] initWithURLMetadata:urlMetadata
                                            clientURL:clientURL
                                         canonicalURL:[self canonicalURLForURL:clientURL]];
}

#pragma mark - Support

- (void)addMetadata:(NSArray *)metadataArray parentURL:(NSURL *)parentURL toCache:(id<GDMetadataCache>)cache continuation:(void (^)(GDURLMetadata *, NSArray *))continuation
{
    NSMutableArray *childMetadataArray = [NSMutableArray arrayWithCapacity:[metadataArray count]];
    NSMutableDictionary *keyedChildMetadata = [NSMutableDictionary dictionaryWithCapacity:[metadataArray count]];
    
    for (GDGoogleDriveMetadata *metadata in metadataArray) {
        GDURLMetadata *urlMetadata = [self clientMetadataForGoogleDriveMetadata:metadata parentURL:parentURL];
        if (urlMetadata) {
            NSURL *canonicalURL = urlMetadata.canonicalURL;
            [childMetadataArray addObject:urlMetadata];
            keyedChildMetadata[canonicalURL] = urlMetadata;
        }
    }
    [cache setDirectoryContents:keyedChildMetadata forURL:[self canonicalURLForURL:parentURL]];
    
    return continuation(nil, [childMetadataArray copy]);
}


@end
