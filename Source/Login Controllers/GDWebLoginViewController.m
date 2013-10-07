//
//  GDWebLoginViewController.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 9/06/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDWebLoginViewController.h"
#import "GDWebLoginController.h"
#import "GDWebLoginController_Private.h"

#import <QuartzCore/QuartzCore.h>

#include <tgmath.h>

@interface GDWebLoginViewController () <UIWebViewDelegate, UIAlertViewDelegate>

@property (nonatomic, weak, readwrite) GDWebLoginController *loginController;

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong, readwrite) NSURLRequest *urlRequest;
@property (nonatomic) BOOL haveStartedLoading;
@property (nonatomic) BOOL hasLoaded;

@property (nonatomic, strong) UIAlertView *alertView;

- (void)beginLoading;

@end

@implementation GDWebLoginViewController

- (void)dealloc
{
    self.webView.delegate = nil;
    self.webView = nil;
}

// Override the parent's designated initialiser.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [self initWithWebLoginController:nil];
}

- (id)initWithWebLoginController:(GDWebLoginController *)loginController
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self) {
        self.loginController = loginController;
        
        UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                    target:self.loginController action:@selector(cancel)];
        
        self.navigationItem.rightBarButtonItem = cancelItem;
    }
    
    return self;
}

- (void)loadView
{
    [super loadView];
    
    self.view.backgroundColor = self.loginController.backgroundColor;
    
    UIActivityIndicatorView *activityIndicator =
    [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    
    activityIndicator.autoresizingMask =
    UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |
    UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    
    CGRect frame = activityIndicator.frame;
    frame.origin.x = floor(self.view.bounds.size.width/2 - frame.size.width/2);
    frame.origin.y = floor(self.view.bounds.size.height/2 - frame.size.height/2) - 20;
    activityIndicator.frame = frame;
    
    [activityIndicator startAnimating];
    [self.view addSubview:activityIndicator];
    
    self.webView = [[UIWebView alloc] initWithFrame:self.view.frame];
    self.webView.delegate = self;
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.scalesPageToFit = NO;
    self.webView.hidden = YES;
    self.webView.dataDetectorTypes = UIDataDetectorTypeNone;
    [self.view addSubview:self.webView];

}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    [self beginLoading];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [self stopLoading];
    
    self.webView.delegate = nil;
    self.webView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ||
    [self.loginController webLoginViewController:self shouldAutorotateToInterfaceOrientation:interfaceOrientation]; // Delegate to login controller.
}

#pragma mark - Loading a URL

- (void)loadURL:(NSURL *)url
{
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
    
    return [self loadURLRequest:urlRequest];
}


- (void)loadURLRequest:(NSURLRequest *)urlRequest
{
    [self stopLoading];
    self.haveStartedLoading = NO;
    self.hasLoaded = NO;
    
    self.urlRequest = urlRequest;
    
    [self beginLoading];
}


- (void)beginLoading
{
    if (self.urlRequest && [self isViewLoaded] && !self.haveStartedLoading) {
        NSParameterAssert(self.webView);
        [self.webView loadRequest:self.urlRequest];
        self.haveStartedLoading = YES;
    }
}

#pragma mark UIWebViewDelegate methods

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [self.loginController networkRequestStarted];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSString *title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    if ([title length])
        self.navigationItem.title = title;
    [webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitTouchCallout = \"none\";"]; // Disable touch-and-hold action sheet
    [webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitUserSelect = \"none\";"]; // Disable text selection
    self.webView.frame = self.view.bounds;
    
    NSString* js =
    [NSString stringWithFormat:@"var meta = document.createElement('meta'); " \
     "meta.setAttribute( 'name', 'viewport' ); " \
     "meta.setAttribute( 'content', 'width = %fpx, initial-scale = 5.0, user-scalable = yes' ); " \
     "document.getElementsByTagName('head')[0].appendChild(meta)", CGRectGetWidth(self.view.frame)];
    
    [self.webView stringByEvaluatingJavaScriptFromString: js];
    
    CATransition* transition = [CATransition animation];
    transition.duration = 0.25;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    transition.type = kCATransitionFade;
    [self.view.layer addAnimation:transition forKey:nil];
    
    self.webView.hidden = NO;
    self.hasLoaded = YES;
    
    [self.loginController networkRequestStopped];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [self.loginController networkRequestStopped];
    
    // ignore "Frame Load Interrupted" errors and cancels
    if (error.code == 102 && [error.domain isEqualToString:@"WebKitErrorDomain"]) return;
    if (error.code == NSURLErrorCancelled && [error.domain isEqualToString:NSURLErrorDomain]) return;
    
    NSString *title = @"";
    NSString *message = @"";
    
    if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorNotConnectedToInternet) {
        title = NSLocalizedString(@"No internet connection", @"");
        message = NSLocalizedString(@"Try again once you have an internet connection", @"");
    } else if ([error.domain isEqualToString:NSURLErrorDomain] &&
               (error.code == NSURLErrorTimedOut || error.code == NSURLErrorCannotConnectToHost)) {
        title = NSLocalizedString(@"Internet connection lost", @"");
        message = NSLocalizedString(@"Please try again.", @"");
    } else {
        title = NSLocalizedString(@"Unknown Error Occurred", @"");
        message = NSLocalizedString(@"There was an error loading Dropbox. Please try again.", @"");
    }
    
    if (self.hasLoaded) {
        // If it has loaded, it means it's a form submit, so users can cancel/retry on their own
        NSString *okStr = NSLocalizedString(@"OK", nil);
        
        self.alertView =
        [[UIAlertView alloc]
          initWithTitle:title message:message delegate:nil cancelButtonTitle:okStr otherButtonTitles:nil];
    } else {
        // if the page hasn't loaded, this alert gives the user a way to retry
        NSString *retryStr = NSLocalizedString(@"Retry", @"Retry loading a page that has failed to load");
        
        self.alertView =
        [[UIAlertView alloc]
          initWithTitle:title message:message delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
          otherButtonTitles:retryStr, nil];
    }
    
    
    [self.alertView show];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    return [self.loginController webLoginViewController:self shouldStartLoadWithRequest:request navigationType:navigationType hasLoaded:self.hasLoaded];
}

#pragma mark - UIAlertView methods

- (void)setAlertView:(UIAlertView *)alertView
{
    if (alertView == self.alertView) return;
    self.alertView.delegate = nil;
    _alertView = alertView;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex) {
        [self beginLoading];
    } else {
        [self.loginController webLoginViewControllerUserDidAbortOnLoadFail:self];
    }
    
    self.alertView = nil;
}

#pragma mark - private methods

- (void)stopLoading
{
    if ([self.webView isLoading])
        [self.webView stopLoading];
}

@end
