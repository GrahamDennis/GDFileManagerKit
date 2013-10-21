//
//  GDMasterViewController.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 8/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDFileListViewController.h"

#import "GDFileManagerKit.h"

static NSComparator metadataComparator = ^NSComparisonResult(GDURLMetadata *metadata1, GDURLMetadata *metadata2){
    NSComparisonResult result = [metadata1.filename localizedStandardCompare:metadata2.filename];
    if (result == NSOrderedSame)
        result = [[metadata1.canonicalURL absoluteString] compare:[metadata2.canonicalURL absoluteString]];
    return result;
};


@interface GDFileListViewController ()


@end

@implementation GDFileListViewController

- (void)awakeFromNib
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
    }
    self.folders = [NSMutableArray new];
    self.files = [NSMutableArray new];
    if (!self.fileManager) {
        self.fileManager = [GDFileManager new];
    }
    
    [super awakeFromNib];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.url) {
        GDFileServiceSession *session = [self.fileManager fileServiceSessionForURL:self.url];
        GDFileService *service = [session fileService];
        
        self.navigationItem.title = [service name];
        
        [self fetchMetadataManager];
    }
    if (self.metadata) {
        self.navigationItem.title = [self.metadata filename];
    }
}

- (GDURLMetadata *)metadataForIndexPath:(NSIndexPath *)indexPath
{
    NSArray *array = [self metadataArrayForSection:indexPath.section];
    if ([array count] <= indexPath.row) return nil;
    return array[indexPath.row];
}

- (NSMutableArray *)metadataArrayForSection:(NSUInteger)section
{
    return section == 0 ? self.folders : self.files;
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self metadataArrayForSection:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];

    GDURLMetadata *metadata = [self metadataForIndexPath:indexPath];
    cell.textLabel.text = [metadata filename];
    if (indexPath.section == 0)
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    else
        cell.accessoryType = UITableViewCellAccessoryNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    GDURLMetadata *object = [self metadataForIndexPath:indexPath];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self didSelectFileMetadata:object];
    }
    
    if ([object isDirectory]) {
        [self pushViewControllerForFolderMetadata:object];
    } else {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            [self didSelectFileMetadata:object];
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)pushViewControllerForFolderMetadata:(GDURLMetadata *)folderMetadata
{
    if (![folderMetadata isDirectory]) return;
    GDFileListViewController *childFolderController = nil;
    if (self.fileListControllerFactory) {
        childFolderController = self.fileListControllerFactory(self);
        childFolderController.fileListControllerFactory = self.fileListControllerFactory;
    } else {
        childFolderController = [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([self class])];
    }
    childFolderController.metadata = folderMetadata;
    childFolderController.url = folderMetadata.url;
    childFolderController.fileManager = self.fileManager;
    
    [self.navigationController pushViewController:childFolderController animated:YES];
    
}

#pragma mark - Metadata

- (void)fetchMetadataManager
{
    [self.fileManager getContentsOfDirectoryAtURL:self.url success:^(NSArray *contents) {
        [self.folders removeAllObjects];
        [self.files removeAllObjects];
        for (GDURLMetadata *metadata in contents) {
            NSMutableArray *array = [metadata isDirectory] ? self.folders : self.files;
            [array addObject:metadata];
        }
        
        [self.folders sortUsingComparator:metadataComparator];
        [self.files sortUsingComparator:metadataComparator];
        
        [self didLoadDirectoryContents];
    } failure:^(NSError *error) {
        [self didFailToLoadDirectoryContentsWithError:error];
        NSLog(@"error: %@", error);
    }];
}

- (void)didSelectFileMetadata:(GDURLMetadata *)metadata
{
    
}

- (void)didLoadDirectoryContents
{
    [self.tableView reloadData];
}

- (void)didFailToLoadDirectoryContentsWithError:(NSError *)error
{
    
}

@end
