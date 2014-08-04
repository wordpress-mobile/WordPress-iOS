#import "WPStatsViewController.h"
#import "WPStatsButtonCell.h"
#import "WPStatsCounterCell.h"
#import "WPStatsNoResultsCell.h"
#import "WPStatsSummary.h"
#import "WPStatsTitleCountItem.h"
#import "WPStatsTodayYesterdayButtonCell.h"
#import "WPStatsTwoColumnCell.h"
#import "WPStatsLinkToWebviewCell.h"
#import "WPTableViewSectionHeaderView.h"
#import "WPStatsGroup.h"
#import "WPNoResultsView.h"
#import "WPStatsService.h"
#import "WPStyleGuide.h"
#import "WPStatsGraphViewController.h"
#import "WPStatsGraphToastView.h"

static NSString *const VisitorsUnitButtonCellReuseIdentifier = @"VisitorsUnitButtonCellReuseIdentifier";
static NSString *const TodayYesterdayButtonCellReuseIdentifier = @"TodayYesterdayButtonCellReuseIdentifier";
static NSString *const CountCellReuseIdentifier = @"DoubleCountCellReuseIdentifier";
static NSString *const NoResultsCellIdentifier = @"NoResultsCellIdentifier";
static NSString *const ResultRowCellIdentifier = @"ResultRowCellIdentifier";
static NSString *const GraphCellIdentifier = @"GraphCellIdentifier";
static NSString *const StatsGroupedCellIdentifier = @"StatsGroupedCellIdentifier";
static NSString *const LinkToWebviewCellIdentifier = @"LinkToWebviewCellIdentifier";
static NSString *const WPStatsSiteIDRestorationKey = @"WPStatsSiteIDRestorationKey";
static NSString *const WPStatsOAuth2TokenRestorationKey = @"WPStatsOAuth2TokenRestorationKey";
static NSString *const WPStatsTimeZoneRestorationKey = @"WPStatsTimeZoneRestorationKey";

static NSUInteger const ResultRowMaxItems = 10;
static CGFloat const HeaderHeight = 44.0f;
static CGFloat const GraphHeight = 200.0f;
static CGFloat const GraphToastHeight = 75.0f;

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

@interface WPStatsViewController () <UITableViewDataSource, UITableViewDelegate, WPStatsTodayYesterdayButtonCellDelegate, UIViewControllerRestoration, StatsButtonCellDelegate, WPStatsGraphViewControllerDelegate>

@property (nonatomic, strong) WPStatsService *statsService;
@property (nonatomic, strong) NSMutableDictionary *statModels;
@property (nonatomic, strong) NSMutableDictionary *showingToday;
@property (nonatomic, assign) WPStatsViewsVisitorsUnit currentViewsVisitorsGraphUnit;
@property (nonatomic, assign) BOOL resultsAvailable;
@property (nonatomic, weak) WPNoResultsView *noResultsView;
@property (nonatomic, strong) NSMutableDictionary *expandedLinkGroups;
@property (nonatomic, strong) WPStatsGraphViewController *graphViewController;
@property (nonatomic, strong) WPStatsGraphToastView *graphToastView;
@property (nonatomic, assign, getter=isShowingGraphToast) BOOL showingGraphToast;

@end

@implementation WPStatsViewController

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {
    NSNumber *siteID = [coder decodeObjectForKey:WPStatsSiteIDRestorationKey];
    if (!siteID)
        return nil;
    
    NSString *oauth2Token = [coder decodeObjectForKey:WPStatsOAuth2TokenRestorationKey];
    NSTimeZone *timeZone = [coder decodeObjectForKey:WPStatsTimeZoneRestorationKey];
    
    WPStatsViewController *viewController = [[self alloc] initWithSiteID:siteID siteTimeZone:timeZone andOAuth2Token:oauth2Token];
    
    return viewController;
}

- (id)init
{
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
        _graphViewController = [[WPStatsGraphViewController alloc] init];
        _showingGraphToast = NO;
        [self addChildViewController:_graphViewController];
        
        self.restorationIdentifier = NSStringFromClass([self class]);
        self.restorationClass = [self class];
    }
    return self;
}

- (instancetype)initWithSiteID:(NSNumber *)siteID siteTimeZone:(NSTimeZone *)timeZone andOAuth2Token:(NSString *)oauth2Token
{
    self = [self init];
    if (self) {
        _siteID = siteID;
        _oauth2Token = oauth2Token;
        _siteTimeZone = timeZone;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Stats", nil);
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", nil) style:UIBarButtonItemStyleBordered target:nil action:nil];
    self.navigationItem.backBarButtonItem = backButton;
  
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, HeaderHeight, 0);
    
    [self.tableView registerClass:[WPStatsButtonCell class] forCellReuseIdentifier:VisitorsUnitButtonCellReuseIdentifier];
    [self.tableView registerClass:[WPStatsTodayYesterdayButtonCell class] forCellReuseIdentifier:TodayYesterdayButtonCellReuseIdentifier];
    [self.tableView registerClass:[WPStatsCounterCell class] forCellReuseIdentifier:CountCellReuseIdentifier];
    [self.tableView registerClass:[WPStatsNoResultsCell class] forCellReuseIdentifier:NoResultsCellIdentifier];
    [self.tableView registerClass:[WPStatsTwoColumnCell class] forCellReuseIdentifier:ResultRowCellIdentifier];
    [self.tableView registerClass:[WPTableViewCell class] forCellReuseIdentifier:GraphCellIdentifier];
    [self.tableView registerClass:[WPStatsLinkToWebviewCell class] forCellReuseIdentifier:LinkToWebviewCellIdentifier];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshControlTriggered) forControlEvents:UIControlEventValueChanged];
    
    self.graphViewController.graphDelegate = self;

    [self showNoResultsWithTitle:NSLocalizedString(@"Fetching latest stats", @"Message to display while initially loading stats") message:nil];
    
    [self initStats];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    self.statModels = nil;
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.siteID forKey:WPStatsSiteIDRestorationKey];
    [coder encodeObject:self.oauth2Token forKey:WPStatsOAuth2TokenRestorationKey];
    [super encodeRestorableStateWithCoder:coder];
}

- (void)initStats
{
    if (self.statsService == nil) {
        self.statsService = [[WPStatsService alloc] initWithSiteId:self.siteID siteTimeZone:self.siteTimeZone andOAuth2Token:self.oauth2Token];
        [self loadStats];
    }
}

- (void)showNoResultsWithTitle:(NSString *)title message:(NSString *)message
{
    [_noResultsView removeFromSuperview];
    WPNoResultsView *noResultsView = [WPNoResultsView noResultsViewWithTitle:title message:message accessoryView:nil buttonTitle:nil];
    _noResultsView = noResultsView;
    [self.tableView addSubview:_noResultsView];
}

- (void)hideNoResultsView
{
    [_noResultsView removeFromSuperview];
}

- (void)loadStats
{
    void (^failure)(NSError *error) = ^(NSError *error) {
        if (!_resultsAvailable) {
            [self showNoResultsWithTitle:NSLocalizedString(@"Error displaying stats", nil) message:NSLocalizedString(@"Please try again later", nil)];
        } else {
            [self.refreshControl endRefreshing];
        }
        DDLogError(@"Stats: Error fetching stats %@", error);
    };
    
    [self.statsService retrieveStatsWithCompletionHandler:^(WPStatsSummary *summary, NSDictionary *topPosts, NSDictionary *clicks, NSDictionary *countryViews, NSDictionary *referrers, NSDictionary *searchTerms, WPStatsViewsVisitors *viewsVisitors) {
        self.statModels[@(StatsSectionVisitors)] = summary;
        self.statModels[@(StatsSectionVisitorsGraph)] = viewsVisitors;
        self.statModels[@(StatsSectionTopPosts)] = topPosts;
        self.statModels[@(StatsSectionClicks)] = clicks;
        self.statModels[@(StatsSectionViewsByCountry)] = countryViews;
        self.statModels[@(StatsSectionReferrers)] = referrers;
        self.statModels[@(StatsSectionSearchTerms)] = searchTerms;

        self.resultsAvailable = YES;
        [self hideNoResultsView];
        [self.tableView reloadData];
        [self.refreshControl endRefreshing];
        [self statsGraphViewControllerDidDeselectAllBars:nil];
        [self.graphViewController.collectionView reloadData];
    } failureHandler:failure];
}

- (void)refreshControlTriggered
{
    [self loadStats];
}

- (BOOL)showingTodayForSection:(StatsSection)section
{
    return [_showingToday[@(section)] boolValue];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger statsWebViewSectionAdjustment = [self.statsDelegate respondsToSelector:@selector(statsViewController:didSelectViewWebStatsForSiteID:)] ? 0 : -1;
    
    return _resultsAvailable ? StatsSectionTotalCount + statsWebViewSectionAdjustment : 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (!_resultsAvailable) {
        return 0;
    }
    switch (section) {
        case StatsSectionVisitors:
            return VisitorSectionTotalRows;
        case StatsSectionTotalsFollowersShares:
            return TotalFollowersShareRowTotalRows;
        case StatsSectionLinkToWebview:
            return 1;
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case StatsSectionVisitors:
            switch (indexPath.row) {
                case VisitorRowGraphUnitButton:
                    return [WPStatsButtonCell heightForRow];
                case VisitorRowGraph:
                    return GraphHeight + (self.isShowingGraphToast ? GraphToastHeight + 6.0f : 0.0f);
                case VisitorRowTodayStats:
                case VisitorRowBestEver:
                case VisitorRowAllTime:
                    return [WPStatsCounterCell heightForRow];
                default:
                    return 0.0f;
            }
            break;
        case StatsSectionTotalsFollowersShares:
            return [WPStatsCounterCell heightForRow];
        case StatsSectionTopPosts:
        case StatsSectionViewsByCountry:
        case StatsSectionClicks:
        case StatsSectionReferrers:
        case StatsSectionSearchTerms:
            switch (indexPath.row) {
                case StatsDataRowButtons:
                    return [WPStatsButtonCell heightForRow];
                case StatsDataRowTitle:
                    return [self resultsForSection:indexPath.section].count > 0 ? [WPStatsTwoColumnCell heightForRow] : 0.0;
                default:
                    return [self resultsForSection:indexPath.section].count > 0 ? [WPStatsTwoColumnCell heightForRow] : [WPStatsNoResultsCell heightForRowForSection:(StatsSection)indexPath.section withWidth:CGRectGetWidth(self.view.bounds)];
            }
        case StatsSectionLinkToWebview:
            return [WPStatsLinkToWebviewCell heightForRow];
        default:
            return 0.0f;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case StatsSectionVisitors:
            switch (indexPath.row) {
                case VisitorRowGraphUnitButton:
                {
                    WPStatsButtonCell *cell = [tableView dequeueReusableCellWithIdentifier:VisitorsUnitButtonCellReuseIdentifier];
                    cell.delegate = self;
                    [cell addSegmentWithTitle:NSLocalizedString(@"Days", nil)];
                    [cell addSegmentWithTitle:NSLocalizedString(@"Weeks", nil)];
                    [cell addSegmentWithTitle:NSLocalizedString(@"Months", nil)];
                    cell.segmentedControl.selectedSegmentIndex = _currentViewsVisitorsGraphUnit;
                    return cell;
                }
                case VisitorRowGraph:
                {
                    WPTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:GraphCellIdentifier];
                    cell.clipsToBounds = YES;
                    self.graphViewController.viewsVisitors = self.statModels[@(StatsSectionVisitorsGraph)];
                    self.graphViewController.currentUnit = self.currentViewsVisitorsGraphUnit;
                    
                    if (![[cell.contentView subviews] containsObject:self.graphViewController.view]) {
                        UIView *graphView = self.graphViewController.view;
                        graphView.frame = CGRectMake(0.0f, 0.0f, CGRectGetWidth(cell.contentView.bounds), GraphHeight);
                        graphView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
                        [cell.contentView addSubview:graphView];
                        
                        WPStatsGraphToastView *toastView = [[WPStatsGraphToastView alloc] initWithFrame:CGRectMake(0, GraphHeight, CGRectGetWidth(cell.contentView.bounds), GraphToastHeight)];
                        toastView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
                        [cell.contentView addSubview:toastView];
                        self.graphToastView = toastView;
                    }
                    
                    return cell;
                }
                case VisitorRowTodayStats:
                {
                    WPStatsCounterCell *cell = [tableView dequeueReusableCellWithIdentifier:CountCellReuseIdentifier];
                    WPStatsSummary *summary = _statModels[@(StatsSectionVisitors)];
                    [cell setTitle:NSLocalizedString(@"Today", @"Title for Today cell")];
                    [cell addCount:summary.visitorCountToday withLabel:NSLocalizedString(@"Visitors", @"Visitor label for Today cell")];
                    [cell addCount:summary.viewCountToday withLabel:NSLocalizedString(@"Views", @"View label for Today cell")];
                    return cell;
                }
                case VisitorRowBestEver:
                {
                    WPStatsCounterCell *cell = [tableView dequeueReusableCellWithIdentifier:CountCellReuseIdentifier];
                    WPStatsSummary *summary = _statModels[@(StatsSectionVisitors)];
                    [cell setTitle:NSLocalizedString(@"Best Ever", nil)];
                    [cell addCount:summary.viewCountBest withLabel:NSLocalizedString(@"Views", nil)];
                    return cell;
                }
                case VisitorRowAllTime:
                {
                    WPStatsCounterCell *cell = [tableView dequeueReusableCellWithIdentifier:CountCellReuseIdentifier];
                    WPStatsSummary *summary = _statModels[@(StatsSectionVisitors)];
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
        case StatsSectionLinkToWebview:
        {
            if ([self.statsDelegate respondsToSelector:@selector(statsViewController:didSelectViewWebStatsForSiteID:)]) {
                WPStatsLinkToWebviewCell *cell = [tableView dequeueReusableCellWithIdentifier:LinkToWebviewCellIdentifier];
                [cell configureForSection:StatsSectionLinkToWebview];
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.onTappedLinkToWebview = ^{
                    [self.statsDelegate statsViewController:self didSelectViewWebStatsForSiteID:self.siteID];
                };
                return cell;
            } else {
                return nil;
            }
        }
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
    
    WPStatsSummary *summary = _statModels[@(StatsSectionVisitors)];
    switch (index) {
        case TotalFollowersShareRowContentPost:
            title = NSLocalizedString(@"Content", @"Stats - Title for the data cell");
            leftLabel = NSLocalizedString(@"Posts", @"Stats - Label for the count");
            leftCount = summary.totalPosts;
            break;
        case TotalFollowersShareRowContentCategoryTag:
            leftLabel = NSLocalizedString(@"Categories", @"Stats - Title for the data cell");
            leftCount = summary.totalCategories;
            rightLabel = NSLocalizedString(@"Tags", @"Stats - Label for the count");
            rightCount = summary.totalTags;
            break;
        case TotalFollowersShareRowFollowers:
            title = NSLocalizedString(@"Followers", @"Stats - Title for the data cell");
            leftLabel = NSLocalizedString(@"Blog", @"Stats - Label for the count");
            leftCount = summary.totalFollowersBlog;
            rightLabel = NSLocalizedString(@"Comments", @"Stats -Label for the right count");
            rightCount = summary.totalFollowersComments;
            break;
        case TotalFollowersShareRowShare:
            title = NSLocalizedString(@"Shares", @"Stats - Title for the data cell");
            leftLabel = NSLocalizedString(@"Shares", @"Stats - Label for the count");
            leftCount = summary.totalShares;
            break;
    }
    
    WPStatsCounterCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CountCellReuseIdentifier];
    [cell setTitle:title];
    [cell addCount:leftCount withLabel:leftLabel];
    if (rightLabel) {
        [cell addCount:rightCount withLabel:rightLabel];
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
            [(WPStatsTodayYesterdayButtonCell *)cell setupForSection:indexPath.section delegate:self todayActive:[self showingTodayForSection:indexPath.section]];
            break;
        }
        case StatsDataRowTitle:
        {
            cell = [self.tableView dequeueReusableCellWithIdentifier:ResultRowCellIdentifier];
            [(WPStatsTwoColumnCell *)cell setLeft:[dataTitleRowLeft uppercaseStringWithLocale:[NSLocale currentLocale]] withImageUrl:nil right:[dataTitleRowRight uppercaseStringWithLocale:[NSLocale currentLocale]] titleCell:YES];
            break;
        }
        default:
        {
            if ([self resultsForSection:indexPath.section].count == 0) {
                cell = [self.tableView dequeueReusableCellWithIdentifier:NoResultsCellIdentifier];
                [(WPStatsNoResultsCell *)cell configureForSection:indexPath.section];
            } else {
                cell = [self.tableView dequeueReusableCellWithIdentifier:ResultRowCellIdentifier];
                [(WPStatsTwoColumnCell *)cell insertData:[self resultForIndexPath:indexPath]];
            }
        }
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    WPStatsTitleCountItem *item = [self itemSelectedAtIndexPath:indexPath];
    return [item isKindOfClass:[WPStatsGroup class]] || item.URL != nil || indexPath.section == StatsSectionLinkToWebview;
}

- (WPStatsTitleCountItem *)itemSelectedAtIndexPath:(NSIndexPath *)indexPath {
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

- (WPStatsTitleCountItem *)resultForIndexPath:(NSIndexPath *)indexPath {
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
            WPStatsGroup *group = sectionResults[expandedGroup.row-offset];
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
    NSInteger index = indexPath.row - offset;
    
    if (index < 0) {
        return nil;
    }
    
    return sectionResults[index];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    WPStatsTitleCountItem *item = [self itemSelectedAtIndexPath:indexPath];
    if ([item isKindOfClass:[WPStatsGroup class]]) {
        [self toggleGroupExpanded:indexPath childCount:[(WPStatsGroup *)item children].count];
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
            return NSLocalizedString(@"Top Posts & Pages", @"Stats: Section title");
        case StatsSectionViewsByCountry:
            return NSLocalizedString(@"Views By Country", @"Stats: Section title");
        case StatsSectionTotalsFollowersShares:
            return NSLocalizedString(@"Totals, Followers & Shares", @"Stats: Section title");
        case StatsSectionClicks:
            return NSLocalizedString(@"Clicks", @"Stats: Section title");
        case StatsSectionReferrers:
            return NSLocalizedString(@"Referrers", @"Stats: Section title");
        case StatsSectionSearchTerms:
            return NSLocalizedString(@"Search Engine Terms", @"Stats: Section title");
        case StatsSectionLinkToWebview:
            return NSLocalizedString(@"Web Version", @"Stats: Section title");
        default:
            return @"";
    }
}

#pragma mark - StatsTodayYesterdayButtonCellDelegate

- (void)statsDayChangedForSection:(StatsSection)section todaySelected:(BOOL)todaySelected {
    BOOL todayCurrentlySelected = [self.showingToday[@(section)] boolValue];
    
    // Only reload section if the selection changed
    if (todayCurrentlySelected != todaySelected) {
        [self.showingToday setObject:@(todaySelected) forKey:@(section)];
        [self.expandedLinkGroups removeObjectForKey:@(section)];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:UITableViewRowAnimationFade];
    }
}


#pragma mark - Visitors Graph button selectors

- (void)graphUnitSelected:(WPStatsViewsVisitorsUnit)unit {
    [self statsGraphViewControllerDidDeselectAllBars:nil];
    
    self.currentViewsVisitorsGraphUnit = unit;
    self.graphViewController.currentUnit = unit;
    [self.graphViewController.collectionView reloadData];
}

#pragma mark - StatsButtonCellDelegate methods

- (void)statsButtonCell:(WPStatsButtonCell *)statsButtonCell didSelectIndex:(NSUInteger)index {
    WPStatsViewsVisitorsUnit unit = (WPStatsViewsVisitorsUnit)index;
    [self graphUnitSelected:unit];
}

#pragma mark - WPStatsGraphViewControllerDelegate methods

- (void)statsGraphViewController:(WPStatsGraphViewController *)controller didSelectData:(NSArray *)data withXLocation:(CGFloat)xLocation
{
    self.showingGraphToast = YES;
    self.graphToastView.xOffset = xLocation;
    self.graphToastView.viewCount = [data[0][@"value"] unsignedIntegerValue];
    self.graphToastView.visitorsCount = [data[1][@"value"] unsignedIntegerValue];

    // Causes table rows to be redrawn if heights have changed
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

- (void)statsGraphViewControllerDidDeselectAllBars:(WPStatsGraphViewController *)controller
{
    self.showingGraphToast = NO;
    
    // Causes table rows to be redrawn if heights have changed
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

@end
