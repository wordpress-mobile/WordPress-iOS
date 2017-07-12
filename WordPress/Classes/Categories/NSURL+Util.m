#import "NSURL+Util.h"
#import "Constants.h"
#import <WordPressShared/NSString+Util.h>
@import WordPressShared;

@implementation NSURL (Util)

- (BOOL)isWordPressDotComUrl
{
    return [self.absoluteString isWordPressComPath];
}

- (NSURL *)ensureSecureURL
{
    NSString *url = [self absoluteString];
    return [NSURL URLWithString:[url stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"]];
}

@end
