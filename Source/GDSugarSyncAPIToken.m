//
//  GDSugarSyncAPIToken.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 19/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDSugarSyncAPIToken.h"

@implementation GDSugarSyncAPIToken

+ (instancetype)registerTokenWithKey:(NSString *)key secret:(NSString *)secret appID:(NSString *)appID
{
    GDSugarSyncAPIToken *apiToken = [[[self class] alloc] initWithKey:key secret:secret appID:appID];
    [[self class] registerToken:apiToken];
    return apiToken;
}

- (id)initWithKey:(NSString *)key secret:(NSString *)secret
{
    return [self initWithKey:key secret:secret appID:nil];
}

- (id)initWithKey:(NSString *)key secret:(NSString *)secret appID:(NSString *)appID
{
    NSParameterAssert(appID);
    
    if ((self = [super initWithKey:key secret:secret])) {
        _appID = [appID copy];
    }
    
    return self;
}

- (BOOL)isEqual:(id)object
{
    if (![super isEqual:object])
        return NO;
    
    if (![object isKindOfClass:[GDSugarSyncAPIToken class]])
        return NO;
    
    return [self.appID isEqualToString:[(GDSugarSyncAPIToken *)object appID]];
}

- (NSUInteger)hash
{
    return NSUINTROTATE([super hash], NSUINT_BIT/2 ) ^ [self.appID hash];
}

@end
