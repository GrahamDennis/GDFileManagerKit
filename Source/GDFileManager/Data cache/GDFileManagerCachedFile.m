#import "GDFileManagerCachedFile.h"

#define DDLogWarn   NSLog

@interface GDFileManagerCachedFile ()

// Private interface goes here.

@end


@implementation GDFileManagerCachedFile

// Custom logic goes here.

- (NSURL *)sourceURL { return [NSURL URLWithString:self.sourceURLString]; }
- (void)setSourceURL:(NSURL *)sourceURL { [self setSourceURLString:[sourceURL absoluteString]]; }

- (NSDictionary *)metadataDictionary
{
    NSError *error = nil;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:self.metadataJSONData options:0 error:&error];
    if (error) {
        NSLog(@"Error decoding JSON: %@", error);
        return nil;
    }
    if (![jsonObject isKindOfClass:[NSDictionary class]]) {
        NSLog(@"json didn't decode to a dictionary");
        return nil;
    }
    return jsonObject;
}

- (void)setMetadataDictionary:(NSDictionary *)metadataDictionary
{
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:metadataDictionary options:0 error:&error];
    if (error) {
        NSLog(@"error encoding JSON dictionary: %@", error);
        return;
    }
    self.metadataJSONData = jsonData;
}

@end
