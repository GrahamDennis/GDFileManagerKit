//
//  GDDropboxFileServiceSession.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 27/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDDropboxFileServiceSession.h"
#import "GDDropbox.h"
#import "GDFileManager.h"
#import "GDDropboxURLMetadata.h"
#import "GDURLMetadata_Private.h"
#import "GDFileService.h"
#import "GDFileManagerUploadState.h"

@interface GDDropboxFileServiceSession ()


@end

@implementation GDDropboxFileServiceSession

@dynamic client;

- (BOOL)automaticallyAvoidsUploadOverwrites
{
    return YES;
}

- (void)validateAccessWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure
{
    [self.client getAccountInfoWithSuccess:^(GDDropboxAccountInfo *accountInfo) {
        if ([accountInfo.userID isEqualToString:self.client.userID]) {
            if (success) {
                success();
            }
        } else {
            NSError *error = [NSError errorWithDomain:GDFileManagerErrorDomain code:GDFileManagerUserIDChangedError userInfo:nil];
            if (failure)
                failure(error);
        }
    } failure:failure];
}

- (void)getMetadataForURL:(NSURL *)url metadataCache:(id <GDMetadataCache>)metadataCache cachedMetadata:(id<GDURLMetadata>)cachedMetadataOrNil
                  success:(void (^)(GDURLMetadata *metadata))success failure:(void (^)(NSError *error))failure
{
    [self getMetadataAndContentsForURL:url metadataCache:metadataCache cachedMetadata:cachedMetadataOrNil cachedContents:nil
                               success:^(GDURLMetadata *metadata, NSArray *metadataContents) {
                                   if (success) success(metadata);
                               } failure:failure];
}

- (void)getContentsOfDirectoryAtURL:(NSURL *)url metadataCache:(id<GDMetadataCache>)metadataCache
                     cachedMetadata:(id<GDURLMetadata>)cachedMetadataOrNil cachedContents:(NSArray *)contentsOrNil
                            success:(void (^)(NSArray *))success failure:(void (^)(NSError *))failure
{
    [self getMetadataAndContentsForURL:url metadataCache:metadataCache
                        cachedMetadata:cachedMetadataOrNil cachedContents:contentsOrNil
                               success:^(GDURLMetadata *metadata, NSArray *metadataContents) {
                                   if (success) success(metadataContents);
                               } failure:failure];
}

- (void)getMetadataAndContentsForURL:(NSURL *)url metadataCache:(id<GDMetadataCache>)metadataCache
                      cachedMetadata:(id <GDURLMetadata>)cachedMetadata cachedContents:(NSArray *)cachedMetadataArray
                             success:(void (^)(GDURLMetadata *metadata, NSArray *metadataContents))success failure:(void (^)(NSError *))failure
{
    if (!cachedMetadata)
        cachedMetadata = [metadataCache metadataForURL:url];
    
    NSURL *canonicalURL = [self canonicalURLForURL:url];
    NSString *directoryContentsHash = nil;
    NSString *dropboxPath = [self dropboxPathFromCanonicalURL:url];
    if (!cachedMetadataArray)
        cachedMetadataArray = [metadataCache directoryContentsMetadataArrayForURL:url];
    
    if (cachedMetadata && cachedMetadata.isDirectory && [(GDDropboxURLMetadata *)cachedMetadata directoryContentsHash] && cachedMetadataArray) {
        directoryContentsHash = [(GDDropboxURLMetadata *)cachedMetadata directoryContentsHash];
    }
    
    [self.client getMetadataForPath:dropboxPath withHash:directoryContentsHash success:^(GDDropboxMetadata *metadata, BOOL didChange) {
        if (didChange && metadata) {
            [self addMetadata:metadata parentURL:url toCache:metadataCache continuation:^(GDURLMetadata *urlMetadata, NSArray *metadataContents) {
                if ([metadata isDeleted]) {
                    if (failure) failure(GDFileManagerError(GDFileManagerFileDeletedError));
                    return;
                } else {
                    if (success) success(urlMetadata, metadataContents);
                }
            }];
            return;
        } else {
            if ([metadata isDeleted]) {
                if (failure) failure(GDFileManagerError(GDFileManagerFileDeletedError));
            } else if (success) {
                GDURLMetadata *urlMetadata = [[GDURLMetadata alloc] initWithURLMetadata:cachedMetadata clientURL:url canonicalURL:canonicalURL];
                NSArray *urlMetadataArray = [self clientMetadataArrayWithCachedMetadataArray:cachedMetadataArray parentURL:url cache:metadataCache];
                return success(urlMetadata, urlMetadataArray);
            }
        }
    } failure:failure];
}

- (void)deleteURL:(NSURL *)url success:(void (^)())success failure:(void (^)(NSError *))failure
{
    NSString *dropboxPath = [self dropboxPathFromCanonicalURL:url];
    
    return [self.client deletePath:dropboxPath success:^(GDDropboxMetadata *metadata) {
        if (success) success();
    } failure:failure];
}

- (void)copyFileAtURL:(NSURL *)sourceURL toParentURL:(NSURL *)destinationParentURL name:(NSString *)name success:(void (^)(GDURLMetadata *))success failure:(void (^)(NSError *))failure
{
    NSString *sourcePath = [self dropboxPathFromCanonicalURL:sourceURL];
    NSString *destinationFolder = [self dropboxPathFromCanonicalURL:destinationParentURL];
    NSString *destinationPath = [destinationFolder stringByAppendingPathComponent:name];
    
    [self.client copyPath:sourcePath toPath:destinationPath success:^(GDDropboxMetadata *metadata) {
        if (success) success([self clientMetadataForDropboxMetadata:metadata]);
    } failure:failure];
}

- (void)moveFileAtURL:(NSURL *)sourceURL toParentURL:(NSURL *)destinationParentURL name:(NSString *)name success:(void (^)(GDURLMetadata *))success failure:(void (^)(NSError *))failure
{
    NSString *sourcePath = [self dropboxPathFromCanonicalURL:sourceURL];
    NSString *destinationFolder = [self dropboxPathFromCanonicalURL:destinationParentURL];
    NSString *destinationPath = [destinationFolder stringByAppendingPathComponent:name];
    
    [self.client movePath:sourcePath toPath:destinationPath success:^(GDDropboxMetadata *metadata) {
        if (success) success([self clientMetadataForDropboxMetadata:metadata]);
    } failure:failure];
}

- (NSOperation *)downloadURL:(NSURL *)url intoFileURL:(NSURL *)localURL fileVersion:(NSString *)fileVersionIdentifier
                    progress:(void (^)(NSUInteger, long long, long long))progress
                     success:(void (^)(NSURL *, GDURLMetadata *))success
                     failure:(void (^)(NSError *))failure
{
    NSString *dropboxPath = [self dropboxPathFromCanonicalURL:url];
    
    return [self.client downloadFile:dropboxPath intoPath:[localURL path] atRev:fileVersionIdentifier
                            progress:progress
                             success:^(NSString *localPath, GDDropboxMetadata *metadata) {
                                 GDURLMetadata *urlMetadata = [self clientMetadataForDropboxMetadata:metadata];
                                 if (success)
                                     success([NSURL fileURLWithPath:localPath], urlMetadata);
                             }
                             failure:failure];
}

- (NSOperation *)uploadFileURL:(NSURL *)localURL mimeType:mimeType toDestinationURL:(NSURL *)destinationURL
               parentVersionID:(NSString *)parentVersionID
           internalUploadState:(GDDropboxUploadState *)internalUploadState uploadStateHandler:(void (^)(GDFileManagerUploadState * uploadState))uploadStateHandler
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


- (NSOperation *)uploadFileURL:(NSURL *)localURL toDestinationURL:(NSURL *)destinationURL
                      filename:(NSString *)filename mimeType:(NSString *)mimeType parentVersionID:(NSString *)parentVersionID
           internalUploadState:(GDDropboxUploadState *)internalUploadState uploadStateHandler:(void (^)(GDFileManagerUploadState * uploadState))uploadStateHandler
                      progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress
                       success:(void (^)(GDURLMetadata *metadata, NSArray *conflicts))success
                       failure:(void (^)(NSError *error))failure
{
    NSString *localPath = [localURL path];
    NSString *dropboxPath = [self dropboxPathFromCanonicalURL:destinationURL];
    // This is necessary to preserve case.
    if (filename) {
        dropboxPath = [dropboxPath stringByDeletingLastPathComponent];
        dropboxPath = [dropboxPath stringByAppendingPathComponent:filename];
    }
    
    return [self.client uploadFile:localPath toDropboxPath:dropboxPath parentRev:parentVersionID
                       uploadState:internalUploadState uploadStateHandler:^(GDDropboxUploadState *uploadState) {
                           if (uploadStateHandler) {
                               GDFileManagerUploadState *clientUploadState = [[GDFileManagerUploadState alloc] initWithUploadState:uploadState
                                                                                                                          mimeType:mimeType
                                                                                                                         uploadURL:destinationURL
                                                                                                                   parentVersionID:parentVersionID];
                               uploadStateHandler(clientUploadState);
                           }
                       } progress:progress
                           success:^(GDDropboxMetadata *metadata, NSArray *conflictingRevisions) {
                               GDURLMetadata *urlMetadata = [self clientMetadataForDropboxMetadata:metadata];
                               if (success) success(urlMetadata, conflictingRevisions);
                           } failure:failure];
}

- (NSOperation *)uploadFileURL:(NSURL *)localURL filename:(NSString *)filename mimeType:(NSString *)mimeType toParentFolderURL:(NSURL *)parentFolderURL
            uploadStateHandler:(void (^)(GDFileManagerUploadState * uploadState))uploadStateHandler
                      progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress
                       success:(void (^)(GDURLMetadata *metadata, NSArray *conflicts))success
                       failure:(void (^)(NSError *error))failure
{
    NSString *dropboxFolderPath = [self dropboxPathFromCanonicalURL:parentFolderURL];
    NSString *dropboxPath = [dropboxFolderPath stringByAppendingPathComponent:filename];
    NSURL *destinationURL = [self canonicalURLForDropboxPath:dropboxPath];
    
    return [self uploadFileURL:localURL toDestinationURL:destinationURL filename:filename mimeType:mimeType parentVersionID:nil internalUploadState:nil
            uploadStateHandler:uploadStateHandler
                      progress:progress
                       success:success
                       failure:failure];
}

#pragma mark - URL / path support

- (NSString *)dropboxPathFromCanonicalURL:(NSURL *)url
{
    return [url path];
}

- (NSURL *)canonicalURLForDropboxPath:(NSString *)path
{
    NSString *unicodeNormalisedPath = [path precomposedStringWithCanonicalMapping];
    NSString *lowercaseURLEscapedPath = [[unicodeNormalisedPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] lowercaseString];
    return [self canonicalURLForURL:[[NSURL URLWithString:lowercaseURLEscapedPath relativeToURL:self.baseURL] absoluteURL]];
}

- (GDURLMetadata *)clientMetadataForDropboxMetadata:(GDDropboxMetadata *)metadata
{
    NSURL *canonicalURL = [self canonicalURLForDropboxPath:metadata.path];
    return [[GDURLMetadata alloc] initWithURLMetadata:[[GDDropboxURLMetadata alloc] initWithDropboxMetadata:metadata]
                                            clientURL:canonicalURL
                                         canonicalURL:canonicalURL];
}

- (GDURLMetadata *)clientMetadataWithCachedMetadata:(id <GDURLMetadata>)urlMetadata parentURL:(NSURL *)url
{
    NSURL *clientURL = [self canonicalURLForDropboxPath:[(GDDropboxURLMetadata *)urlMetadata dropboxPath]];
    return [[GDURLMetadata alloc] initWithURLMetadata:urlMetadata clientURL:clientURL canonicalURL:clientURL];
}

#pragma mark - Metadata support

- (void)addMetadata:(GDDropboxMetadata *)metadata parentURL:(NSURL *)parentURL toCache:(id <GDMetadataCache>)cache
       continuation:(void (^)(GDURLMetadata *metadata, NSArray *metadataContents))continuation
{
    GDURLMetadata *parentMetadata = [self clientMetadataForDropboxMetadata:metadata];
    [cache setMetadata:parentMetadata forURL:parentMetadata.canonicalURL];
    
    NSArray *metadataContents = nil;
    if ([metadata directoryContents]) {
        NSMutableArray *mutableMetadataContents = [NSMutableArray arrayWithCapacity:[metadata.directoryContents count]];
        NSMutableDictionary *keyedMetadataContents = [NSMutableDictionary dictionaryWithCapacity:[metadata.directoryContents count]];
        for (GDDropboxMetadata *childMetadata in metadata.directoryContents) {
            GDURLMetadata *childURLMetadata = [self clientMetadataForDropboxMetadata:childMetadata];
            NSURL *canonicalURL = childURLMetadata.canonicalURL;
            
            keyedMetadataContents[canonicalURL] = childURLMetadata;
            [mutableMetadataContents addObject:childURLMetadata];
        }
        [cache setDirectoryContents:[keyedMetadataContents copy] forURL:parentMetadata.canonicalURL];
        metadataContents = [mutableMetadataContents copy];
    }
    
    return continuation(parentMetadata, metadataContents);
}

@end
