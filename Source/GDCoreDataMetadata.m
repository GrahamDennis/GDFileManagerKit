#import "GDCoreDataMetadata.h"


@interface GDCoreDataMetadata ()

// Private interface goes here.

@end


@implementation GDCoreDataMetadata

// Custom logic goes here.

- (NSDictionary *)jsonDictionary
{
    NSError *error = nil;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:self.jsonData options:0 error:&error];
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

- (void)setJsonDictionary:(NSDictionary *)jsonDictionary
{
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDictionary options:0 error:&error];
    if (error) {
        NSLog(@"error encoding JSON dictionary: %@", error);
        return;
    }
    self.jsonData = jsonData;
}

@end
