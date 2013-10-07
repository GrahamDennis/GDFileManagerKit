//
//  GDDropboxURLMetadata.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 13/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDURLMetadata.h"
#import "GDURLMetadataInternal.h"

@class GDDropboxMetadata;

@interface GDDropboxURLMetadata : NSObject <GDURLMetadata>

- (id)initWithDropboxMetadata:(GDDropboxMetadata *)metadata;

@property (nonatomic, readonly, copy) NSString *directoryContentsHash;
@property (nonatomic, copy, readonly)  NSString *dropboxPath;

@end
