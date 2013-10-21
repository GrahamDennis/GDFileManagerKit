//
//  GDWebLoginController.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 18/06/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDWebLoginController.h"
#import "GDWebLoginController_Private.h"

#import "GDWebLoginViewController.h"
#import "GDWebLoginControllerDefaultDelegate.h"

#import "GDKeyboardDismissingNavigationController.h"

#import <objc/runtime.h>

@interface GDWebLoginController ()

@property (nonatomic, strong) UINavigationController *navigationController;
@property (nonatomic, weak) UIViewController *presentingViewController;
@property (nonatomic, strong, readwrite) NSURL *initialURL;

@end

@implementation GDWebLoginController

- (id)init
{
    return [self initWithURL:nil];
}

- (id)initWithURL:(NSURL *)url
{
    self = [super init];
    if (self) {
        // Custom initialization
        self.backgroundColor = [UIColor whiteColor];
        
        self.initialURL = url;
    }
    return self;
}

- (void)setCallbackURL:(NSURL *)callbackURL success:(void (^)(NSURL *))success failure:(void (^)())failure
{
    static const void *defaultDelegateKey = &defaultDelegateKey;
    
    GDWebLoginControllerDefaultDelegate *delegate = [[GDWebLoginControllerDefaultDelegate alloc] initWithCallbackURL:callbackURL
                                                                                                             success:success
                                                                                                             failure:failure];
    
    self.delegate = delegate;
    
    objc_setAssociatedObject(self, defaultDelegateKey, delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)presentFromViewController:(UIViewController *)viewController
{
    static const void *webLoginControllerKey = &webLoginControllerKey;
    
    NSParameterAssert(!self.presentingViewController);
    self.presentingViewController = viewController;

    GDWebLoginViewController *rootWebLoginViewController = [[GDWebLoginViewController alloc] initWithWebLoginController:self];
    rootWebLoginViewController.navigationItem.title = self.initialTitle;
    [rootWebLoginViewController loadURL:self.initialURL];
    
    self.navigationController = [[GDKeyboardDismissingNavigationController alloc] initWithRootViewController:rootWebLoginViewController];
    
    self.navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    self.navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    objc_setAssociatedObject(self.navigationController, webLoginControllerKey, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [self.presentingViewController presentViewController:self.navigationController animated:YES completion:nil];
}

#pragma Private API

- (BOOL)webLoginViewController:(GDWebLoginViewController *)loginViewController
    shouldStartLoadWithRequest:(NSURLRequest *)request
                navigationType:(UIWebViewNavigationType)navigationType
                     hasLoaded:(BOOL)hasLoaded
{
    NSURL *url = [request URL];
    
    if ([self.delegate webLoginController:self shouldDismissForURL:url]) {
        GDWebLoginViewController *loginController = [[GDWebLoginViewController alloc] initWithWebLoginController:self];
        loginController.navigationItem.title = self.initialTitle;
        
        [self.navigationController pushViewController:loginController animated:YES];
        return NO;
    }
    
    NSString *urlScheme = [url scheme];
    
    // If the scheme is not an obvious web scheme, then see if we can open it in another app.
    if (![urlScheme isEqualToString:@"http"] && ![urlScheme isEqualToString:@"https"]) {
        // Maybe we should ask the delegate whether to open such URLs?
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
            // We assume if we're being redirected to another application, then we've failed the login.
            // This could be false if we were redirected to another app and then sent back here again.  But then we'd have to intercept
            // [[UIApplication delegate] openURL:] calls.
            [self cancelAnimated:NO];
            return NO;
        }
    } else if (![[loginViewController.urlRequest.URL path] isEqualToString:url.path] && hasLoaded) {
        GDWebLoginViewController *loginController = [[GDWebLoginViewController alloc] initWithWebLoginController:self];
        loginController.navigationItem.title = self.initialTitle;
        [loginController loadURLRequest:request];
        
        [self.navigationController pushViewController:loginController animated:YES];
        return NO;
    }
    
    return YES;
}

- (void)networkRequestStarted
{
    if ([self.delegate respondsToSelector:@selector(networkRequestStarted)])
        [self.delegate networkRequestStarted];
}

- (void)networkRequestStopped
{
    if ([self.delegate respondsToSelector:@selector(networkRequestStopped)])
        [self.delegate networkRequestStopped];
}

- (BOOL)webLoginViewController:(GDWebLoginViewController *)loginViewController shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [self.presentingViewController shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

- (void)webLoginViewControllerUserDidAbortOnLoadFail:(GDWebLoginViewController *)loginViewController
{
    if ([self.navigationController.viewControllers count] > 1) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self cancel];
    }
}

- (void)cancel
{
    [self cancelAnimated:YES];
}

- (void)cancelAnimated:(BOOL)animated
{
    [self.delegate webLoginViewControllerDidCancel:self];
}

- (void)dismiss
{
    [self dismissAnimated:YES];
}

- (void)dismissAnimated:(BOOL)animated
{
    [(GDWebLoginViewController *)[self.navigationController topViewController] stopLoading];
    
    [self clearBrowserCookies];
    
    [self.presentingViewController dismissViewControllerAnimated:animated completion:nil];
}

- (void)clearBrowserCookies
{
    if (self.cookiesURL) {
        NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        NSArray *cookies = [cookieStorage cookiesForURL:self.cookiesURL];

        for (NSHTTPCookie *cookie in cookies) {
            [cookieStorage deleteCookie:cookie];
        }
    }
}

@end
