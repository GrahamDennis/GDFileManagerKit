//
//  GDGoogleDriveChunkedUploadOperation.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 10/08/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDGoogleDriveChunkedUploadOperation.h"

#import "GDGoogleDriveUploadState_Private.h"

#import "GDHTTPOperation.h"

@interface GDGoogleDriveChunkedUploadOperation ()

@property (nonatomic, readonly, strong) void (^success)(GDGoogleDriveMetadata *metadata, NSArray *conflictingRevisionIDs);
@property (nonatomic, readonly, strong) void (^failure)(NSError *error);

@property (nonatomic, strong) GDGoogleDriveMetadata *fileMetadata;
@property (nonatomic, strong) NSArray *fileVersionHistory;
@property (nonatomic) NSInteger fileSize;
@property (nonatomic, strong, readonly) NSString *uploadSessionURI;
@property (nonatomic, strong) NSString *uploadedMD5;
@property (nonatomic, strong) NSString *revisionID;
@property (nonatomic, strong, readonly) NSString *metadataFields;

@end

@implementation GDGoogleDriveChunkedUploadOperation

- (id)initWithClient:(GDGoogleDriveClient *)client fromLocalPath:(NSString *)sourcePath
             success:(void (^)(GDGoogleDriveMetadata *metadata, NSArray *conflictingRevisionIDs))success
             failure:(void (^)(NSError *error))failure
{
    if ((self = [super init])) {
        _client = client;
        _sourcePath = sourcePath;
        
        __block typeof(self) strongSelf = self;
        dispatch_block_t cleanup = ^{[strongSelf finish]; strongSelf->_success = nil; strongSelf->_failure = nil; strongSelf->_uploadProgressBlock = nil; strongSelf->_uploadStateHandler = nil; strongSelf = nil;};
        _success = ^(GDGoogleDriveMetadata *metadata, NSArray *conflictingRevisionIDs){
            dispatch_async(strongSelf.successCallbackQueue, ^{
                if (success) success(metadata, conflictingRevisionIDs);
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

- (void)createNewFileWithFilename:(NSString *)filename parentFolderID:(NSString *)parentFolderID
{
    return [self createNewFileWithFilename:filename mimeType:nil parentFolderID:parentFolderID];
}

- (void)createNewFileWithFilename:(NSString *)filename mimeType:(NSString *)mimeType parentFolderID:(NSString *)parentFolderID
{
    NSParameterAssert(![self isExecuting]);
    
    NSMutableDictionary *metadataDictionary = [NSMutableDictionary new];
    if (filename) metadataDictionary[@"title"] = filename;
    if (mimeType) metadataDictionary[@"mimeType"] = mimeType;
    if (parentFolderID) metadataDictionary[@"parents"] = @[@{@"id": parentFolderID}];
    
    self.fileMetadata = [[GDGoogleDriveMetadata alloc] initWithDictionary:metadataDictionary];
}

- (void)setUploadProgressBlock:(void (^)(NSUInteger, long long, long long))uploadProgressBlock
{
    if (!uploadProgressBlock) {
        _uploadProgressBlock = nil;
        return;
    }
    __weak typeof(self) weakSelf = self;
    
    _uploadProgressBlock = ^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite){
        return uploadProgressBlock(bytesWritten, totalBytesWritten + weakSelf.uploadState.offset, weakSelf.fileSize);
    };
}

- (void)setUploadState:(GDGoogleDriveUploadState *)uploadState
{
    return [self setUploadState:uploadState notifyDelegate:NO];
}

- (void)setUploadState:(GDGoogleDriveUploadState *)uploadState notifyDelegate:(BOOL)notifyDelegate
{
    _uploadState = uploadState;
    if (notifyDelegate && self.uploadStateHandler) {
        self.uploadStateHandler(self.uploadState);
    }
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
    
    if (!self.uploadState) {
        [self createUploadSession];
    } else if (self.uploadState.offset < self.fileSize) {
        [self uploadNextChunk];
    } else if (!self.fileVersionHistory) {
        [self getFileVersionHistory];
    } else {
        [self getFileMetadata];
    }
}

- (void)createUploadSession
{
    NSString *path = @"/upload/drive/v2/files";
    NSMutableDictionary *urlParameters = [NSMutableDictionary new];
    urlParameters[@"uploadType"] = @"resumable";
    urlParameters[@"prettyPrint"] = @"false";
    
    if (self.metadataFields)
        urlParameters[@"fields"] = self.metadataFields;
    
    NSString *requestMethod = nil;
    if (self.fileMetadata) {
        requestMethod = @"POST";
    } else if (self.destinationFileID) {
        requestMethod = @"PUT";
        path = [path stringByAppendingPathComponent:self.destinationFileID];
    } else {
        self.failure(nil);
    }
    
    NSMutableURLRequest *request = [self.client requestWithMethod:requestMethod path:path parameters:urlParameters];
    [request setValue:[@(self.fileSize) stringValue] forHTTPHeaderField:@"X-Upload-Content-Length"];
    
    if (self.fileMetadata) {
        [request setValue:self.fileMetadata.mimeType forHTTPHeaderField:@"X-Upload-Content-Type"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

        NSError *error = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self.fileMetadata.backingStore options:0 error:&error];
        if (!jsonData) {
            NSLog(@"Failed to encode file metadata due to error: %@", error);
            return self.failure(error);
        }
        [request setHTTPBody:jsonData];
    }
    
    [self.client enqueueOperationWithURLRequest:request
                         requiresAuthentication:YES
                                        success:^(AFHTTPRequestOperation *requestOperation, id responseObject) {
                                            NSString *sessionURI = [[[requestOperation response] allHeaderFields] objectForKey:@"Location"];
                                            
                                            GDGoogleDriveUploadState *uploadState = [[GDGoogleDriveUploadState alloc] initWithUploadSessionURI:sessionURI
                                                                                                                                        offset:0
                                                                                                                                      fileSize:self.fileSize];
                                            [self setUploadState:uploadState notifyDelegate:YES];
                                            
                                            [self nextUploadStep];
                                        } failure:^(AFHTTPRequestOperation *requestOperation, NSError *error) {
                                            self.failure(error);
                                        }];
}

static const NSInteger kGDGoogleDriveDefaultUploadSize = 2*1024*1024;

- (void)uploadNextChunk
{
    NSInteger chunkSize = self.chunkSize;
    if (chunkSize <= 0) chunkSize = kGDGoogleDriveDefaultUploadSize;
    
    NSFileHandle *file = [NSFileHandle fileHandleForReadingAtPath:self.sourcePath];
	if (!file) {
        // File to upload doesn't exist.
        return self.failure(nil);
	}
    
    [file seekToFileOffset:self.uploadState.offset];
    
	NSData *data = [file readDataOfLength:chunkSize];
    [file closeFile];
    file = nil;
    chunkSize = [data length];
    
    NSMutableURLRequest *urlRequest = [self.client requestWithMethod:@"PUT" path:self.uploadSessionURI parameters:nil];
    [urlRequest addValue:[@([data length]) stringValue] forHTTPHeaderField:@"Content-Length"];
    NSString *contentRange = [NSString stringWithFormat:@"bytes %@-%@/%@", @(self.uploadState.offset), @(self.uploadState.offset + chunkSize - 1), @(self.fileSize)];
    [urlRequest addValue:contentRange forHTTPHeaderField:@"Content-Range"];
    
    [self.client enqueueOperationWithURLRequest:urlRequest
                         requiresAuthentication:YES
                               shouldRetryBlock:NULL
                                        success:^(AFHTTPRequestOperation *requestOperation, id responseObject) {
                                            GDGoogleDriveUploadState *newUploadState = [[GDGoogleDriveUploadState alloc] initWithUploadSessionURI:self.uploadSessionURI
                                                                                                                                           offset:self.fileSize
                                                                                                                                         fileSize:self.fileSize];
                                            
                                            [self setUploadState:newUploadState notifyDelegate:YES];
                                            
                                            GDGoogleDriveMetadata *metadata = [[GDGoogleDriveMetadata alloc] initWithDictionary:responseObject];
                                            self.destinationFileID = metadata.identifier;
                                            self.uploadedMD5 = metadata.md5Checksum;
                                            
                                            [self nextUploadStep];
                                        }
                                        failure:^(AFHTTPRequestOperation *requestOperation, NSError *error) {
                                            if ([[error domain] isEqualToString:GDHTTPStatusErrorDomain]) {
                                                switch ([error code]) {
                                                    case 308:
                                                        // Resume incomplete
                                                    {
                                                        NSString *rangeString = [[[requestOperation response] allHeaderFields] objectForKey:@"Range"];
                                                        NSArray *rangeComponents = [rangeString componentsSeparatedByString:@"-"];
                                                        if ([rangeComponents count] == 2) {
                                                            NSInteger uploadOffset = [rangeComponents[1] integerValue] + 1;
                                                            GDGoogleDriveUploadState *newUploadState = [[GDGoogleDriveUploadState alloc] initWithUploadSessionURI:self.uploadSessionURI
                                                                                                                                                           offset:uploadOffset
                                                                                                                                                         fileSize:self.fileSize];
                                                            
                                                            [self setUploadState:newUploadState notifyDelegate:YES];
                                                            return [self nextUploadStep];
                                                        }
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

- (void)getFileVersionHistory
{
    [self.client getRevisionHistoryForFileID:self.destinationFileID
                                     success:^(NSArray *history) {
                                         self.fileVersionHistory = history;
                                         
                                         [self nextUploadStep];
                                     } failure:self.failure];
}

- (void)getFileMetadata
{
    [self.client getMetadataForFileID:self.destinationFileID
                                 etag:nil
                       metadataFields:self.metadataFields
                              success:^(GDGoogleDriveMetadata *metadata) {
                                  BOOL foundCurrentRevision = NO;
                                  NSMutableArray *conflictingRevisions = self.parentRevisionID ? [NSMutableArray new] : nil;
                                  for (GDGoogleDriveMetadata *revisionMetadata in self.fileVersionHistory) {
                                      if (foundCurrentRevision && self.parentRevisionID) {
                                          if ([revisionMetadata.identifier isEqualToString:self.parentRevisionID])
                                              break;
                                          [conflictingRevisions addObject:revisionMetadata.identifier];
                                      } else if ([revisionMetadata.md5Checksum isEqualToString:self.uploadedMD5]) {
                                          self.revisionID = revisionMetadata.identifier;
                                          foundCurrentRevision = YES;
                                      }
                                  }
                                  if (!self.revisionID) {
                                      NSLog(@"Unable to find revision ID corresponding to MD5 %@ in history %@", self.uploadedMD5, self.fileVersionHistory);
                                      self.failure(nil);
                                  }
                                  if (![metadata.headRevisionIdentifier isEqualToString:self.revisionID]) {
                                      NSMutableDictionary *modifiedMetadataDictionary = [metadata.backingStore mutableCopy];
                                      modifiedMetadataDictionary[@"headRevisionId"] = self.revisionID;
                                      metadata = [[GDGoogleDriveMetadata alloc] initWithDictionary:modifiedMetadataDictionary];
                                  }
                                  self.success(metadata, [conflictingRevisions copy]);
                              } failure:self.failure];
}

- (NSString *)uploadSessionURI
{
    return self.uploadState.uploadSessionURI;
}

- (NSString *)metadataFields
{
    if (self.client.defaultMetadataFields)
        return [@"md5Checksum,id," stringByAppendingString:self.client.defaultMetadataFields];
    return nil;
}

@end
