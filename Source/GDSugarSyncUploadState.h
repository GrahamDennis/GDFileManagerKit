//
//  GDSugarSyncUploadState.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 6/08/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDDictionaryBackedObject.h"

@interface GDSugarSyncUploadState : GDDictionaryBackedObject

@property (nonatomic, readonly, copy) NSString *fileID;
@property (nonatomic, readonly, copy) NSString *fileVersionID;
@property (nonatomic, readonly) NSInteger offset;

@end
