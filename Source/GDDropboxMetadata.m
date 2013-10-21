//
//  GDDropboxMetadata.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 23/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDDropboxMetadata.h"

static NSString *const kFileIsDirectory = @"is_dir";
static NSString *const kFilePath = @"path";
static NSString *const kDirectoryContents = @"contents";
static NSString *const kFileVersionIdentifier = @"rev";
static NSString *const kDirectoryContentsHash = @"hash";
static NSString *const kFileSize = @"bytes";
static NSString *const kIsDeleted = @"is_deleted";

@implementation GDDropboxMetadata

+ (NSString *)canonicalPathForPath:(NSString *)path
{
    NSString *unicodeNormalisedPath = [path precomposedStringWithCanonicalMapping];
    NSString *lowercaseURLEscapedPath = [[unicodeNormalisedPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] lowercaseString];
    return [lowercaseURLEscapedPath stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}


- (id)initWithDictionary:(NSDictionary *)metadata
{
    if ((self = [super initWithDictionary:metadata])) {
        
        BOOL isDirectory = [(NSNumber *)metadata[kFileIsDirectory] boolValue];
        if (isDirectory) {
            NSArray *directoryContentsMetadata = metadata[kDirectoryContents];
            if (directoryContentsMetadata) {
                NSMutableArray *directoryContents = [NSMutableArray arrayWithCapacity:[directoryContentsMetadata count]];
                for (NSDictionary *directoryEntryMetadata in directoryContentsMetadata) {
                    GDDropboxMetadata *entryMetadata = [[[self class] alloc] initWithDictionary:directoryEntryMetadata];
                    if (entryMetadata) {
                        [directoryContents addObject:entryMetadata];
                    }
                }
                _directoryContents = [directoryContents copy];
            }
        }
    }
    
    return self;
}

- (NSString *)path { return self.backingStore[kFilePath]; }
- (NSString *)rev { return self.backingStore[kFileVersionIdentifier]; }
- (BOOL)isDirectory { return [(NSNumber *)self.backingStore[kFileIsDirectory] boolValue]; }
- (NSInteger)fileSize { return [self.backingStore[kFileSize] integerValue]; }
- (NSString *)directoryContentsHash { return self.backingStore[kDirectoryContentsHash]; }
- (BOOL)isDeleted { return [(NSNumber *)self.backingStore[kIsDeleted] boolValue]; }

@end

// Code taken from the Dropbox SDK
NSDateFormatter *GDDropboxDateFormatter()
{
    NSMutableDictionary* dictionary = [[NSThread currentThread] threadDictionary];
    static NSString* dateFormatterKey = @"GDDropboxMetadataDateFormatter";
    
    NSDateFormatter* dateFormatter = [dictionary objectForKey:dateFormatterKey];
    if (dateFormatter == nil) {
        dateFormatter = [NSDateFormatter new];
        // Must set locale to ensure consistent parsing:
        // http://developer.apple.com/iphone/library/qa/qa2010/qa1480.html
        dateFormatter.locale =
        [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        dateFormatter.dateFormat = @"EEE, dd MMM yyyy HH:mm:ss Z";
        [dictionary setObject:dateFormatter forKey:dateFormatterKey];
    }
    return dateFormatter;
}