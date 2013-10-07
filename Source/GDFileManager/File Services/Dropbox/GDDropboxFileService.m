//
//  GDDropboxFileService.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 26/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDDropboxFileService.h"
#import "GDDropbox.h"
#import "GDDropboxFileServiceSession.h"

#import "GDFileManagerResourceBundle.h"

static NSString *const GDDropboxFileServiceURLScheme   = @"dropbox";

@implementation GDDropboxFileService

+ (Class)clientManagerClass
{
    return [GDDropboxClientManager class];
}

+ (Class)fileServiceSessionClass
{
    return [GDDropboxFileServiceSession class];
}

- (NSString *)urlScheme
{
    return GDDropboxFileServiceURLScheme;
}

- (UIImage *)logoImage
{
    return [UIImage imageWithContentsOfFile:[GDFileManagerResourcesBundle() pathForResource:@"Dropbox" ofType:@"png"]];
}

- (UIImage *)iconImage
{
    return [UIImage imageWithContentsOfFile:[GDFileManagerResourcesBundle() pathForResource:@"dropbox-icon" ofType:@"png"]];
}

- (NSString *)name
{
    return @"Dropbox";
}

- (void)linkUserID:(NSString *)userID apiToken:(GDAPIToken *)apiToken
    fromController:(UIViewController *)rootController
           success:(void (^)(GDFileServiceSession *fileServiceSession))success
           failure:(void (^)(NSError *error))failure
{
    [(GDDropboxClientManager *)self.clientManager linkUserID:userID apiToken:apiToken fromController:rootController
                                                     success:^(GDDropboxClient *client) {
                                                         GDDropboxFileServiceSession *session = [[GDDropboxFileServiceSession alloc] initWithFileService:self client:client];
                                                         [self addFileServiceSession:session];
                                                         if (success) success(session);
                                                     } failure:failure];
}

- (BOOL)handleOpenURL:(NSURL *)url
{
    return [(GDDropboxClientManager *)self.clientManager handleOpenURL:url];
}

@end
