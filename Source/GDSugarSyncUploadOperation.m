//
//  GDSugarSyncUploadOperation.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 6/08/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDSugarSyncUploadOperation.h"
#import "GDSugarSyncUploadState_Private.h"
#import "GDHTTPOperation.h"

@interface GDSugarSyncUploadOperation ()

@property (nonatomic, readonly, strong) void (^success)(GDSugarSyncMetadata *metadata, NSString *fileVersionID, NSArray *conflictingVersionIDs);
@property (nonatomic, readonly, strong) void (^failure)(NSError *error);

@property (nonatomic, strong) NSString *fileVersionID;
@property (nonatomic) NSInteger fileSize;

@property (nonatomic, strong) GDSugarSyncMetadata *fileVersionMetadata;
@property (nonatomic, strong) NSArray *fileVersionHistory;

@end

@implementation GDSugarSyncUploadOperation

- (id)initWithClient:(GDSugarSyncClient *)client fromLocalPath:(NSString *)sourcePath toFileID:(NSString *)fileID
             success:(void (^)(GDSugarSyncMetadata *, NSString *, NSArray *))success
             failure:(void (^)(NSError *))failure
{
    if ((self = [super init])) {
        _client = client;
        _sourcePath = [sourcePath copy];
        _fileID = [fileID copy];
        
        __block typeof(self) strongSelf = self;
        dispatch_block_t cleanup = ^{[strongSelf finish]; strongSelf->_success = nil; strongSelf->_failure = nil; strongSelf->_uploadProgressBlock = nil; strongSelf->_uploadStateHandler = nil; strongSelf = nil;};
        _success = ^(GDSugarSyncMetadata *metadata, NSString *fileVersionID, NSArray *conflictingVersionIDs){
            dispatch_async(strongSelf.successCallbackQueue, ^{
                if (success) success(metadata, fileVersionID, conflictingVersionIDs);
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

- (void)setUploadProgressBlock:(void (^)(NSUInteger, long long, long long))uploadProgressBlock
{
    if (!uploadProgressBlock) {
        _uploadProgressBlock = nil;
        return;
    }
    __weak typeof(self) weakSelf = self;
    NSInteger fileSize = self.fileSize;
    
    _uploadProgressBlock = ^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite){
        return uploadProgressBlock(bytesWritten, totalBytesWritten + weakSelf.uploadState.offset, fileSize);
    };
}

- (void)main
{
    NSError *error = nil;
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.sourcePath error:&error];
    if (!fileAttributes) {
        return self.failure(error);
    }
    self.fileSize = [fileAttributes fileSize];
    
    [self nextUploadStep];
}

- (void)setUploadState:(GDSugarSyncUploadState *)uploadState
{
    return [self setUploadState:uploadState notifyDelegate:NO];
}

- (void)setUploadState:(GDSugarSyncUploadState *)uploadState notifyDelegate:(BOOL)notifyDelegate
{
    _uploadState = uploadState;
    if (notifyDelegate && self.uploadStateHandler) {
        self.uploadStateHandler(self.uploadState);
    }
}


- (void)nextUploadStep
{
    if (![self isExecuting])
        return self.failure(GDOperationCancelledError);
    
    if (!self.fileVersionMetadata) {
        if (!self.uploadState) {
            [self createFileVersion];
        } else if (self.uploadState.offset < self.fileSize) {
            [self sendNextChunk];
        } else if (self.uploadState.offset == self.fileSize) {
            [self commitUpload];
        } else {
            self.failure(nil);
        }
    } else {
        // File Uploaded, now check state
        if (self.parentVersionID && !self.fileVersionHistory) {
            [self checkIfUploadConflictsWithParent];
        } else {
            [self getFileMetadata];
        }
    }
}

- (void)createFileVersion
{
    [self.client createFileVersionForFileID:self.fileID
                                    success:^(NSString *versionID) {
                                        GDSugarSyncUploadState *newUploadState = [[GDSugarSyncUploadState alloc] initWithFileID:self.fileID fileVersionID:versionID offset:0];
                                        [self setUploadState:newUploadState notifyDelegate:YES];

                                        [self nextUploadStep];
                                    } failure:self.failure];
}

- (void)sendNextChunk
{
    NSInteger fileSize = self.fileSize, offset = self.uploadState.offset;
    NSString *fileVersionDataID = [self.fileVersionID stringByAppendingPathComponent:@"data"];
    NSInputStream *inputStream = [NSInputStream inputStreamWithFileAtPath:self.sourcePath];
    [inputStream setProperty:@(offset) forKey:NSStreamFileCurrentOffsetKey];
    
    NSString *path = fileVersionDataID;
    NSMutableURLRequest *urlRequest = [self.client requestWithMethod:@"PUT" path:path parameters:nil];

    [urlRequest setValue:[@(fileSize - offset) stringValue] forHTTPHeaderField:@"Content-Length"];
    NSString *rangeString = [NSString stringWithFormat:@"bytes=%@-", @(offset)];
    [urlRequest setValue:rangeString forHTTPHeaderField:@"Range"];
    
    [self.client enqueueOperationWithURLRequest:urlRequest
                         requiresAuthentication:YES
                               shouldRetryBlock:NULL
                                        success:^(AFHTTPRequestOperation *requestOperation, id responseObject) {
                                            if ([[[requestOperation response] allHeaderFields] count] == 0) {
                                                // Sometimes we get an empty 200 status response.  I suspect this is a bug in NSURLConnection.
                                                // The actual response from the server I believe is just a time-out or disconnect.
                                                // In this case, check the upload state with the server and continue.
                                                return [self checkUploadStateWithServer];
                                            }
                                            GDSugarSyncUploadState *newUploadState = [[GDSugarSyncUploadState alloc] initWithFileID:self.fileID fileVersionID:self.fileVersionID offset:fileSize];
                                            
                                            [self setUploadState:newUploadState notifyDelegate:NO];
                                            
                                            [self nextUploadStep];
                                        }
                                        failure:^(AFHTTPRequestOperation *requestOperation, NSError *error) {
                                            if ([[error domain] isEqualToString:GDHTTPStatusErrorDomain]) {
                                                switch ([error code]) {
                                                    case 404:
                                                        // Version no longer exists
                                                        [self setUploadState:nil notifyDelegate:YES];
                                                        [self nextUploadStep];
                                                        return;
                                                        
                                                    case 416:
                                                        // Incorrect byte range, we have to start at a different offset
                                                        [self checkUploadStateWithServer];
                                                        return;
                                                        
                                                    default:
                                                        break;
                                                }
                                            }
                                            [self checkIfProgressHasBeenMadeOrFailWithError:error];
                                        }
                        configureOperationBlock:^(AFHTTPRequestOperation *requestOperation) {
                            [self addChildOperation:requestOperation];
                            requestOperation.inputStream = inputStream;
                            [requestOperation setUploadProgressBlock:self.uploadProgressBlock];
                        }];

}

- (void)checkUploadStateWithServer
{
    [self.client getMetadataForObjectID:self.fileVersionID
                         success:^(GDSugarSyncMetadata *metadata) {
                             NSInteger offset = [metadata storedFileSize];
                             GDSugarSyncUploadState *newUploadState = [[GDSugarSyncUploadState alloc] initWithFileID:self.fileID fileVersionID:self.fileVersionID offset:offset];
                             [self setUploadState:newUploadState notifyDelegate:YES];
                             
                             [self nextUploadStep];
                         } failure:self.failure];

}

- (void)checkIfProgressHasBeenMadeOrFailWithError:(NSError *)originalError
{
    [self.client getMetadataForObjectID:self.fileVersionID
                                success:^(GDSugarSyncMetadata *metadata) {
                                    NSInteger offset = [metadata storedFileSize];
                                    if (offset > self.uploadState.offset) {
                                        GDSugarSyncUploadState *newUploadState = [[GDSugarSyncUploadState alloc] initWithFileID:self.fileID fileVersionID:self.fileVersionID offset:offset];
                                        [self setUploadState:newUploadState notifyDelegate:YES];
                                        
                                        [self nextUploadStep];
                                    } else {
                                        self.failure(originalError);
                                    }
                                } failure:^(NSError *error) {
                                    self.failure(originalError);
                                }];
}

- (void)commitUpload
{
    [self.client getMetadataForObjectID:self.fileVersionID
                                success:^(GDSugarSyncMetadata *metadata) {
                                    // Verify that it's present on the server.
                                    if (metadata.fileDataAvailableOnServer) {
                                        self.fileVersionMetadata = metadata;
                                        [self nextUploadStep];
                                    } else if (self.uploadState.offset == self.fileSize) {
                                        [self sendNextChunk]; // Should send a zero-sized chunk.
                                    } else {
                                        self.failure(nil);
                                    }
                                } failure:self.failure];
}

- (void)checkIfUploadConflictsWithParent
{
    [self.client getVersionHistoryForObjectID:self.fileID
                                      success:^(NSArray *history) {
                                          self.fileVersionHistory = history;
                                          [self nextUploadStep];
                                      } failure:self.failure];
}

- (void)getFileMetadata
{
    [self.client getMetadataForObjectID:self.fileID
                                success:^(GDSugarSyncMetadata *metadata) {
                                    BOOL foundCurrentRevision = NO;
                                    NSMutableArray *conflictingRevisions = self.parentVersionID ? [NSMutableArray new] : nil;
                                    for (GDSugarSyncMetadata *versionMetadata in self.fileVersionHistory) {
                                        if (foundCurrentRevision && self.parentVersionID) {
                                            if ([versionMetadata.objectID isEqualToString:self.parentVersionID])
                                                break;
                                            [conflictingRevisions addObject:versionMetadata.objectID];
                                        } else if ([versionMetadata.objectID isEqualToString:self.fileVersionID]) {
                                            foundCurrentRevision = YES;
                                        }
                                    }
                                    self.success(metadata, self.fileVersionID, [conflictingRevisions copy]);
                                } failure:self.failure];
}

- (NSString *)fileVersionID
{
    return self.uploadState.fileVersionID;
}
@end
