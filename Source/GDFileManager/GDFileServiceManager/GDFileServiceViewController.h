//
//  GDFileServiceViewController.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 2/03/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GDFileServiceManager, GDFileServiceSession;

@protocol GDFileServiceViewControllerDelegate;

@interface GDFileServiceViewController : UITableViewController

- (id)initWithFileServiceManager:(GDFileServiceManager *)fileServiceManager;

@property (nonatomic, strong) GDFileServiceManager *fileServiceManager;
@property (nonatomic, weak) id <GDFileServiceViewControllerDelegate> delegate;

@end


@protocol GDFileServiceViewControllerDelegate <NSObject>

@optional

- (void)fileServiceViewController:(GDFileServiceViewController *)fileServiceViewController
         didAddFileServiceSession:(GDFileServiceSession *)session;

- (void)fileServiceViewController:(GDFileServiceViewController *)fileServiceViewController
                 didFailWithError:(NSError *)error;

@end