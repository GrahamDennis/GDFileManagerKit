//
//  GDSugarSyncAccountInfo.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 28/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GDDictionaryBackedObject.h"

@interface GDSugarSyncAccountInfo : GDDictionaryBackedObject

@property (nonatomic, copy, readonly) NSString *username;
@property (nonatomic, copy, readonly) NSString *nickname;
@property (nonatomic, copy, readonly) NSString *workspacesObjectID;
@property (nonatomic, copy, readonly) NSString *syncFoldersObjectID;
@property (nonatomic, copy, readonly) NSString *deletedItemsObjectID;
@property (nonatomic, copy, readonly) NSString *magicBriefcaseObjectID;

@end
