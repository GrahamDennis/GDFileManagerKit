//
//  GDFileServiceManager+AutoRegistration.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 13/07/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDFileServiceManager+AutoRegistration.h"

#import "GDAPIToken.h"
#import "GDClientManager.h"

#import "GDDropboxFileService.h"
#import "GDSugarSyncFileService.h"
#import "GDWebDAVFileService.h"
#import "GDGoogleDriveFileService.h"
#import "GDLocalFileService.h"

#import "GDRemoteFileServiceSession.h"

@implementation GDFileServiceManager (AutoRegistration)

- (void)registerKnownFileServices
{
    static NSArray *knownRemoteFileServiceClasses;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        knownRemoteFileServiceClasses = @[
                                          [GDDropboxFileService class],
                                          [GDSugarSyncFileService class],
                                          [GDWebDAVFileService class],
                                          [GDGoogleDriveFileService class],
                                          ];
    });
    
    for (Class fileServiceClass in knownRemoteFileServiceClasses) {
        GDClientManager *clientManager = (GDClientManager *)[[fileServiceClass clientManagerClass] sharedManager];
        GDRemoteFileService *remoteFileService = [(GDRemoteFileService *)[fileServiceClass alloc] initWithClientManager:clientManager];
        if (![clientManager isValid]) continue;
        [self registerFileService:remoteFileService];
        
        Class remoteFileServiceSessionClass = [fileServiceClass fileServiceSessionClass];
        
        for (GDHTTPClient *client in [clientManager allIndependentClients]) {
            GDRemoteFileServiceSession *session = [(GDRemoteFileServiceSession *)[remoteFileServiceSessionClass alloc] initWithFileService:remoteFileService client:client];
            [remoteFileService addFileServiceSession:session];
        }
    }
}

@end
