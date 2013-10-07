//
//  GDDropboxUploadStateWrapper.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 11/08/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDFileManagerUploadState.h"

@implementation GDFileManagerUploadState

@synthesize parentVersionID = _parentVersionID;

- (instancetype)initWithUploadState:(id<NSCoding>)uploadState mimeType:(NSString *)mimeType uploadURL:(NSURL *)uploadURL parentVersionID:(NSString *)parentVersionID
{
    return [self initWithUploadState:uploadState mimeType:mimeType uploadURL:uploadURL parentVersionID:parentVersionID extraState:nil];
}

- (instancetype)initWithUploadState:(id <NSCoding>)uploadState mimeType:(NSString *)mimeType uploadURL:(NSURL *)uploadURL parentVersionID:(NSString *)parentVersionID extraState:(NSDictionary *)extraState
{
    if ((self = [super init])) {
        _uploadState = uploadState;
        _uploadURL = uploadURL;
        _parentVersionID = parentVersionID;
        _mimeType = mimeType;
        _extraState = extraState;
    }
    
    return self;
}

- (NSURL *)fileServiceSessionURL { return self.uploadURL; }

#pragma mark - NSCoding

static NSString *const kUploadState = @"UploadState";
static NSString *const kUploadURL = @"UploadURL";
static NSString *const kParentVersionID = @"ParentVersionID";
static NSString *const kMIMEType = @"MIMEType";
static NSString *const kExtraState = @"ExtraState";

- (id)initWithCoder:(NSCoder *)aDecoder
{
    id <NSCoding> uploadState = [aDecoder decodeObjectForKey:kUploadState];
    NSURL *uploadURL = [aDecoder decodeObjectForKey:kUploadURL];
    NSString *parentVersionID = [aDecoder decodeObjectForKey:kParentVersionID];
    NSString *mimeType = [aDecoder decodeObjectForKey:kMIMEType];
    NSDictionary *extraState = [aDecoder decodeObjectForKey:kExtraState];
    return [self initWithUploadState:uploadState mimeType:mimeType uploadURL:uploadURL parentVersionID:parentVersionID extraState:extraState];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.uploadState forKey:kUploadState];
    [aCoder encodeObject:self.uploadURL forKey:kUploadURL];
    [aCoder encodeObject:self.parentVersionID forKey:kParentVersionID];
    [aCoder encodeObject:self.mimeType forKey:kMIMEType];
    [aCoder encodeObject:self.extraState forKey:kExtraState];
}

@end
