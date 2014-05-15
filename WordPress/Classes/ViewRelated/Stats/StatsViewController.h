#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, StatsSection) {
    StatsSectionVisitors,
    StatsSectionTopPosts,
    StatsSectionViewsByCountry,
    StatsSectionTotalsFollowersShares,
    StatsSectionClicks,
    StatsSectionReferrers,
    StatsSectionSearchTerms,
    StatsSectionLinkToWebview,
    StatsSectionTotalCount,
    StatsSectionVisitorsGraph   // Not a real section!
};

@class Blog;

@interface StatsViewController : UITableViewController

@property (nonatomic, weak) Blog *blog;

@end
