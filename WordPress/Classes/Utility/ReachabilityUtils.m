#import "ReachabilityUtils.h"
#import "WordPressAppDelegate.h"
#import "WordPress-Swift.h"

@import WordPressUI;


@implementation ReachabilityUtils

+ (BOOL)isInternetReachable
{
    WordPressAppDelegate *appDelegate = (WordPressAppDelegate *) [[UIApplication sharedApplication] delegate];
    return appDelegate.connectionAvailable;
}

+ (NSString *)noConnectionMessage
{
    return NSLocalizedString(@"The Internet connection appears to be offline.", @"");
}

@end
