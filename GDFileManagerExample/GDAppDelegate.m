//
//  GDAppDelegate.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 8/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDAppDelegate.h"
#import "GDFileManagerKit.h"

#import <SSKeychain/SSKeychain.h>

@implementation GDAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [SSKeychain setAccessibilityType:kSecAttrAccessibleAfterFirstUnlock];
    
    // You should change all of these tokens to your own in shipping applications.  They are intended for use only for testing GDFileManagerKit
    
    // This token only has access to the "/Apps/GDFileManager Example" directory of a Dropbox account
    [GDDropboxAPIToken registerTokenWithKey:@"sccmsv40co0yc6s"
                                     secret:@"iaskhoaim99j3om"
                                       root:GDDropboxRootAppFolder];
    
    //
    [GDGoogleDriveAPIToken registerTokenWithKey:@"293490489543.apps.googleusercontent.com"
                                         secret:@"nWi6IQwzLTASHr8H6hhhDI-P"];
    
    [GDSugarSyncAPIToken registerTokenWithKey:@"NTQxMjE1MzEzODExMzM0NjYyOTk"
                                       secret:@"Mjc0Y2Y5YWEzNjZiNGFhZTlmMzEyMzNmNjQ4MzJkOTk"
                                        appID:@"/sc/5412153/436_158384810"];
    
    NSURL *documentsURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    [[GDFileManager sharedManager] addLocalFileServiceSessionForLocalURL:documentsURL name:@"documents"];
    
    GDCoreDataMetadataCache *metadataCache = [GDCoreDataMetadataCache new];
    
    [GDFileManager setSharedMetadataCache:metadataCache];
    [GDFileManager setSharedFileCache:[GDFileManagerDataCacheCoordinator sharedCacheCoordinator]];
    

    // Override point for customization after application launch.
    UIStoryboard *fileBrowserStoryboard = [UIStoryboard storyboardWithName:@"FileBrowser" bundle:nil];
    GDFileServiceSessionListController *serviceController = [fileBrowserStoryboard instantiateInitialViewController];
    
    serviceController.fileListControllerFactory = ^(UIViewController *parent){
        return [[UIStoryboard storyboardWithName:@"GDMasterViewController" bundle:nil] instantiateInitialViewController];
    };
    
    UINavigationController *masterNavController = nil;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
        UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
        splitViewController.delegate = (id)navigationController.topViewController;
        masterNavController = [splitViewController.viewControllers objectAtIndex:0];
    } else {
        masterNavController = (UINavigationController *)self.window.rootViewController;
    }
    
    [masterNavController pushViewController:serviceController animated:NO];
    
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    
    [[GDFileManager sharedFileCache] resumePendingUploads];
    
    return YES;
}

@end
