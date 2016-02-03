#import "BlogSiteVisibilityHelper.h"
#import "WordPress-Swift.h"

@implementation BlogSiteVisibilityHelper

+ (NSArray *)siteVisibilityValuesForBlog:(Blog *)blog
{
    if ([blog supports:BlogFeaturePrivate]) {
        return @[ @(SiteVisibilityPublic), @(SiteVisibilityHidden), @(SiteVisibilityPrivate) ];
    } else {
        return @[ @(SiteVisibilityPublic), @(SiteVisibilityHidden) ];
    }
}

+ (NSArray *)titlesForSiteVisibilityValues:(NSArray *)values
{
    NSMutableArray *titles = [NSMutableArray array];
    for (NSNumber *value in values) {
        [titles addObject:[self titleForSiteVisibility:[value integerValue]]];
    }
    
    return titles;
}

+ (NSArray *)hintsForSiteVisibilityValues:(NSArray *)values
{
    NSMutableArray *hints = [NSMutableArray array];
    for (NSNumber *value in values) {
        [hints addObject:[self hintTextForSiteVisibility:[value integerValue]]];
    }
    
    return hints;
}

+ (NSString *)titleForSiteVisibility:(SiteVisibility)privacy
{
    switch (privacy) {
        case SiteVisibilityPrivate:
            return NSLocalizedString(@"Private", @"Text for privacy settings: Private");
        case SiteVisibilityHidden:
            return NSLocalizedString(@"Hidden", @"Text for privacy settings: Hidden");
        case SiteVisibilityPublic:
            return NSLocalizedString(@"Public", @"Text for privacy settings: Public");
        case SiteVisibilityUnknown:
            return NSLocalizedString(@"Unknown", @"Text for unknown privacy setting");
    }
}

+ (NSString *)hintTextForSiteVisibility:(SiteVisibility)privacy
{
    switch (privacy) {
        case SiteVisibilityPrivate:
            return NSLocalizedString(@"Your site is only visible to you and users you approve.",
                                     @"Hint for users when private privacy setting is set");
        case SiteVisibilityHidden:
            return NSLocalizedString(@"Your site is visible to everyone, but asks search engines not to index your site.",
                                     @"Hint for users when hidden privacy setting is set");
        case SiteVisibilityPublic:
            return NSLocalizedString(@"Your site is visible to everyone, and it may be indexed by search engines.",
                                     @"Hint for users when public privacy setting is set");
        case SiteVisibilityUnknown:
            return NSLocalizedString(@"Unknown", @"Text for unknown privacy setting");
    }
}

+ (NSString *)titleForCurrentSiteVisibilityOfBlog:(Blog *)blog
{
    if (!blog.settings.privacy) {
        return [self titleForSiteVisibility:SiteVisibilityUnknown];
    }
    
    return [self titleForSiteVisibility:[blog.settings.privacy intValue]];
}

@end
