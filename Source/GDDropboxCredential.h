//
//  GDDropboxCredential.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 23/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GDClientCredential.h"
#import "GDDropboxAPIToken.h"

@interface GDDropboxCredential : GDClientCredential

- (id)initWithUserID:(NSString *)userID apiToken:(GDDropboxAPIToken *)apiToken;

@property (nonatomic, readonly, strong) GDDropboxAPIToken *apiToken;
@property (nonatomic, readonly, copy) NSString *root;

@end
