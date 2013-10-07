//
//  GDWebDAVMetadata.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 1/02/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDWebDAVMetadata.h"

@implementation GDWebDAVMetadata

#pragma mark - Accessors

- (NSString *)href
{
    return self.backingStore[@"href"];
}

- (NSString *)contentType
{
    return [self.backingStore valueForKeyPath:@"propstat.prop.getcontenttype"];
}

- (BOOL)isDirectory
{
    return [self.backingStore valueForKeyPath:@"propstat.prop.resourcetype.collection"] != nil;
}

- (NSInteger)fileSize
{
    NSString *fileSizeString = [self.backingStore valueForKeyPath:@"propstat.prop.getcontentlength"];
    return [fileSizeString integerValue];
}

- (NSString *)lastModifiedString
{
    return [self.backingStore valueForKeyPath:@"propstat.prop.getlastmodified"];
}

- (NSString *)eTag
{
    return [self.backingStore valueForKeyPath:@"propstat.prop.getetag"];
}

- (NSString *)mimeType
{
    return [self.backingStore valueForKeyPath:@"propstat.prop.getcontenttype"];
}

@end
