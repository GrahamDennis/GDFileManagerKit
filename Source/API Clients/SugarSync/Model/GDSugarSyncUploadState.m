//
//  GDSugarSyncUploadState.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 6/08/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDSugarSyncUploadState.h"
#import "GDSugarSyncUploadState_Private.h"

@implementation GDSugarSyncUploadState

static NSString *const kFileID = @"fileID";
static NSString *const kFileVersionID = @"fileVersionID";
static NSString *const kFileOffset = @"fileOffset";

- (id)initWithFileID:(NSString *)fileID fileVersionID:(NSString *)fileVersionID offset:(NSInteger)offset
{
    return [self initWithDictionary:@{kFileID: [fileID copy], kFileVersionID: [fileVersionID copy], kFileOffset: @(offset)}];
}

- (NSString *)fileID { return self.backingStore[kFileID]; }
- (NSString *)fileVersionID { return self.backingStore[kFileVersionID]; }
- (NSInteger)offset { return [(NSNumber *)self.backingStore[kFileOffset] integerValue]; }

@end
