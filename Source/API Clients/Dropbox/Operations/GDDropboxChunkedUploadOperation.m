//
//  GDDropboxChunkedUploadOperation.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 4/08/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDDropboxChunkedUploadOperation.h"
#import "GDDropboxUploadState.h"
#import "GDDropboxMetadata.h"

#import "GDHTTPOperation.h"

@interface GDDropboxChunkedUploadOperation ()

@property (nonatomic, readonly, strong) void (^success)(GDDropboxMetadata *metadata, NSArray *conflictingRevisions);
@property (nonatomic, readonly, strong) void (^failure)(NSError *error);

@property (nonatomic, strong) GDDropboxUploadState *uploadState;
@property (nonatomic, strong) GDDropboxMetadata *fileMetadata;
@property (nonatomic) NSInteger fileSize;
@property (nonatomic, getter = isConflict) BOOL conflict;

@end

@implementation GDDropboxChunkedUploadOperation

- (id)initWithClient:(GDDropboxClient *)client fromLocalPath:(NSString *)sourcePath toDropboxPath:(NSString *)destinationPath
             success:(void (^)(GDDropboxMetadata *metadata, NSArray *conflictingRevisions))success
             failure:(void (^)(NSError *error))failure
{
    if ((self = [super init])) {
        _client = client;
        _sourcePath = [sourcePath copy];
        _destinationPath = [destinationPath copy];
        
        __block typeof(self) strongSelf = self;
        dispatch_block_t cleanup = ^{[strongSelf finish]; strongSelf->_success = nil; strongSelf->_failure = nil; strongSelf->_uploadProgressBlock = nil; strongSelf->_uploadStateHandler = nil;  strongSelf = nil;};
        _success = ^(GDDropboxMetadata *metadata, NSArray *conflictingRevisions){
            dispatch_async(strongSelf.successCallbackQueue, ^{
                if (success) success(metadata, conflictingRevisions);
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

- (void)nextUploadStep
{
    if (![self isExecuting])
        return self.failure(GDOperationCancelledError);

    if (!self.uploadState || self.uploadState.offset < self.fileSize) {
        [self sendNextChunk];
    } else if (self.uploadState && self.uploadState.offset == self.fileSize && ![self isConflict]) {
        [self commitUpload];
    } else if (self.uploadState && self.uploadState.offset == self.fileSize && [self isConflict]) {
        [self getConflictingRevisions];
    } else {
        return self.failure(nil);
    }
}

static const NSInteger kGDDropboxDefaultUploadChunkSize = 2*1024*1024;
static NSString *const kUploadID = @"upload_id";
static NSString *const kOffset = @"offset";

- (void)sendNextChunk
{
    NSInteger chunkSize = self.chunkSize;
    if (chunkSize <= 0) chunkSize = kGDDropboxDefaultUploadChunkSize;
    
    NSFileHandle *file = [NSFileHandle fileHandleForReadingAtPath:self.sourcePath];
	if (!file) {
        // File to upload doesn't exist.
        return self.failure([NSError errorWithDomain:@"GDDropbox" code:0 userInfo:nil]);
	}
    
    NSString *path = @"https://api-content.dropbox.com/1/chunked_upload";
    
    NSMutableDictionary *parameters = nil;
    if (self.uploadState) {
        parameters = [NSMutableDictionary new];
        parameters[kUploadID] = self.uploadState.uploadID;
        parameters[kOffset] = [@(self.uploadState.offset) stringValue];
        [file seekToFileOffset:self.uploadState.offset];
    }
    
	NSData *data = [file readDataOfLength:chunkSize];
    [file closeFile];
    file = nil;
    
    NSMutableURLRequest *urlRequest = [self.client requestWithMethod:@"PUT" path:path parameters:parameters];
    [urlRequest addValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    [urlRequest addValue:[@([data length]) stringValue] forHTTPHeaderField:@"Content-Length"];
    
    [self.client enqueueOperationWithURLRequest:urlRequest
                         requiresAuthentication:YES
                               shouldRetryBlock:NULL
                                        success:^(AFHTTPRequestOperation *requestOperation, id responseObject) {
                                            GDDropboxUploadState *newUploadState = [[GDDropboxUploadState alloc] initWithDictionary:responseObject];
                                            
                                            [self setUploadState:newUploadState notifyDelegate:YES];

                                            [self nextUploadStep];
                                        }
                                        failure:^(AFHTTPRequestOperation *requestOperation, NSError *error) {
                                            if ([[error domain] isEqualToString:GDHTTPStatusErrorDomain] &&
                                                [requestOperation isKindOfClass:[AFJSONRequestOperation class]]) {
                                                AFJSONRequestOperation *jsonOperation = (AFJSONRequestOperation *)requestOperation;
                                                switch ([error code]) {
                                                    case 400:
                                                        // Incorrect offset
                                                    {
                                                        GDDropboxUploadState *newUploadState = [[GDDropboxUploadState alloc] initWithDictionary:jsonOperation.responseJSON];
                                                        [self setUploadState:newUploadState notifyDelegate:YES];
                                                        return [self nextUploadStep];
                                                    }
                                                        break;
                                                    case 404:
                                                        // Upload expired
                                                    {
                                                        [self setUploadState:nil notifyDelegate:YES];
                                                        return [self nextUploadStep];
                                                    }
                                                        break;
                                                        
                                                    default:
                                                        break;
                                                }
                                            }
                                            self.failure(error);
                                        }
                        configureOperationBlock:^(AFHTTPRequestOperation *requestOperation) {
                            requestOperation.inputStream = [NSInputStream inputStreamWithData:data];
                            [requestOperation setUploadProgressBlock:self.uploadProgressBlock];
                            [self addChildOperation:requestOperation];
                        }];
}

- (void)setUploadState:(GDDropboxUploadState *)uploadState notifyDelegate:(BOOL)notifyDelegate
{
    self.uploadState = uploadState;
    if (notifyDelegate && self.uploadStateHandler) {
        self.uploadStateHandler(self.uploadState);
    }
}

static NSString *const kParentRev = @"parent_rev";

- (void)commitUpload
{
    NSString *path = [[NSString stringWithFormat:@"https://api-content.dropbox.com/1/commit_chunked_upload/%@%@", self.client.root, self.destinationPath] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    
    parameters[@"overwrite"] = @"false";
    if (self.parentRev) {
        parameters[kParentRev] = self.parentRev;
    }
    parameters[kUploadID] = self.uploadState.uploadID;
    
    NSMutableURLRequest *urlRequest = [self.client requestWithMethod:@"POST" path:path parameters:parameters];
    
    [self.client enqueueOperationWithURLRequest:urlRequest
                         requiresAuthentication:YES
                               shouldRetryBlock:NULL
                                        success:^(AFHTTPRequestOperation *requestOperation, id responseObject) {
                                            GDDropboxMetadata *metadata = [[GDDropboxMetadata alloc] initWithDictionary:responseObject];
                                            NSString *canonicalOriginalPath = [GDDropboxMetadata canonicalPathForPath:self.destinationPath];
                                            NSString *canonicalFinalPath = [GDDropboxMetadata canonicalPathForPath:metadata.path];
                                            BOOL didConflict = ![canonicalOriginalPath isEqualToString:canonicalFinalPath];
                                            if (!didConflict) {
                                                self.success(metadata, self.parentRev ? @[] : nil);
                                            } else {
                                                self.conflict = YES;
                                                self.fileMetadata = metadata;
                                                [self nextUploadStep];
                                            }
                                        }
                                        failure:^(AFHTTPRequestOperation *requestOperation, NSError *error) {
                                            self.failure(error);
                                        }
                        configureOperationBlock:^(AFHTTPRequestOperation *requestOperation) {
                            [self addChildOperation:requestOperation];
                        }];
}

- (void)getConflictingRevisions
{
    [self.client getRevisionHistoryForFile:self.destinationPath
                                   success:^(NSArray *versionHistory) {
                                       NSMutableArray *conflictingRevisions = [NSMutableArray new];
                                       for (GDDropboxMetadata *revisionMetadata in versionHistory) {
                                           if ([revisionMetadata.rev isEqualToString:self.parentRev])
                                               break;
                                           [conflictingRevisions addObject:revisionMetadata.rev];
                                       }
                                       self.success(self.fileMetadata, [conflictingRevisions copy]);
                                   } failure:self.failure];
}

@end
