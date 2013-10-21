//
//  GDFileManagerUploadOperation.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 18/08/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDParentOperation.h"

#import "GDFileManagerConstants.h"

@class GDFileManager, GDURLMetadata;
@class GDFileManagerUploadState;

@interface GDFileManagerUploadOperation : GDParentOperation

- (instancetype)initWithFileManager:(GDFileManager *)fileManager sourceFileURL:(NSURL *)sourceURL options:(GDFileManagerUploadOptions)options
                            success:(void (^)(GDURLMetadata *metadata, NSArray *conflicts))success
                            failure:(void (^)(NSError *error))failure;

@property (nonatomic, readonly, strong) GDFileManager *fileManager;
@property (nonatomic, readonly, strong) NSURL *sourceURL;
@property (nonatomic, readonly, strong) NSURL *destinationURL;
@property (nonatomic, readonly, copy) NSString *destinationFilename;
@property (nonatomic, readonly, copy) NSString *mimeType;
@property (nonatomic, readonly, copy) NSString *parentVersionID;
@property (nonatomic, readonly, strong) NSURL *parentFolderURL;
@property (nonatomic) GDFileManagerUploadOptions options;

@property (nonatomic, strong) GDFileManagerUploadState *uploadState;
@property (nonatomic, strong) void (^uploadStateHandler)(GDFileManagerUploadState * uploadState);
@property (nonatomic, strong) void (^uploadProgressBlock)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite);

- (void)createNewFileWithFilename:(NSString *)filename mimeType:(NSString *)mimeType parentFolderURL:(NSURL *)parentFolderURL;

- (void)setDestinationURL:(NSURL *)destinationURL mimeType:(NSString *)mimeType parentVersionID:(NSString *)parentVersionID;


@end
