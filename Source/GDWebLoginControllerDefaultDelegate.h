//
//  GDWebLoginControllerDefaultDelegate.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 19/06/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GDWebLoginController.h"

@interface GDWebLoginControllerDefaultDelegate : NSObject <GDWebLoginControllerDelegate>

@property (nonatomic, strong, readonly) NSURL *callbackURL;
@property (nonatomic, strong, readonly) void (^success)(NSURL *);
@property (nonatomic, strong, readonly) void (^failure)();

- (id)initWithCallbackURL:(NSURL *)callbackURL success:(void (^)(NSURL *))success failure:(void (^)())failure;

@end
