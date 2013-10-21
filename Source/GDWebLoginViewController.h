//
//  GDWebLoginViewController.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 9/06/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GDWebLoginController;

@interface GDWebLoginViewController : UIViewController

@property (nonatomic, strong, readonly) NSURLRequest *urlRequest;
@property (nonatomic, weak, readonly) GDWebLoginController *loginController;

- (id)initWithWebLoginController:(GDWebLoginController *)loginController;

- (void)loadURL:(NSURL *)url;
- (void)loadURLRequest:(NSURLRequest *)urlRequest;

- (void)stopLoading;

@end
