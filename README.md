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

# Donate

<form action="https://www.paypal.com/cgi-bin/webscr" method="post" target="_top">
<input type="hidden" name="cmd" value="_s-xclick">
<input type="hidden" name="encrypted" value="-----BEGIN PKCS7-----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-----END PKCS7-----
">
<input type="image" src="https://www.paypalobjects.com/en_AU/i/btn/btn_donateCC_LG.gif" border="0" name="submit" alt="PayPal — The safer, easier way to pay online.">
<img alt="" border="0" src="https://www.paypalobjects.com/en_AU/i/scr/pixel.gif" width="1" height="1">
</form>


[PocketBib]: http://itunes.apple.com/app/pocketbib-for-bibtex-bibdesk/id524521749?ls=1&mt=8