//
//  GDDropboxUploadStateWrapper.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 11/08/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GDFileManagerUploadState.h"

@interface GDFileManagerUploadState : NSObject <NSCoding>

- (instancetype)initWithUploadState:(id <NSCoding>)uploadState mimeType:(NSString *)mimeType uploadURL:(NSURL *)uploadURL parentVersionID:(NSString *)parentVersionID;
- (instancetype)initWithUploadState:(id <NSCoding>)uploadState mimeType:(NSString *)mimeType uploadURL:(NSURL *)uploadURL parentVersionID:(NSString *)parentVersionID extraState:(NSDictionary *)extraState;

@property (nonatomic, strong, readonly) id <NSCoding> uploadState;
@property (nonatomic, strong, readonly) NSURL *uploadURL;
@property (nonatomic, strong, readonly) NSString *mimeType;
@property (nonatomic, strong, readonly) NSDictionary *extraState;

@property (nonatomic, readonly, strong) NSURL *fileServiceSessionURL;
@property (nonatomic, readonly, strong) NSString *parentVersionID;

@end
