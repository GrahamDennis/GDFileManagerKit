//
//  GDSugarSyncClient.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 27/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDHTTPClient.h"
#import "GDSugarSyncClientManager.h"
#import "GDSugarSyncCredential.h"
#import "GDSugarSyncMetadata.h"
#import "GDSugarSyncUploadState.h"

@class GDSugarSyncAccountInfo;

@interface GDSugarSyncClient : GDHTTPClient

- (void)getRefreshTokenWithUsername:(NSString *)username password:(NSString *)password
                            success:(void (^)(GDSugarSyncCredential *credential))success failure:(void (^)(NSError *error))failure;

- (void)getAccessTokenWithSuccess:(void (^)(GDSugarSyncCredential *credential))success failure:(void (^)(NSError *error))failure;

- (void)getAccountInfoWithSuccess:(void (^)(GDSugarSyncAccountInfo *accountInfo))success failure:(void (^)(NSError *error))failure;

- (void)getCachedAccountInfoWithSuccess:(void (^)(GDSugarSyncAccountInfo *accountInfo))success failure:(void (^)(NSError *error))failure;

- (void)getWorkspacesWithSuccess:(void (^)(NSArray *workspaces))success failure:(void (^)(NSError *error))failure;
- (void)getSyncFoldersWithSuccess:(void (^)(NSArray *syncFolders))success failure:(void (^)(NSError *error))failure;

- (void)getMetadataForObjectID:(NSString *)objectID success:(void (^)(GDSugarSyncMetadata *metadata))success failure:(void (^)(NSError *error))failure;

- (void)getContentsOfCollectionID:(NSString *)collectionID success:(void (^)(NSArray *contents))success failure:(void (^)(NSError *error))failure;

- (void)trashObjectID:(NSString *)objectID success:(void (^)())success failure:(void (^)(NSError *error))failure;

- (void)copyFileID:(NSString *)objectID toFolderID:(NSString *)folderID name:(NSString *)name success:(void (^)(NSString *newFileID))success failure:(void (^)(NSError *error))failure;
- (void)moveObjectID:(NSString *)objectID toFolderID:(NSString *)folderID name:(NSString *)name success:(void (^)())success failure:(void (^)(NSError *error))failure;

- (NSOperation *)downloadFileID:(NSString *)fileID intoPath:(NSString *)localPath fileVersionID:(NSString *)fileVersionID
                       progress:(void (^)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))progress
                        success:(void (^)(NSString *localPath, GDSugarSyncMetadata *metadata, NSString *fileVersionID))success
                        failure:(void (^)(NSError *error))failure;

- (void)createFileWithName:(NSString *)filename mimeType:(NSString *)mimeType inCollectionID:(NSString *)collectionID
                   success:(void (^)(NSString *fileID))success
                   failure:(void (^)(NSError *error))failure;

- (void)getVersionHistoryForObjectID:(NSString *)objectID
                             success:(void (^)(NSArray *history))success
                             failure:(void (^)(NSError *error))failure;

- (void)createFileVersionForFileID:(NSString *)fileID
                           success:(void (^)(NSString *versionID))success
                           failure:(void (^)(NSError *error))failure;

- (NSOperation *)uploadFile:(NSString *)localPath toFileID:(NSString *)fileID parentVersionID:(NSString *)parentVersionID
                uploadState:(GDSugarSyncUploadState *)uploadState
         uploadStateHandler:(void (^)(GDSugarSyncUploadState *uploadState))uploadStateHandler
                   progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress
                    success:(void (^)(GDSugarSyncMetadata *metadata, NSString *fileVersionID, NSArray *conflictingVersionIDs))success
                    failure:(void (^)(NSError *error))failure;

- (GDSugarSyncMetadata *)workspacesMetadata;
- (GDSugarSyncMetadata *)syncFoldersMetadata;
- (GDSugarSyncMetadata *)rootMetadata;

@property (atomic, strong) GDSugarSyncCredential *credential;
@property (nonatomic, strong, readonly) GDSugarSyncAPIToken *apiToken;

@end
