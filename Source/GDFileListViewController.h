//
//  GDMasterViewController.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 8/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GDFileManager;
@class GDURLMetadata;

@interface GDFileListViewController : UITableViewController

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) GDURLMetadata *metadata;
@property (nonatomic, strong) GDFileManager *fileManager;
@property (nonatomic, strong) GDFileListViewController *(^fileListControllerFactory)(UIViewController *parentController);

@property (nonatomic, strong) NSMutableArray *folders;
@property (nonatomic, strong) NSMutableArray *files;

- (void)didSelectFileMetadata:(GDURLMetadata *)metadata;
- (void)fetchMetadataManager;
- (void)didLoadDirectoryContents;
- (void)didFailToLoadDirectoryContentsWithError:(NSError *)error;
- (void)pushViewControllerForFolderMetadata:(GDURLMetadata *)folderMetadata;
- (GDURLMetadata *)metadataForIndexPath:(NSIndexPath *)indexPath;
- (NSMutableArray *)metadataArrayForSection:(NSUInteger)section;

@end
