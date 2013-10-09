//
//  GDGoogleDriveUploadState.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 10/08/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDDictionaryBackedObject.h"

@interface GDGoogleDriveUploadState : GDDictionaryBackedObject

@property (nonatomic, readonly, copy) NSString *uploadSessionURI;
@property (nonatomic, readonly) NSInteger offset;
@property (nonatomic, readonly) NSInteger fileSize;

@end
