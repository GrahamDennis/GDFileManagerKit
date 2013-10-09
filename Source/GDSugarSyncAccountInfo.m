//
//  GDSugarSyncAccountInfo.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 28/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDSugarSyncAccountInfo.h"

@implementation GDSugarSyncAccountInfo

- (NSString *)username { return [self objectForKey:@"username"]; }
- (NSString *)nickname { return [self objectForKey:@"nickname"]; }
- (NSString *)workspacesObjectID { return [self objectForKey:@"workspaces"]; }
- (NSString *)syncFoldersObjectID { return [self objectForKey:@"syncfolders"]; }
- (NSString *)deletedItemsObjectID { return [self objectForKey:@"deleted"]; }
- (NSString *)magicBriefcaseObjectID { return [self objectForKey:@"magicBriefcase"]; }

@end
