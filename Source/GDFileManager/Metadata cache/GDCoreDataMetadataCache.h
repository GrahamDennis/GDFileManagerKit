//
//  GDCoreDataMetadataCache.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 18/07/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GDMetadataCache.h"

@interface GDCoreDataMetadataCache : NSObject <GDMetadataCache>

- (id)initWithCacheDirectory:(NSURL *)url;

@end
