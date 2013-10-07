//
//  GDDropboxAPIToken.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 11/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDAPIToken.h"

extern NSString *const GDDropboxRootDropbox;
extern NSString *const GDDropboxRootAppFolder;

@interface GDDropboxAPIToken : GDAPIToken

+ (instancetype)registerTokenWithKey:(NSString *)key secret:(NSString *)secret root:(NSString *)root;

- (id)initWithKey:(NSString *)key secret:(NSString *)secret root:(NSString *)root;

@property (nonatomic, readonly, copy) NSString *root;

@end
