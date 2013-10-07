//
//  GDMasterViewController.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 8/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDMasterViewController.h"

#import "GDDetailViewController.h"

#import "GDFileManagerKit.h"

static NSComparator metadataComparator = ^NSComparisonResult(GDURLMetadata *metadata1, GDURLMetadata *metadata2){
    NSComparisonResult result = [metadata1.filename localizedStandardCompare:metadata2.filename];
    if (result == NSOrderedSame)
        result = [[metadata1.canonicalURL absoluteString] compare:[metadata2.canonicalURL absoluteString]];
    return result;
};


@implementation GDMasterViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.detailViewController = (GDDetailViewController *)[[self.splitViewController.viewControllers lastObject] viewControllers][0];
}

#pragma mark - Table View

- (void)didSelectFileMetadata:(GDURLMetadata *)metadata
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.detailViewController.fileManager = self.fileManager;
        UINavigationController *navController = [self.splitViewController.viewControllers lastObject];
        
        BOOL waitForAppear = ![[navController topViewController] isKindOfClass:[GDDetailViewController class]];
        [self.detailViewController setDetailItem:metadata waitForAppear:waitForAppear];
        if (waitForAppear) {
            [(UINavigationController *)[self.splitViewController.viewControllers lastObject] popToRootViewControllerAnimated:YES];
        }
    } else {
        GDDetailViewController *detailViewController = [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([GDDetailViewController class])];
        detailViewController.fileManager = self.fileManager;
        [detailViewController setDetailItem:metadata waitForAppear:YES];
        detailViewController.navigationItem.title = [metadata filename];
        [self.navigationController pushViewController:detailViewController animated:YES];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    
}

#pragma mark - File upload

- (IBAction)uploadFile:(id)sender
{
    NSURL *sourceURL = [[NSBundle mainBundle] URLForResource:@"FileToUpload" withExtension:@"txt"];
    
    GDFileManagerUploadOperation *uploadOperation = [self.fileManager persistentUploadOperationFromSourceFileURL:sourceURL options:GDFileManagerUploadNewVersionsCancelOld
                                                                                                         success:^(GDURLMetadata *metadata, NSArray *conflicts) {
                                                                                                             NSLog(@"upload success: %@ conflicts = %@", metadata, conflicts);
                                                                                                             [self fetchMetadataManager];
                                                                                                         } failure:^(NSError *error) {
                                                                                                             NSLog(@"Upload failed: %@", error);
                                                                                                         }];
    
    [uploadOperation createNewFileWithFilename:@"Upload test.txt" mimeType:@"text/plain" parentFolderURL:self.url];
    
    [self.fileManager enqueueFileManagerOperation:uploadOperation];
}

@end
