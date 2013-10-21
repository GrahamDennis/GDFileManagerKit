//
//  GDFileServiceSession.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 26/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDFileServiceSession.h"

#import "GDURLMetadata.h"
#import "GDURLMetadata_Private.h"
#import "GDMetadataCache.h"
#import "GDFileService.h"
#import "AsyncSequentialEnumeration.h"

#import "GDFileManagerUploadState.h"

@implementation GDFileServiceSession

- (id)initWithBaseURL:(NSURL *)baseURL fileService:(GDFileService *)fileService
{
    if ((self = [super init])) {
        _baseURL = baseURL;
        _fileService = fileService;
        self.userVisible = YES;
    }
    
    return self;
}

- (void)unlink
{
    
}

- (void)getContentsOfDirectoryAtURL:(NSURL *)url metadataCache:(id<GDMetadataCache>)metadataCache
                     cachedMetadata:(id<GDURLMetadata>)cachedMetadata cachedContents:(NSArray *)contents
                         success:(void (^)(NSArray *))success failure:(void (^)(NSError *))failure
{
    [self getMetadataForURL:url metadataCache:metadataCache cachedMetadata:cachedMetadata success:^(GDURLMetadata *metadata) {
        if ([metadata isDirectory]) {
            if (success) {
                success([metadataCache directoryContentsMetadataArrayForURL:metadata.url]);
            }
        } else {
            // FIXME
            if (failure) {
                failure(nil);
            }
        }
    } failure:failure];
}

- (NSString *)normalisedPathForPath:(NSString *)path
{
    NSString *unicodeNormalisedPath = [path precomposedStringWithCanonicalMapping];
    NSString *lowercaseURLEscapedPath = [[unicodeNormalisedPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] lowercaseString];
    return [lowercaseURLEscapedPath stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (NSURL *)canonicalURLForURL:(NSURL *)url
{
    static dispatch_once_t onceToken;
    static NSCache *canonicalURLCache;
    dispatch_once(&onceToken, ^{
        canonicalURLCache = [NSCache new];
        canonicalURLCache.name = @"me.grahamdennis.GDFileManagerKit.CanonicalURLCache";
    });
    NSURL *canonicalURL = [canonicalURLCache objectForKey:url];
    if (!canonicalURL) {
        canonicalURL = [self _canonicalURLForURL:url];
        [canonicalURLCache setObject:canonicalURL forKey:url];
    }
    return canonicalURL;
}

- (NSURL *)_canonicalURLForURL:(NSURL *)url
{
    NSString *urlString = [url absoluteString];
    if ([urlString hasSuffix:@"/"]) {
        return [NSURL URLWithString:[urlString substringToIndex:[urlString length]-1]];
    }
    return url;
}

- (void)getLatestVersionIdentifierForURL:(NSURL *)url metadataCache:(id <GDMetadataCache>)metadataCache cachedMetadata:(id <GDURLMetadata>)cachedMetadataOrNil
                                 success:(void (^)(NSString *fileVersionIdentifier))success failure:(void (^)(NSError *error))failure
{
    [self getMetadataForURL:url metadataCache:metadataCache cachedMetadata:cachedMetadataOrNil
                    success:^(GDURLMetadata *metadata) {
                        if (success) success(metadata.fileVersionIdentifier);
                    } failure:failure];
}

- (NSOperation *)downloadURL:(NSURL *)url intoFileURL:(NSURL *)localURL
                    progress:(void (^)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))progress
                     success:(void (^)(NSURL *localURL, GDURLMetadata *metadata))success
                     failure:(void (^)(NSError *error))failure
{
    return [self downloadURL:url intoFileURL:localURL fileVersion:nil progress:progress success:success failure:failure];
}

- (void)addMetadata:(id)metadata parentURL:(NSURL *)parentURL toCache:(id <GDMetadataCache>)cache
       continuation:(void (^)(GDURLMetadata *metadata, NSArray *metadataContents))continuation
{
    [self doesNotRecognizeSelector:_cmd];
}

- (NSArray *)clientMetadataArrayWithCachedMetadataArray:(NSArray *)urlMetadataArray parentURL:(NSURL *)parentURL cache:(id<GDMetadataCache>)cache
{
    NSMutableArray *clientMetadataArray = [NSMutableArray arrayWithCapacity:[urlMetadataArray count]];
    NSMutableDictionary *keyedMetadataToCache = [NSMutableDictionary dictionaryWithCapacity:[urlMetadataArray count]];
    
    for (id <GDURLMetadata> urlMetadata in urlMetadataArray) {
        GDURLMetadata *clientMetadata = [self clientMetadataWithCachedMetadata:urlMetadata parentURL:parentURL];
        if (clientMetadata) {
            [clientMetadataArray addObject:clientMetadata];
            keyedMetadataToCache[clientMetadata.canonicalURL] = urlMetadata;
        }
    }
    [cache setDirectoryContents:[keyedMetadataToCache copy] forURL:[self canonicalURLForURL:parentURL]];
    return [clientMetadataArray copy];
}

- (NSOperation *)resumeUploadWithUploadState:(GDFileManagerUploadState *)uploadState fromFileURL:(NSURL *)localURL
                          uploadStateHandler:(void (^)(GDFileManagerUploadState * uploadState))uploadStateHandler
                                    progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress
                                     success:(void (^)(GDURLMetadata *metadata, NSArray *conflicts))success
                                     failure:(void (^)(NSError *error))failure
{
    NSParameterAssert([uploadState isKindOfClass:[GDFileManagerUploadState class]]);
    if (![uploadState isKindOfClass:[GDFileManagerUploadState class]]) {
        if (failure) failure(nil);
        return nil;
    }
    
    GDFileManagerUploadState *uploadStateWrapper = uploadState;
    NSURL *destinationURL = [uploadStateWrapper uploadURL];
    NSString *parentVersionID = [uploadStateWrapper parentVersionID];
    NSString *mimeType = uploadStateWrapper.mimeType;
    
    return [self uploadFileURL:localURL mimeType:mimeType toDestinationURL:destinationURL parentVersionID:parentVersionID
           internalUploadState:uploadStateWrapper.uploadState
            uploadStateHandler:uploadStateHandler
                      progress:progress
                       success:success
                       failure:failure];
}

- (NSString *)filenameAvoidingConflictsWithExistingContents:(NSArray *)contents preferredFilename:(NSString *)preferredFilename
{
    NSMutableSet *filenameSet = [NSMutableSet new];
    for (GDURLMetadata *metadata in contents) {
        NSString *filename = metadata.filename;
        if (!filename) continue;
        filename = [self normalisedPathForPath:filename];
        [filenameSet addObject:filename];
    }
    
    NSString *normalisedDestinationFilename = [self normalisedPathForPath:preferredFilename];
    if (![filenameSet containsObject:normalisedDestinationFilename])
        return preferredFilename;
    
    NSInteger numberToAppend = 1;
    NSString *baseFilename = [preferredFilename stringByDeletingPathExtension];
    NSString *pathExtension = [preferredFilename pathExtension];
    
    while (true) {
        NSString *candidateFilename = [NSString stringWithFormat:@"%@ (%@).%@", baseFilename, @(numberToAppend++), pathExtension];
        NSString *normalisedCandidate = [self normalisedPathForPath:candidateFilename];
        if (![filenameSet containsObject:normalisedCandidate])
            return candidateFilename;
    };
}

- (NSURL *)cacheURLForURL:(NSURL *)canonicalURL versionIdentifier:(NSString *)versionIdentifier cachedMetadata:(GDURLMetadata *__autoreleasing *)cachedMetadata
{
    // Doesn't support it. That's OK.
    return nil;
}


#pragma - Subclasses to provide

- (BOOL)automaticallyAvoidsUploadOverwrites
{
    return NO;
}

- (BOOL)shouldCacheResults
{
    return [self.fileService shouldCacheResults];
}

- (NSString *)userDescription
{
    return nil;
}

- (NSString *)detailDescription
{
    NSString *netLoc =  (__bridge_transfer NSString *)CFURLCopyNetLocation((__bridge CFURLRef)self.baseURL);
    return [NSString stringWithFormat:@"Account ID: %@", netLoc];
}

- (GDURLMetadata *)clientMetadataWithCachedMetadata:(id <GDURLMetadata>)urlMetadata parentURL:(NSURL *)url
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (void)validateAccessWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure
{
    [self doesNotRecognizeSelector:_cmd];
}

- (void)getMetadataForURL:(NSURL *)url metadataCache:(id <GDMetadataCache>)metadataCache cachedMetadata:(id<GDURLMetadata>)cachedMetadataOrNil
                  success:(void (^)(GDURLMetadata *metadata))success failure:(void (^)(NSError *error))failure
{
    [self doesNotRecognizeSelector:_cmd];
}

- (void)deleteURL:(NSURL *)url success:(void (^)())success failure:(void (^)(NSError *error))failure
{
    [self doesNotRecognizeSelector:_cmd];
}

- (void)copyFileAtURL:(NSURL *)sourceURL toParentURL:(NSURL *)destinationParentURL name:(NSString *)name success:(void (^)(GDURLMetadata *))success failure:(void (^)(NSError *))failure
{
    [self doesNotRecognizeSelector:_cmd];
}

- (void)moveFileAtURL:(NSURL *)sourceURL toParentURL:(NSURL *)destinationParentURL name:(NSString *)name success:(void (^)(GDURLMetadata *))success failure:(void (^)(NSError *))failure
{
    [self doesNotRecognizeSelector:_cmd];
}


- (NSOperation *)downloadURL:(NSURL *)url intoFileURL:(NSURL *)localURL fileVersion:(NSString *)fileVersionIdentifier
                    progress:(void (^)(NSUInteger, long long, long long))progress
                     success:(void (^)(NSURL *localURL, GDURLMetadata *metadata))success
                     failure:(void (^)(NSError *))failure
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (NSOperation *)uploadFileURL:(NSURL *)localURL mimeType:(NSString *)mimeType toDestinationURL:(NSURL *)destinationURL parentVersionID:(NSString *)parentVersionID
           internalUploadState:(id <NSCoding>)internalUploadState uploadStateHandler:(void (^)(GDFileManagerUploadState * uploadState))uploadStateHandler
                      progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress
                       success:(void (^)(GDURLMetadata *metadata, NSArray *conflicts))success
                       failure:(void (^)(NSError *error))failure
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (NSOperation *)uploadFileURL:(NSURL *)localURL filename:(NSString *)filename mimeType:(NSString *)mimeType toParentFolderURL:(NSURL *)parentFolderURL
            uploadStateHandler:(void (^)(GDFileManagerUploadState * uploadState))uploadStateHandler
                      progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress
                       success:(void (^)(GDURLMetadata *metadata, NSArray *conflicts))success
                       failure:(void (^)(NSError *error))failure
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}


@end
