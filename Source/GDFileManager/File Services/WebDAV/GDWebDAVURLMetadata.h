//
//  GDWebDAVURLMetadata.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 4/02/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GDURLMetadata.h"
#import "GDURLMetadataInternal.h"

@class GDWebDAVMetadata;

@interface GDWebDAVURLMetadata : NSObject <GDURLMetadata>

- (id)initWithWebDAVMetadata:(GDWebDAVMetadata *)metadata;

@property (nonatomic, readonly, copy) NSString *webDAVPath;

@end
