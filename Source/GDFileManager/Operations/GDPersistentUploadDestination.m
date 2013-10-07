//
//  GDPersistentUploadDestination.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 18/08/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDPersistentUploadDestination.h"
#import "GDFileManagerUploadOperation_Private.h"

@interface GDPersistentUploadDestination ()

@property (nonatomic) GDFileManagerUploadOperationMode uploadMode;
@property (nonatomic, readwrite, copy) NSString *filename;
@property (nonatomic, copy) NSString *mimeType;
@property (nonatomic, strong) NSURL *parentFolderURL;
@property (nonatomic, strong) NSURL *destinationURL;
@property (nonatomic, strong) NSString *parentVersionID;
@property (nonatomic, strong) GDFileManagerUploadState *uploadState;

@end

@implementation GDPersistentUploadDestination

- (void)createNewFileWithFilename:(NSString *)filename mimeType:(NSString *)mimeType parentFolderURL:(NSURL *)parentFolderURL
{
    self.uploadMode = GDFileManagerUploadOperationModeCreateFile;
    
    self.filename = filename;
    self.mimeType = mimeType;
    self.parentFolderURL = parentFolderURL;
}

- (void)setDestinationURL:(NSURL *)destinationURL mimeType:(NSString *)mimeType parentVersionID:(NSString *)parentVersionID
{
    self.uploadMode = GDFileManagerUploadOperationModeUpdateExistingFile;
    
    self.destinationURL = destinationURL;
    self.mimeType = mimeType;
    self.parentVersionID = parentVersionID;
}

- (void)setUploadState:(GDFileManagerUploadState *)uploadState
{
    if (self.uploadMode == GDFileManagerUploadOperationModeUnknown)
        self.uploadMode = GDFileManagerUploadOperationModeResumeUpload;
    _uploadState = uploadState;
}


- (void)applyToUploadOperation:(GDFileManagerUploadOperation *)operation
{
    switch (self.uploadMode) {
        case GDFileManagerUploadOperationModeUnknown:
            return;
        case GDFileManagerUploadOperationModeCreateFile:
            return [operation createNewFileWithFilename:self.filename mimeType:self.mimeType parentFolderURL:self.parentFolderURL];
        case GDFileManagerUploadOperationModeUpdateExistingFile:
            return [operation setDestinationURL:self.destinationURL mimeType:self.mimeType parentVersionID:self.parentVersionID];
        case GDFileManagerUploadOperationModeResumeUpload:
            return [operation setUploadState:self.uploadState];
    }
}

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:[GDPersistentUploadDestination class]]) return NO;
    GDPersistentUploadDestination *other = object;
    if (!self.uploadMode == other.uploadMode) return NO;
    switch (self.uploadMode) {
        case GDFileManagerUploadOperationModeUnknown:
            return YES;
        case GDFileManagerUploadOperationModeCreateFile:
            return [self.filename isEqualToString:other.filename] && [self.parentFolderURL isEqual:other.parentFolderURL];
        case GDFileManagerUploadOperationModeUpdateExistingFile:
            return [self.destinationURL isEqual:other.destinationURL];
        case GDFileManagerUploadOperationModeResumeUpload:
            return [self.uploadState isEqual:other.uploadState];
    }
}

#pragma mark - NSCoding

static NSString *const kUploadMode = @"uploadMode";
static NSString *const kFilename = @"filename";
static NSString *const kMIMEType = @"mimeType";
static NSString *const kParentFolderURL = @"parentFolderURL";
static NSString *const kDestinationURL = @"destinationURL";
static NSString *const kParentVersionID = @"parentVersionID";
static NSString *const kUploadState = @"uploadState";

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super init])) {
        self.uploadMode = [aDecoder decodeIntegerForKey:kUploadMode];
        self.filename = [aDecoder decodeObjectForKey:kFilename];
        self.mimeType = [aDecoder decodeObjectForKey:kMIMEType];
        self.parentFolderURL = [aDecoder decodeObjectForKey:kParentFolderURL];
        self.destinationURL = [aDecoder decodeObjectForKey:kDestinationURL];
        self.parentVersionID = [aDecoder decodeObjectForKey:kParentVersionID];
        self.uploadState = [aDecoder decodeObjectForKey:kUploadState];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInteger:self.uploadMode forKey:kUploadMode];
    [aCoder encodeObject:self.filename forKey:kFilename];
    [aCoder encodeObject:self.mimeType forKey:kMIMEType];
    [aCoder encodeObject:self.parentFolderURL forKey:kParentFolderURL];
    [aCoder encodeObject:self.destinationURL forKey:kDestinationURL];
    [aCoder encodeObject:self.parentVersionID forKey:kParentVersionID];
    [aCoder encodeObject:self.uploadState forKey:kUploadState];
}

@end
