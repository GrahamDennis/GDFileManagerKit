//
//  GDWebLoginController.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 18/06/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GDWebLoginController;

@protocol GDWebLoginControllerDelegate <NSObject>

- (BOOL)webLoginController:(GDWebLoginController *)loginController shouldDismissForURL:(NSURL *)url;
- (void)webLoginViewControllerDidCancel:(GDWebLoginController *)loginController;
//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation;
//- (void)dismissWebLoginViewController:(GDWebLoginViewController *)loginController;

@optional
- (void)networkRequestStarted;
- (void)networkRequestStopped;

@end


@interface GDWebLoginController : NSObject

@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic, weak) id <GDWebLoginControllerDelegate> delegate;
@property (nonatomic, strong, readonly) NSURL *initialURL;
@property (nonatomic, strong) NSURL *cookiesURL;
@property (nonatomic, strong) NSString *initialTitle;

- (id)initWithURL:(NSURL *)url;

// This is an either/or proposition with the delegate.  This is a convenience method that creates a GDWebLoginControllerDefaultDelegate
- (void)setCallbackURL:(NSURL *)callbackURL success:(void (^)(NSURL *callbackURL))success failure:(void (^)())failure;

- (void)presentFromViewController:(UIViewController *)viewController;

- (void)dismiss;
- (void)dismissAnimated:(BOOL)animated;

- (void)cancel;
- (void)cancelAnimated:(BOOL)animated;

@end
