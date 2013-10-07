//
//  GDGoogleDriveUploadState_Private.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 10/08/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDGoogleDriveUploadState.h"

@interface GDGoogleDriveUploadState ()

- (instancetype)initWithUploadSessionURI:(NSString *)uploadSessionURI offset:(NSInteger)offset fileSize:(NSInteger)fileSize;

@end
