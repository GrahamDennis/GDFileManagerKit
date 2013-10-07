// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to GDCoreDataFileNode.h instead.

#import <CoreData/CoreData.h>


extern const struct GDCoreDataFileNodeAttributes {
	__unsafe_unretained NSString *childrenAreUnknown;
	__unsafe_unretained NSString *root;
	__unsafe_unretained NSString *urlString;
} GDCoreDataFileNodeAttributes;

extern const struct GDCoreDataFileNodeRelationships {
	__unsafe_unretained NSString *children;
	__unsafe_unretained NSString *metadata;
	__unsafe_unretained NSString *parents;
} GDCoreDataFileNodeRelationships;

extern const struct GDCoreDataFileNodeFetchedProperties {
} GDCoreDataFileNodeFetchedProperties;

@class GDCoreDataFileNode;
@class GDCoreDataMetadata;
@class GDCoreDataFileNode;





@interface GDCoreDataFileNodeID : NSManagedObjectID {}
@end

@interface _GDCoreDataFileNode : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (GDCoreDataFileNodeID*)objectID;





@property (nonatomic, strong) NSNumber* childrenAreUnknown;



@property BOOL childrenAreUnknownValue;
- (BOOL)childrenAreUnknownValue;
- (void)setChildrenAreUnknownValue:(BOOL)value_;

//- (BOOL)validateChildrenAreUnknown:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* root;



@property BOOL rootValue;
- (BOOL)rootValue;
- (void)setRootValue:(BOOL)value_;

//- (BOOL)validateRoot:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* urlString;



//- (BOOL)validateUrlString:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSSet *children;

- (NSMutableSet*)childrenSet;




@property (nonatomic, strong) GDCoreDataMetadata *metadata;

//- (BOOL)validateMetadata:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSSet *parents;

- (NSMutableSet*)parentsSet;





@end

@interface _GDCoreDataFileNode (CoreDataGeneratedAccessors)

- (void)addChildren:(NSSet*)value_;
- (void)removeChildren:(NSSet*)value_;
- (void)addChildrenObject:(GDCoreDataFileNode*)value_;
- (void)removeChildrenObject:(GDCoreDataFileNode*)value_;

- (void)addParents:(NSSet*)value_;
- (void)removeParents:(NSSet*)value_;
- (void)addParentsObject:(GDCoreDataFileNode*)value_;
- (void)removeParentsObject:(GDCoreDataFileNode*)value_;

@end

@interface _GDCoreDataFileNode (CoreDataGeneratedPrimitiveAccessors)


- (NSNumber*)primitiveChildrenAreUnknown;
- (void)setPrimitiveChildrenAreUnknown:(NSNumber*)value;

- (BOOL)primitiveChildrenAreUnknownValue;
- (void)setPrimitiveChildrenAreUnknownValue:(BOOL)value_;




- (NSNumber*)primitiveRoot;
- (void)setPrimitiveRoot:(NSNumber*)value;

- (BOOL)primitiveRootValue;
- (void)setPrimitiveRootValue:(BOOL)value_;




- (NSString*)primitiveUrlString;
- (void)setPrimitiveUrlString:(NSString*)value;





- (NSMutableSet*)primitiveChildren;
- (void)setPrimitiveChildren:(NSMutableSet*)value;



- (GDCoreDataMetadata*)primitiveMetadata;
- (void)setPrimitiveMetadata:(GDCoreDataMetadata*)value;



- (NSMutableSet*)primitiveParents;
- (void)setPrimitiveParents:(NSMutableSet*)value;


@end
