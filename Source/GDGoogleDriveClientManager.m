//
//  GDGoogleDriveClientManager.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 24/06/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDGoogleDriveClientManager.h"
#import "GDGoogleDriveClient.h"
#import "GDGoogleDriveAccountInfo.h"

#import "GDWebLoginController.h"
#import "GDURLUtilities.h"
#import "GDOAuth2Credential.h"

@implementation GDGoogleDriveClientManager

@dynamic defaultAPIToken;

+ (Class)apiTokenClass
{
    return [GDGoogleDriveAPIToken class];
}

+ (Class)clientClass
{
    return [GDGoogleDriveClient class];
}

#pragma mark - Authentication

- (void)linkUserID:(NSString *)userID apiToken:(GDGoogleDriveAPIToken *)apiToken
    fromController:(UIViewController *)rootController
           success:(void (^)(id <GDClient> client))success
           failure:(void (^)(NSError *error))failure
{
    NSParameterAssert(apiToken.key);
    NSParameterAssert(apiToken.secret);
    
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    if (userID)
        parameters[@"login_hint"] = userID;
    
    parameters[@"client_id"] = apiToken.key;
    parameters[@"response_type"] = @"code";
    parameters[@"redirect_uri"] = @"http://localhost";
    
    NSArray *scopes = @[@"https://www.googleapis.com/auth/userinfo.profile", @"https://www.googleapis.com/auth/drive"];
    parameters[@"scope"] = [scopes componentsJoinedByString:@" "];
    parameters[@"state"] = apiToken.key;
    
    NSString *urlString = [NSString stringWithFormat:@"https://accounts.google.com/o/oauth2/auth?%@", GDURLQueryStringFromParametersWithEncoding(parameters, NSUTF8StringEncoding)];
    
    GDWebLoginController *webLoginController = [[GDWebLoginController alloc] initWithURL:[NSURL URLWithString:urlString]];
    webLoginController.cookiesURL = [NSURL URLWithString:@"https://accounts.google.com"];
    webLoginController.initialTitle = @"Google Drive";
    
    typeof(success) successWrapper = ^(id <GDClient> client){
        [webLoginController dismissAnimated:YES];
        if (success) success(client);
    };
    
    typeof(failure) failureWrapper = ^(NSError *error){
        [webLoginController dismissAnimated:YES];
        if (failure) failure(error);
    };
    
    
    NSURL *callbackURL = [NSURL URLWithString:@"http://localhost"];
    
    [webLoginController setCallbackURL:callbackURL
                               success:^(NSURL *callbackURL) {
                                   NSLog(@"success with callback URL: %@", callbackURL);
                                   
                                   AFOAuth2Client *oauthClient = [AFOAuth2Client clientWithBaseURL:[NSURL URLWithString:@"https://accounts.google.com/o/oauth2"]
                                                                                          clientID:apiToken.key secret:apiToken.secret];
                                   
                                   NSError *error = nil;
                                   NSString *oauthCode = [self oauthCodeFromCallbackURL:callbackURL error:&error];
                                   if (!oauthCode) {
                                       return failureWrapper(error);
                                   }
                                   
                                   [oauthClient authenticateUsingOAuthWithPath:@"token"
                                                                          code:oauthCode
                                                                   redirectURI:@"http://localhost"
                                                                       success:^(AFOAuthCredential *credential) {
                                                                           GDOAuth2Credential *gdCredential = [[GDOAuth2Credential alloc] initWithOAuthCredential:credential userID:nil apiToken:apiToken];
                                                                           
                                                                           [self validateCredential:gdCredential
                                                                                           apiToken:apiToken
                                                                                            success:^(GDGoogleDriveClient *client) {
                                                                                                [self addCredential:client.credential];
                                                                                                
                                                                                                return successWrapper(client);
                                                                                            } failure:^(NSError *error) {
                                                                                                return failureWrapper(error);
                                                                                            }];
                                                                       } failure:^(NSError *error) {
                                                                           NSLog(@"failure: %@", error);
                                                                           return failureWrapper(error);
                                                                       }];
                                   
                               } failure:^{
                                   NSLog(@"failure");
                                   
                                   return failureWrapper(nil);
                               }];
    
    [webLoginController presentFromViewController:rootController];
}

- (NSString *)oauthCodeFromCallbackURL:(NSURL *)callbackURL error:(NSError **)error
{
    NSString *queryString = [callbackURL query];
    NSDictionary *parameters = GDParametersFromURLQueryStringWithEncoding(queryString, NSUTF8StringEncoding);
    
    if (parameters[@"code"]) {
        return parameters[@"code"];
    } else if (parameters[@"error"]) {
        if (error) {
            *error = [NSError errorWithDomain:@"OAuth" code:0 userInfo:parameters];
        }
    }
    return nil;
}

- (void)validateCredential:(GDOAuth2Credential *)credential apiToken:(GDGoogleDriveAPIToken *)apiToken
                   success:(void (^)(GDGoogleDriveClient *client))success failure:(void (^)(NSError *error))failure
{
    GDGoogleDriveClient *client = [[GDGoogleDriveClient alloc] initWithClientManager:self credential:credential];
    
    [client getAccountInfoWithSuccess:^(GDGoogleDriveAccountInfo *accountInfo) {
        GDOAuth2Credential *validatedCredential = [[GDOAuth2Credential alloc] initWithOAuthCredential:credential.oauthCredential
                                                                                               userID:accountInfo.userID
                                                                                             apiToken:apiToken];
        client.credential = validatedCredential;
        if (success) {
            success(client);
        }
    } failure:failure];
}


@end

