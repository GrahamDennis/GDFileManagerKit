//
//  GDDropboxCredential.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 23/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDDropboxCredential.h"
#import "GDDropboxCredential_Private.h"

#import "GDDropboxClientManager.h"

@implementation GDDropboxCredential

@synthesize authorisationHeader = _authorisationHeader;

- (id)initWithUserID:(NSString *)userID apiToken:(GDDropboxAPIToken *)apiToken
{
    return [self initWithUserID:userID apiToken:apiToken oauthParameters:nil];
}

- (id)initWithUserID:(NSString *)userID apiToken:(GDDropboxAPIToken *)apiToken oauthParameters:(NSDictionary *)oauthParams
{
    if ((self = [super initWithUserID:userID apiToken:apiToken])) {
        _oauthParameters = [oauthParams copy];
    }
    
    return self;
}

#pragma mark - NSCoding

static NSString *const kOAuthParametersCoderKey    = @"oauthParams";

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
        _oauthParameters = [aDecoder decodeObjectForKey:kOAuthParametersCoderKey];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:self.oauthParameters forKey:kOAuthParametersCoderKey];
}

#pragma mark - Public

- (BOOL)isValid
{
    return [self.oauthParameters count] && self.apiToken;
}

- (NSString *)root
{
    return self.apiToken.root;
}

- (NSString *)authorisationHeader
{
    if (!_authorisationHeader) {
        _authorisationHeader = [NSString stringWithFormat:@"OAuth oauth_version=\"1.0\", oauth_signature_method=\"PLAINTEXT\", oauth_consumer_key=\"%@\", oauth_token=\"%@\", oauth_signature=\"%@&%@\"", self.apiToken.key, self.oauthParameters[@"oauth_token"], self.apiToken.secret, self.oauthParameters[@"oauth_token_secret"]];
    }
    
    return _authorisationHeader;
}

@end
