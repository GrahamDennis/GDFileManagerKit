// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to GDFileManagerCachedFile.m instead.

#import "_GDFileManagerCachedFile.h"

const struct GDFileManagerCachedFileAttributes GDFileManagerCachedFileAttributes = {
	.cacheDirectoryPath = @"cacheDirectoryPath",
	.cacheFilePath = @"cacheFilePath",
	.downloadDate = @"downloadDate",
	.fileSize = @"fileSize",
	.lastAccess = @"lastAccess",
	.metadataClassName = @"metadataClassName",
	.metadataJSONData = @"metadataJSONData",
	.sourceURLString = @"sourceURLString",
	.versionIdentifier = @"versionIdentifier",
};

const struct GDFileManagerCachedFileRelationships GDFileManagerCachedFileRelationships = {
};

const struct GDFileManagerCachedFileFetchedProperties GDFileManagerCachedFileFetchedProperties = {
};

@implementation GDFileManagerCachedFileID
@end

@implementation _GDFileManagerCachedFile

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"CachedFile" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"CachedFile";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"CachedFile" inManagedObjectContext:moc_];
}

- (GDFileManagerCachedFileID*)objectID {
	return (GDFileManagerCachedFileID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"fileSizeValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"fileSize"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}




@dynamic cacheDirectoryPath;






@dynamic cacheFilePath;






@dynamic downloadDate;






@dynamic fileSize;



- (int64_t)fileSizeValue {
	NSNumber *result = [self fileSize];
	return [result longLongValue];
}

- (void)setFileSizeValue:(int64_t)value_ {
	[self setFileSize:[NSNumber numberWithLongLong:value_]];
}

- (int64_t)primitiveFileSizeValue {
	NSNumber *result = [self primitiveFileSize];
	return [result longLongValue];
}

- (void)setPrimitiveFileSizeValue:(int64_t)value_ {
	[self setPrimitiveFileSize:[NSNumber numberWithLongLong:value_]];
}





@dynamic lastAccess;






@dynamic metadataClassName;






@dynamic metadataJSONData;






@dynamic sourceURLString;






@dynamic versionIdentifier;











@end
