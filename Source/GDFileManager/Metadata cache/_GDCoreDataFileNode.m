// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to GDCoreDataFileNode.m instead.

#import "_GDCoreDataFileNode.h"

const struct GDCoreDataFileNodeAttributes GDCoreDataFileNodeAttributes = {
	.childrenAreUnknown = @"childrenAreUnknown",
	.root = @"root",
	.urlString = @"urlString",
};

const struct GDCoreDataFileNodeRelationships GDCoreDataFileNodeRelationships = {
	.children = @"children",
	.metadata = @"metadata",
	.parents = @"parents",
};

const struct GDCoreDataFileNodeFetchedProperties GDCoreDataFileNodeFetchedProperties = {
};

@implementation GDCoreDataFileNodeID
@end

@implementation _GDCoreDataFileNode

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"FileNode" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"FileNode";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"FileNode" inManagedObjectContext:moc_];
}

- (GDCoreDataFileNodeID*)objectID {
	return (GDCoreDataFileNodeID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"childrenAreUnknownValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"childrenAreUnknown"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"rootValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"root"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}




@dynamic childrenAreUnknown;



- (BOOL)childrenAreUnknownValue {
	NSNumber *result = [self childrenAreUnknown];
	return [result boolValue];
}

- (void)setChildrenAreUnknownValue:(BOOL)value_ {
	[self setChildrenAreUnknown:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveChildrenAreUnknownValue {
	NSNumber *result = [self primitiveChildrenAreUnknown];
	return [result boolValue];
}

- (void)setPrimitiveChildrenAreUnknownValue:(BOOL)value_ {
	[self setPrimitiveChildrenAreUnknown:[NSNumber numberWithBool:value_]];
}





@dynamic root;



- (BOOL)rootValue {
	NSNumber *result = [self root];
	return [result boolValue];
}

- (void)setRootValue:(BOOL)value_ {
	[self setRoot:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveRootValue {
	NSNumber *result = [self primitiveRoot];
	return [result boolValue];
}

- (void)setPrimitiveRootValue:(BOOL)value_ {
	[self setPrimitiveRoot:[NSNumber numberWithBool:value_]];
}





@dynamic urlString;






@dynamic children;

	
- (NSMutableSet*)childrenSet {
	[self willAccessValueForKey:@"children"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"children"];
  
	[self didAccessValueForKey:@"children"];
	return result;
}
	

@dynamic metadata;

	

@dynamic parents;

	
- (NSMutableSet*)parentsSet {
	[self willAccessValueForKey:@"parents"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"parents"];
  
	[self didAccessValueForKey:@"parents"];
	return result;
}
	






@end
