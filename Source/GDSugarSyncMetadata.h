//
//  GDSugarSyncMetadata.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 28/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDDictionaryBackedObject.h"

extern NSString *const GDSugarSyncMetadataXMLElementKey;

@interface GDSugarSyncMetadata : GDDictionaryBackedObject

+ (NSString *)objectIDFromObjectURL:(NSURL *)objectURL;

@property (nonatomic, readonly, copy) NSString *displayName;
@property (nonatomic, readonly, copy) NSString *objectID;
@property (nonatomic, readonly)       NSInteger fileSize;
@property (nonatomic, readonly)       NSInteger storedFileSize;
@property (nonatomic, readonly, copy) NSString *lastModifiedString;

@property (nonatomic, readonly, getter = isDirectory)                 BOOL directory;
@property (nonatomic, readonly, getter = isFileDataAvailableOnServer) BOOL fileDataAvailableOnServer;

@end
