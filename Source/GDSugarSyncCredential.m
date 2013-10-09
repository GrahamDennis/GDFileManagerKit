//
//  GDSugarSyncCredential.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 27/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDSugarSyncCredential.h"
#import "GDSugarSyncAPIToken.h"
#import "GDSugarSyncClient.h"

@interface GDSugarSyncCredential ()

@property (nonatomic, readwrite, copy) NSDate *accessTokenExpirationDate;

@end

@implementation GDSugarSyncCredential

@dynamic apiToken;
@synthesize accessTokenExpirationDate = _accessTokenExpirationDate;

- (id)initWithUserID:(NSString *)userID apiToken:(GDSugarSyncAPIToken *)apiToken
{
    return [self initWithUserID:userID apiToken:apiToken refreshToken:nil accessToken:nil accessTokenExpirationDate:nil];
}

- (id)initWithUserID:(NSString *)userID apiToken:(GDSugarSyncAPIToken *)apiToken
        refreshToken:(NSString *)refreshToken
         accessToken:(NSString *)accessToken accessTokenExpirationDate:(NSDate *)accessTokenExpirationDate
{
    if ((self = [super initWithUserID:userID apiToken:apiToken])) {
        _refreshToken = refreshToken;
        _accessToken = accessToken;
        _accessTokenExpirationDate = accessTokenExpirationDate;
    }
    
    return self;
}

#pragma mark - NSCoding

static NSString *const kRefreshTokenCoderKey    = @"refreshToken";
static NSString *const kAccessTokenCoderKey     = @"accessToken";
static NSString *const kAccessTokenExpirationDateCoderKey = @"accessTokenExpirationDate";

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
        _refreshToken = [aDecoder decodeObjectForKey:kRefreshTokenCoderKey];
        _accessToken  = [aDecoder decodeObjectForKey:kAccessTokenCoderKey];
        _accessTokenExpirationDate = [aDecoder decodeObjectForKey:kAccessTokenExpirationDateCoderKey];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:self.refreshToken forKey:kRefreshTokenCoderKey];
    [aCoder encodeObject:self.accessToken forKey:kAccessTokenCoderKey];
    [aCoder encodeObject:self.accessTokenExpirationDate forKey:kAccessTokenExpirationDateCoderKey];
}


#pragma mark - Public

- (BOOL)isValid
{
    return (self.refreshToken || [self isAccessTokenValid]) && self.apiToken;
}

- (BOOL)isAccessTokenValid
{
    // Say that the access token is invalid if it will expire in 60s.
    return [(NSDate *)[NSDate dateWithTimeIntervalSinceNow:-60.] compare:self.accessTokenExpirationDate] == NSOrderedAscending;
}

- (NSString *)appID
{
    return self.apiToken.appID;
}

- (BOOL)canBeRenewed
{
    return !!self.refreshToken;
}

@end
