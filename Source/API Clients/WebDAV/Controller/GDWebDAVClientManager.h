//
//  GDWebDAVClientManager.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 1/02/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDClientManager.h"

@class GDWebDAVClient;
@class GDWebDAVCredential;

@interface GDWebDAVClientManager : GDClientManager

- (GDWebDAVCredential *)credentialForUsername:(NSString *)userID serverURL:(NSURL *)serverURL;
- (GDWebDAVClient *)newClientForUsername:(NSString *)userID serverURL:(NSURL *)serverURL;

@end
