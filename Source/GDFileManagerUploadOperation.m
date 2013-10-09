//
//  GDFileManagerUploadOperation.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 18/08/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDFileManagerUploadOperation.h"
#import "GDFileManagerUploadOperation_Private.h"

#import "GDFileManager.h"
#import "GDFileManager_Private.h"
#import "GDURLMetadata_Private.h"
#import "GDFileManagerUploadState.h"
#import "GDFileServiceSession.h"
#import "GDFileServiceManager.h"

@implementation GDFileManagerUploadOperation

@synthesize destinationURL = _destinationURL;
@synthesize mimeType = _mimeType;
@synthesize uploadMode = _uploadMode;

- (instancetype)initWithFileManager:(GDFileManager *)fileManager sourceFileURL:(NSURL *)sourceURL options:(GDFileManagerUploadOptions)options
                            success:(void (^)(GDURLMetadata *, NSArray *))success
                            failure:(void (^)(NSError *))failure
{
    if (!sourceURL) return nil;
    
    if ((self = [super init])) {
        _fileManager = fileManager;
        _sourceURL = [sourceURL copy];
        _options = options;
        self.uploadMode = GDFileManagerUploadOperationModeUnknown;
        
        __block typeof(self) strongSelf = self;
        dispatch_block_t cleanup = ^{[strongSelf finish]; strongSelf->_success = nil; strongSelf->_failure = nil; strongSelf->_uploadProgressBlock = nil; strongSelf->_uploadStateHandler = nil; strongSelf = nil;};
        
        _success = ^(GDURLMetadata *metadata, NSArray *conflicts) {
            dispatch_async(strongSelf.successCallbackQueue, ^{
                if (success) success(metadata, conflicts);
                cleanup();
            });
        };
        _failure = ^(NSError *error){
            dispatch_async(strongSelf.failureCallbackQueue, ^{
                if (failure) failure(error);
                cleanup();
            });
        };
    }
    return self;
}

- (void)setUploadMode:(GDFileManagerUploadOperationMode)uploadMode
{
    _uploadMode = uploadMode;
}

- (void)createNewFileWithFilename:(NSString *)filename mimeType:(NSString *)mimeType parentFolderURL:(NSURL *)parentFolderURL
{
    NSParameterAssert(self.uploadMode == GDFileManagerUploadOperationModeUnknown);
    self.uploadMode = GDFileManagerUploadOperationModeCreateFile;
    
    _destinationFilename = [filename copy];
    _mimeType = [mimeType copy];
    _parentFolderURL = [parentFolderURL copy];
    
}

- (void)setDestinationURL:(NSURL *)destinationURL mimeType:(NSString *)mimeType parentVersionID:(NSString *)parentVersionID
{
    NSParameterAssert(self.uploadMode == GDFileManagerUploadOperationModeUnknown);
    self.uploadMode = GDFileManagerUploadOperationModeUpdateExistingFile;
    
    _destinationURL = [destinationURL copy];
    _parentVersionID = [parentVersionID copy];
    _mimeType = [mimeType copy];
}

- (void)setUploadState:(GDFileManagerUploadState *)uploadState
{
    if (self.uploadMode == GDFileManagerUploadOperationModeUnknown)
        self.uploadMode = GDFileManagerUploadOperationModeResumeUpload;
    
    _uploadState = uploadState;
}

- (NSURL *)destinationURL
{
    return self.uploadState.uploadURL ?: _destinationURL;
}

- (NSString *)mimeType
{
    return self.uploadState.mimeType ?: _mimeType;
}

- (void)main
{
    return [self startUpload];
}

typedef void (^GDUploadSuccessBlock)(GDURLMetadata *, NSArray *);
typedef void (^GDUploadFailureBlock)(NSError *);
typedef NSOperation *(^GDUploadConfigurationBlock)(GDFileServiceSession *, GDUploadSuccessBlock, GDUploadFailureBlock);

- (void)startUpload
{
    switch (self.uploadMode) {
        case GDFileManagerUploadOperationModeUnknown:
            return self.failure(nil);
        case GDFileManagerUploadOperationModeCreateFile:
        {
            __block NSString *destinationFilename = self.destinationFilename;
            GDUploadConfigurationBlock configurationBlock = ^(GDFileServiceSession *session, GDUploadSuccessBlock success, GDUploadFailureBlock failure){
                return [session uploadFileURL:self.sourceURL
                                     filename:destinationFilename
                                     mimeType:self.mimeType
                            toParentFolderURL:self.parentFolderURL
                           uploadStateHandler:self.uploadStateHandler
                                     progress:self.uploadProgressBlock
                                      success:success
                                      failure:failure];
            };
            return [self startChildUploadOperationWithSessionURL:self.parentFolderURL
                                              configurationBlock:^NSOperation *(GDFileServiceSession *session, GDUploadSuccessBlock success, GDUploadFailureBlock failure) {
                                                  if (![session automaticallyAvoidsUploadOverwrites]) {
                                                      __block GDParentOperation *parentOperation = [GDParentOperation new];
                                                      dispatch_block_t cleanup = ^{[parentOperation finish]; parentOperation = nil;};
                                                      
                                                      GDUploadSuccessBlock successWrapper = ^(GDURLMetadata *metadata, NSArray *conflicts){
                                                          success(metadata, conflicts);
                                                          cleanup();
                                                      };
                                                      GDUploadFailureBlock failureWrapper = ^(NSError *error){
                                                          failure(error);
                                                          cleanup();
                                                      };
                                                      
                                                      [self.fileManager getContentsOfDirectoryAtURL:self.parentFolderURL
                                                                                            success:^(NSArray *contents) {
                                                                                                destinationFilename = [self filenameAvoidingConflictsWithExistingContents:contents fromSession:session];
                                                                                                
                                                                                                NSOperation *childOperation = configurationBlock(session, successWrapper, failureWrapper);
                                                                                                [parentOperation addChildOperation:childOperation];
                                                                                                
                                                                                            } failure:failure];
                                                      [parentOperation start];
                                                      return parentOperation;
                                                  } else {
                                                      return configurationBlock(session, success, failure);
                                                  }
                                              }];
            
        }
        case GDFileManagerUploadOperationModeResumeUpload:
            return [self startChildUploadOperationWithSessionURL:self.destinationURL
                                              configurationBlock:^NSOperation *(GDFileServiceSession *session, GDUploadSuccessBlock success, GDUploadFailureBlock failure) {
                                                  return [session resumeUploadWithUploadState:self.uploadState
                                                                                  fromFileURL:self.sourceURL
                                                                           uploadStateHandler:self.uploadStateHandler
                                                                                     progress:self.uploadProgressBlock
                                                                                      success:success
                                                                                      failure:failure];
                                              }];
        case GDFileManagerUploadOperationModeUpdateExistingFile:
            return [self startChildUploadOperationWithSessionURL:self.destinationURL
                                              configurationBlock:^NSOperation *(GDFileServiceSession *session, GDUploadSuccessBlock success, GDUploadFailureBlock failure) {
                                                  return [session uploadFileURL:self.sourceURL
                                                                       mimeType:self.mimeType
                                                               toDestinationURL:self.destinationURL
                                                                parentVersionID:self.parentVersionID
                                                            internalUploadState:self.uploadState.uploadState
                                                             uploadStateHandler:self.uploadStateHandler
                                                                       progress:self.uploadProgressBlock
                                                                        success:success
                                                                        failure:failure];
                                              }];
    
    }
    
}

- (NSString *)filenameAvoidingConflictsWithExistingContents:(NSArray *)contents fromSession:(GDFileServiceSession *)session
{
    return [session filenameAvoidingConflictsWithExistingContents:contents preferredFilename:self.destinationFilename];
}

- (void)startChildUploadOperationWithSessionURL:(NSURL *)sessionURL
                             configurationBlock:(GDUploadConfigurationBlock)configurationBlock
{
    GDFileManager *fileManager = self.fileManager;
    
    GDFileServiceSession *session = [fileManager.fileServiceManager fileServiceSessionForURL:sessionURL];
    
    NSURL *canonicalURL = [session canonicalURLForURL:sessionURL];
    if (!canonicalURL) {
        return self.failure(GDFileManagerError(GDFileManagerNoCanonicalURLError));
    }
    
    if (!self.sourceURL) {
        return self.failure(GDFileManagerError(GDFileManagerNoLocalURLError));
    } else if (![self.sourceURL isFileURL]) {
        return self.failure(GDFileManagerError(GDFileManagerLocalURLNotFileURLError));
    }
    BOOL isDirectory = NO;
    if (![[NSFileManager defaultManager] fileExistsAtPath:[self.sourceURL path] isDirectory:&isDirectory] || isDirectory) {
        return self.failure(GDFileManagerError(GDFileManagerCantReadFromLocalURLError));
    }
    
    NSOperation *childOperation = configurationBlock(session, ^(GDURLMetadata *metadata, NSArray *conflicts) {
        [fileManager cacheClientMetadata:metadata addToParent:YES];
        self.success(metadata, conflicts);
        // Do this so that if the success callback wants the original file it can use or delete it first.  We then delete it later.
        if (self.options & GDFileManagerUploadDeleteOnSuccess) {
            [[NSFileManager defaultManager] removeItemAtURL:self.sourceURL error:nil];
        }
    }, self.failure);
    
    if (childOperation)
        [self addChildOperation:childOperation];
}


@end
