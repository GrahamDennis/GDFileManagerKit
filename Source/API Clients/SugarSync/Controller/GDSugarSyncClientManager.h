//
//  GDSugarSyncClientManager.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 27/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDClientManager.h"

#import "GDSugarSyncAPIToken.h"

@class GDSugarSyncCredential;
@class GDSugarSyncClient;

@interface GDSugarSyncClientManager : GDClientManager

- (void)setDefaultKey:(NSString *)key secret:(NSString *)secret appID:(NSString *)appID;

@property (nonatomic, strong) GDSugarSyncAPIToken *defaultAPIToken;

@end
