//
//  GDWebDAVCredential.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 1/02/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDWebDAVCredential.h"

@implementation GDWebDAVCredential

- (id)initWithUserID:(NSString *)userID apiToken:(GDAPIToken *)apiToken
{
    return [self initWithUsername:userID password:nil serverURL:nil];
}

- (id)initWithUsername:(NSString *)username password:(NSString *)password serverURL:(NSURL *)serverURL
{
    if ((self = [super initWithUserID:username apiToken:nil])) {
        _password = password;
        _serverURL = serverURL;
    }
    
    return self;
}

#pragma mark - NSCoding

static NSString *const kPasswordCoderKey = @"password";
static NSString *const kServerURLCoderKey = @"serverURL";

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
        _password = [aDecoder decodeObjectForKey:kPasswordCoderKey];
        _serverURL = [aDecoder decodeObjectForKey:kServerURLCoderKey];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:self.password forKey:kPasswordCoderKey];
    [aCoder encodeObject:self.serverURL forKey:kServerURLCoderKey];
}

#pragma mark - Public

- (NSString *)username
{
    return self.userID;
}

- (BOOL)isValid
{
    return YES;
}

@end
