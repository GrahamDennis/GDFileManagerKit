//
//  GDFileManagerDownloadOperation.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 5/08/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDFileManagerCachedDownloadOperation.h"
#import "GDFileManagerDownloadOperation_Private.h"
#import "GDFileManager_Private.h"

#import "GDFileServiceSession.h"
#import "GDFileServiceManager.h"
#import "GDURLMetadata_Private.h"

@interface GDFileManagerCachedDownloadOperation ()

@property (nonatomic, strong) NSURL *canonicalURL;
@property (nonatomic, strong) GDFileServiceSession *session;
@property (nonatomic) BOOL didFetchNewFileVersion;

@end

@implementation GDFileManagerCachedDownloadOperation

- (instancetype)initWithFileManager:(GDFileManager *)fileManager sourceURL:(NSURL *)sourceURL success:(void (^)(NSURL *, GDURLMetadata *))success failure:(void (^)(NSError *))failure
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (instancetype)initWithFileManager:(GDFileManager *)fileManager downloadURL:(NSURL *)url cachePolicy:(GDFileManagerCachePolicy)cachePolicy
                            success:(void (^)(NSURL *, GDURLMetadata *))success
                            failure:(void (^)(NSError *))failure
{
    typeof(success) successWrapper = ^(NSURL *localURL, GDURLMetadata *metadata){
        NSURL *cacheURL = localURL;
        if ([self didFetchNewFileVersion] && [self.session shouldCacheResults]) {
            cacheURL = [[GDFileManager sharedFileCache] moveLocalURL:localURL
                                                     intoCacheForURL:self.canonicalURL
                                                            metadata:metadata];
        }
        
        if (success) success(cacheURL, metadata);
    };
    
    if ((self = [super initWithFileManager:fileManager sourceURL:url success:successWrapper failure:failure])) {
        _cachePolicy = cachePolicy;
    }
    return self;
}

- (void)main
{
    GDFileManager *fileManager = self.fileManager;
    GDFileServiceSession *session = [fileManager.fileServiceManager fileServiceSessionForURL:self.sourceURL];
    self.session = session;
    
    if (![session shouldCacheResults]) {
        return [super main];
    }

    GDFileManagerDataCacheCoordinator *fileCacheCoordinator = [GDFileManager sharedFileCache];
    if (!fileCacheCoordinator) {
        return self.failure(GDFileManagerError(GDFileManagerNoDataCacheCoordinatorError));
    }
    
    NSURL *canonicalURL = [session canonicalURLForURL:self.sourceURL];
    if (!canonicalURL) {
        return self.failure(GDFileManagerError(GDFileManagerNoCanonicalURLError));
    }
    self.canonicalURL = canonicalURL;
    
    id <GDURLMetadata> cachedMetadata = nil;
    NSURL *cacheURL = [fileCacheCoordinator cacheURLForURL:canonicalURL cachedMetadata:&cachedMetadata];
    if (cacheURL) {
        if (self.cachePolicy == GDFileManagerReturnCacheDataElseLoad ||
            self.cachePolicy == GDFileManagerReturnCacheDataElseDontLoad) {
            GDURLMetadata *clientMetadata = [fileManager clientMetadataForURLMetadata:cachedMetadata
                                                                            clientURL:self.sourceURL
                                                                   fileServiceSession:session
                                                                                cache:nil];
            return self.success(cacheURL, clientMetadata);
        }
    }
    
    if (self.cachePolicy == GDFileManagerReturnCacheDataElseDontLoad) {
        return self.failure(GDFileManagerError(GDFileManagerNoResultInCacheError));
    }
    
    if (cacheURL && cachedMetadata.fileVersionIdentifier) {
        [self.fileManager getLatestVersionIdentifierForURL:self.sourceURL cachePolicy:self.cachePolicy
                                                   success:^(NSString *versionIdentifier) {
                                                       if ([versionIdentifier isEqualToString:cachedMetadata.fileVersionIdentifier]) {
                                                           self.didFetchNewFileVersion = NO;
                                                           GDURLMetadata *clientMetadata = [fileManager clientMetadataForURLMetadata:cachedMetadata
                                                                                                                           clientURL:self.sourceURL
                                                                                                                  fileServiceSession:session
                                                                                                                               cache:nil];
                                                           return self.success(cacheURL, clientMetadata);
                                                       } else {
                                                           self.didFetchNewFileVersion = YES;
                                                           return [self downloadFile];
                                                       }
                                                   } failure:self.failure];
    } else {
        self.didFetchNewFileVersion = YES;
        [self downloadFile];
    }
}

@end
