//
//  GDDropboxUploadState.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 3/08/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDDropboxUploadState.h"
#import "GDDropboxMetadata.h"

static NSString *const kUploadID = @"upload_id";
static NSString *const kOffset = @"offset";
static NSString *const kExpiryDate = @"expiry";

@implementation GDDropboxUploadState

- (NSString *)uploadID { return self.backingStore[kUploadID]; }
- (NSInteger)offset { return [self.backingStore[kOffset] integerValue]; }

- (NSDate *)expiryDate
{
    NSString *dateString = self.backingStore[kExpiryDate];
    NSDate *expiryDate = [GDDropboxDateFormatter() dateFromString:dateString];
    return expiryDate;
}

@end
