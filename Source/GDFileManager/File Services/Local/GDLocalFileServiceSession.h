//
//  GDLocalFileServiceSession.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 26/08/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDFileServiceSession.h"

@interface GDLocalFileServiceSession : GDFileServiceSession

- (id)initWithName:(NSString *)name localRootURL:(NSURL *)localRootURL fileService:(GDFileService *)fileService;

@end
