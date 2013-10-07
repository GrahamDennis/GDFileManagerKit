//
//  GDGoogleDriveChunkedUploadOperation.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 10/08/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDParentOperation.h"

#import "GDGoogleDriveClient.h"
#import "GDGoogleDriveUploadState.h"

@interface GDGoogleDriveChunkedUploadOperation : GDParentOperation

- (id)initWithClient:(GDGoogleDriveClient *)client fromLocalPath:(NSString *)sourcePath
             success:(void (^)(GDGoogleDriveMetadata *metadata, NSArray *conflictingRevisionIDs))success
             failure:(void (^)(NSError *error))failure;

- (void)createNewFileWithFilename:(NSString *)filename parentFolderID:(NSString *)parentFolderID;
- (void)createNewFileWithFilename:(NSString *)filename mimeType:(NSString *)mimeType parentFolderID:(NSString *)parentFolderID;

@property (nonatomic, readonly, strong) GDGoogleDriveClient *client;
@property (nonatomic, readonly, copy) NSString *sourcePath;
@property (nonatomic, copy) NSString *destinationFileID;
@property (nonatomic, copy) NSString *parentRevisionID;
@property (nonatomic) NSInteger chunkSize;
@property (nonatomic, strong) GDGoogleDriveUploadState *uploadState;
@property (nonatomic, strong) void (^uploadStateHandler)(GDGoogleDriveUploadState *uploadState);
@property (nonatomic, strong) void (^uploadProgressBlock)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite);


@end
