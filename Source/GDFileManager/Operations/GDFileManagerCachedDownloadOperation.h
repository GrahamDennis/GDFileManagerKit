//
//  GDFileManagerDownloadOperation.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 5/08/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDFileManagerDownloadOperation.h"
#import "GDFileManagerConstants.h"

@interface GDFileManagerCachedDownloadOperation : GDFileManagerDownloadOperation

- (instancetype)initWithFileManager:(GDFileManager *)fileManager downloadURL:(NSURL *)url cachePolicy:(GDFileManagerCachePolicy)cachePolicy
                            success:(void (^)(NSURL *localURL, GDURLMetadata *metadata))success
                            failure:(void (^)(NSError *error))failure;

@property (nonatomic) GDFileManagerCachePolicy cachePolicy;

@end
