//
//  GDLocalFSURLMetadata.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 26/08/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDLocalURLMetadata.h"
#import <ISO8601DateFormatter/ISO8601DateFormatter.h>

@interface GDLocalURLMetadata ()

@property (nonatomic, readonly, copy) NSDictionary *metadataDictionary;

@end

@implementation GDLocalURLMetadata

- (id)initWithMetadataDictionary:(NSDictionary *)metadataDictionary
{
    if ((self = [super init])) {
        _metadataDictionary = [metadataDictionary copy];
    }
    return self;
}

- (NSDictionary *)jsonDictionary
{
    return self.metadataDictionary;
}

- (id <GDURLMetadata>)cacheableMetadata {return self;}

- (ISO8601DateFormatter *)dateFormatter
{
    static NSString *ISO8601DateFormatterKey = @"me.grahamdennis.GDFileManagerKit.GDLocalURLMetadata.ISO8601DateFormatter";
    NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
    ISO8601DateFormatter *dateFormatter = threadDictionary[ISO8601DateFormatterKey];
    if (!dateFormatter) {
        dateFormatter = [ISO8601DateFormatter new];
        dateFormatter.includeTime = YES;
        threadDictionary[ISO8601DateFormatterKey] = dateFormatter;
    }
    return dateFormatter;
}

#pragma mark - call through to file properties

- (BOOL)isDirectory { return [self.metadataDictionary[NSURLIsDirectoryKey] boolValue]; }
- (BOOL)isReadOnly { return ![self.metadataDictionary[NSURLIsWritableKey] boolValue]; } // Because we don't currently support received shares.
- (NSInteger)fileSize { return [self.metadataDictionary[NSURLFileSizeKey] integerValue]; }
- (NSString *)fileVersionIdentifier { return [[self dateFormatter] stringFromDate:self.metadataDictionary[NSURLContentModificationDateKey]]; }

- (NSString *)filename { return self.metadataDictionary[NSURLNameKey]; }

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@: %@", [super description], [self.metadataDictionary description]];
}

- (BOOL)isValid { return [self filename] != nil; }

@end
