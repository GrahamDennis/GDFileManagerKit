//
//  GDSugarSyncDownloadOperation.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 8/08/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDParentOperation.h"

#import "GDSugarSyncClient.h"

@interface GDSugarSyncDownloadOperation : GDParentOperation

- (id)initWithClient:(GDSugarSyncClient *)client fileID:(NSString *)fileID toLocalPath:(NSString *)localPath
             success:(void (^)(NSString *localPath, GDSugarSyncMetadata *metadata, NSString *fileVersionID))success
             failure:(void (^)(NSError *error))failure;

@property (nonatomic, readonly, strong) GDSugarSyncClient *client;
@property (nonatomic, readonly, copy) NSString *localPath;
@property (nonatomic, readonly, copy) NSString *fileID;
@property (nonatomic, strong) NSString *fileVersionID;
@property (nonatomic, strong) void (^downloadProgressBlock)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead);

@end
