# GDFileManagerKit

[![Version](http://cocoapod-badges.herokuapp.com/v/GDFileManagerKit/badge.png)](http://cocoadocs.org/docsets/GDFileManagerKit)
[![Platform](http://cocoapod-badges.herokuapp.com/p/GDFileManagerKit/badge.png)](http://cocoadocs.org/docsets/GDFileManagerKit)

GDFileManagerKit lets you access Dropbox, Google Drive, SugarSync and WebDAV with a consistent,
NSFileManager-like API.

Features of GDFileManagerKit include:

* Persistent cached file metadata.  Old metadata is re-validated where possible making API calls more efficient.
* Cached file downloads.
* Chunked upload / downloads where available for reliability in intermittently connected environments.
* Copy/Delete/Move file operations.
* Aliases to keep track of files if the user moves / renames them remotely (requires a file service that supports persistent file identifiers like Google Drive or SugarSync).

While GDFileManagerKit is currently beta-quality software, it is used in my app [PocketBib].

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


See the included `GDFileManagerExample` for details.  To run the demo app, run `pod install`, and then open `GDFileManagerExample.xcworkspace` and build.

More details to come.

## Requirements

iOS 5.0+, various Pods.

## Author

Graham Dennis, graham@grahamdennis.me

## License

GDFileManagerKit is available under the MIT license. See the LICENSE file for more info.  If you require a non-attribution license, please contact me at graham@grahamdennis.me


[PocketBib]: http://itunes.apple.com/app/pocketbib-for-bibtex-bibdesk/id524521749?ls=1&mt=8