//
//  GDWebDAVURLMetadata.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 4/02/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDWebDAVURLMetadata.h"

#import "GDWebDAVMetadata.h"

@interface GDWebDAVURLMetadata ()

@property (nonatomic, readonly, strong) GDWebDAVMetadata *metadata;

@end

@implementation GDWebDAVURLMetadata

- (id)initWithMetadataDictionary:(NSDictionary *)metadataDictionary
{
    GDWebDAVMetadata *metadata = [[GDWebDAVMetadata alloc] initWithDictionary:metadataDictionary];
    return [self initWithWebDAVMetadata:metadata];
}

- (id)initWithWebDAVMetadata:(GDWebDAVMetadata *)metadata
{
    if ((self = [super init])) {
        _metadata = metadata;
    }
    
    return self;
}

- (NSDictionary *)jsonDictionary
{
    return self.metadata.backingStore;
}

- (id <GDURLMetadata>)cacheableMetadata {return self;}

#pragma mark - call through to GDDropboxMetadata

- (BOOL)isDirectory { return [self.metadata isDirectory]; }
- (BOOL)isReadOnly { return NO; }
- (NSInteger)fileSize { return self.metadata.fileSize; }
- (NSString *)fileVersionIdentifier { return self.metadata.eTag ?: self.metadata.lastModifiedString; }
- (NSString *)filename { return [self.webDAVPath lastPathComponent]; }
- (NSString *)webDAVPath { return [self.metadata.href stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]; }

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@: %@", [super description], [self.metadata description]];
}

- (BOOL)isValid { return [self webDAVPath] != nil; }

@end
