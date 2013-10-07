//
//  GDGoogleDriveUploadState.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 10/08/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDGoogleDriveUploadState.h"
#import "GDGoogleDriveUploadState_Private.h"

@implementation GDGoogleDriveUploadState

static NSString *const kUploadSessionURI = @"uploadSessionURI";
static NSString *const kFileOffset = @"fileOffset";
static NSString *const kFileSize = @"fileSize";

- (instancetype)initWithUploadSessionURI:(NSString *)uploadSessionURI offset:(NSInteger)offset fileSize:(NSInteger)fileSize
{
    return [self initWithDictionary:@{kUploadSessionURI: uploadSessionURI, kFileOffset: @(offset), kFileSize: @(fileSize)}];
}

- (NSString *)uploadSessionURI { return self.backingStore[kUploadSessionURI]; }
- (NSInteger)offset { return [self.backingStore[kFileOffset] integerValue]; }
- (NSInteger)fileSize { return [self.backingStore[kFileSize] integerValue]; }

@end
