//
//  GDLayeredMetadataCache.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 17/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDLayeredMetadataCache.h"

@implementation GDLayeredMetadataCache

- (id)initWithMetadataCaches:(NSArray *)caches
{
    if ((self = [super init])) {
        _caches = [caches copy];
    }
    
    return self;
}

- (void)setMetadata:(id <GDURLMetadata>)metadata forURL:(NSURL *)url
{
    [self setMetadata:metadata forURL:url addToParent:nil];
}

- (void)setMetadata:(id<GDURLMetadata>)metadata forURL:(NSURL *)url addToParent:(NSURL *)parentURL
{
    for (id <GDMetadataCache> cache in self.caches) {
        [cache setMetadata:metadata forURL:url addToParent:parentURL];
    }
}

- (id <GDURLMetadata>)metadataForURL:(NSURL *)url
{
    id <GDURLMetadata> metadata = nil;
    
    for (id <GDMetadataCache> cache in self.caches) {
        metadata = [cache metadataForURL:url];
        if (metadata) break;
    }
    
    return metadata;
}

- (void)setDirectoryContents:(NSDictionary *)contents forURL:(NSURL *)url
{
    for (id <GDMetadataCache> cache in self.caches) {
        [cache setDirectoryContents:contents forURL:url];
    }
}

- (void)removeMetadataForURL:(NSURL *)url removeFromParent:(NSURL *)parentURL
{
    for (id <GDMetadataCache> cache in self.caches) {
        [cache removeMetadataForURL:url removeFromParent:parentURL];
    }
}


- (NSArray *)directoryContentsForURL:(NSURL *)url
{
    NSArray *directoryContents = nil;
    
    for (id <GDMetadataCache> cache in self.caches) {
        directoryContents = [cache directoryContentsForURL:url];
        if (directoryContents) break;
    }
    return directoryContents;
}

- (void)setMetadata:(id<GDURLMetadata>)metadata directoryContents:(NSDictionary *)contents forURL:(NSURL *)url addToParent:(NSURL *)parentURL
{
    for (id <GDMetadataCache> cache in self.caches) {
        [cache setMetadata:metadata directoryContents:contents forURL:url addToParent:parentURL];
    }
}

- (id <GDURLMetadata>)metadataForURL:(NSURL *)url directoryContents:(NSArray **)contents
{
    id <GDURLMetadata> resultMetadata = nil;
    
    if (contents) *contents = nil;
    for (id <GDMetadataCache> cache in self.caches) {
        id <GDURLMetadata> metadata = [cache metadataForURL:url directoryContents:contents];
        if (metadata && !resultMetadata)
            resultMetadata = metadata;
        if (resultMetadata
            && (!contents || (contents && *contents))) break;
    }
    return resultMetadata;
}

- (NSArray *)directoryContentsMetadataArrayForURL:(NSURL *)url
{
    NSArray *metadataArray = nil;
    
    for (id <GDMetadataCache> cache in self.caches) {
        metadataArray = [cache directoryContentsMetadataArrayForURL:url];
        if (metadataArray) break;
    }
    return metadataArray;
}


- (void)reset
{
    for (id <GDMetadataCache> cache in self.caches) {
        [cache reset];
    }
}

@end
