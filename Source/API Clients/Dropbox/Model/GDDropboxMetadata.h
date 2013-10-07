//
//  GDDropboxMetadata.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 23/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GDDictionaryBackedObject.h"

NSDateFormatter *GDDropboxDateFormatter();

@interface GDDropboxMetadata : GDDictionaryBackedObject

+ (NSString *)canonicalPathForPath:(NSString *)path;

@property (nonatomic, readonly, copy)   NSString *path;
@property (nonatomic, readonly, copy)   NSString *rev;
@property (nonatomic, readonly)         BOOL isDirectory;
@property (nonatomic, readonly)         NSInteger fileSize;
@property (nonatomic, readonly)         BOOL isDeleted;

// Directory-only
@property (nonatomic, readonly, copy)   NSArray *directoryContents;
@property (nonatomic, readonly, copy)   NSString *directoryContentsHash;


@end
