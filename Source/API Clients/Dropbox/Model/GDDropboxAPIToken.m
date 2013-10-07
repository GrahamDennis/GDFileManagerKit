//
//  GDDropboxAPIToken.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 11/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDDropboxAPIToken.h"

NSString *const GDDropboxRootDropbox    = @"dropbox";
NSString *const GDDropboxRootAppFolder  = @"sandbox";

@implementation GDDropboxAPIToken

+ (instancetype)registerTokenWithKey:(NSString *)key secret:(NSString *)secret root:(NSString *)root
{
    GDDropboxAPIToken *apiToken = [[[self class] alloc] initWithKey:key secret:secret root:root];
    [[self class] registerToken:apiToken];
    return apiToken;
}

- (id)initWithKey:(NSString *)key secret:(NSString *)secret
{
    return [self initWithKey:key secret:secret root:nil];
}

- (id)initWithKey:(NSString *)key secret:(NSString *)secret root:(NSString *)root
{
    NSParameterAssert(root);
    
    if ((self = [super initWithKey:key secret:secret])) {
        _root = [root copy];
    }
    
    return self;
}

- (BOOL)isEqual:(id)object
{
    if (![super isEqual:object])
        return NO;
    
    if (![object isKindOfClass:[GDDropboxAPIToken class]])
        return NO;
    
    return [self.root isEqualToString:[(GDDropboxAPIToken *)object root]];
}

- (NSUInteger)hash
{
    return NSUINTROTATE([super hash], NSUINT_BIT/2 ) ^ [self.root hash];
}

@end