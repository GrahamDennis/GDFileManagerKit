//
//  GDMasterViewController.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 8/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "GDFileListViewController.h"

@class GDDetailViewController;

@class GDFileManager;
@class GDURLMetadata;

@interface GDMasterViewController : GDFileListViewController

@property (strong, nonatomic) GDDetailViewController *detailViewController;

@end
