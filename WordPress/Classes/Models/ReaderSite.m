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
    return [self.siteID integerValue] == 0 ? YES : NO;
}

- (NSString *)nameForDisplay
{
    if ([self.path isEqualToString:self.name]) {
        return [[self.name componentsSeparatedByString:@"://"] lastObject];
    }
    return [self.name capitalizedStringWithLocale:[NSLocale systemLocale]];
}

- (NSString *)pathForDisplay
{
    return [[self.path componentsSeparatedByString:@"://"] lastObject];
}

@end
