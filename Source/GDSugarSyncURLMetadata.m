//
//  GDSugarSyncURLMetadata.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 29/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDSugarSyncURLMetadata.h"
#import "GDSugarSyncURLMetadata_Private.h"

#import "GDSugarSyncMetadata.h"

static NSString *const kSugarSyncFileVersionID = @"SugarSyncFileVersionID";

@implementation GDSugarSyncURLMetadata

- (id)initWithMetadataDictionary:(NSDictionary *)metadataDictionary
{
    GDSugarSyncMetadata *sugarsyncMetadata = [[GDSugarSyncMetadata alloc] initWithDictionary:metadataDictionary];
    return [self initWithSugarSyncMetadata:sugarsyncMetadata];
}

- (id)initWithSugarSyncMetadata:(GDSugarSyncMetadata *)metadata
{
    return [self initWithSugarSyncMetadata:metadata fileVersionID:nil];
}

- (id)initWithSugarSyncMetadata:(GDSugarSyncMetadata *)metadata fileVersionID:(NSString *)fileVersionID
{
    if ((self = [super init])) {
        if (fileVersionID) {
            NSMutableDictionary *metadataDictionary = [metadata.backingStore mutableCopy];
            metadataDictionary[kSugarSyncFileVersionID] = fileVersionID;
            metadata = [[GDSugarSyncMetadata alloc] initWithDictionary:metadataDictionary];
        }
        _metadata = metadata;
    }
    
    return self;
}

- (NSDictionary *)jsonDictionary
{
    return self.metadata.backingStore;
}

- (id <GDURLMetadata>)cacheableMetadata {return self;}

#pragma mark - call through to GDSugarSyncMetadata

- (BOOL)isDirectory { return [self.metadata isDirectory]; }
- (BOOL)isReadOnly { return NO; } // Because we don't currently support received shares.
- (NSInteger)fileSize { return self.metadata.fileSize; }
- (NSString *)fileVersionIdentifier { return self.metadata.backingStore[kSugarSyncFileVersionID]; }

- (NSString *)objectID { return self.metadata.objectID; }
- (NSString *)filename { return self.metadata.displayName; }

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@: %@", [super description], [self.metadata description]];
}

- (BOOL)isValid { return [self objectID] != nil; }

@end
