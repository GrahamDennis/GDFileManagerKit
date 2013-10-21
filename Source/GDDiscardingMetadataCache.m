//
//  GDDiscardingMetadataCache.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 15/07/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDDiscardingMetadataCache.h"
#import "GDAbstractMetadataCache_Private.h"

@interface GDDiscardingMetadataCache ()

@property (nonatomic, strong, readonly) NSCache *cache;

@end

@implementation GDDiscardingMetadataCache

- (id)init
{
    if ((self = [super init])) {
        _cache = [NSCache new];
    }
    
    return self;
}

- (void)reset
{
    [self.cache removeAllObjects];
}

- (GDFileTreeNode *)treeNodeForURL:(NSURL *)url
{
    return [self.cache objectForKey:url];
}

- (void)setTreeNode:(GDFileTreeNode *)treeNode forURL:(NSURL *)url
{
    [self.cache setObject:treeNode forKey:url];
}

- (void)removeTreeNodeForURL:(NSURL *)url
{
    [self.cache removeObjectForKey:url];
}

@end
