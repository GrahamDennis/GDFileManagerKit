//
//  GDSugarSyncMetadata.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 28/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDSugarSyncMetadata.h"

NSString *const GDSugarSyncMetadataXMLElementKey = @"GDSugarSyncMetadataXMLElementKey";

@implementation GDSugarSyncMetadata

+ (NSString *)objectIDFromObjectURL:(NSURL *)objectURL
{
    return [objectURL path];
}

- (NSString *)displayName { return self.backingStore[@"displayName"]; }
- (NSString *)lastModifiedString { return self.backingStore[@"lastModified"]; }

- (NSString *)objectID
{
    BOOL stripLastPathComponent = NO;
    NSString *urlString = self.backingStore[@"ref"];
    if (!urlString) {
        urlString = self.backingStore[@"fileData"];
        stripLastPathComponent = YES;
    }
    NSURL *objectURL = [NSURL URLWithString:urlString];
    if (stripLastPathComponent) {
        objectURL = [objectURL URLByDeletingLastPathComponent];
    }
    return [[self class] objectIDFromObjectURL:objectURL];
}

- (BOOL)isDirectory
{
    static dispatch_once_t onceToken;
    static NSSet *folderXMLElements;
    dispatch_once(&onceToken, ^{
        folderXMLElements = [NSSet setWithArray:@[@"collection", @"folder"]];
    });
    return [folderXMLElements containsObject:self.backingStore[GDSugarSyncMetadataXMLElementKey]];
}

- (BOOL)isFileDataAvailableOnServer
{
    return [self.backingStore[@"presentOnServer"] isEqualToString:@"true"];
}

- (NSInteger)fileSize
{
    NSString *sizeString = self.backingStore[@"size"];
    if (!sizeString) return 0;
    return [sizeString integerValue];
}

- (NSInteger)storedFileSize
{
    NSString *storedSizeString = self.backingStore[@"storedSize"];
    if (!storedSizeString) {
        if ([self isFileDataAvailableOnServer])
            return self.fileSize;
        else
            return -1;
    }
    return [storedSizeString integerValue];
}

@end
