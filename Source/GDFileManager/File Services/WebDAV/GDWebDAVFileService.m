//
//  GDWebDAVFileService.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 4/02/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDWebDAVFileService.h"
#import "GDWebDAVFileServiceSession.h"
#import "GDWebDAV.h"
#import "GDFileManagerResourceBundle.h"

static NSString *const GDWebDAVURLSchemePrefix   = @"webdav+";
static NSString *const GDWebDAV_HTTPFileServiceURLScheme   = @"webdav+http";
static NSString *const GDWebDAV_HTTPSFileServiceURLScheme   = @"webdav+https";

@interface GDWebDAVFileService ()

@property (nonatomic, strong, readonly) GDWebDAVClientManager *clientManager;

@end

@implementation GDWebDAVFileService

+ (Class)clientManagerClass
{
    return [GDWebDAVClientManager class];
}

+ (Class)fileServiceSessionClass
{
    return [GDWebDAVFileServiceSession class];
}

- (NSString *)urlScheme
{
    return GDWebDAV_HTTPFileServiceURLScheme;
}

- (NSArray *)urlSchemes
{
    return @[GDWebDAV_HTTPFileServiceURLScheme, GDWebDAV_HTTPSFileServiceURLScheme];
}

- (UIImage *)logoImage
{
    return [UIImage imageWithContentsOfFile:[GDFileManagerResourcesBundle() pathForResource:@"WebDAV" ofType:@"png"]];
}

- (UIImage *)iconImage
{
    return [UIImage imageWithContentsOfFile:[GDFileManagerResourcesBundle() pathForResource:@"webdav-icon" ofType:@"png"]];
}

- (NSString *)name
{
    return @"WebDAV";
}

- (NSString *)urlSchemeForClient:(GDWebDAVClient *)client
{
    NSString *urlScheme = [GDWebDAVURLSchemePrefix stringByAppendingString:[client.baseURL scheme]];
    if (![self.urlSchemes containsObject:urlScheme]) {
        NSLog(@"Invalid WebDAV URL Scheme: %@", urlScheme);
        return nil;
    }
    return urlScheme;
}

- (void)linkUserID:(NSString *)userID apiToken:(GDAPIToken *)apiToken
    fromController:(UIViewController *)rootController
           success:(void (^)(GDFileServiceSession *fileServiceSession))success
           failure:(void (^)(NSError *error))failure
{
    [self.clientManager linkUserID:userID apiToken:apiToken fromController:rootController
                           success:^(GDWebDAVClient *client) {
                               GDWebDAVFileServiceSession *session = [[GDWebDAVFileServiceSession alloc] initWithFileService:self client:client];
                               [self addFileServiceSession:session];
                               if (success) success(session);
                           } failure:failure];
}


@end