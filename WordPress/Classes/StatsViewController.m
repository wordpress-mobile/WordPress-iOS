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
#import "WPTableViewSectionHeaderView.h"
#import "StatsGroup.h"
#import "WPNoResultsView.h"

static NSString *const VisitorsUnitButtonCellReuseIdentifier = @"VisitorsUnitButtonCellReuseIdentifier";
static NSString *const TodayYesterdayButtonCellReuseIdentifier = @"TodayYesterdayButtonCellReuseIdentifier";
static NSString *const GraphCellReuseIdentifier = @"GraphCellReuseIdentifier";
static NSString *const CountCellReuseIdentifier = @"DoubleCountCellReuseIdentifier";
static NSString *const NoResultsCellIdentifier = @"NoResultsCellIdentifier";
static NSString *const ResultRowCellIdentifier = @"ResultRowCellIdentifier";
static NSString *const GraphCellIdentifier = @"GraphCellIdentifier";
static NSString *const StatsGroupedCellIdentifier = @"StatsGroupedCellIdentifier";

static CGFloat const SectionHeaderPadding = 8.0f;
static NSUInteger const ResultRowMaxItems = 10;
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

@property (nonatomic, strong) StatsApiHelper *statsApiHelper;
@property (nonatomic, strong) NSMutableDictionary *statModels;
@property (nonatomic, strong) NSMutableDictionary *showingToday;
@property (nonatomic, assign) StatsViewsVisitorsUnit currentViewsVisitorsGraphUnit;
@property (nonatomic, assign) BOOL resultsAvailable;
@property (nonatomic, weak) WPNoResultsView *noResultsView;
@property (nonatomic, strong) NSMutableDictionary *expandedLinkGroups;

@end

@implementation StatsViewController

- (id)init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _statModels = [NSMutableDictionary dictionary];
        _expandedLinkGroups = [NSMutableDictionary dictionary];
        
        // By default, show data for Today
        _showingToday = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                         @YES, @(StatsSectionTopPosts),
                         @YES, @(StatsSectionViewsByCountry),
                         @YES, @(StatsSectionSearchTerms),
                         @YES, @(StatsSectionClicks),
                         @YES, @(StatsSectionReferrers), nil];
        
        _resultsAvailable = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Stats", nil);
  
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, HeaderHeight, 0);
    
    [self.tableView registerClass:[StatsButtonCell class] forCellReuseIdentifier:VisitorsUnitButtonCellReuseIdentifier];
    [self.tableView registerClass:[StatsTodayYesterdayButtonCell class] forCellReuseIdentifier:TodayYesterdayButtonCellReuseIdentifier];
    [self.tableView registerClass:[StatsViewsVisitorsBarGraphCell class] forCellReuseIdentifier:GraphCellReuseIdentifier];
    [self.tableView registerClass:[StatsCounterCell class] forCellReuseIdentifier:CountCellReuseIdentifier];
    [self.tableView registerClass:[StatsNoResultsCell class] forCellReuseIdentifier:NoResultsCellIdentifier];
    [self.tableView registerClass:[StatsTwoColumnCell class] forCellReuseIdentifier:ResultRowCellIdentifier];
    [self.tableView registerClass:[StatsViewsVisitorsBarGraphCell class] forCellReuseIdentifier:GraphCellIdentifier];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshControlTriggered) forControlEvents:UIControlEventValueChanged];

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
        self.statsApiHelper = [[StatsApiHelper alloc] initWithSiteID:self.blog.blogID];
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
    
    // Show no results until at least the summary has returned
    [self.statsApiHelper fetchSummaryWithSuccess:^(StatsSummary *summary) {
        saveStatsForSection(summary, StatsSectionVisitors);
        _resultsAvailable = YES;
        [self hideNoResultsView];
        [self.tableView reloadData];
    } failure:failure];
    
    [self.statsApiHelper fetchViewsVisitorsWithSuccess:^(StatsViewsVisitors *viewsVisitors) {
        _statModels[@(StatsSectionVisitorsGraph)] = viewsVisitors;
        if (_resultsAvailable) {
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:StatsSectionVisitors] withRowAnimation:UITableViewRowAnimationNone];
        }
    } failure:failure];

    [self.statsApiHelper fetchTopPostsWithSuccess:^(NSDictionary *todayAndYesterdayTopPosts) {
        saveStatsForSection(todayAndYesterdayTopPosts, StatsSectionTopPosts);
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
            NSArray *groups = [self resultsForSection:section];
            NSDictionary *expandedGroup = _expandedLinkGroups[@(section)];
            
            // 2: Today/Yesterday buttons, column titles
            // No groups -> +1 for 'no results' cell
            NSUInteger rows = groups.count ? 2 + MIN(groups.count, ResultRowMaxItems) : 3;
            
            // Add rows for the expanded group's children
            return (expandedGroup ? rows + [expandedGroup[@"count"] unsignedIntegerValue] : rows);
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
            return [self cellForItemListSectionAtIndexPath:indexPath];
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

- (UITableViewCell *)cellForItemListSectionAtIndexPath:(NSIndexPath *)indexPath {
    NSString *dataTitleRowLeft = NSLocalizedString(@"Title", nil);
    NSString *dataTitleRowRight = NSLocalizedString(@"Views", nil);
    switch (indexPath.section) {
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
    switch (indexPath.row) {
        case StatsDataRowButtons:
        {
            cell = [self.tableView dequeueReusableCellWithIdentifier:TodayYesterdayButtonCellReuseIdentifier];
            [(StatsTodayYesterdayButtonCell *)cell setupForSection:indexPath.section delegate:self todayActive:[self showingTodayForSection:indexPath.section]];
            break;
        }
        case StatsDataRowTitle:
        {
            cell = [self.tableView dequeueReusableCellWithIdentifier:ResultRowCellIdentifier];
            [(StatsTwoColumnCell *)cell setLeft:dataTitleRowLeft.uppercaseString withImageUrl:nil right:dataTitleRowRight.uppercaseString titleCell:YES];
            break;
        }
        default:
        {
            if ([self resultsForSection:indexPath.section].count == 0) {
                cell = [self.tableView dequeueReusableCellWithIdentifier:NoResultsCellIdentifier];
                [(StatsNoResultsCell *)cell configureForSection:indexPath.section];
            } else {
                cell = [self.tableView dequeueReusableCellWithIdentifier:ResultRowCellIdentifier];
                [(StatsTwoColumnCell *)cell insertData:[self resultForIndexPath:indexPath]];
            }
        }
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    StatsTitleCountItem *item = [self itemSelectedAtIndexPath:indexPath];
    return [item isKindOfClass:[StatsGroup class]] || item.URL != nil;
}

- (StatsTitleCountItem *)itemSelectedAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row != StatsDataRowTitle &&
        (indexPath.section == StatsSectionTopPosts ||
         indexPath.section == StatsSectionClicks ||
         indexPath.section == StatsSectionReferrers) &&
        [self resultsForSection:indexPath.section].count > 0) {
        return [self resultForIndexPath:indexPath];
    }
    return nil;
}

- (NSArray *)resultsForSection:(StatsSection)section {
    NSDictionary *data = _statModels[@(section)];
    if (data) {
        return [self showingTodayForSection:section] ? data[StatsResultsToday] : data[StatsResultsYesterday];
    }
    return @[];
}

- (StatsTitleCountItem *)resultForIndexPath:(NSIndexPath *)indexPath {
    NSArray *sectionResults = [self resultsForSection:indexPath.section];
    NSIndexPath *expandedGroup = [self expandedGroupIndexPath:indexPath.section];
    NSUInteger offset = StatsDataRowTitle+1; // Column titles + Today/Yesterday buttons
    
    // There is an expanded group in this section
    if (expandedGroup) {
        // Row for the group itself
        if (expandedGroup.row == indexPath.row) {
            return sectionResults[indexPath.row-offset];
        }

        // Row outside the group row & a child, or below the expanded group
        if (indexPath.row > expandedGroup.row) {
            StatsGroup *group = sectionResults[expandedGroup.row-offset];
            NSUInteger childCount = group.children.count;

            if (indexPath.row > expandedGroup.row + childCount) {
                // Outside of the children of the expanded group
                return sectionResults[indexPath.row-offset-childCount];
            }

            // A child of expanded group
            return group.children[indexPath.row-expandedGroup.row-1]; // -1 for the group itself
        }
        
        // Outside and above the expanded group
        // or there was no expanded group to worry about!
    }
    return sectionResults[indexPath.row-offset];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    StatsTitleCountItem *item = [self itemSelectedAtIndexPath:indexPath];
    if ([item isKindOfClass:[StatsGroup class]]) {
        [self toggleGroupExpanded:indexPath childCount:[(StatsGroup *)item children].count];
    } else {
        [[UIApplication sharedApplication] openURL:item.URL];
    }
}

- (NSIndexPath *)expandedGroupIndexPath:(StatsSection)section {
    return _expandedLinkGroups[@(section)][@"indexPath"];
}

- (void)toggleGroupExpanded:(NSIndexPath *)indexPath childCount:(NSUInteger)count {
    NSDictionary *current = _expandedLinkGroups[@(indexPath.section)];
    BOOL addChildren = NO;
    
    [self.tableView beginUpdates];
    
    if (current) {
        [_expandedLinkGroups removeObjectForKey:@(indexPath.section)];
    }
    
    // Remove children from current expanded group
    NSMutableArray *childrenToRemove = [NSMutableArray array];
    if (current) {
        NSUInteger count = [current[@"count"] unsignedIntegerValue];
        NSUInteger offset = [(NSIndexPath *)current[@"indexPath"] row]+1;
        for (NSUInteger i = 0; i < count; i++) {
            [childrenToRemove addObject:[NSIndexPath indexPathForRow:i+offset inSection:indexPath.section]];
        }
        [self.tableView deleteRowsAtIndexPaths:childrenToRemove withRowAnimation:UITableViewRowAnimationFade];
    }
    
    // Insert new children if another group was tapped
    NSIndexPath *actualIndexPath = indexPath;
    if (![current[@"indexPath"] isEqual:indexPath]) {
        addChildren = YES;
        if (current && indexPath.row > [current[@"indexPath"] row]) {
            NSUInteger childOffset = indexPath.row - [current[@"count"] unsignedIntegerValue];
            actualIndexPath = [NSIndexPath indexPathForRow:childOffset inSection:indexPath.section];
        }
        _expandedLinkGroups[@(indexPath.section)] = @{@"indexPath": actualIndexPath, @"count": @(count)};
    }
    
    NSMutableArray *childrenToAdd = [NSMutableArray arrayWithCapacity:count];
    if (addChildren) {
        for (NSUInteger c = 0; c < count; c++) {
            [childrenToAdd addObject:[NSIndexPath indexPathForRow:c+actualIndexPath.row+1 inSection:indexPath.section]];
        }
        [self.tableView insertRowsAtIndexPaths:childrenToAdd withRowAnimation:UITableViewRowAnimationFade];
    }
    
    [self.tableView endUpdates];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    NSString *title = [self headerTextForSection:section];
    return [WPTableViewSectionHeaderView heightForTitle:title andWidth:CGRectGetWidth(self.view.bounds)];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    WPTableViewSectionHeaderView *header = [[WPTableViewSectionHeaderView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 0)];
    header.title = [self headerTextForSection:section];
    return header;
}

- (NSString *)headerTextForSection:(StatsSection)section {
    switch (section) {
        case StatsSectionVisitors:
            return NSLocalizedString(@"Visitors and Views", @"Stats: Section title");
        case StatsSectionTopPosts:
            return NSLocalizedString(@"Top Posts", @"Stats: Section title");;
        case StatsSectionViewsByCountry:
            return NSLocalizedString(@"Views By Country", @"Stats: Section title");;
        case StatsSectionTotalsFollowersShares:
            return NSLocalizedString(@"Totals, Followers & Shares", @"Stats: Section title");;
        case StatsSectionClicks:
            return NSLocalizedString(@"Clicks", @"Stats: Section title");;
        case StatsSectionReferrers:
            return NSLocalizedString(@"Referrers", @"Stats: Section title");;
        case StatsSectionSearchTerms:
            return NSLocalizedString(@"Search Engine Terms", @"Stats: Section title");;
        default:
            return @"";
    }
}

#pragma mark - StatsTodayYesterdayButtonCellDelegate

- (void)statsDayChangedForSection:(StatsSection)section todaySelected:(BOOL)todaySelected {
    [_showingToday setObject:@(todaySelected) forKey:@(section)];
    [_expandedLinkGroups removeAllObjects];
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
