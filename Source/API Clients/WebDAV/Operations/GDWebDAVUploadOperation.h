//
//  GDWebDAVUploadOperation.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 12/08/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDParentOperation.h"

#import "GDWebDAVClient.h"

@interface GDWebDAVUploadOperation : GDParentOperation

- (id)initWithClient:(GDWebDAVClient *)client fromLocalPath:(NSString *)sourcePath toWebDAVPath:(NSString *)destinationPath
             success:(void (^)(GDWebDAVMetadata *metadata))success
             failure:(void (^)(NSError *error))failure;

@property (nonatomic, readonly, strong) GDWebDAVClient *client;
@property (nonatomic, readonly, copy) NSString *sourcePath;
@property (nonatomic, readonly, copy) NSString *destinationPath;
@property (nonatomic, strong) NSString *mimeType;
@property (nonatomic, strong) void (^uploadProgressBlock)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite);

@end
