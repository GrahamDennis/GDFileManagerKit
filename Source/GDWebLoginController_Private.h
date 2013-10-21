//
//  GDWebLoginController_Private.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 18/06/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDWebLoginController.h"

@class GDWebLoginViewController;

@interface GDWebLoginController ()

- (BOOL)webLoginViewController:(GDWebLoginViewController *)loginViewController
    shouldStartLoadWithRequest:(NSURLRequest *)request
                navigationType:(UIWebViewNavigationType)navigationType
                     hasLoaded:(BOOL)hasLoaded;

- (BOOL)webLoginViewController:(GDWebLoginViewController *)loginViewController shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;

- (void)webLoginViewControllerUserDidAbortOnLoadFail:(GDWebLoginViewController *)loginViewController;

- (void)networkRequestStarted;
- (void)networkRequestStopped;

@end
