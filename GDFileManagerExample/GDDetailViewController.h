//
//  GDDetailViewController.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 8/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "GDURLMetadata.h"

@class GDFileManager;

@interface GDDetailViewController : UIViewController <UISplitViewControllerDelegate>

@property (strong, nonatomic) GDURLMetadata *detailItem;
@property (strong, nonatomic) GDFileManager *fileManager;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *downloadProgressView;
@end
