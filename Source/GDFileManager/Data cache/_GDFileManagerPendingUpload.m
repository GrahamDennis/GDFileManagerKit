// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to GDFileManagerPendingUpload.m instead.

#import "_GDFileManagerPendingUpload.h"

const struct GDFileManagerPendingUploadAttributes GDFileManagerPendingUploadAttributes = {
	.sourceFilePath = @"sourceFilePath",
	.uploadDestination = @"uploadDestination",
	.uploadOptions = @"uploadOptions",
	.uploadState = @"uploadState",
};

const struct GDFileManagerPendingUploadRelationships GDFileManagerPendingUploadRelationships = {
};

const struct GDFileManagerPendingUploadFetchedProperties GDFileManagerPendingUploadFetchedProperties = {
};

@implementation GDFileManagerPendingUploadID
@end

@implementation _GDFileManagerPendingUpload

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"PendingUpload" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"PendingUpload";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"PendingUpload" inManagedObjectContext:moc_];
}

- (GDFileManagerPendingUploadID*)objectID {
	return (GDFileManagerPendingUploadID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"uploadOptionsValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"uploadOptions"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}




@dynamic sourceFilePath;






@dynamic uploadDestination;






@dynamic uploadOptions;



- (int64_t)uploadOptionsValue {
	NSNumber *result = [self uploadOptions];
	return [result longLongValue];
}

- (void)setUploadOptionsValue:(int64_t)value_ {
	[self setUploadOptions:[NSNumber numberWithLongLong:value_]];
}

- (int64_t)primitiveUploadOptionsValue {
	NSNumber *result = [self primitiveUploadOptions];
	return [result longLongValue];
}

- (void)setPrimitiveUploadOptionsValue:(int64_t)value_ {
	[self setPrimitiveUploadOptions:[NSNumber numberWithLongLong:value_]];
}





@dynamic uploadState;











@end
