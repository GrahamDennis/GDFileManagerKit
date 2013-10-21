//
//  GDGoogleDriveMetadata.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 26/06/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDGoogleDriveMetadata.h"

@implementation GDGoogleDriveMetadata

- (NSString *)title { return self.backingStore[@"title"]; }
- (NSString *)identifier { return self.backingStore[@"id"]; }
- (NSString *)etag { return self.backingStore[@"etag"]; }
- (NSString *)md5Checksum { return self.backingStore[@"md5Checksum"]; }
- (NSString *)headRevisionIdentifier { return self.backingStore[@"headRevisionId"]; }
- (NSString *)mimeType { return self.backingStore[@"mimeType"]; }

- (BOOL)isDirectory
{
    return [@"application/vnd.google-apps.folder" isEqualToString:self.mimeType];
}

- (BOOL)isEditable
{
    return [(NSString *)self.backingStore[@"editable"] boolValue];
}

- (NSInteger)fileSize
{
    NSString *sizeString = self.backingStore[@"fileSize"];
    if (!sizeString) return 0;
    return [sizeString integerValue];
}

- (NSString *)downloadURLString { return self.backingStore[@"downloadUrl"]; }

@end
