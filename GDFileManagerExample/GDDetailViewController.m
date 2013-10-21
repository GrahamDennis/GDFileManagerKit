//
//  GDDetailViewController.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 8/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDDetailViewController.h"
#import "GDFileManagerKit.h"
#import <QuickLook/QuickLook.h>

@interface GDDetailViewController () <UIDocumentInteractionControllerDelegate>
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@property (strong, nonatomic) GDFileManagerDownloadOperation *downloadOperation;
@property (nonatomic) BOOL waitForAppear;

- (void)configureView;
@end

@implementation GDDetailViewController

@synthesize fileManager = _fileManager;

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem waitForAppear:(BOOL)waitForAppear
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        _waitForAppear = waitForAppear;
        // Update the view.
        [self configureView];
    }

    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }        
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (_waitForAppear) {
        // Begin the download operation on appear
        if (self.downloadOperation) {
            [self.fileManager enqueueFileManagerOperation:self.downloadOperation];
        }
        _waitForAppear = NO;
    }
    
}

- (void)willMoveToParentViewController:(UIViewController *)parent
{
    [super willMoveToParentViewController:parent];
    
    if (parent == nil) {
        // we are being removed, cancel our download operation
        [self.downloadOperation cancel];
    }
}

- (void)configureView
{
    // Update the user interface for the detail item.

    if (self.detailItem && [self isViewLoaded]) {
        self.detailDescriptionLabel.text = [self.detailItem.url absoluteString];
        self.navigationItem.title = self.detailItem.filename;
        
        [self.downloadOperation cancel];
        self.downloadOperation = nil;
        
        if ([self.detailItem isDirectory]) {
            [self.downloadProgressView setHidden:YES];
        } else {
            [self.downloadProgressView setProgress:0.0 animated:NO];
            [self.downloadProgressView setHidden:NO];
            
            GDFileManager *fileManager = self.fileManager;
            
            
            __weak typeof(self) weakSelf = self;
            
            self.downloadOperation = [fileManager cachedDownloadOperationFromSourceURL:self.detailItem.url
                                                                               success:^(NSURL *localURL, GDURLMetadata *metadata) {
                                                                                   weakSelf.downloadOperation = nil;
                                                                                   NSLog(@"success: %@; metadata = %@", localURL, metadata);
                                                                                   UIDocumentInteractionController *interactionController = [UIDocumentInteractionController interactionControllerWithURL:localURL];
                                                                                   interactionController.delegate = self;
                                                                                   [interactionController presentPreviewAnimated:YES];
                                                                                   
                                                                               } failure:^(NSError *error) {
                                                                                   weakSelf.downloadOperation = nil;
                                                                                   if ([[error domain] isEqualToString:NSURLErrorDomain] && [error code] == NSURLErrorCancelled) {
                                                                                   } else
                                                                                       NSLog(@"download failed: %@", error);
                                                                               }];
            
            [self.downloadOperation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
                CGFloat progressFraction = ((CGFloat)totalBytesRead)/((CGFloat)totalBytesExpectedToRead);
                
                [weakSelf.downloadProgressView setProgress:progressFraction animated:YES];
            }];
            
            if (!self.waitForAppear) {
                [self.fileManager enqueueFileManagerOperation:self.downloadOperation];
            }

        }
        
        
    }
}

- (GDFileManager *)fileManager
{
    return _fileManager ?: [GDFileManager sharedManager];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self configureView];
}

#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Master", @"Master");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}


#pragma mark - UIDocumentInteractionControllerDelegate

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller
{
    return self.navigationController;
}
@end
