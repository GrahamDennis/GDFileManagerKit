//
//  GDLayeredMetadataCache.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 17/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GDMetadataCache.h"

@interface GDLayeredMetadataCache : NSObject <GDMetadataCache>

- (id)initWithMetadataCaches:(NSArray *)caches;

@property (nonatomic, readonly, copy) NSArray *caches;

@end
