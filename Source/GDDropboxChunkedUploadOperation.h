//
//  GDDropboxChunkedUploadOperation.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 4/08/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDParentOperation.h"

#import "GDDropboxClient.h"

@interface GDDropboxChunkedUploadOperation : GDParentOperation

- (id)initWithClient:(GDDropboxClient *)client fromLocalPath:(NSString *)sourcePath toDropboxPath:(NSString *)destinationPath
             success:(void (^)(GDDropboxMetadata *metadata, NSArray *conflictingRevisions))success
             failure:(void (^)(NSError *error))failure;

@property (nonatomic, readonly, strong) GDDropboxClient *client;
@property (nonatomic, readonly, copy) NSString *sourcePath;
@property (nonatomic, readonly, copy) NSString *destinationPath;
@property (nonatomic, copy) NSString *parentRev;
@property (nonatomic) NSInteger chunkSize;
@property (nonatomic, strong) void (^uploadStateHandler)(GDDropboxUploadState *uploadState);
@property (nonatomic, strong) void (^uploadProgressBlock)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite);

@end
