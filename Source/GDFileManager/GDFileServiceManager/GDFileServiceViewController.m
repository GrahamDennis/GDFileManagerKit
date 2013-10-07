//
//  GDFileServiceViewController.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 2/03/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDFileServiceViewController.h"
#import "GDFileServiceManager.h"
#import "GDFileService.h"
#import "GDRemoteFileService.h"
#import "GDFileManagerResourceBundle.h"

#import "GDImageCell.h"

@interface GDFileServiceViewController ()

@property (nonatomic, readonly) NSArray *fileServices;

- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath;

@end

@implementation GDFileServiceViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    return [self initWithFileServiceManager:nil];
}

- (id)initWithFileServiceManager:(GDFileServiceManager *)fileServiceManager
{
    if ((self = [super initWithStyle:UITableViewStyleGrouped])) {
        if (!fileServiceManager) fileServiceManager = [GDFileServiceManager sharedManager];
        
        self.fileServiceManager = fileServiceManager;
        self.navigationItem.title = @"Add Account…";
        self.definesPresentationContext = YES;
        self.providesPresentationContextTransitionStyle = YES;
        self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    }
    
    return self;
}

- (void)setFileServiceManager:(GDFileServiceManager *)fileServiceManager
{
    _fileServiceManager = fileServiceManager;

    NSMutableArray *fileServices = [[fileServiceManager allFileServices] mutableCopy];
    [fileServices filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(GDFileService *service, NSDictionary *bindings) {
        return [service isKindOfClass:[GDRemoteFileService class]];
    }]];
    
    [fileServices sortUsingComparator:^NSComparisonResult(GDFileService *service1, GDFileService *service2) {
        return [service1.name compare:service2.name];
    }];
    
    _fileServices = [fileServices copy];
    
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *nibName = NSStringFromClass([GDImageCell class]);
    [self.tableView registerNib:[UINib nibWithNibName:nibName bundle:GDFileManagerResourcesBundle()] forCellReuseIdentifier:nibName];
    self.tableView.rowHeight = 70.0;
}

- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    NSParameterAssert([cell isKindOfClass:[GDImageCell class]]);
    
    GDImageCell *imageCell = (GDImageCell *)cell;
    if (indexPath.row >= [self.fileServices count]) {
        NSParameterAssert(false);
        return;
    }
    GDFileService *fileService = self.fileServices[indexPath.row];
    imageCell.imageView.image = fileService.logoImage;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.fileServices count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ cellIdentifier = NSStringFromClass([GDImageCell class]); });
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    // Configure the cell...
    [self configureCell:cell forIndexPath:indexPath];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    if (indexPath.row >= [self.fileServices count]) {
        NSParameterAssert(false);
        return;
    }

    GDFileService *fileService = self.fileServices[indexPath.row];
    [fileService linkFromController:self
                            success:^(GDFileServiceSession *fileServiceSession) {
                                NSLog(@"fileServiceSession: %@", fileServiceSession);
                                
                                if ([self.delegate respondsToSelector:@selector(fileServiceViewController:didAddFileServiceSession:)]) {
                                    [self.delegate fileServiceViewController:self didAddFileServiceSession:fileServiceSession];
                                }
                            } failure:^(NSError *error) {
                                NSLog(@"Error: %@", error);
                                
                                if ([self.delegate respondsToSelector:@selector(fileServiceViewController:didFailWithError:)]) {
                                    [self.delegate fileServiceViewController:self didFailWithError:error];
                                }
                            }];
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

@end
