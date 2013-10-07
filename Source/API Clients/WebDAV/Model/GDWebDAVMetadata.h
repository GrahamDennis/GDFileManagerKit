//
//  GDWebDAVMetadata.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 1/02/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDDictionaryBackedObject.h"

@interface GDWebDAVMetadata : GDDictionaryBackedObject

@property (nonatomic, readonly, copy) NSString *href;
@property (nonatomic, readonly, copy) NSString *contentType;
@property (nonatomic, readonly)       BOOL isDirectory;
@property (nonatomic, readonly)       NSInteger fileSize;
@property (nonatomic, readonly, copy) NSString *lastModifiedString;
@property (nonatomic, readonly, copy) NSString *eTag;
@property (nonatomic, readonly, copy) NSString *mimeType;

@end
