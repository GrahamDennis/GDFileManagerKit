//
//  GDDropboxSession.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 23/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDClientManager.h"
#import "GDDropboxAPIToken.h"

@class GDDropboxCredential;
@class GDDropboxClient;

@interface GDDropboxClientManager : GDClientManager

- (void)setDefaultKey:(NSString *)key secret:(NSString *)secret root:(NSString *)root;
- (BOOL)handleOpenURL:(NSURL *)callbackURL;

@property (nonatomic, strong) GDDropboxAPIToken *defaultAPIToken;

@end

