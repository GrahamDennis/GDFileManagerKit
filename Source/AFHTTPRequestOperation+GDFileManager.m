//
//  AFHTTPRequestOperation+GDFileManager.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 21/08/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "AFHTTPRequestOperation+GDFileManager.h"

@implementation AFHTTPRequestOperation (GDFileManager)

- (void)connection:(NSURLConnection *)connection
didReceiveResponse:(NSURLResponse *)response
{
    NSUInteger statusCode = ([self.response isKindOfClass:[NSHTTPURLResponse class]]) ? (NSUInteger)[self.response statusCode] : 200;
    BOOL hasAcceptableStatusCode = ![[self class] acceptableStatusCodes] || [[[self class] acceptableStatusCodes] containsIndex:statusCode];
    
    if (!hasAcceptableStatusCode) {
        self.outputStream = [NSOutputStream outputStreamToMemory];
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        for (NSString *runLoopMode in self.runLoopModes) {
            [self.outputStream scheduleInRunLoop:runLoop forMode:runLoopMode];
        }
    }
    
    [super connection:connection didReceiveResponse:response];
}


@end
