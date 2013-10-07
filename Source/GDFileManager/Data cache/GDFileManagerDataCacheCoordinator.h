//
//  GDFileManagerDataCacheManager.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 1/08/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GDURLMetadata;
@class GDFileManagerPersistentUploadOperation;
@class GDFileManagerUploadState;
@class GDURLMetadata;

extern NSString *const GDFileManagerNewCacheFileNotification;

@interface GDFileManagerDataCacheCoordinator : NSObject

+ (instancetype)sharedCacheCoordinator;

- (NSURL *)cacheURLForURL:(NSURL *)url cachedMetadata:(id <GDURLMetadata> *)cachedMetadata;
- (NSURL *)cacheURLForURL:(NSURL *)url versionIdentifier:(NSString *)versionIdentifier cachedMetadata:(id <GDURLMetadata> *)cachedMetadata;
- (NSURL *)moveLocalURL:(NSURL *)localURL intoCacheForURL:(NSURL *)url metadata:(id <GDURLMetadata>)metadata;
- (void)removeAllItems;

- (void)registerPersistentUploadOperation:(GDFileManagerPersistentUploadOperation *)uploadOperation;
- (void)persistentUploadOperation:(GDFileManagerPersistentUploadOperation *)uploadOperation newUploadState:(GDFileManagerUploadState *)uploadState;
- (void)persistentUploadOperation:(GDFileManagerPersistentUploadOperation *)uploadOperation completedSuccessfullyWithMetadata:(GDURLMetadata *)metadata;
- (void)persistentUploadOperation:(GDFileManagerPersistentUploadOperation *)uploadOperation failedWithError:(NSError *)error;

- (void)resumePendingUploads;

@property (nonatomic, strong, readonly) NSNumber *cacheSize;
@property (nonatomic, strong) NSNumber *maximumCacheSize;
@property (nonatomic, strong) NSURL *fileCacheDirectoryURL;

@end
