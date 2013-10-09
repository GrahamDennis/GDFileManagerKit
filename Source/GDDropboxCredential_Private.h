//
//  GDDropboxCredential_Private.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 24/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDDropboxCredential.h"

@interface GDDropboxCredential ()

- (id)initWithUserID:(NSString *)userID apiToken:(GDDropboxAPIToken *)apiToken oauthParameters:(NSDictionary *)oauthParams;

@property (nonatomic, strong, readonly) NSString *authorisationHeader;
@property (nonatomic, readonly, copy) NSDictionary *oauthParameters;

@end
