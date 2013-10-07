//
//  GDWebDAVFileService.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 4/02/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDRemoteFileService.h"

@class GDWebDAVClient;

@interface GDWebDAVFileService : GDRemoteFileService

- (NSString *)urlSchemeForClient:(GDWebDAVClient *)client;

@end
