//
//  GDFileManagerPersistentUploadOperation_Private.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 18/08/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDFileManagerPersistentUploadOperation.h"
#import "GDPersistentUploadDestination.h"
#import "GDFileManagerPendingUpload.h"

@interface GDFileManagerPersistentUploadOperation ()

@property (nonatomic, strong) GDPersistentUploadDestination *uploadDestination;
@property (nonatomic, strong) GDFileManagerPendingUpload *pendingUpload;

@end
