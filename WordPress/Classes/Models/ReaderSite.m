#import "ReaderSite.h"
#import "WPAccount.h"

@implementation ReaderSite

@dynamic recordID;
@dynamic siteID;
@dynamic feedID;
@dynamic name;
@dynamic path;
@dynamic icon;
@dynamic isSubscribed;
@dynamic account;

- (BOOL)isFeed
{
    return [self.feedID integerValue] > 0 ? YES : NO;
}

@end
