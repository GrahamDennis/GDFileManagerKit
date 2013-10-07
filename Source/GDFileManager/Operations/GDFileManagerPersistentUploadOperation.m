//
//  GDFileManagerPersistentUploadOperation.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 18/08/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDFileManagerPersistentUploadOperation.h"
#import "GDFileManagerPersistentUploadOperation_Private.h"
#import "GDFileManagerUploadOperation_Private.h"
#import "GDFileManager.h"
#import "GDPersistentUploadDestination.h"
#import "GDFileManagerPendingUpload.h"
#import "GDFileServiceManager.h"
#import "GDFileServiceSession.h"

#import "GDFileManagerDataCacheCoordinator.h"

@interface GDFileManagerPersistentUploadOperation ()

@property (nonatomic) BOOL shouldCacheOutcome;

@end

@implementation GDFileManagerPersistentUploadOperation

- (id)initWithFileManager:(GDFileManager *)fileManager
            sourceFileURL:(NSURL *)sourceURL
                  options:(GDFileManagerUploadOptions)options
                  success:(void (^)(GDURLMetadata *, NSArray *))success
                  failure:(void (^)(NSError *))failure
{
    GDFileManagerDataCacheCoordinator *dataCache = [GDFileManager sharedFileCache];
    __weak typeof(self) weakSelf = self;
    
    typeof(success) successWrapper = ^(GDURLMetadata *metadata, NSArray *conflicts){
        if (weakSelf.shouldCacheOutcome)
            [dataCache persistentUploadOperation:self completedSuccessfullyWithMetadata:metadata];
        if (success) success(metadata, conflicts);
    };
    typeof(failure) failureWrapper = ^(NSError *error) {
        if (weakSelf.shouldCacheOutcome)
            [dataCache persistentUploadOperation:self failedWithError:error];
        if (failure) failure(error);
    };
    
    if ((self = [super initWithFileManager:fileManager sourceFileURL:sourceURL options:options success:successWrapper failure:failureWrapper])) {
        self.uploadDestination = [GDPersistentUploadDestination new];
        self.shouldCacheOutcome = YES;
    }
    
    return self;
}

- (void)createNewFileWithFilename:(NSString *)filename mimeType:(NSString *)mimeType parentFolderURL:(NSURL *)parentFolderURL
{
    [self.uploadDestination createNewFileWithFilename:filename mimeType:mimeType parentFolderURL:parentFolderURL];
    
    [super createNewFileWithFilename:filename mimeType:mimeType parentFolderURL:parentFolderURL];
}

- (void)setDestinationURL:(NSURL *)destinationURL mimeType:(NSString *)mimeType parentVersionID:(NSString *)parentVersionID
{
    [self.uploadDestination setDestinationURL:destinationURL mimeType:mimeType parentVersionID:parentVersionID];
    
    [super setDestinationURL:destinationURL mimeType:mimeType parentVersionID:parentVersionID];
}

- (void)setUploadState:(GDFileManagerUploadState *)uploadState
{
    if (![self isExecuting]) {
        [self.uploadDestination setUploadState:uploadState];
    }
    [super setUploadState:uploadState];
}

- (void (^)(GDFileManagerUploadState *))uploadStateHandler
{
    void (^uploadStateHandlerWrapper)(GDFileManagerUploadState *) = ^(GDFileManagerUploadState *uploadState) {
        [[GDFileManager sharedFileCache] persistentUploadOperation:self newUploadState:uploadState];
        void (^uploadStateHandler)(GDFileManagerUploadState *) = [super uploadStateHandler];
        if (uploadStateHandler) uploadStateHandler(uploadState);
    };
    return uploadStateHandlerWrapper;
}

- (void)main
{
    NSURL *sessionURL = self.destinationURL ?: self.parentFolderURL;
    GDFileServiceSession *session = [[self.fileManager fileServiceManager] fileServiceSessionForURL:sessionURL];
    self.shouldCacheOutcome = [session shouldCacheResults];
    
    if (self.shouldCacheOutcome && !self.pendingUpload) {
        GDFileManagerDataCacheCoordinator *dataCache = [GDFileManager sharedFileCache];
        [dataCache registerPersistentUploadOperation:self];
    }
    
    [self startUpload];
}

@end
