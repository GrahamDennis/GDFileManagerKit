//
//  GDDropboxSession.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 23/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDDropboxClientManager.h"

#import "GDDropbox.h"
#import "GDDropboxAPIToken.h"
#import "GDDropboxCredential.h"
#import "GDDropboxCredential_Private.h"

#import "GDWebLoginController.h"

#import "GDURLUtilities.h"

#import <CommonCrypto/CommonDigest.h>

@interface GDDropboxClientManager ()

@property (atomic, strong) void (^successCallback)(id <GDClient> client);
@property (atomic, strong) void (^failureCallback)(NSError *error);

@end

@implementation GDDropboxClientManager

@dynamic defaultAPIToken;

+ (Class)apiTokenClass
{
    return [GDDropboxAPIToken class];
}

+ (Class)clientClass
{
    return [GDDropboxClient class];
}

- (void)setDefaultKey:(NSString *)key secret:(NSString *)secret root:(NSString *)root
{
    GDDropboxAPIToken *apiToken = [[GDDropboxAPIToken alloc] initWithKey:key secret:secret root:root];
    if (apiToken) {
        [GDDropboxAPIToken registerToken:apiToken];
    }
    self.defaultAPIToken = apiToken;
}

#pragma mark - Authentication

- (void)linkUserID:(NSString *)userID apiToken:(GDDropboxAPIToken *)apiToken
    fromController:(UIViewController *)rootController
           success:(void (^)(id <GDClient> client))success
           failure:(void (^)(NSError *error))failure
{
    NSParameterAssert(apiToken.key);
    NSParameterAssert(apiToken.secret);
    self.successCallback = nil;
    self.failureCallback = nil;
    
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    if (userID) {
        NSRange atRange = [userID rangeOfString:@"@"];
        if (atRange.location != NSNotFound) {
            userID = [userID substringToIndex:atRange.location];
        }
        parameters[@"u"] = userID;
    }
    
    parameters[@"k"] = apiToken.key;
    
    NSData *consumerSecret = [apiToken.secret dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char md[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(consumerSecret.bytes, [consumerSecret length], md);
    uint32_t sha_32 = htonl(((uint32_t *)md)[CC_SHA1_DIGEST_LENGTH/sizeof(uint32_t) - 1]);
    NSString *secret = [NSString stringWithFormat:@"%x", sha_32];
    parameters[@"s"] = secret;
    
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    NSString *nonce = CFBridgingRelease(CFUUIDCreateString(NULL, uuid));
    CFRelease(uuid); uuid = NULL;
    
    parameters[@"state"] = nonce;
    
    [[NSUserDefaults standardUserDefaults] setObject:apiToken.key forKey:nonce];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSURL *dropboxAppConnectURL = [NSURL URLWithString:@"dbapi-2://1/connect"];
    if ([[UIApplication sharedApplication] canOpenURL:dropboxAppConnectURL]) {
        self.successCallback = success;
        self.failureCallback = failure;
        
        NSString *urlString = [NSString stringWithFormat:@"%@?%@", dropboxAppConnectURL, AFQueryStringFromParametersWithEncoding(parameters, NSUTF8StringEncoding)];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
    } else {
        parameters[@"easl"] = @"1";
        NSString *urlString = [NSString stringWithFormat:@"https://www.dropbox.com/1/connect_login?%@", AFQueryStringFromParametersWithEncoding(parameters, NSUTF8StringEncoding)];
        
        GDWebLoginController *webLoginController = [[GDWebLoginController alloc] initWithURL:[NSURL URLWithString:urlString]];
        webLoginController.backgroundColor = [UIColor colorWithRed:241.0/255 green:249.0/255 blue:255.0/255 alpha:1.0];
        webLoginController.cookiesURL = [NSURL URLWithString:@"https://www.dropbox.com"];
        webLoginController.initialTitle = @"Dropbox";
        __weak typeof(webLoginController) weakLoginController = webLoginController;

        typeof(success) successWrapper = ^(id <GDClient> client){
            [weakLoginController dismissAnimated:YES];
            if (success) success(client);
        };
        
        typeof(failure) failureWrapper = ^(NSError *error){
            [weakLoginController dismissAnimated:YES];
            if (failure) failure(error);
        };
        
        NSURL *callbackURL = [NSURL URLWithString:[NSString stringWithFormat:@"db-%@://", apiToken.key]];
        
        [webLoginController setCallbackURL:callbackURL
                                   success:^(NSURL *callbackURL) {
                                       NSLog(@"success with callback URL: %@", callbackURL);
                                       
                                       GDDropboxAPIToken *apiToken = nil;
                                       NSDictionary *oauthParameters = [self oauthParametersFromCallbackURL:callbackURL
                                                                                                   apiToken:&apiToken];
                                       
                                       [self validateOAuthParameters:oauthParameters
                                                            apiToken:apiToken
                                                             success:^(GDDropboxClient *client) {
                                                                 [self addCredential:client.credential];
                                                                 
                                                                 successWrapper(client);
                                                             }
                                                             failure:failureWrapper];
                                   } failure:^{
                                       NSLog(@"failure");
                                       
                                       failureWrapper(nil);
                                   }];
        
        [webLoginController presentFromViewController:rootController];
    }
}

- (BOOL)handleOpenURL:(NSURL *)callbackURL
{
    NSString *urlScheme = [callbackURL scheme];
    if (![urlScheme hasPrefix:@"db-"]) return NO;
    NSString *apiKey = [urlScheme substringFromIndex:3];
    GDDropboxAPIToken *apiToken = [GDDropboxAPIToken tokenForKey:apiKey];
    if (!apiToken) return NO;
    NSDictionary *oauthParameters = [self oauthParametersFromCallbackURL:callbackURL
                                                                apiToken:&apiToken];
    if (!oauthParameters || !apiToken) return NO;
    
    typeof(self.successCallback) success = self.successCallback;
    typeof(self.failureCallback) failure = self.failureCallback;
    
    self.successCallback = nil;
    self.failureCallback = nil;
    
    [self validateOAuthParameters:oauthParameters
                         apiToken:apiToken
                          success:^(GDDropboxClient *client) {
                              [self addCredential:client.credential];
                              
                              if (success) {
                                  success(client);
                              }
                          }
                          failure:failure];

    return YES;
}

- (NSDictionary *)oauthParametersFromCallbackURL:(NSURL *)callbackURL apiToken:(GDDropboxAPIToken **)apiTokenOut
{
    NSString *queryString = [callbackURL query];
    NSDictionary *parameters = GDParametersFromURLQueryStringWithEncoding(queryString, NSUTF8StringEncoding);
    
//    NSString *token = parameters[@"oauth_token"];
//    NSString *secret = parameters[@"oauth_token_secret"];
//    NSString *userID = parameters[@"uid"];
    NSString *state = parameters[@"state"];
    // No state.
    if (!state) {
        NSLog(@"Failed to get oauth state parameter from queryString: %@", queryString);
        return nil;
    }
    
    NSString *apiTokenKey = [[NSUserDefaults standardUserDefaults] objectForKey:state];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:state];
    [[NSUserDefaults standardUserDefaults] synchronize];
    if (!apiTokenKey) {
        // No registered state.
        return nil;
    }
    GDDropboxAPIToken *apiToken = [GDDropboxAPIToken tokenForKey:apiTokenKey];
    if (!apiToken) {
        return nil;
    }
    *apiTokenOut = apiToken;
    
    return parameters;
}

- (void)validateOAuthParameters:(NSDictionary *)oauthParameters apiToken:(GDDropboxAPIToken *)apiToken
              success:(void (^)(GDDropboxClient *client))success failure:(void (^)(NSError *error))failure
{
    GDDropboxCredential *credential = [[GDDropboxCredential alloc] initWithUserID:nil
                                                                         apiToken:apiToken
                                                                  oauthParameters:oauthParameters];
                                       
    GDDropboxClient *client = [[GDDropboxClient alloc] initWithClientManager:self credential:credential];
    
    [client getAccountInfoWithSuccess:^(GDDropboxAccountInfo *accountInfo) {
        NSString *userID = [NSString stringWithFormat:@"%@@%@", accountInfo.userID, apiToken.root];
        GDDropboxCredential *validatedCredential = [[GDDropboxCredential alloc] initWithUserID:userID
                                                                                      apiToken:apiToken
                                                                               oauthParameters:oauthParameters];
        client.credential = validatedCredential;
        if (success) {
            success(client);
        }
    } failure:failure];
}

@end
