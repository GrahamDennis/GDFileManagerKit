//
//  GDSugarSyncFileService.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 29/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDSugarSyncFileService.h"
#import "GDSugarSyncFileServiceSession.h"
#import "GDSugarSync.h"

#import "GDFileManagerResourceBundle.h"

static NSString *const GDSugarSyncFileServiceURLScheme   = @"sugarsync";

@interface GDSugarSyncFileService ()

@property (nonatomic, readonly, strong) GDSugarSyncClientManager *clientManager;

@end

@implementation GDSugarSyncFileService

+ (Class)clientManagerClass
{
    return [GDSugarSyncClientManager class];
}

+ (Class)fileServiceSessionClass
{
    return [GDSugarSyncFileServiceSession class];
}

- (NSString *)urlScheme
{
    return GDSugarSyncFileServiceURLScheme;
}

- (UIImage *)logoImage
{
    return [UIImage imageWithContentsOfFile:[GDFileManagerResourcesBundle() pathForResource:@"SugarSync" ofType:@"png"]];
}

- (UIImage *)iconImage
{
    return [UIImage imageWithContentsOfFile:[GDFileManagerResourcesBundle() pathForResource:@"sugarsync-icon" ofType:@"png"]];
}

- (NSString *)name
{
    return @"SugarSync";
}

- (void)linkUserID:(NSString *)userID apiToken:(GDAPIToken *)apiToken
    fromController:(UIViewController *)rootController
           success:(void (^)(GDFileServiceSession *fileServiceSession))success
           failure:(void (^)(NSError *error))failure
{
    [self.clientManager linkUserID:userID apiToken:apiToken fromController:rootController
                           success:^(GDSugarSyncClient *client) {
                               GDSugarSyncFileServiceSession *session = [[GDSugarSyncFileServiceSession alloc] initWithFileService:self client:client];
                               [self addFileServiceSession:session];
                               if (success) success(session);
                           } failure:failure];
}


@end
