//
//  GDSugarSyncFileServiceSession.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 29/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDRemoteFileServiceSession.h"
#import "GDSugarSync.h"

@interface GDSugarSyncFileServiceSession : GDRemoteFileServiceSession

@property (nonatomic, strong) GDSugarSyncClient *client;

@end
