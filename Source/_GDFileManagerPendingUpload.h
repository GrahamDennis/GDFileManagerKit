// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to GDFileManagerPendingUpload.h instead.

#import <CoreData/CoreData.h>


extern const struct GDFileManagerPendingUploadAttributes {
	__unsafe_unretained NSString *sourceFilePath;
	__unsafe_unretained NSString *uploadDestination;
	__unsafe_unretained NSString *uploadOptions;
	__unsafe_unretained NSString *uploadState;
} GDFileManagerPendingUploadAttributes;

extern const struct GDFileManagerPendingUploadRelationships {
} GDFileManagerPendingUploadRelationships;

extern const struct GDFileManagerPendingUploadFetchedProperties {
} GDFileManagerPendingUploadFetchedProperties;



@class NSObject;

@class NSObject;

@interface GDFileManagerPendingUploadID : NSManagedObjectID {}
@end

@interface _GDFileManagerPendingUpload : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (GDFileManagerPendingUploadID*)objectID;





@property (nonatomic, strong) NSString* sourceFilePath;



//- (BOOL)validateSourceFilePath:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) id uploadDestination;



//- (BOOL)validateUploadDestination:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* uploadOptions;



@property int64_t uploadOptionsValue;
- (int64_t)uploadOptionsValue;
- (void)setUploadOptionsValue:(int64_t)value_;

//- (BOOL)validateUploadOptions:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) id uploadState;



//- (BOOL)validateUploadState:(id*)value_ error:(NSError**)error_;






@end

@interface _GDFileManagerPendingUpload (CoreDataGeneratedAccessors)

@end

@interface _GDFileManagerPendingUpload (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveSourceFilePath;
- (void)setPrimitiveSourceFilePath:(NSString*)value;




- (id)primitiveUploadDestination;
- (void)setPrimitiveUploadDestination:(id)value;




- (NSNumber*)primitiveUploadOptions;
- (void)setPrimitiveUploadOptions:(NSNumber*)value;

- (int64_t)primitiveUploadOptionsValue;
- (void)setPrimitiveUploadOptionsValue:(int64_t)value_;




- (id)primitiveUploadState;
- (void)setPrimitiveUploadState:(id)value;




@end
