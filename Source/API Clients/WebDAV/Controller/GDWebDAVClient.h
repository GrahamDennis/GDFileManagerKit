//
//  GDWebDAVClient.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 1/02/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDHTTPClient.h"

#import "GDWebDAVCredential.h"

@class GDWebDAVMetadata;

@interface GDWebDAVClient : GDHTTPClient

- (void)validateWebDAVServerWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;

- (void)getMetadataForPath:(NSString *)path success:(void (^)(GDWebDAVMetadata *metadata))success failure:(void (^)(NSError *error))failure;
- (void)getContentsOfDirectoryAtPath:(NSString *)path success:(void (^)(NSArray *contents))success failure:(void (^)(NSError *error))failure;
- (void)getPROPFINDResponseForPath:(NSString *)path depth:(NSUInteger)depth success:(void (^)(NSArray *results))success failure:(void (^)(NSError *error))failure;

- (void)deletePath:(NSString *)path success:(void (^)())success failure:(void (^)(NSError *error))failure;

- (void)copyPath:(NSString *)sourcePath toPath:(NSString *)destinationPath success:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)movePath:(NSString *)sourcePath toPath:(NSString *)destinationPath success:(void (^)())success failure:(void (^)(NSError *error))failure;

- (NSOperation *)downloadFile:(NSString *)remotePath intoPath:(NSString *)localPath
                     progress:(void (^)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))progress
                      success:(void (^)(NSString *localPath, GDWebDAVMetadata *metadata))success
                      failure:(void (^)(NSError *error))failure;

- (NSOperation *)uploadFile:(NSString *)localPath mimeType:(NSString *)mimeType toWebDAVPath:(NSString *)destinationPath
                   progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress
                    success:(void (^)(GDWebDAVMetadata *metadata))success
                    failure:(void (^)(NSError *error))failure;


@property (atomic, strong) GDWebDAVCredential *credential;

@end
