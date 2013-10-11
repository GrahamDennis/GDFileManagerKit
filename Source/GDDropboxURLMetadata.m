//
//  GDDropboxURLMetadata.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 13/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDDropboxURLMetadata.h"
#import "GDDropboxMetadata.h"

@interface GDDropboxURLMetadata ()

@property (nonatomic, readonly, strong) GDDropboxMetadata *metadata;

@end

@implementation GDDropboxURLMetadata

- (id)initWithMetadataDictionary:(NSDictionary *)metadataDictionary
{
    GDDropboxMetadata *dropboxMetadata = [[GDDropboxMetadata alloc] initWithDictionary:metadataDictionary];
    return [self initWithDropboxMetadata:dropboxMetadata];
}

- (id)initWithDropboxMetadata:(GDDropboxMetadata *)metadata
{
    if (!metadata) return nil;
    
    if ((self = [super init])) {
        _metadata = metadata;
    }
    
    return self;
}

- (NSDictionary *)jsonDictionary
{
    if (![self.metadata directoryContents])
        return self.metadata.backingStore;
    
    // Remove the "contents" key for encoding
    NSMutableDictionary *jsonDictionary = [self.metadata.backingStore mutableCopy];
    [jsonDictionary removeObjectForKey:@"contents"];
    return [jsonDictionary copy];
}

- (id <GDURLMetadata>)cacheableMetadata {return self;}

#pragma mark - call through to GDDropboxMetadata

- (BOOL)isDirectory { return [self.metadata isDirectory]; }
- (BOOL)isReadOnly { return NO; }
- (NSInteger)fileSize { return self.metadata.fileSize; }
- (NSString *)fileVersionIdentifier { return self.metadata.rev; }
- (NSString *)directoryContentsHash { return self.metadata.directoryContentsHash; }
- (NSString *)filename { return [self.metadata.path lastPathComponent]; }
- (NSString *)dropboxPath { return self.metadata.path; }

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@: %@", [super description], [self.metadata description]];
}

- (BOOL)isValid { return [self dropboxPath] != nil; }

@end
