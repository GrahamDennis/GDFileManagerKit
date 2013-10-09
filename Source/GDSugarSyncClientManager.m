//
//  GDSugarSyncClientManager.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 27/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDSugarSyncClientManager.h"
#import "GDSugarSyncClient.h"
#import "GDSugarSyncCredential.h"
#import "UIAlertView+Blocks.h"
#import "GDFileManager.h"

#import "GDKeyboardDismissingNavigationController.h"
#import "GDLoginFormViewController.h"

#import "GDFileManagerResourceBundle.h"

@implementation GDSugarSyncClientManager

@dynamic defaultAPIToken;

+ (Class)apiTokenClass
{
    return [GDSugarSyncAPIToken class];
}

+ (Class)clientClass
{
    return [GDSugarSyncClient class];
}

- (void)setDefaultKey:(NSString *)key secret:(NSString *)secret appID:(NSString *)appID
{
    GDSugarSyncAPIToken *apiToken = [[GDSugarSyncAPIToken alloc] initWithKey:key secret:secret appID:appID];
    if (apiToken) {
        [GDSugarSyncAPIToken registerToken:apiToken];
    }
    self.defaultAPIToken = apiToken;
}

#pragma mark - Authentication

- (void)linkUserID:(NSString *)userID apiToken:(GDSugarSyncAPIToken *)apiToken
    fromController:(UIViewController *)rootController
           success:(void (^)(id <GDClient> client))success
           failure:(void (^)(NSError *error))failure
{
    NSString *loginFormJSONPath = [GDFileManagerResourcesBundle() pathForResource:@"SugarSyncLoginForm" ofType:@"json"];
    NSError *error = nil;
    id json = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:loginFormJSONPath] options:0 error:&error];
    if (!json) {
        NSLog(@"Failed to convert json due to error: %@", error);
        return;
    }
    QRootElement *rootElement = [[QRootElement alloc] initWithJSON:json andData:nil];
    GDLoginFormViewController *loginController = [[GDLoginFormViewController alloc] initWithRoot:rootElement];
    __weak GDLoginFormViewController *weakLoginController = loginController;
    __weak UIViewController *weakRootController = rootController;
    
    typeof(success) successWrapper = ^(id <GDClient> client) {
        weakLoginController.loading = NO;
        [weakRootController dismissViewControllerAnimated:YES completion:NULL];
        
        if (success) success(client);
    };
    
    typeof(failure) failureWrapper = ^(NSError *error) {
        weakLoginController.loading = NO;
        
        if (failure) failure(error);
    };
    
    loginController.buttonTapHandler = ^(NSDictionary *result){
        weakLoginController.loading = YES;
        
        NSString *username = result[@"email"];
        NSString *password = result[@"password"];
        
        [self validateUsername:username password:password success:successWrapper failure:^(NSError *error) {
            RIButtonItem *dismissItem = [RIButtonItem itemWithLabel:@"Dismiss"];
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Login failed" message:@"Incorrect email or password" cancelButtonItem:dismissItem otherButtonItems:nil];
            
            [alert show];
            
            failureWrapper(error);
        }];
    };
    
    loginController.cancelHandler = ^{
        [weakRootController dismissViewControllerAnimated:YES completion:NULL];
        failureWrapper(GDFileManagerError(GDFileManagerLoginCancelledError));
    };
    
    UINavigationController *navWrapper = [[GDKeyboardDismissingNavigationController alloc] initWithRootViewController:loginController];
    navWrapper.modalPresentationStyle = UIModalPresentationFormSheet;
    navWrapper.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    [rootController presentViewController:navWrapper animated:YES completion:NULL];

}

- (void)validateUsername:(NSString *)username password:(NSString *)password
                 success:(void (^)(id <GDClient> client))success failure:(void (^)(NSError *error))failure

{
    GDSugarSyncCredential *credential = [[GDSugarSyncCredential alloc] initWithUserID:nil apiToken:self.defaultAPIToken];
    
    GDSugarSyncClient *client = [[GDSugarSyncClient alloc] initWithClientManager:self credential:credential];
    
    [client getRefreshTokenWithUsername:username password:password
                                     success:^(GDSugarSyncCredential *credential) {
                                         client.credential = credential;
                                         // Next we need an access token
                                         [self generateAccessTokenWithClient:client success:success failure:failure];
                                     } failure:failure];
}

- (void)generateAccessTokenWithClient:(GDSugarSyncClient *)client success:(void (^)(id <GDClient> client))success failure:(void (^)(NSError *error))failure
{
    [client getAccessTokenWithSuccess:^(GDSugarSyncCredential *credential) {
        client.credential = credential;
        [self addCredential:credential];
        if (success) success(client);
    } failure:failure];
}


@end
