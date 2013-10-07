//
//  GDPersistentUploadDestination.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 18/08/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GDFileManagerUploadState, GDFileManagerUploadOperation;

@interface GDPersistentUploadDestination : NSObject <NSCoding>

- (void)createNewFileWithFilename:(NSString *)filename mimeType:(NSString *)mimeType parentFolderURL:(NSURL *)parentFolderURL;

- (void)setDestinationURL:(NSURL *)destinationURL mimeType:(NSString *)mimeType parentVersionID:(NSString *)parentVersionID;

- (void)setUploadState:(GDFileManagerUploadState *)uploadState;

- (void)applyToUploadOperation:(GDFileManagerUploadOperation *)operation;

@property (nonatomic, readonly, copy) NSString *filename;


@end
