//
//  GDDropboxFileServiceSession.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 27/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDRemoteFileServiceSession.h"
#import "GDDropbox.h"

@interface GDDropboxFileServiceSession : GDRemoteFileServiceSession

@property (nonatomic, strong) GDDropboxClient *client;

@end
