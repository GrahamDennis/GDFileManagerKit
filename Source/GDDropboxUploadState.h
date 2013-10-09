//
//  GDDropboxUploadState.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 3/08/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDDictionaryBackedObject.h"

@interface GDDropboxUploadState : GDDictionaryBackedObject

@property (nonatomic, copy, readonly) NSString *uploadID;
@property (nonatomic, readonly) NSInteger offset;
@property (nonatomic, strong, readonly) NSDate *expiryDate;

@end
