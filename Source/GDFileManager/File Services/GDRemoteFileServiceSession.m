//
//  GDRemoteFileServiceSession.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 27/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDRemoteFileServiceSession.h"
#import "GDFileService.h"
#import "GDHTTPClient.h"

@implementation GDRemoteFileServiceSession

+ (NSURL *)baseURLForFileService:(GDFileService *)fileService client:(GDHTTPClient *)client
{
    NSString *urlString = [NSString stringWithFormat:@"%@://%@/", [fileService urlScheme],  client.userID];
    return [NSURL URLWithString:urlString];
}


- (id)initWithFileService:(GDFileService *)fileService client:(GDHTTPClient *)client
{
    NSURL *baseURL = [[self class] baseURLForFileService:fileService client:client];
    
    if ((self = [super initWithBaseURL:baseURL fileService:fileService])) {
        self.client = client;
    }
    
    return self;
}

- (BOOL)isAvailable
{
    return [self.client isAvailable];
}

- (void)unlink
{
    [self.fileService unlinkSession:self];
}

- (NSOperation *)downloadURL:(NSURL *)url intoFileURL:(NSURL *)localURL
                    progress:(void (^)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))progress
                     success:(void (^)(NSURL *localURL))success
                     failure:(void (^)(NSError *error))failure
{
    [self doesNotRecognizeSelector:_cmd];
    
    return nil;
}

@end
