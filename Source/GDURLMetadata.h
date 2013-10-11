//
//  GDURLMetadata.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 17/07/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GDURLMetadataProperties <NSObject>

@property (nonatomic, readonly, getter = isDirectory) BOOL directory;
@property (nonatomic, readonly) NSInteger fileSize;
@property (nonatomic, readonly, copy) NSString *fileVersionIdentifier;
@property (nonatomic, readonly, copy) NSString *filename;
@property (nonatomic, readonly, getter = isReadOnly) BOOL readOnly;
- (BOOL)isValid;

@end

@interface GDURLMetadata : NSObject <GDURLMetadataProperties, NSCoding>

@property (nonatomic, readonly, strong) NSURL *url;
@property (nonatomic, readonly, strong) NSURL *canonicalURL;

@end
