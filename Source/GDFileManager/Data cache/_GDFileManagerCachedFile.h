// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to GDFileManagerCachedFile.h instead.

#import <CoreData/CoreData.h>


extern const struct GDFileManagerCachedFileAttributes {
	__unsafe_unretained NSString *cacheDirectoryPath;
	__unsafe_unretained NSString *cacheFilePath;
	__unsafe_unretained NSString *downloadDate;
	__unsafe_unretained NSString *fileSize;
	__unsafe_unretained NSString *lastAccess;
	__unsafe_unretained NSString *metadataClassName;
	__unsafe_unretained NSString *metadataJSONData;
	__unsafe_unretained NSString *sourceURLString;
	__unsafe_unretained NSString *versionIdentifier;
} GDFileManagerCachedFileAttributes;

extern const struct GDFileManagerCachedFileRelationships {
} GDFileManagerCachedFileRelationships;

extern const struct GDFileManagerCachedFileFetchedProperties {
} GDFileManagerCachedFileFetchedProperties;












@interface GDFileManagerCachedFileID : NSManagedObjectID {}
@end

@interface _GDFileManagerCachedFile : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (GDFileManagerCachedFileID*)objectID;





@property (nonatomic, strong) NSString* cacheDirectoryPath;



//- (BOOL)validateCacheDirectoryPath:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* cacheFilePath;



//- (BOOL)validateCacheFilePath:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* downloadDate;



//- (BOOL)validateDownloadDate:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* fileSize;



@property int64_t fileSizeValue;
- (int64_t)fileSizeValue;
- (void)setFileSizeValue:(int64_t)value_;

//- (BOOL)validateFileSize:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* lastAccess;



//- (BOOL)validateLastAccess:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* metadataClassName;



//- (BOOL)validateMetadataClassName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSData* metadataJSONData;



//- (BOOL)validateMetadataJSONData:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* sourceURLString;



//- (BOOL)validateSourceURLString:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* versionIdentifier;



//- (BOOL)validateVersionIdentifier:(id*)value_ error:(NSError**)error_;






@end

@interface _GDFileManagerCachedFile (CoreDataGeneratedAccessors)

@end

@interface _GDFileManagerCachedFile (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveCacheDirectoryPath;
- (void)setPrimitiveCacheDirectoryPath:(NSString*)value;




- (NSString*)primitiveCacheFilePath;
- (void)setPrimitiveCacheFilePath:(NSString*)value;




- (NSDate*)primitiveDownloadDate;
- (void)setPrimitiveDownloadDate:(NSDate*)value;




- (NSNumber*)primitiveFileSize;
- (void)setPrimitiveFileSize:(NSNumber*)value;

- (int64_t)primitiveFileSizeValue;
- (void)setPrimitiveFileSizeValue:(int64_t)value_;




- (NSDate*)primitiveLastAccess;
- (void)setPrimitiveLastAccess:(NSDate*)value;




- (NSString*)primitiveMetadataClassName;
- (void)setPrimitiveMetadataClassName:(NSString*)value;




- (NSData*)primitiveMetadataJSONData;
- (void)setPrimitiveMetadataJSONData:(NSData*)value;




- (NSString*)primitiveSourceURLString;
- (void)setPrimitiveSourceURLString:(NSString*)value;




- (NSString*)primitiveVersionIdentifier;
- (void)setPrimitiveVersionIdentifier:(NSString*)value;




@end
