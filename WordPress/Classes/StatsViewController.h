/*
 * StatsViewController.h
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

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
    StatsSectionVisitorsGraph
};

@class Blog;

@interface StatsViewController : UITableViewController

@property (nonatomic, weak) Blog *blog;

@end
