#import "BlogSiteVisibilityHelper.h"

@implementation BlogSiteVisibilityHelper

+ (NSString *)textForSiteVisibility:(SiteVisibility)privacy
{
    switch (privacy) {
        case SiteVisibilityPrivate:
            return NSLocalizedString(@"Private", @"Text for privacy settings: Private");
            break;
        case SiteVisibilityHidden:
            return NSLocalizedString(@"Hidden", @"Text for privacy settings: Hidden");
            break;
        case SiteVisibilityPublic:
            return NSLocalizedString(@"Public", @"Text for privacy settings: Public");
            break;
        case SiteVisibilityUnknown:
            return NSLocalizedString(@"Unknown", @"Text for unknow privacy setting");
            break;
    }
}

@end
