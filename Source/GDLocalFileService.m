//
//  GDLocalFileService.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 26/08/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDLocalFileService.h"
#import "GDLocalFileServiceSession.h"
#import "GDFileManagerResourceBundle.h"

static NSString *const GDLocalFileServiceURLScheme   = @"local";

@implementation GDLocalFileService

+ (Class)fileServiceSessionClass
{
    return [GDLocalFileServiceSession class];
    return nil;
}

- (BOOL)shouldCacheResults
{
    return NO;
}

- (NSString *)urlScheme
{
    return GDLocalFileServiceURLScheme;
}

- (UIImage *)logoImage
{
    return nil;
}

- (UIImage *)iconImage
{
    return [UIImage imageWithContentsOfFile:[GDFileManagerResourcesBundle() pathForResource:@"local-icon" ofType:@"png"]];
}

- (NSString *)name
{
    return @"Local Storage";
}

@end
