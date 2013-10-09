//
//  GDSugarSyncAPIToken.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 19/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDAPIToken.h"

@interface GDSugarSyncAPIToken : GDAPIToken

+ (instancetype)registerTokenWithKey:(NSString *)key secret:(NSString *)secret appID:(NSString *)appID;

- (id)initWithKey:(NSString *)key secret:(NSString *)secret appID:(NSString *)appID;

@property (nonatomic, readonly, copy) NSString *appID;

@end
