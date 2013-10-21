//
//  GDWebDAVUploadOperation.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 12/08/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDWebDAVUploadOperation.h"

#import "GDHTTPOperation.h"

@interface GDWebDAVUploadOperation ()

@property (nonatomic, readonly, strong) void (^success)(GDWebDAVMetadata *metadata);
@property (nonatomic, readonly, strong) void (^failure)(NSError *error);

@property (nonatomic) NSInteger fileSize;
@property (nonatomic, getter = isUploadComplete) BOOL uploadComplete;

@end

@implementation GDWebDAVUploadOperation

- (id)initWithClient:(GDWebDAVClient *)client fromLocalPath:(NSString *)sourcePath toWebDAVPath:(NSString *)destinationPath
             success:(void (^)(GDWebDAVMetadata *))success failure:(void (^)(NSError *))failure
{
    if ((self = [super init])) {
        _client = client;
        _sourcePath = [sourcePath copy];
        _destinationPath = [destinationPath copy];
        
        __block typeof(self) strongSelf = self;
        dispatch_block_t cleanup = ^{[strongSelf finish]; strongSelf->_success = nil; strongSelf->_failure = nil; strongSelf->_uploadProgressBlock = nil; strongSelf = nil;};
        _success = ^(GDWebDAVMetadata *metadata){
            dispatch_async(strongSelf.successCallbackQueue, ^{
                if (success) success(metadata);
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
    NSError *error = nil;
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.sourcePath error:&error];
    if (!fileAttributes) {
        return self.failure(error);
    }
    self.fileSize = [fileAttributes fileSize];
    
    [self nextUploadStep];
}

- (void)nextUploadStep
{
    if (![self isExecuting])
        return self.failure(GDOperationCancelledError);
    
    if (![self isUploadComplete]) {
        [self uploadFile];
    } else {
        [self getFileMetadata];
    }
}

- (void)uploadFile
{
    NSInteger fileSize = self.fileSize;
    NSInputStream *inputStream = [NSInputStream inputStreamWithFileAtPath:self.sourcePath];
    
    NSString *urlEncodedPath = [self.destinationPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableURLRequest *urlRequest = [self.client requestWithMethod:@"PUT" path:urlEncodedPath parameters:nil];
    [urlRequest setValue:@"*/*" forHTTPHeaderField:@"Accept"];
    
    [urlRequest setValue:[@(fileSize) stringValue] forHTTPHeaderField:@"Content-Length"];
    if (self.mimeType)
        [urlRequest setValue:self.mimeType forHTTPHeaderField:@"Content-Type"];
    
    [self.client enqueueOperationWithURLRequest:urlRequest
                         requiresAuthentication:YES
                               shouldRetryBlock:NULL
                                        success:^(AFHTTPRequestOperation *requestOperation, id responseObject) {
                                            self.uploadComplete = YES;
                                            
                                            [self nextUploadStep];
                                        }
                                        failure:^(AFHTTPRequestOperation *requestOperation, NSError *error) {
                                            if ([[error domain] isEqualToString:GDHTTPStatusErrorDomain]) {
                                                switch ([error code]) {
                                                    case 409:
                                                        // Parent directory doesn't exist?
                                                        break;
                                                        
                                                    default:
                                                        break;
                                                }
                                            }
                                            self.failure(error);
                                        }
                        configureOperationBlock:^(AFHTTPRequestOperation *requestOperation) {
                            [self addChildOperation:requestOperation];
                            requestOperation.inputStream = inputStream;
                            [requestOperation setUploadProgressBlock:self.uploadProgressBlock];
                        }];
    
}

- (void)getFileMetadata
{
    [self.client getMetadataForPath:self.destinationPath
                            success:self.success
                            failure:self.failure];
}

@end
