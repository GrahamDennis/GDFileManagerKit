//
//  GDFileManagerUploadOperation_Private.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 18/08/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDFileManagerUploadOperation.h"
#import "GDFileManagerUploadState.h"

typedef NS_ENUM(NSUInteger, GDFileManagerUploadOperationMode) {
    GDFileManagerUploadOperationModeUnknown = 0,
    GDFileManagerUploadOperationModeCreateFile,
    GDFileManagerUploadOperationModeResumeUpload,
    GDFileManagerUploadOperationModeUpdateExistingFile,
};


@interface GDFileManagerUploadOperation ()

@property (nonatomic, readonly, strong) void (^success)(GDURLMetadata *metadata, NSArray *conflicts);
@property (nonatomic, readonly, strong) void (^failure)(NSError *error);

@property (nonatomic) GDFileManagerUploadOperationMode uploadMode;
@property (nonatomic, readwrite, strong) NSURL *sourceURL;

- (void)startUpload;

@end
