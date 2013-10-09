//
//  GDWebLoginControllerDefaultDelegate.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 19/06/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDWebLoginControllerDefaultDelegate.h"

@interface GDWebLoginControllerDefaultDelegate ()

@property (nonatomic, strong, readwrite) NSURL *callbackURL;
@property (nonatomic, strong, readwrite) void (^success)(NSURL *);
@property (nonatomic, strong, readwrite) void (^failure)();

@end

@implementation GDWebLoginControllerDefaultDelegate

- (id)init
{
    return [self initWithCallbackURL:nil success:nil failure:nil];
}

- (id)initWithCallbackURL:(NSURL *)callbackURL success:(void (^)(NSURL *))success failure:(void (^)())failure
{
    self = [super init];
    
    if (self) {
        self.callbackURL = callbackURL;
        self.success = success;
        self.failure = failure;
    }
    
    return self;
}

- (BOOL)webLoginController:(GDWebLoginController *)loginController shouldDismissForURL:(NSURL *)url
{
    if ([[url absoluteString] hasPrefix:[self.callbackURL absoluteString]]) {
        if (self.success)
            self.success(url);
        
        [self cleanup];
        
        return YES;
    }
    return NO;
}

- (void)webLoginViewControllerDidCancel:(GDWebLoginController *)loginController
{
    if (self.failure)
        self.failure();
    
    [self cleanup];
}

- (void)cleanup
{
    self.success = nil;
    self.failure = nil;
}

@end
