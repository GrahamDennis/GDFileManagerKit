#import "_GDFileManagerPendingUpload.h"

#import "GDPersistentUploadDestination.h"
#import "GDFileManagerUploadState.h"

@class GDFileManagerPersistentUploadOperation;

@interface GDFileManagerPendingUpload : _GDFileManagerPendingUpload {}
// Custom logic goes here.

@property (nonatomic, strong) NSURL *sourceURL;
@property (nonatomic, strong) GDPersistentUploadDestination *uploadDestination;
@property (nonatomic, strong) GDFileManagerUploadState *uploadState;
@property (nonatomic, weak) GDFileManagerPersistentUploadOperation *uploadOperation;

@end
