#import "GDFileManagerPendingUpload.h"

#import "GDFileManagerPersistentUploadOperation_Private.h"

@interface GDFileManagerPendingUpload ()

// Private interface goes here.

@end


@implementation GDFileManagerPendingUpload

@dynamic uploadState, uploadDestination, sourceURL;
@synthesize uploadOperation;

// Custom logic goes here.

- (void)prepareForDeletion
{
    if (self.uploadOperation) {
        [self.uploadOperation cancel];
        self.uploadOperation.pendingUpload = nil;
        self.uploadOperation = nil;
    }
}

@end
