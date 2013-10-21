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

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

static NSString *const GDURLMetadataPasteboardType = @"GDURLMetadataPasteboardType";

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if (action == @selector(copy:)) {
        return YES;
    } else if (action == @selector(paste:)) {
        GDURLMetadata *metadata = [self metadataForIndexPath:indexPath];
        return [metadata isDirectory] && [[UIPasteboard generalPasteboard] dataForPasteboardType:GDURLMetadataPasteboardType];
    }
    
    return NO;
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if (action == @selector(copy:)) {
        GDURLMetadata *metadata = [self metadataForIndexPath:indexPath];
        [[UIPasteboard generalPasteboard] setURL:metadata.url];
        [[UIPasteboard generalPasteboard] setData:[NSKeyedArchiver archivedDataWithRootObject:metadata] forPasteboardType:GDURLMetadataPasteboardType];
    } else if (action == @selector(paste:)) {
        NSData *sourceMetadataData = [[UIPasteboard generalPasteboard] dataForPasteboardType:GDURLMetadataPasteboardType];
        if (!sourceMetadataData) return;
        GDURLMetadata *sourceMetadata = [NSKeyedUnarchiver unarchiveObjectWithData:sourceMetadataData];
        if (!sourceMetadata) return;
        GDURLMetadata *destinationMetadata = [self metadataForIndexPath:indexPath];
        [self.fileManager copyFileAtURL:sourceMetadata.url toParentURL:destinationMetadata.url name:sourceMetadata.filename success:^(GDURLMetadata *metadata) {
            NSLog(@"Successfully copied to url: %@; metadata: %@", metadata.url, metadata);
        } failure:^(NSError *error) {
            NSLog(@"error copying: %@", error);
        }];
    }
}

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

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        GDURLMetadata *metadata = [self metadataForIndexPath:indexPath];
        NSURL *url = metadata.url;
        [self.fileManager deleteURL:url
                            success:^{
                                // Everything is OK...
                            } failure:^(NSError *error) {
                                NSLog(@"failed to delete due to error: %@", error);
                                // We assumed that the deletion would work, but it didn't.
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    NSMutableArray *array = [self metadataArrayForSection:indexPath.section];
                                    NSUInteger index = [array indexOfObject:metadata
                                                              inSortedRange:NSMakeRange(0, [array count])
                                                                    options:NSBinarySearchingInsertionIndex
                                                            usingComparator:metadataComparator];
                                    [tableView beginUpdates];
                                    [array insertObject:metadata atIndex:index];
                                    [tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:indexPath.section]]
                                                     withRowAnimation:UITableViewRowAnimationAutomatic];
                                    [tableView endUpdates];
                                });
                            }];
        [tableView beginUpdates];
        [[self metadataArrayForSection:indexPath.section] removeObjectIdenticalTo:metadata];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [tableView endUpdates];
    }
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
