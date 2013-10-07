//
//  GDWebDAVFileServiceSession.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 5/02/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDRemoteFileServiceSession.h"
#import "GDWebDAV.h"

@interface GDWebDAVFileServiceSession : GDRemoteFileServiceSession

@property (nonatomic, strong) GDWebDAVClient *client;

@end
