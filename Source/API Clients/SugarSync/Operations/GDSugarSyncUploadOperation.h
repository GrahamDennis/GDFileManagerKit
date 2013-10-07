//
//  GDSugarSyncUploadOperation.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 6/08/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDParentOperation.h"

#import "GDSugarSyncClient.h"
#import "GDSugarSyncUploadState.h"

@interface GDSugarSyncUploadOperation : GDParentOperation

- (id)initWithClient:(GDSugarSyncClient *)client fromLocalPath:(NSString *)sourcePath toFileID:(NSString *)fileID
             success:(void (^)(GDSugarSyncMetadata *metadata, NSString *fileVersionID, NSArray *conflictingVersionIDs))success
             failure:(void (^)(NSError *error))failure;

@property (nonatomic, readonly, strong) GDSugarSyncClient *client;
@property (nonatomic, readonly, copy) NSString *sourcePath;
@property (nonatomic, readonly, copy) NSString *fileID;
@property (nonatomic, copy) NSString *parentVersionID;
@property (nonatomic, strong) GDSugarSyncUploadState *uploadState;
@property (nonatomic, strong) void (^uploadStateHandler)(GDSugarSyncUploadState *uploadState);
@property (nonatomic, strong) void (^uploadProgressBlock)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite);

@end
