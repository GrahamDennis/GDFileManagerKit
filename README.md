# GDFileManagerKit

[![Version](http://cocoapod-badges.herokuapp.com/v/GDFileManagerKit/badge.png)](http://cocoadocs.org/docsets/GDFileManagerKit)
[![Platform](http://cocoapod-badges.herokuapp.com/p/GDFileManagerKit/badge.png)](http://cocoadocs.org/docsets/GDFileManagerKit)

Fed up with different/inconsistent/non-existent SDKs for cloud file storage services?  Try GDFileManagerKit! GDFileManagerKit lets you access Dropbox, Google Drive, SugarSync and WebDAV with a consistent, NSFileManager-like API.

Features of GDFileManagerKit include:

* Persistent cached file metadata.  Old metadata is re-validated where possible making API calls more efficient.
* Cached file downloads.
* Chunked upload / downloads where available for reliability in intermittently connected environments.
* Copy/Delete/Move file operations.
* Aliases to keep track of files if the user moves / renames them remotely (requires a file service that supports persistent file identifiers like Google Drive or SugarSync).

GDFileManagerKit is currently beta-quality software, but I am using it in my app [PocketBib].  See my [blog post][blog-post] for details.

## Screenshots

File service list.  To add an account, tap the 'plus' button.
[![FileServiceList](http://www.grahamdennis.me/images/gdfilemanagerkit/file-service-list-small.png)](http://www.grahamdennis.me/images/gdfilemanagerkit/file-service-list.png)

Adding an account...

[![AddAccount](http://www.grahamdennis.me/images/gdfilemanagerkit/add-account-small.png)](http://www.grahamdennis.me/images/gdfilemanagerkit/add-account.png)

Downloading a file. (To upload a test file, tap the 'plus' button in the left navigation bar).

[![DownloadingFile](http://www.grahamdennis.me/images/gdfilemanagerkit/downloading-file-small.png)](http://www.grahamdennis.me/images/gdfilemanagerkit/downloading-file.png)


## Usage

Get the contents of a directory:

    [[GDFileManager sharedManager] getContentsOfDirectoryAtURL:url success:^(NSArray *contents) {
        for (GDURLMetadata *metadata in contents) {
            NSLog(@"Found %@ called \"%@\"", [metadata isDirectory] ? @"folder" : @"file", metadata.filename);
        }
    
    } failure:^(NSError *error) {
        NSLog(@"error: %@", error);
    }];

Check the local cache for the file, download it if it has been updated, and cache the result:

    GDFileManager *fileManager = [GDFileManager new];
    GDFileManagerDownloadOperation *downloadOperation = [fileManager cachedDownloadOperationFromSourceURL:url
                                                                       success:^(NSURL *localURL, GDURLMetadata *metadata) {
                                                                           NSLog(@"success: %@; metadata = %@", localURL, metadata);
                                                                       } failure:^(NSError *error) {
                                                                           if ([[error domain] isEqualToString:NSURLErrorDomain] && [error code] == NSURLErrorCancelled) {
                                                                           } else
                                                                               NSLog(@"download failed: %@", error);
                                                                       }];
    [fileManager enqueueFileManagerOperation:downloadOperation];

To set your Dropbox API key:

    [GDDropboxAPIToken registerTokenWithKey:@"<dropbox_key>"
                                     secret:@"<dropbox_secret>"
                                       root:GDDropboxRootDropbox]; // This token has access to the entire dropbox folder

See the included `GDFileManagerExample` for more examples.  To run the demo app, run `pod install`, and then open `GDFileManagerExample.xcworkspace` and build.

## Requirements

iOS 5.0+, uses a number of external libraries including AFNetworking 1.x, SSKeychain, AFOAuth2Client.

## Installation

GDFileManagerKit is available through [CocoaPods](http://cocoapods.org), to install
it simply add the following line to your `Podfile`:

    pod "GDFileManagerKit"


## Author

Graham Dennis, graham@grahamdennis.me

## License

GDFileManagerKit is available under the MIT license. See the LICENSE file for more info.  If you require a non-attribution license, please contact me at graham@grahamdennis.me


[PocketBib]: http://itunes.apple.com/app/pocketbib-for-bibtex-bibdesk/id524521749?ls=1&mt=8
[blog-post]: http://www.grahamdennis.me/blog/2013/10/12/gdfilemanagerkit-a-consistent-ios-api-for-cloud-file-storage-services/