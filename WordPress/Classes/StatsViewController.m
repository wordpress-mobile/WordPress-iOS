/*
 * StatsViewController.m
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "StatsViewController.h"
#import "Blog+Jetpack.h"
#import "WordPressAppDelegate.h"
#import "JetpackSettingsViewController.h"
#import "WPAccount.h"
#import "StatsApiHelper.h"
#import "ContextManager.h"
#import "StatsButtonCell.h"
#import "StatsCounterCell.h"
#import "StatsNoResultsCell.h"
#import "StatsViewsVisitorsBarGraphCell.h"
#import "StatsSummary.h"
#import "StatsTitleCountItem.h"
#import "StatsTodayYesterdayButtonCell.h"
#import "StatsTwoColumnCell.h"
#import "StatsGroup.h"
#import "WPNoResultsView.h"

static NSString *const VisitorsUnitButtonCellReuseIdentifier = @"VisitorsUnitButtonCellReuseIdentifier";
static NSString *const TodayYesterdayButtonCellReuseIdentifier = @"TodayYesterdayButtonCellReuseIdentifier";
static NSString *const GraphCellReuseIdentifier = @"GraphCellReuseIdentifier";
static NSString *const CountCellReuseIdentifier = @"DoubleCountCellReuseIdentifier";
static NSString *const TwoLabelCellReuseIdentifier = @"TwoLabelCellReuseIdentifier";
static NSString *const StatSectionHeaderViewIdentifier = @"StatSectionHeaderViewIdentifier";
static NSString *const NoResultsCellIdentifier = @"NoResultsCellIdentifier";
static NSString *const ResultRowCellIdentifier = @"ResultRowCellIdentifier";
static NSString *const GraphCellIdentifier = @"GraphCellIdentifier";
static NSString *const StatsGroupedCellIdentifier = @"StatsGroupedCellIdentifier";

static CGFloat const SectionHeaderPadding = 8.0f;
static NSUInteger const ResultRowMaxItems = 10;
static CGFloat const TableViewFixedWidth = 600.0f;
static CGFloat const HeaderHeight = 44.0f;

typedef NS_ENUM(NSInteger, VisitorsRow) {
    VisitorRowGraphUnitButton,
    VisitorRowGraph,
    VisitorRowTodayStats,
    VisitorRowBestEver,
    VisitorRowAllTime,
    VisitorSectionTotalRows
};

typedef NS_ENUM(NSInteger, StatsDataRow) {
    StatsDataRowButtons,
    StatsDataRowTitle
};

typedef NS_ENUM(NSInteger, TotalFollowersShareRow) {
    TotalFollowersShareRowContentPost,
    TotalFollowersShareRowContentCategoryTag,
    TotalFollowersShareRowFollowers,
    TotalFollowersShareRowShare,
    TotalFollowersShareRowTotalRows
};

@interface StatsViewController () <UITableViewDataSource, UITableViewDelegate, StatsTodayYesterdayButtonCellDelegate>

@property (nonatomic, weak) Blog *blog;
@property (nonatomic, strong) StatsApiHelper *statsApiHelper;
@property (nonatomic, strong) NSMutableDictionary *statModels;
@property (nonatomic, strong) NSMutableDictionary *showingToday;
@property (nonatomic, assign) StatsViewsVisitorsUnit currentViewsVisitorsGraphUnit;
@property (nonatomic, assign) BOOL resultsAvailable;
@property (nonatomic, weak) WPNoResultsView *noResultsView;

@end

@implementation StatsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Stats", nil);
  
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, HeaderHeight, 0);
    [self.tableView registerClass:[UITableViewHeaderFooterView class] forHeaderFooterViewReuseIdentifier:StatSectionHeaderViewIdentifier];
    [self.tableView registerClass:[StatsButtonCell class] forCellReuseIdentifier:VisitorsUnitButtonCellReuseIdentifier];
    [self.tableView registerClass:[StatsTodayYesterdayButtonCell class] forCellReuseIdentifier:TodayYesterdayButtonCellReuseIdentifier];
    [self.tableView registerClass:[StatsViewsVisitorsBarGraphCell class] forCellReuseIdentifier:GraphCellReuseIdentifier];
    [self.tableView registerClass:[StatsCounterCell class] forCellReuseIdentifier:CountCellReuseIdentifier];
    [self.tableView registerClass:[StatsTwoColumnCell class] forCellReuseIdentifier:TwoLabelCellReuseIdentifier];
    [self.tableView registerClass:[StatsNoResultsCell class] forCellReuseIdentifier:NoResultsCellIdentifier];
    [self.tableView registerClass:[StatsTwoColumnCell class] forCellReuseIdentifier:ResultRowCellIdentifier];
    [self.tableView registerClass:[StatsViewsVisitorsBarGraphCell class] forCellReuseIdentifier:GraphCellIdentifier];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshControlTriggered) forControlEvents:UIControlEventValueChanged];
    
    _statModels = [NSMutableDictionary dictionary];
    

    // By default, show data for Today
    _showingToday = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                     @(YES), @(StatsSectionTopPosts),
                     @(YES), @(StatsSectionViewsByCountry),
                     @(YES), @(StatsSectionSearchTerms),
                     @(YES), @(StatsSectionClicks),
                     @(YES), @(StatsSectionReferrers), nil];
    
    _resultsAvailable = NO;

    [self showNoResultsWithTitle:NSLocalizedString(@"No stats to display", nil) message:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    _statModels = nil;
}

- (void)setBlog:(Blog *)blog {
    _blog = blog;
    DDLogInfo(@"Loading Stats for the following blog: %@", [blog url]);
    
    WordPressAppDelegate *appDelegate = [WordPressAppDelegate sharedWordPressApplicationDelegate];
    if (!appDelegate.connectionAvailable) {
        [self showNoResultsWithTitle:NSLocalizedString(@"No Connection", @"") message:NSLocalizedString(@"An active internet connection is required to view stats", @"")];
    } else {
        [self initStats];
    }
}

- (void)initStats {
    if (self.blog.isWPcom) {
        self.statsApiHelper = [[StatsApiHelper alloc] initWithSiteID:_blog.blogID];
        [self loadStats];
        return;
    }
    
    // Jetpack
    BOOL needsJetpackLogin = ![[[WPAccount defaultWordPressComAccount] restApi] hasCredentials];
    if (!needsJetpackLogin && self.blog.jetpackBlogID) {
        self.statsApiHelper = [[StatsApiHelper alloc] initWithSiteID:self.blog.jetpackBlogID];
        [self loadStats];
    } else {
        [self promptForJetpackCredentials];
    }
}

- (void)promptForJetpackCredentials {
    JetpackSettingsViewController *controller = [[JetpackSettingsViewController alloc] initWithBlog:self.blog];
    controller.showFullScreen = NO;
    __weak JetpackSettingsViewController *safeController = controller;
    [controller setCompletionBlock:^(BOOL didAuthenticate) {
        if (didAuthenticate) {
            [safeController.view removeFromSuperview];
            [safeController removeFromParentViewController];
            self.tableView.scrollEnabled = YES;
            [self initStats];
        }
    }];
    
    self.tableView.scrollEnabled = NO;
    [self addChildViewController:controller];
    [self.tableView addSubview:controller.view];
}

- (void)showNoResultsWithTitle:(NSString *)title message:(NSString *)message {
    [_noResultsView removeFromSuperview];
    WPNoResultsView *noResultsView = [WPNoResultsView noResultsViewWithTitle:title message:message accessoryView:nil buttonTitle:nil];
    _noResultsView = noResultsView;
    [self.tableView addSubview:_noResultsView];
}

- (void)hideNoResultsView {
    [_noResultsView removeFromSuperview];
}

- (void)loadStats {
    void (^saveStatsForSection)(id stats, StatsSection section) = ^(id stats, StatsSection section) {
        [_statModels setObject:stats forKey:@(section)];
        if (_resultsAvailable) {
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:UITableViewRowAnimationNone];
            [self.refreshControl endRefreshing];
        }
    };
    void (^failure)(NSError *error) = ^(NSError *error) {
        if (!_resultsAvailable) {
            [self showNoResultsWithTitle:NSLocalizedString(@"Error displaying stats", nil) message:NSLocalizedString(@"Please try again later", nil)];
        } else {
            [self.refreshControl endRefreshing];
        }
        DDLogWarn(@"Stats: Error fetching stats %@", error);
    };
    
    [self.statsApiHelper fetchSummaryWithSuccess:^(StatsSummary *summary) {
        saveStatsForSection(summary, StatsSectionVisitors);
    } failure:failure];
    
    [self.statsApiHelper fetchViewsVisitorsWithSuccess:^(StatsViewsVisitors *viewsVisitors) {
        _statModels[@(StatsSectionVisitorsGraph)] = viewsVisitors;
        if (_resultsAvailable) {
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:StatsSectionVisitors] withRowAnimation:UITableViewRowAnimationNone];
        }
    } failure:failure];

    // Show no results until at least the summary has returned
    [self.statsApiHelper fetchTopPostsWithSuccess:^(NSDictionary *todayAndYesterdayTopPosts) {
        saveStatsForSection(todayAndYesterdayTopPosts, StatsSectionTopPosts);
        _resultsAvailable = YES;
        [self hideNoResultsView];
        [self.tableView reloadData];
    } failure:failure];
    
    [self.statsApiHelper fetchClicksWithSuccess:^(NSDictionary *clicks) {
        saveStatsForSection(clicks, StatsSectionClicks);
    } failure:failure];
    
    [self.statsApiHelper fetchCountryViewsWithSuccess:^(NSDictionary *views) {
        saveStatsForSection(views, StatsSectionViewsByCountry);
    } failure:failure];
    
    [self.statsApiHelper fetchReferrerWithSuccess:^(NSDictionary *referrers) {
        saveStatsForSection(referrers, StatsSectionReferrers);
    } failure:failure];
    
    [self.statsApiHelper fetchSearchTermsWithSuccess:^(NSDictionary *terms) {
        saveStatsForSection(terms, StatsSectionSearchTerms);
    } failure:failure];
}

- (void)refreshControlTriggered {
    [self loadStats];
}

- (BOOL)showingTodayForSection:(StatsSection)section {
    return [_showingToday[@(section)] boolValue];
}

- (NSArray *)resultsForSection:(StatsSection)section {
    NSDictionary *data = _statModels[@(section)];
    if (data) {
        return [self showingTodayForSection:section] ? data[@"today"] : data[@"yesterday"];
    }
    return @[];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _resultsAvailable ? StatsSectionTotalCount : 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (!_resultsAvailable) {
        return 0;
    }
    switch (section) {
        case StatsSectionVisitors:
            return VisitorSectionTotalRows;
        case StatsSectionTotalsFollowersShares:
            return TotalFollowersShareRowTotalRows;
        default:
        {
            NSInteger numberOfResults = [self resultsForSection:section].count;
            return numberOfResults ? 2 + MIN(numberOfResults, ResultRowMaxItems) : 3;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case StatsSectionVisitors:
            switch (indexPath.row) {
                case VisitorRowGraphUnitButton:
                    return [StatsButtonCell heightForRow];
                case VisitorRowGraph:
                    return [StatsViewsVisitorsBarGraphCell heightForRow];
                case VisitorRowTodayStats:
                case VisitorRowBestEver:
                case VisitorRowAllTime:
                    return [StatsCounterCell heightForRow];
                default:
                    return 0.0f;
            }
            break;
        case StatsSectionTotalsFollowersShares:
            return [StatsCounterCell heightForRow];
        case StatsSectionTopPosts:
        case StatsSectionViewsByCountry:
        case StatsSectionClicks:
        case StatsSectionReferrers:
        case StatsSectionSearchTerms:
            switch (indexPath.row) {
                case StatsDataRowButtons:
                    return [StatsButtonCell heightForRow];
                case StatsDataRowTitle:
                    return [StatsTwoColumnCell heightForRow];
                default:
                    return [self resultsForSection:indexPath.section].count > 0 ? [StatsTwoColumnCell heightForRow] : [StatsNoResultsCell heightForRow];
            }
        default:
            return 0.0f;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case StatsSectionVisitors:
            switch (indexPath.row) {
                case VisitorRowGraphUnitButton:
                {
                    StatsButtonCell *cell = [tableView dequeueReusableCellWithIdentifier:VisitorsUnitButtonCellReuseIdentifier];
                    [cell addButtonWithTitle:NSLocalizedString(@"Days", nil) target:self action:@selector(daySelected:) section:indexPath.section];
                    [cell addButtonWithTitle:NSLocalizedString(@"Weeks", nil) target:self action:@selector(weekSelected:) section:indexPath.section];
                    [cell addButtonWithTitle:NSLocalizedString(@"Months", nil) target:self action:@selector(monthSelected:) section:indexPath.section];
                    cell.currentActiveButton = _currentViewsVisitorsGraphUnit;
                    return cell;
                }
                case VisitorRowGraph:
                {
                    StatsViewsVisitorsBarGraphCell *cell = [tableView dequeueReusableCellWithIdentifier:GraphCellIdentifier];
                    [cell setViewsVisitors:_statModels[@(StatsSectionVisitorsGraph)]];
                    [cell showGraphForUnit:_currentViewsVisitorsGraphUnit];
                    return cell;
                }
                case VisitorRowTodayStats:
                {
                    StatsCounterCell *cell = [tableView dequeueReusableCellWithIdentifier:CountCellReuseIdentifier];
                    StatsSummary *summary = _statModels[@(StatsSectionVisitors)];
                    [cell setTitle:NSLocalizedString(@"Today", @"Title for Today cell")];
                    [cell addCount:summary.visitorCountToday withLabel:NSLocalizedString(@"Visitors", @"Visitor label for Today cell")];
                    [cell addCount:summary.viewCountToday withLabel:NSLocalizedString(@"Views", @"View label for Today cell")];
                    return cell;
                }
                case VisitorRowBestEver:
                {
                    StatsCounterCell *cell = [tableView dequeueReusableCellWithIdentifier:CountCellReuseIdentifier];
                    StatsSummary *summary = _statModels[@(StatsSectionVisitors)];
                    [cell setTitle:NSLocalizedString(@"Best Ever", nil)];
                    [cell addCount:summary.viewCountBest withLabel:NSLocalizedString(@"Views", nil)];
                    return cell;
                }
                case VisitorRowAllTime:
                {
                    StatsCounterCell *cell = [tableView dequeueReusableCellWithIdentifier:CountCellReuseIdentifier];
                    StatsSummary *summary = _statModels[@(StatsSectionVisitors)];
                    [cell setTitle:NSLocalizedString(@"All Time", nil)];
                    [cell addCount:summary.totalViews withLabel:NSLocalizedString(@"Views", nil)];
                    [cell addCount:summary.totalComments withLabel:NSLocalizedString(@"Comments", nil)];
                    return cell;
                }
                default:
                    NSAssert(NO, @"There must be a cell.");
            }
            break;
        case StatsSectionTotalsFollowersShares:
            return [self cellForTotalsFollowersSharesRowWithIndex:indexPath.row];
        case StatsSectionTopPosts:
        case StatsSectionViewsByCountry:
        case StatsSectionClicks:
        case StatsSectionReferrers:
        case StatsSectionSearchTerms:
            return [self cellForItemListSection:indexPath.section rowIndex:indexPath.row];
        default:
            return nil;
    }
    NSAssert(NO, @"There must be a cell");
    return nil;
}

- (UITableViewCell *)cellForTotalsFollowersSharesRowWithIndex:(NSInteger)index {
    NSString *title;
    NSString *leftLabel;
    NSNumber *leftCount;
    NSString *rightLabel;
    NSNumber *rightCount;
    
    StatsSummary *summary = _statModels[@(StatsSectionVisitors)];
    
    switch (index) {
        case TotalFollowersShareRowContentPost:
            title = @"Content";
            leftLabel = @"Posts";
            leftCount = summary.totalPosts;
            break;
        case TotalFollowersShareRowContentCategoryTag:
            leftLabel = @"Categories";
            leftCount = summary.totalCatagories;
            rightLabel = @"Tags";
            rightCount = summary.totalTags;
            break;
        case TotalFollowersShareRowFollowers:
            title = @"Followers";
            leftLabel = @"Blog";
            leftCount = summary.totalFollowersBlog;
            rightLabel = @"Comments";
            rightCount = summary.totalFollowersComments;
            break;
        case TotalFollowersShareRowShare:
            title = @"Shares";
            leftLabel = @"Shares";
            leftCount = summary.totalShares;
            break;
    }
    
    StatsCounterCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CountCellReuseIdentifier];
    [cell setTitle:NSLocalizedString(title,@"Title for the data cell")];
    [cell addCount:leftCount withLabel:NSLocalizedString(leftLabel,@"Label for the count")];
    if (rightLabel) {
        [cell addCount:rightCount withLabel:NSLocalizedString(rightLabel,@"Label for the right count")];
    }
    return cell;
}

- (UITableViewCell *)cellForItemListSection:(StatsSection)section rowIndex:(NSInteger)index {
    // Data title header
    NSString *dataTitleRowLeft = NSLocalizedString(@"Title", nil);
    NSString *dataTitleRowRight = NSLocalizedString(@"Views", nil);
    switch (section) {
        case StatsSectionViewsByCountry:
            dataTitleRowLeft = NSLocalizedString(@"Country", nil);
            break;
        case StatsSectionClicks:
            dataTitleRowLeft = NSLocalizedString(@"URL", nil);
            dataTitleRowRight = NSLocalizedString(@"Clicks", nil);
            break;
        case StatsSectionReferrers:
            dataTitleRowLeft = NSLocalizedString(@"Referrers", nil);
            break;
        case StatsSectionSearchTerms:
            dataTitleRowLeft = NSLocalizedString(@"Search", nil);
            break;
        default:
            break;
    }
    
    UITableViewCell *cell;
    switch (index) {
        case StatsDataRowButtons:
        {
            cell = [self.tableView dequeueReusableCellWithIdentifier:TodayYesterdayButtonCellReuseIdentifier];
            [(StatsTodayYesterdayButtonCell *)cell setupForSection:section delegate:self todayActive:[self showingTodayForSection:section]];
            break;
        }
        case StatsDataRowTitle:
        {
            cell = [self.tableView dequeueReusableCellWithIdentifier:TwoLabelCellReuseIdentifier];
            [(StatsTwoColumnCell *)cell setLeft:dataTitleRowLeft.uppercaseString withImageUrl:nil right:dataTitleRowRight.uppercaseString titleCell:YES];
            break;
        }
        default:
        {
            if ([self resultsForSection:section].count == 0) {
                cell = [self.tableView dequeueReusableCellWithIdentifier:NoResultsCellIdentifier];
                [(StatsNoResultsCell *)cell configureForSection:section];
            } else {
                cell = [self.tableView dequeueReusableCellWithIdentifier:ResultRowCellIdentifier];
                [(StatsTwoColumnCell *)cell insertData:[self resultsForSection:section][index-2]];
                
            }
        }
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return HeaderHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = [tableView dequeueReusableHeaderFooterViewWithIdentifier:StatSectionHeaderViewIdentifier];
    [header.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    header.contentView.backgroundColor = [WPStyleGuide itsEverywhereGrey];
    
    CGFloat headerLeftPadding = SectionHeaderPadding;
    if (IS_IPAD) {
        headerLeftPadding = (self.view.frame.size.width - TableViewFixedWidth)/2;
    }
    CGFloat lineHeight = [[WPStyleGuide postTitleAttributes][NSParagraphStyleAttributeName] maximumLineHeight];
    UILabel *sectionName = [[UILabel alloc] initWithFrame:CGRectMake(headerLeftPadding, HeaderHeight - (lineHeight + SectionHeaderPadding), 0, lineHeight)];
    sectionName.textColor = [WPStyleGuide littleEddieGrey];
    sectionName.backgroundColor = [WPStyleGuide itsEverywhereGrey];
    sectionName.opaque = YES;
    sectionName.font = [WPStyleGuide postTitleFont];
    
    NSString *text;
    switch (section) {
        case StatsSectionVisitors:
            text = @"Visitors and Views";
            break;
        case StatsSectionTopPosts:
            text = @"Top Posts";
            break;
        case StatsSectionViewsByCountry:
            text = @"Views By Country";
            break;
        case StatsSectionTotalsFollowersShares:
            text = @"Totals, Followers & Shares";
            break;
        case StatsSectionClicks:
            text = @"Clicks";
            break;
        case StatsSectionReferrers:
            text = @"Referrers";
            break;
        case StatsSectionSearchTerms:
            text = @"Search Engine Terms";
            break;
        default:
            text = @"";
            break;
    }
    sectionName.text = NSLocalizedString(text, nil);
    [sectionName sizeToFit];
    [header.contentView addSubview:sectionName];
    return header;
}


#pragma mark - StatsTodayYesterdayButtonCellDelegate

- (void)statsDayChangedForSection:(StatsSection)section todaySelected:(BOOL)todaySelected {
    [_showingToday setObject:@(todaySelected) forKey:@(section)];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:UITableViewRowAnimationFade];
}


#pragma mark - Visitors Graph button selectors

- (void)graphUnitSelected:(StatsViewsVisitorsUnit)unit {
    _currentViewsVisitorsGraphUnit = unit;
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:StatsSectionVisitors] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)daySelected:(UIButton *)sender {
    [self graphUnitSelected:StatsViewsVisitorsUnitDay];
}

- (void)weekSelected:(UIButton *)sender {
    [self graphUnitSelected:StatsViewsVisitorsUnitWeek];
}

- (void)monthSelected:(UIButton *)sender {
    [self graphUnitSelected:StatsViewsVisitorsUnitMonth];
}

@end
