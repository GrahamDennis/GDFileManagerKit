// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to GDCoreDataMetadata.m instead.

#import "_GDCoreDataMetadata.h"

const struct GDCoreDataMetadataAttributes GDCoreDataMetadataAttributes = {
	.jsonData = @"jsonData",
	.metadataClassName = @"metadataClassName",
};

const struct GDCoreDataMetadataRelationships GDCoreDataMetadataRelationships = {
	.fileNode = @"fileNode",
};

const struct GDCoreDataMetadataFetchedProperties GDCoreDataMetadataFetchedProperties = {
};

@implementation GDCoreDataMetadataID
@end

@implementation _GDCoreDataMetadata

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Metadata" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Metadata";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Metadata" inManagedObjectContext:moc_];
}

- (GDCoreDataMetadataID*)objectID {
	return (GDCoreDataMetadataID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}




@dynamic jsonData;






@dynamic metadataClassName;






@dynamic fileNode;

	






@end
