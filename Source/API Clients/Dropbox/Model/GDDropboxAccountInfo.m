//
//  GDDropboxAccountInfo.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 23/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDDropboxAccountInfo.h"

@implementation GDDropboxAccountInfo

- (NSString *)userID
{
    return [self objectForKey:@"uid"];
}

@end
