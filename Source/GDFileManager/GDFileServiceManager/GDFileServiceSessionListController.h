//
//  GDFileServiceSessionListController.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 31/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GDFileServiceManager;
@class GDFileListViewController;
@class GDFileManager;

@interface GDFileServiceSessionListController : UITableViewController

@property (nonatomic, strong) GDFileServiceManager *fileServiceManager;
@property (nonatomic, strong) GDFileListViewController *(^fileListControllerFactory)(UIViewController *parent);
@property (nonatomic, strong) GDFileManager *fileManager;

- (IBAction)addButtonTapped:(id)sender;

@end
