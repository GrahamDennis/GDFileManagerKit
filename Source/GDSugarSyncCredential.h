//
//  GDSugarSyncCredential.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 27/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDAccessTokenClientCredential.h"

#import "GDSugarSyncAPIToken.h"

@class GDSugarSyncClient;

@interface GDSugarSyncCredential : GDAccessTokenClientCredential

- (id)initWithUserID:(NSString *)userID apiToken:(GDSugarSyncAPIToken *)apiToken
        refreshToken:(NSString *)refreshToken
         accessToken:(NSString *)accessToken accessTokenExpirationDate:(NSDate *)accessTokenExpirationDate;

@property (nonatomic, readonly, copy) NSString *appID;
@property (nonatomic, readonly, strong) GDSugarSyncAPIToken *apiToken;

@property (nonatomic, readonly, copy) NSString *refreshToken;
@property (nonatomic, readonly, copy) NSString *accessToken;
@property (nonatomic, readonly, copy) NSDate *accessTokenExpirationDate;

@end
