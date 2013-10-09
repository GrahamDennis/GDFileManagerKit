//
//  GDFileServiceSessionListController.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 31/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDFileServiceSessionListController.h"

#import "GDFileServiceManager.h"
#import "GDFileService.h"
#import "GDFileServiceSession.h"
#import "GDFileListViewController.h"
#import "GDFileServiceViewController.h"

#import "GDFileManager.h"

#import "GDWebLoginController.h"

#import "GDFileManagerResourceBundle.h"

@interface GDFileServiceSessionListController () <GDFileServiceViewControllerDelegate>

- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath;

- (void)updateTableData;

@property (nonatomic, copy) NSArray *tableData;

@end

@implementation GDFileServiceSessionListController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (nibNameOrNil == nil) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"FileBrowser" bundle:GDFileManagerResourcesBundle()];
        self = [storyboard instantiateInitialViewController];
    } else {
        self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.fileServiceManager = [GDFileServiceManager sharedManager];
    if (!self.fileManager)
        self.fileManager = [GDFileManager new];
//    self.fileManager.defaultCachePolicy = GDFileManagerReturnCacheDataElseLoad;
    
    [self updateTableData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    if ([self presentingViewController]) {
        // If we are being presented, then we should have a cancel button.
        UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
        self.navigationItem.leftBarButtonItem = cancelItem;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateTableData];
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    
//    GDWebLoginController *loginController = [[GDWebLoginController alloc] initWithURL:[NSURL URLWithString:@"http://www.google.com/"]];
//    
//    [loginController setCallbackURL:[NSURL URLWithString:@"http://www.grahamdennis.me"]
//                            success:^(NSURL *callbackURL) {
//                                NSLog(@"success with callback: %@", callbackURL);
//                            } failure:^{
//                                NSLog(@"failure with error");
//                            }];
//    
//    [loginController presentFromViewController:self];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)cancel:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [self.tableData count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section < [self.tableData count]) {
        return [self.tableData[section] count];
    } else {
        return 0;
    }
}

//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
//{
//    GDFileServiceSession *session = [self.tableData[section] lastObject];
//    return session.fileService.urlScheme;
//}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ServiceSessionCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    [self configureCell:cell forIndexPath:indexPath];
    
    return cell;
}

- (void)updateTableData
{
    NSArray *fileServices = [[self.fileServiceManager allFileServices] sortedArrayUsingComparator:^NSComparisonResult(GDFileService *service1, GDFileService *service2) {
        return [service1.urlScheme compare:service2.urlScheme];
    }];
    
    NSMutableArray *result = [NSMutableArray new];
    for (GDFileService *fileService in fileServices) {
        NSArray *fileServiceSessions = [[fileService.fileServiceSessions filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(GDFileServiceSession *session, NSDictionary *bindings) {
            return [session isUserVisible];
        }]] sortedArrayUsingComparator:^NSComparisonResult(GDFileServiceSession *session1, GDFileServiceSession *session2) {
            return [[session1.baseURL absoluteString] compare:[session2.baseURL absoluteString]];
        }];
        if (fileServiceSessions)
            [result addObject:fileServiceSessions];
    }
    
    self.tableData = [result copy];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    GDFileServiceSession *session = self.tableData[indexPath.section][indexPath.row];
    
    NSURL *rootURL = [session canonicalURLForURL:[session baseURL]];
    GDFileListViewController *directoryViewController = nil;
    if (self.fileListControllerFactory) {
        directoryViewController = self.fileListControllerFactory(self);
        directoryViewController.fileListControllerFactory = self.fileListControllerFactory;
    }
    if (!directoryViewController) {
        directoryViewController = [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([GDFileListViewController class])];
    }
    directoryViewController.fileManager = self.fileManager;
    directoryViewController.url = rootURL;
    
    [self.navigationController pushViewController:directoryViewController animated:YES];
    
}

- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    GDFileServiceSession *session = self.tableData[indexPath.section][indexPath.row];
    
    cell.textLabel.text = [session userDescription] ?: [session.fileService name];
    if ([self.tableData[indexPath.section] count] > 1) {
        cell.detailTextLabel.text = [session detailDescription];
        cell.detailTextLabel.textColor = [UIColor grayColor];
    } else {
        cell.detailTextLabel.text = nil;
    }
    cell.imageView.image = [session.fileService iconImage];
}

- (void)addButtonTapped:(id)sender
{
    GDFileServiceViewController *fileServiceViewController = [GDFileServiceViewController new];
    
    fileServiceViewController.delegate = self;
    
    [self.navigationController pushViewController:fileServiceViewController animated:YES];
    
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        GDFileServiceSession *session = self.tableData[indexPath.section][indexPath.row];
        GDFileService *fileService = [session fileService];
        [fileService unlinkSession:session];
        [self updateTableData];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)popFileServiceViewController
{
    if ([[self.navigationController topViewController] isKindOfClass:[GDFileServiceViewController class]]) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - GDFileServiceViewControllerDelegate

- (void)fileServiceViewController:(GDFileServiceViewController *)fileServiceViewController didAddFileServiceSession:(GDFileServiceSession *)session
{
    [self popFileServiceViewController];
}

- (void)fileServiceViewController:(GDFileServiceViewController *)fileServiceViewController didFailWithError:(NSError *)error
{
//    [self popFileServiceViewController];
}

@end
