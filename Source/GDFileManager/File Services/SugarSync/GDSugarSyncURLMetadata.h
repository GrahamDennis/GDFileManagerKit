//
//  GDSugarSyncURLMetadata.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 29/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GDURLMetadata.h"
#import "GDURLMetadataInternal.h"

@class GDSugarSyncMetadata;

@interface GDSugarSyncURLMetadata : NSObject <GDURLMetadata>

- (id)initWithSugarSyncMetadata:(GDSugarSyncMetadata *)metadata;
- (id)initWithSugarSyncMetadata:(GDSugarSyncMetadata *)metadata fileVersionID:(NSString *)fileVersionID;

@property (nonatomic, copy, readonly)  NSString *objectID;

@end
