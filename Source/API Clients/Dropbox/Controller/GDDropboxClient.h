//
//  GDDropboxClient.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 23/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GDHTTPClient.h"
#import "GDDropboxClientManager.h"
#import "GDDropboxCredential.h"

@class GDDropboxClientManager;

@class GDDropboxAccountInfo;
@class GDDropboxMetadata;
@class GDDropboxUploadState;

@interface GDDropboxClient : GDHTTPClient

- (void)getAccountInfoWithSuccess:(void (^)(GDDropboxAccountInfo *accountInfo))success failure:(void (^)(NSError *error))failure;

- (void)getMetadataForPath:(NSString *)path success:(void (^)(GDDropboxMetadata *metadata))success failure:(void (^)(NSError *error))failure;
- (void)getMetadataForPath:(NSString *)path withHash:(NSString *)hash success:(void (^)(GDDropboxMetadata *metadata, BOOL didChange))success failure:(void (^)(NSError *error))failure;
- (void)getMetadataForPath:(NSString *)path atRev:(NSString *)rev success:(void (^)(GDDropboxMetadata *metadata))success failure:(void (^)(NSError *error))failure;

- (void)getRevisionHistoryForFile:(NSString *)dropboxPath success:(void (^)(NSArray *versionHistory))success failure:(void (^)(NSError *error))failure;

- (void)deletePath:(NSString *)path success:(void (^)(GDDropboxMetadata *metadata))success failure:(void (^)(NSError *error))failure;
- (void)copyPath:(NSString *)sourcePath toPath:(NSString *)destinationPath success:(void (^)(GDDropboxMetadata *metadata))success failure:(void (^)(NSError *error))failure;
- (void)movePath:(NSString *)sourcePath toPath:(NSString *)destinationPath success:(void (^)(GDDropboxMetadata *metadata))success failure:(void (^)(NSError *error))failure;

- (NSOperation *)downloadFile:(NSString *)dropboxPath intoPath:(NSString *)localPath
                     progress:(void (^)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))progress
                      success:(void (^)(NSString *localPath, GDDropboxMetadata *metadata))success
                      failure:(void (^)(NSError *error))failure;

- (NSOperation *)downloadFile:(NSString *)dropboxPath intoPath:(NSString *)localPath atRev:(NSString *)revision
                     progress:(void (^)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))progress
                      success:(void (^)(NSString *localPath, GDDropboxMetadata *metadata))success
                      failure:(void (^)(NSError *error))failure;

- (NSOperation *)uploadFile:(NSString *)localPath toDropboxPath:(NSString *)dropboxPath parentRev:(NSString *)parentRevision
                uploadState:(GDDropboxUploadState *)uploadState
         uploadStateHandler:(void (^)(GDDropboxUploadState *uploadState))uploadStateHandler
                   progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress
                    success:(void (^)(GDDropboxMetadata *metadata, NSArray *conflictingRevisions))success
                    failure:(void (^)(NSError *error))failure;

@property (atomic, strong) GDDropboxCredential *credential;
@property (nonatomic, strong, readonly) GDDropboxAPIToken *apiToken;
@property (nonatomic, readonly, copy) NSString *root;

@end
