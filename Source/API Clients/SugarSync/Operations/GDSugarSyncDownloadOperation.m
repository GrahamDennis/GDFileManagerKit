//
//  GDSugarSyncDownloadOperation.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 8/08/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDSugarSyncDownloadOperation.h"

@interface GDSugarSyncDownloadOperation ()

@property (nonatomic, readonly, strong) void (^success)(NSString *localPath, GDSugarSyncMetadata *metadata, NSString *fileVersionID);
@property (nonatomic, readonly, strong) void (^failure)(NSError *error);

@property (nonatomic, strong) GDSugarSyncMetadata *fileMetadata;
@property (nonatomic) NSInteger fileSize;

@end

@implementation GDSugarSyncDownloadOperation

- (id)initWithClient:(GDSugarSyncClient *)client fileID:(NSString *)fileID toLocalPath:(NSString *)localPath
             success:(void (^)(NSString *localPath, GDSugarSyncMetadata *metadata, NSString *fileVersionID))success
             failure:(void (^)(NSError *error))failure;
{
    if ((self = [super init])) {
        _client = client;
        _localPath = [localPath copy];
        _fileID = [fileID copy];
        
        __block typeof(self) strongSelf = self;
        dispatch_block_t cleanup = ^{[strongSelf finish]; strongSelf->_success = nil; strongSelf->_failure = nil; strongSelf->_downloadProgressBlock = nil; strongSelf = nil;};
        _success = ^(NSString *localPath, GDSugarSyncMetadata *metadata, NSString *fileVersionID){
            dispatch_async(strongSelf.successCallbackQueue, ^{
                if (success) success(localPath, metadata, fileVersionID);
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

- (void)main
{
    [self nextDownloadStep];
}

- (void)nextDownloadStep
{
    if (![self isExecuting])
        return self.failure(GDOperationCancelledError);
    
    if (!self.fileMetadata) {
        [self getFileMetadata];
    } else if (!self.fileVersionID) {
        [self getLatestFileVersion];
    } else {
        [self downloadFile];
    }
}

- (void)getFileMetadata
{
    [self.client getMetadataForObjectID:self.fileID
                                success:^(GDSugarSyncMetadata *metadata) {
                                    self.fileMetadata = metadata;
                                    
                                    [self nextDownloadStep];
                                } failure:self.failure];
}

- (void)getLatestFileVersion
{
    [self.client getVersionHistoryForObjectID:self.fileID
                                      success:^(NSArray *history) {
                                          for (GDSugarSyncMetadata *fileVersionMetadata in history) {
                                              self.fileVersionID = fileVersionMetadata.objectID;
                                              [self nextDownloadStep];
                                              return;
                                          }
                                          self.failure(nil);
                                      } failure:self.failure];
}

- (void)downloadFile
{
    NSString *path = [self.fileVersionID stringByAppendingPathComponent:@"data"];
    NSMutableURLRequest *urlRequest = [self.client requestWithMethod:@"GET" path:path parameters:nil];
    [urlRequest setValue:@"*/*" forHTTPHeaderField:@"Accept"];
    
    NSOutputStream *outputStream = [NSOutputStream outputStreamToFileAtPath:self.localPath append:NO];
    
    [self.client enqueueOperationWithURLRequest:urlRequest
                         requiresAuthentication:YES
                               shouldRetryBlock:NULL
                                        success:^(AFHTTPRequestOperation *requestOperation, id responseObject) {
                                            self.success(self.localPath, self.fileMetadata, self.fileVersionID);
                                        }
                                        failure:^(AFHTTPRequestOperation *requestOperation, NSError *error) {
                                            self.failure(error);
                                        }
                        configureOperationBlock:^(AFHTTPRequestOperation *requestOperation) {
                            [self addChildOperation:requestOperation];
                            requestOperation.outputStream = outputStream;
                            [requestOperation setDownloadProgressBlock:self.downloadProgressBlock];
                        }];
    
}

@end
