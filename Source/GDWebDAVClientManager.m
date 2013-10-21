//
//  GDWebDAVClientManager.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 1/02/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDWebDAVClientManager.h"
#import "GDFileManager.h"

#import "GDWebDAVCredential.h"
#import "GDWebDAVClient.h"

#import "UIAlertView+Blocks.h"
#import "GDLoginFormViewController.h"
#import "GDKeyboardDismissingNavigationController.h"

#import "AsyncSequentialEnumeration.h"

#import "GDFileManagerResourceBundle.h"

@implementation GDWebDAVClientManager

+ (Class)clientClass
{
    return [GDWebDAVClient class];
}

- (GDWebDAVCredential *)credentialForUsername:(NSString *)username serverURL:(NSURL *)serverURL
{
    return (GDWebDAVCredential *)[self credentialMatchingPredicate:[NSPredicate predicateWithBlock:^BOOL(GDWebDAVCredential *credential, NSDictionary *bindings) {
        return ((!username || [credential.username isEqualToString:username])
                && (!serverURL || [credential.serverURL isEqual:serverURL]));
    }]];
}

- (GDWebDAVClient *)newClientForUsername:(NSString *)username serverURL:(NSURL *)serverURL
{
    GDWebDAVCredential *credential = [self credentialForUsername:username serverURL:serverURL];
    return (GDWebDAVClient *)[self newClientForCredential:credential];
}

- (BOOL)isValid
{
    return YES;
}

#pragma mark - Authentication

- (void)linkUserID:(NSString *)userID apiToken:(GDAPIToken *)apiToken
    fromController:(UIViewController *)rootController
           success:(void (^)(id <GDClient> client))success
           failure:(void (^)(NSError *error))failure
{
    NSString *loginFormJSONPath = [GDFileManagerResourcesBundle() pathForResource:@"WebDAVServerForm" ofType:@"json"];
    NSError *error = nil;
    id json = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:loginFormJSONPath] options:0 error:&error];
    if (!json) {
        NSLog(@"Failed to convert json due to error: %@", error);
        return;
    }
    QRootElement *rootElement = [[QRootElement alloc] initWithJSON:json andData:nil];
    GDLoginFormViewController *loginController = [[GDLoginFormViewController alloc] initWithRoot:rootElement];
    __weak GDLoginFormViewController *weakLoginController = loginController;
    __weak typeof(rootController) weakRootController = rootController;
    
    typeof(success) successWrapper = ^(id <GDClient> client){
        weakLoginController.loading = NO;
        [weakRootController dismissViewControllerAnimated:YES completion:NULL];
        if (success) success(client);
    };
    
    typeof(failure) failureWrapper = ^(NSError *error){
        weakLoginController.loading = NO;
        if (failure) failure(error);
    };
    
    loginController.buttonTapHandler = ^(NSDictionary *result){
        weakLoginController.loading = YES;
        
        NSString *server = result[@"server"];

        if ([server hasPrefix:@"dav://"])
            server = [server substringFromIndex:6];
        else if ([server hasPrefix:@"davs://"])
            server = [server substringFromIndex:7];
        else if ([server hasPrefix:@"http://"])
            server = [server substringFromIndex:7];
        else if ([server hasPrefix:@"https://"])
            server = [server substringFromIndex:8];

        NSString *username = result[@"username"];
        NSString *password = result[@"password"];
        
        NSArray *protocolsToTry = @[@"https", @"http"];
        
        __block NSError *lastError = nil;
        
        AsyncSequentialEnumeration([protocolsToTry objectEnumerator], ^(NSString *protocolScheme, void (^continuationBlock)(BOOL keepGoing)) {
            NSString *serverURLString = [NSString stringWithFormat:@"%@://%@", protocolScheme, server];
            NSURL *serverURL = [NSURL URLWithString:serverURLString];
            if (!serverURL) return continuationBlock(YES);
            [self validateServerURL:serverURL username:username password:password success:^(id client) {
                continuationBlock(NO);
                
                return successWrapper(client);
            } failure:^(NSError *error) {
                lastError = error;
                continuationBlock(YES);
            }];
        }, ^(BOOL completed) {
            if (completed) {
                failureWrapper(lastError);
                
                RIButtonItem *dismissItem = [RIButtonItem itemWithLabel:@"Dismiss"];
                
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Connection Error"
                                                                    message:@"Could not connect to WebDAV server"
                                                           cancelButtonItem:dismissItem
                                                           otherButtonItems:nil];
                
                [alertView show];
            }
        });
    };
    
    loginController.cancelHandler = ^{
        [weakRootController dismissViewControllerAnimated:YES completion:NULL];
        return failureWrapper(GDFileManagerError(GDFileManagerLoginCancelledError));
    };
    
    UINavigationController *navWrapper = [[GDKeyboardDismissingNavigationController alloc] initWithRootViewController:loginController];
    navWrapper.modalPresentationStyle = UIModalPresentationFormSheet;
    navWrapper.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    [rootController presentViewController:navWrapper animated:YES completion:NULL];
}

- (void)validateServerURL:(NSURL *)serverURL username:(NSString *)username password:(NSString *)password
                 success:(void (^)(id client))success failure:(void (^)(NSError *error))failure

{
    GDWebDAVCredential *credential = [[GDWebDAVCredential alloc] initWithUsername:username password:password serverURL:serverURL];
    
    GDWebDAVClient *client = [[GDWebDAVClient alloc] initWithClientManager:self credential:credential baseURL:serverURL];
    
    [client validateWebDAVServerWithSuccess:^() {
        [self addCredential:client.credential];
        if (success) success(client);
    } failure:failure];
}

@end

