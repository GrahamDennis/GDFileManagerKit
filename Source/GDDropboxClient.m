//
//  GDDropboxClient.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 23/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDDropboxClient.h"
#import "GDDropboxClientManager.h"
#import "GDDropboxCredential_Private.h"

#import "GDDropboxAccountInfo.h"
#import "GDDropboxMetadata.h"
#import "GDDropboxUploadState.h"

#import "GDHTTPOperation.h"
#import "GDDropboxChunkedUploadOperation.h"

@interface GDDropboxClient ()

@end

@implementation GDDropboxClient

@dynamic credential, apiToken;

- (id)initWithClientManager:(GDClientManager *)clientManager credential:(GDClientCredential *)credential baseURL:(NSURL *)baseURL
{
    if (!baseURL)
        baseURL = [NSURL URLWithString:@"https://api.dropbox.com"];
    
    if ((self = [super initWithClientManager:clientManager credential:credential baseURL:baseURL])) {
        [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
        [self setDefaultHeader:@"Accept" value:@"text/javascript; text/json; application/json"];
        [self setDefaultHeader:@"Authorization" value:[(GDDropboxCredential *)credential authorisationHeader]];
        [self setDefaultHeader:@"Accept-Encoding" value:@"gzip"];
    }
    
    return self;
}


#pragma mark - Public

- (NSString *)root
{
    return self.credential.root;
}

- (BOOL)isAuthenticationFailureError:(NSError *)error
{
    return [[error domain] isEqualToString:GDHTTPStatusErrorDomain] && [error code] == 401;
}

#pragma mark - HTTP methods

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method path:(NSString *)path parameters:(NSDictionary *)parameters
{
    NSString *temporaryMethod = method;
    if ([method isEqualToString:@"PUT"]) {
        // We need to do this to ensure that PUT URL parameters are encoded in the URL, not in the HTTP body.
        temporaryMethod = @"GET";
    }
    NSMutableURLRequest *request = [super requestWithMethod:temporaryMethod path:path parameters:parameters];

    [request setHTTPMethod:method];
    
    if ([method isEqualToString:@"GET"] && [path hasPrefix:@"https://api-content.dropbox.com"]) {
        [request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
    }
    
    return request;
}

- (NSOperation *)enqueueDropboxRequestOperationWithMethod:(NSString *)method
                                            path:(NSString *)path
                                      parameters:(NSDictionary *)parameters
                                         success:(void (^)(id json))success
                                         failure:(void (^)(NSError *error))failure
{
    NSMutableURLRequest *request = [self requestWithMethod:method path:path parameters:parameters];
    
    return [self enqueueOperationWithURLRequest:request
                  requiresAuthentication:YES
                                 success:^(AFHTTPRequestOperation *requestOperation, id json) {
                                     if (success) success(json);
                                 }
                                 failure:^(AFHTTPRequestOperation *requestOperation, NSError *error) {
                                     if (failure) failure(error);
                                 }];
}

#pragma mark - Account operations

- (void)getAccountInfoWithSuccess:(void (^)(GDDropboxAccountInfo *))success failure:(void (^)(NSError *))failure
{
    [self enqueueDropboxRequestOperationWithMethod:@"GET" path:@"/1/account/info" parameters:nil
                                           success:^(id json) {
                                               if (success) {
                                                   GDDropboxAccountInfo *accountInfo = [[GDDropboxAccountInfo alloc] initWithDictionary:json];
                                                   success(accountInfo);
                                               }
                                           }
                                           failure:failure];
}

#pragma mark - Metadata operations

- (void)getMetadataForPath:(NSString *)path withParameters:(NSDictionary *)parameters success:(void (^)(GDDropboxMetadata *metadata))success failure:(void (^)(NSError *error))failure
{
    NSString *requestPath = [[NSString stringWithFormat:@"/1/metadata/%@%@", self.root, path] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    [self enqueueDropboxRequestOperationWithMethod:@"GET" path:requestPath parameters:parameters
                                           success:^(id json) {
                                               if (success) {
                                                   GDDropboxMetadata *metadata = [[GDDropboxMetadata alloc] initWithDictionary:json];
                                                   success(metadata);
                                               }
                                           } failure:failure];
}

- (void)getMetadataForPath:(NSString *)path success:(void (^)(GDDropboxMetadata *metadata))success failure:(void (^)(NSError *error))failure
{
    [self getMetadataForPath:path withParameters:nil success:success failure:failure];
}

- (void)getMetadataForPath:(NSString *)path withHash:(NSString *)hash success:(void (^)(GDDropboxMetadata *metadata, BOOL didChange))success failure:(void (^)(NSError *error))failure
{
    NSDictionary *parameters = nil;
    if (hash) {
        parameters = @{@"hash": hash};
    }
    [self getMetadataForPath:path withParameters:parameters success:^(GDDropboxMetadata *metadata) {
        if (success) success(metadata, YES);
    } failure:^(NSError *error) {
        if ([[error domain] isEqualToString:GDHTTPStatusErrorDomain] && [error code] == 304) {
            if (success) success(nil, NO);
        } else if (failure) {
            failure(error);
        }
    }];
}

- (void)getMetadataForPath:(NSString *)path atRev:(NSString *)rev success:(void (^)(GDDropboxMetadata *metadata))success failure:(void (^)(NSError *error))failure
{
    NSDictionary *parameters = nil;
    if (rev) {
        parameters = @{@"rev": rev};
    }
    [self getMetadataForPath:path withParameters:parameters success:success failure:failure];
}

- (void)getRevisionHistoryForFile:(NSString *)dropboxPath
                          success:(void (^)(NSArray *versionHistory))success
                          failure:(void (^)(NSError *error))failure
{
    NSString *requestPath = [[NSString stringWithFormat:@"/1/revisions/%@%@", self.root, dropboxPath] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    [self enqueueDropboxRequestOperationWithMethod:@"GET" path:requestPath parameters:nil
                                           success:^(id json) {
                                               if (![json isKindOfClass:[NSArray class]]) {
                                                   if (failure) failure(nil);
                                                   return;
                                               }
                                               NSArray *rawMetadataArray = json;
                                               NSMutableArray *revisionHistory = [NSMutableArray arrayWithCapacity:[rawMetadataArray count]];
                                               for (NSDictionary *rawMetadata in rawMetadataArray) {
                                                   GDDropboxMetadata *metadata = [[GDDropboxMetadata alloc] initWithDictionary:rawMetadata];
                                                   [revisionHistory addObject:metadata];
                                               }
                                               if (success) {
                                                   success([revisionHistory copy]);
                                               }
                                           } failure:failure];
}

- (void)deletePath:(NSString *)dropboxPath success:(void (^)(GDDropboxMetadata *metadata))success failure:(void (^)(NSError *error))failure
{
    NSParameterAssert(dropboxPath);
    NSString *requestPath = @"/1/fileops/delete";
    
    [self enqueueDropboxRequestOperationWithMethod:@"POST"
                                              path:requestPath
                                        parameters:@{@"root": self.root, @"path": dropboxPath}
                                           success:^(id json) {
                                               if (success) {
                                                   GDDropboxMetadata *metadata = [[GDDropboxMetadata alloc] initWithDictionary:json];
                                                   success(metadata);
                                               }
                                           } failure:failure];
}

- (void)copyPath:(NSString *)sourcePath toPath:(NSString *)destinationPath success:(void (^)(GDDropboxMetadata *))success failure:(void (^)(NSError *))failure
{
    return [self copyOrMove:@"copy" fromPath:sourcePath toPath:destinationPath success:success failure:failure];
}

- (void)movePath:(NSString *)sourcePath toPath:(NSString *)destinationPath success:(void (^)(GDDropboxMetadata *metadata))success failure:(void (^)(NSError *error))failure
{
    return [self copyOrMove:@"move" fromPath:sourcePath toPath:destinationPath success:success failure:failure];
}

- (void)copyOrMove:(NSString *)operation fromPath:(NSString *)sourcePath toPath:(NSString *)destinationPath success:(void (^)(GDDropboxMetadata *))success failure:(void (^)(NSError *))failure
{
    NSString *requestPath = [NSString stringWithFormat:@"/1/fileops/%@", operation];
    NSParameterAssert(sourcePath);
    NSParameterAssert(destinationPath);
    
    [self enqueueDropboxRequestOperationWithMethod:@"POST"
                                              path:requestPath
                                        parameters:@{@"root": self.root, @"from_path": sourcePath, @"to_path": destinationPath}
                                           success:^(id json) {
                                               if (success) {
                                                   GDDropboxMetadata *metadata = [[GDDropboxMetadata alloc] initWithDictionary:json];
                                                   success(metadata);
                                               }
                                           } failure:failure];
}


#pragma mark - Downloading

- (NSOperation *)downloadFile:(NSString *)dropboxPath intoPath:(NSString *)localPath
                     progress:(void (^)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))progress
                      success:(void (^)(NSString *localPath, GDDropboxMetadata *metadata))success
                      failure:(void (^)(NSError *error))failure
{
    return [self downloadFile:dropboxPath intoPath:localPath atRev:nil progress:progress success:success failure:failure];
}

- (NSOperation *)downloadFile:(NSString *)dropboxPath intoPath:(NSString *)localPath atRev:(NSString *)revision
                     progress:(void (^)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))progress
                      success:(void (^)(NSString *localPath, GDDropboxMetadata *metadata))success
                      failure:(void (^)(NSError *error))failure
{
    NSDictionary *urlParameters = nil;
    if (revision) {
        urlParameters = @{@"rev": revision};
    }
    
    return [self downloadFile:dropboxPath intoPath:localPath withParameters:urlParameters progress:progress success:success failure:failure];
}


- (NSOperation *)downloadFile:(NSString *)dropboxPath intoPath:(NSString *)localPath withParameters:(NSDictionary *)parameters
                                progress:(void (^)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))progress
                                 success:(void (^)(NSString *localPath, GDDropboxMetadata *metadata))success
                                 failure:(void (^)(NSError *error))failure
{
    NSString *path = [[NSString stringWithFormat:@"https://api-content.dropbox.com/1/files/%@%@", self.root, dropboxPath] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableURLRequest *urlRequest = [self requestWithMethod:@"GET" path:path parameters:parameters];
    NSOutputStream *outputStream = [NSOutputStream outputStreamToFileAtPath:localPath append:NO];
    
    return [self enqueueOperationWithURLRequest:urlRequest
                         requiresAuthentication:YES
                               shouldRetryBlock:NULL
                                        success:^(AFHTTPRequestOperation *requestOperation, id responseObject) {
                                            dispatch_async(self.workQueue, ^{
                                                NSDictionary *httpHeaders = [[requestOperation response] allHeaderFields];
                                                NSString *metadataString = httpHeaders[@"X-Dropbox-Metadata"];
                                                NSData *metadataData = [metadataString dataUsingEncoding:NSUTF8StringEncoding];
                                                NSError *jsonError = nil;
                                                NSDictionary *metadataDictionary = [NSJSONSerialization JSONObjectWithData:metadataData options:0 error:&jsonError];
                                                GDDropboxMetadata *metadata = nil;
                                                if (metadataDictionary)
                                                    metadata = [[GDDropboxMetadata alloc] initWithDictionary:metadataDictionary];
                                                
                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                    if (metadata) {
                                                        if (success)
                                                            success(localPath, metadata);
                                                    } else {
                                                        if (failure)
                                                            failure(jsonError);
                                                    }
                                                });
                                                
                                            });
                                        }
                                        failure:^(AFHTTPRequestOperation *requestOperation, NSError *error) {
                                            if (failure) failure(error);
                                        }
                        configureOperationBlock:^(AFHTTPRequestOperation *requestOperation) {
                            requestOperation.outputStream = outputStream;
                            [requestOperation setDownloadProgressBlock:progress];
                        }];
}

- (NSOperation *)uploadFile:(NSString *)localPath toDropboxPath:(NSString *)dropboxPath
                  parentRev:(NSString *)parentRevision uploadState:(GDDropboxUploadState *)uploadState
         uploadStateHandler:(void (^)(GDDropboxUploadState *))uploadStateHandler
                   progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress
                    success:(void (^)(GDDropboxMetadata *, NSArray *))success
                    failure:(void (^)(NSError *))failure
{
    GDDropboxChunkedUploadOperation *chunkedUploadOperation = [[GDDropboxChunkedUploadOperation alloc] initWithClient:self
                                                                                                        fromLocalPath:localPath
                                                                                                        toDropboxPath:dropboxPath
                                                                                                              success:success
                                                                                                              failure:failure];
    
    chunkedUploadOperation.uploadStateHandler = uploadStateHandler;
    chunkedUploadOperation.uploadProgressBlock = progress;
    chunkedUploadOperation.parentRev = parentRevision;
    
    [chunkedUploadOperation start];
    
    return chunkedUploadOperation;
}
@end
