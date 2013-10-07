//
//  GDWebDAVCredential.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 1/02/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDClientCredential.h"

@interface GDWebDAVCredential : GDClientCredential
- (id)initWithUsername:(NSString *)username password:(NSString *)password serverURL:(NSURL *)serverURL;

@property (nonatomic, readonly, copy) NSString *username;
@property (nonatomic, readonly, copy) NSString *password;
@property (nonatomic, readonly, strong) NSURL *serverURL;

@end
