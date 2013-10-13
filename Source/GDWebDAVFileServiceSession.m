//
//  GDWebDAVFileServiceSession.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 5/02/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDWebDAVFileServiceSession.h"
#import "GDWebDAVFileService.h"
#import "GDWebDAVURLMetadata.h"

#import "GDURLMetadata_Private.h"

@implementation GDWebDAVFileServiceSession

@dynamic client;

+ (NSURL *)baseURLForFileService:(GDFileService *)fileService client:(GDHTTPClient *)client
{
    if (![fileService isKindOfClass:[GDWebDAVFileService class]] || ![client isKindOfClass:[GDWebDAVClient class]]) {
        return nil;
    }
    
    NSURL *clientBaseURL = client.baseURL;
    NSString *serviceURLScheme = [(GDWebDAVFileService *)fileService urlSchemeForClient:(GDWebDAVClient *)client];
    if (!serviceURLScheme) return nil;

    NSString *clientNetLoc = (__bridge_transfer NSString *)CFURLCopyNetLocation((__bridge CFURLRef)clientBaseURL);
    NSString *urlString = [NSString stringWithFormat:@"%@://%@/", serviceURLScheme, clientNetLoc];
    NSString *clientBasePath = [clientBaseURL path];
    if ([clientBasePath hasPrefix:@"/"])
        clientBasePath = [clientBasePath substringFromIndex:1];
    return [[NSURL URLWithString:urlString] URLByAppendingPathComponent:clientBasePath];
}


- (void)validateAccessWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure
{
    [self.client validateWebDAVServerWithSuccess:success failure:failure];
}

- (void)getMetadataForURL:(NSURL *)url metadataCache:(id <GDMetadataCache>)metadataCache cachedMetadata:(id<GDURLMetadata>)cachedMetadataOrNil
                  success:(void (^)(GDURLMetadata *metadata))success failure:(void (^)(NSError *error))failure
{
    NSString *webDAVPath = [self webDAVPathFromCanonicalURL:url];
    
    [self.client getMetadataForPath:webDAVPath
                            success:^(GDWebDAVMetadata *metadata) {
                                GDURLMetadata *urlMetadata = [self clientMetadataForWebDAVMetadata:metadata];
                                [metadataCache setMetadata:urlMetadata forURL:urlMetadata.canonicalURL];
                                if (success) success(urlMetadata);
                            } failure:failure];
}

- (void)getContentsOfDirectoryAtURL:(NSURL *)url metadataCache:(id<GDMetadataCache>)metadataCache
                     cachedMetadata:(id<GDURLMetadata>)cachedMetadataOrNil cachedContents:(NSArray *)contentsOrNil
                            success:(void (^)(NSArray *))success failure:(void (^)(NSError *))failure
{
    NSString *webDAVPath = [self webDAVPathFromCanonicalURL:url];
    
    [self.client getContentsOfDirectoryAtPath:webDAVPath success:^(NSArray *contents) {
        [self addMetadata:contents parentURL:url toCache:metadataCache continuation:^(GDURLMetadata *metadata, NSArray *metadataContents) {
            if (success) success(metadataContents);
        }];
    } failure:failure];
}

- (void)deleteURL:(NSURL *)url success:(void (^)())success failure:(void (^)(NSError *))failure
{
    NSString *webDAVPath = [self webDAVPathFromCanonicalURL:url];
    
    [self.client deletePath:webDAVPath success:success failure:failure];
}

- (void)copyFileAtURL:(NSURL *)sourceURL toParentURL:(NSURL *)destinationParentURL name:(NSString *)name success:(void (^)(GDURLMetadata *))success failure:(void (^)(NSError *))failure
{
    NSString *sourceWebDAVPath = [self webDAVPathFromCanonicalURL:sourceURL];
    NSString *destinationFolderWebDAVPath = [self webDAVPathFromCanonicalURL:destinationParentURL];
    NSString *destinationPath = [destinationFolderWebDAVPath stringByAppendingPathComponent:name];
    
    [self.client copyPath:sourceWebDAVPath toPath:destinationPath success:^{
        NSURL *clientURL = [self canonicalURLByAppendingPath:name toURL:destinationParentURL];
        [self getMetadataForURL:clientURL metadataCache:nil cachedMetadata:nil success:success failure:failure];
    } failure:failure];
    
}

- (void)moveFileAtURL:(NSURL *)sourceURL toParentURL:(NSURL *)destinationParentURL name:(NSString *)name success:(void (^)(GDURLMetadata *))success failure:(void (^)(NSError *))failure
{
    NSString *sourceWebDAVPath = [self webDAVPathFromCanonicalURL:sourceURL];
    NSString *destinationFolderWebDAVPath = [self webDAVPathFromCanonicalURL:destinationParentURL];
    NSString *destinationPath = [destinationFolderWebDAVPath stringByAppendingPathComponent:name];
    
    [self.client movePath:sourceWebDAVPath toPath:destinationPath success:^{
        NSURL *clientURL = [self canonicalURLByAppendingPath:name toURL:destinationParentURL];
        [self getMetadataForURL:clientURL metadataCache:nil cachedMetadata:nil success:success failure:failure];
    } failure:failure];
    
}

- (NSOperation *)downloadURL:(NSURL *)url intoFileURL:(NSURL *)localURL fileVersion:(NSString *)fileVersionIdentifier
                    progress:(void (^)(NSUInteger, long long, long long))progress
                     success:(void (^)(NSURL *localURL, GDURLMetadata *metadata))success
                     failure:(void (^)(NSError *))failure
{
    NSString *webDAVPath = [self webDAVPathFromCanonicalURL:url];
    
    return [self.client downloadFile:webDAVPath intoPath:[localURL path]
                            progress:progress
                             success:^(NSString *localPath, GDWebDAVMetadata *metadata) {
                                 GDURLMetadata *urlMetadata = [self clientMetadataForWebDAVMetadata:metadata];
                                 if (success) success([NSURL fileURLWithPath:localPath], urlMetadata);
                             } failure:failure];
}

- (NSOperation *)uploadFileURL:(NSURL *)localURL mimeType:(NSString *)mimeType toDestinationURL:(NSURL *)destinationURL parentVersionID:(NSString *)parentVersionID
           internalUploadState:(id)internalUploadState uploadStateHandler:(void (^)(GDFileManagerUploadState * uploadState))uploadStateHandler
                      progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress
                       success:(void (^)(GDURLMetadata *metadata, NSArray *conflicts))success
                       failure:(void (^)(NSError *error))failure
{
    NSString *localPath = [localURL path];
    NSString *webDAVPath = [self webDAVPathFromCanonicalURL:destinationURL];
    
    return [self.client uploadFile:localPath mimeType:mimeType toWebDAVPath:webDAVPath progress:progress
                           success:^(GDWebDAVMetadata *metadata) {
                               GDURLMetadata *urlMetadata = [self clientMetadataForWebDAVMetadata:metadata];
                               if (success) success(urlMetadata, nil);
                           } failure:failure];
}

- (NSOperation *)uploadFileURL:(NSURL *)localURL filename:(NSString *)filename mimeType:(NSString *)mimeType toParentFolderURL:(NSURL *)parentFolderURL
            uploadStateHandler:(void (^)(GDFileManagerUploadState * uploadState))uploadStateHandler
                      progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress
                       success:(void (^)(GDURLMetadata *metadata, NSArray *conflicts))success
                       failure:(void (^)(NSError *error))failure
{
    NSURL *destinationURL = [self canonicalURLByAppendingPath:filename toURL:parentFolderURL];
    
    return [self uploadFileURL:localURL mimeType:mimeType toDestinationURL:destinationURL parentVersionID:nil
           internalUploadState:nil uploadStateHandler:uploadStateHandler
                      progress:progress
                       success:success
                       failure:failure];
}

- (NSOperation *)resumeUploadWithUploadState:(GDFileManagerUploadState *)uploadState fromFileURL:(NSURL *)localURL
                          uploadStateHandler:(void (^)(GDFileManagerUploadState *))uploadStateHandler
                                    progress:(void (^)(NSUInteger, long long, long long))progress
                                     success:(void (^)(GDURLMetadata *, NSArray *))success
                                     failure:(void (^)(NSError *))failure
{
    if (failure) {
        failure(nil);
    }
    return nil;
}

#pragma mark - URL / path support

- (NSString *)normalisedPathForPath:(NSString *)path
{
    return [path precomposedStringWithCanonicalMapping];
}

- (NSString *)webDAVPathFromCanonicalURL:(NSURL *)canonicalURL
{
    return [canonicalURL path];
}

- (NSURL *)canonicalURLByAppendingPath:(NSString *)path toURL:(NSURL *)baseURL
{
    path = [self normalisedPathForPath:path];
    if ([path hasSuffix:@"/"])
        path = [path substringToIndex:[path length]-1];
    if ([path hasPrefix:@"/"]) {
        NSString *urlEscapedPath = [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        return [[NSURL URLWithString:urlEscapedPath relativeToURL:baseURL] absoluteURL];
    } else
        return [baseURL URLByAppendingPathComponent:path];
}

- (NSURL *)canonicalURLForMetadata:(GDWebDAVMetadata *)metadata
{
    return [self canonicalURLByAppendingPath:[metadata.href stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] toURL:self.baseURL];
}

- (GDURLMetadata *)clientMetadataForWebDAVMetadata:(GDWebDAVMetadata *)metadata
{
    NSURL *url = [self canonicalURLForMetadata:metadata];
    
    return [[GDURLMetadata alloc] initWithURLMetadata:[[GDWebDAVURLMetadata alloc] initWithWebDAVMetadata:metadata]
                                            clientURL:url
                                         canonicalURL:url];
}

- (GDURLMetadata *)clientMetadataWithCachedMetadata:(id<GDURLMetadata>)urlMetadata parentURL:(NSURL *)url
{
    NSURL *canonicalURL = [self canonicalURLByAppendingPath:[(GDWebDAVURLMetadata *)urlMetadata webDAVPath] toURL:url];
    
    return [[GDURLMetadata alloc] initWithURLMetadata:urlMetadata clientURL:canonicalURL canonicalURL:canonicalURL];
}

#pragma mark - Metadata support

- (void)addMetadata:(NSArray *)metadataArray parentURL:(NSURL *)parentURL toCache:(id<GDMetadataCache>)cache continuation:(void (^)(GDURLMetadata *, NSArray *))continuation
{
    GDURLMetadata *parentMetadata = nil;
    
    NSMutableArray *childMetadataArray = [NSMutableArray arrayWithCapacity:[metadataArray count]];
    NSMutableDictionary *keyedChildMetadata = [NSMutableDictionary dictionaryWithCapacity:[metadataArray count]];
    for (GDWebDAVMetadata *metadata in metadataArray) {
        GDURLMetadata *urlMetadata = [self clientMetadataForWebDAVMetadata:metadata];

        if (urlMetadata) {
            NSURL *canonicalURL = urlMetadata.canonicalURL;
            
            if ([canonicalURL isEqual:parentURL]) {
                parentMetadata = urlMetadata;
            } else {
                [childMetadataArray addObject:urlMetadata];
                keyedChildMetadata[canonicalURL] = urlMetadata;
            }
        }
    }
    [cache setMetadata:parentMetadata directoryContents:keyedChildMetadata forURL:[self canonicalURLForURL:parentURL] addToParent:nil];
    
    return continuation(parentMetadata, [childMetadataArray copy]);
}

@end
