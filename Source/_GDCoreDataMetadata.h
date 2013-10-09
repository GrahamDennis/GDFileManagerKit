// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to GDCoreDataMetadata.h instead.

#import <CoreData/CoreData.h>


extern const struct GDCoreDataMetadataAttributes {
	__unsafe_unretained NSString *jsonData;
	__unsafe_unretained NSString *metadataClassName;
} GDCoreDataMetadataAttributes;

extern const struct GDCoreDataMetadataRelationships {
	__unsafe_unretained NSString *fileNode;
} GDCoreDataMetadataRelationships;

extern const struct GDCoreDataMetadataFetchedProperties {
} GDCoreDataMetadataFetchedProperties;

@class GDCoreDataFileNode;




@interface GDCoreDataMetadataID : NSManagedObjectID {}
@end

@interface _GDCoreDataMetadata : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (GDCoreDataMetadataID*)objectID;





@property (nonatomic, strong) NSData* jsonData;



//- (BOOL)validateJsonData:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* metadataClassName;



//- (BOOL)validateMetadataClassName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) GDCoreDataFileNode *fileNode;

//- (BOOL)validateFileNode:(id*)value_ error:(NSError**)error_;





@end

@interface _GDCoreDataMetadata (CoreDataGeneratedAccessors)

@end

@interface _GDCoreDataMetadata (CoreDataGeneratedPrimitiveAccessors)


- (NSData*)primitiveJsonData;
- (void)setPrimitiveJsonData:(NSData*)value;




- (NSString*)primitiveMetadataClassName;
- (void)setPrimitiveMetadataClassName:(NSString*)value;





- (GDCoreDataFileNode*)primitiveFileNode;
- (void)setPrimitiveFileNode:(GDCoreDataFileNode*)value;


@end
