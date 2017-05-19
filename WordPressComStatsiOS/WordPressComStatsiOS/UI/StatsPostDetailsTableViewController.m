#import "StatsPostDetailsTableViewController.h"
#import "WPStatsGraphViewController.h"
#import "StatsGroup.h"
#import <WordPressKit/StatsItem.h>
#import <WordPressKit/StatsItemAction.h>
#import "StatsTwoColumnTableViewCell.h"
#import "WPStyleGuide+Stats.h"
#import "StatsTableSectionHeaderView.h"
#import <WordPressComAnalytics/WPAnalytics.h>
#import "UIViewController+SizeClass.h"
#import "AppExtensionUtils.h"

static CGFloat const StatsTableGraphHeight = 185.0f;
static CGFloat const StatsTableNoResultsHeight = 100.0f;
static CGFloat const StatsTableGroupHeaderHeight = 30.0f;
static NSString *const StatsTableSectionHeaderSimpleBorder = @"StatsTableSectionHeaderSimpleBorder";
static NSString *const StatsTableGroupHeaderCellIdentifier = @"GroupHeader";
static NSString *const StatsTableTwoColumnHeaderCellIdentifier = @"TwoColumnHeader";
static NSString *const StatsTableTwoColumnCellIdentifier = @"TwoColumnRow";
static NSString *const StatsTableLoadingIndicatorCellIdentifier = @"LoadingIndicator";
static NSString *const StatsTableGraphSelectableCellIdentifier = @"SelectableRow";
static NSString *const StatsTableGraphCellIdentifier = @"GraphRow";
static NSString *const StatsTableNoResultsCellIdentifier = @"NoResultsRow";

@interface StatsPostDetailsTableViewController () <WPStatsGraphViewControllerDelegate>

@property (nonatomic, strong) NSMutableArray *sections;
@property (nonatomic, strong) NSMutableDictionary *sectionData;
@property (nonatomic, strong) WPStatsGraphViewController *graphViewController;
@property (nonatomic, strong) NSDate *selectedDate;
@property (nonatomic, assign) BOOL isRefreshing;
@end

@implementation StatsPostDetailsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [WPAnalytics track:WPAnalyticsStatStatsSinglePostAccessed withProperties:@{ @"blog_id" : self.statsService.siteId, @"post_id" : self.postID }];
    
    self.sections = [@[@(StatsSectionPostDetailsLoadingIndicator), @(StatsSectionPostDetailsGraph), @(StatsSectionPostDetailsMonthsYears), @(StatsSectionPostDetailsAveragePerDay), @(StatsSectionPostDetailsRecentWeeks)] mutableCopy];
    self.sectionData = [NSMutableDictionary new];

    [self.tableView registerClass:[StatsTableSectionHeaderView class] forHeaderFooterViewReuseIdentifier:StatsTableSectionHeaderSimpleBorder];

    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 20.0f)];
    self.tableView.backgroundColor = [WPStyleGuide itsEverywhereGrey];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    [self setupRefreshControl];
    
    self.graphViewController = [WPStatsGraphViewController new];
    self.graphViewController.allowDeselection = NO;
    self.graphViewController.graphDelegate = self;
    [self addChildViewController:self.graphViewController];
    [self.graphViewController didMoveToParentViewController:self];
    
    self.title = self.postTitle;
    
    self.sectionData[@(StatsSectionPostDetailsGraph)] = [StatsVisits new];
    self.sectionData[@(StatsSectionPostDetailsMonthsYears)] = [[StatsGroup alloc] initWithStatsSection:StatsSectionPostDetailsMonthsYears andStatsSubSection:StatsSubSectionNone];
    self.sectionData[@(StatsSectionPostDetailsAveragePerDay)] = [[StatsGroup alloc] initWithStatsSection:StatsSectionPostDetailsAveragePerDay andStatsSubSection:StatsSubSectionNone];
    self.sectionData[@(StatsSectionPostDetailsRecentWeeks)] = [[StatsGroup alloc] initWithStatsSection:StatsSectionPostDetailsRecentWeeks andStatsSubSection:StatsSubSectionNone];
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self retrieveStats];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self abortRetrieveStats];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return (NSInteger)self.sections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    StatsSection statsSection = [self statsSectionForTableViewSection:section];
    
    switch (statsSection) {
        case StatsSectionPostDetailsLoadingIndicator:
            return self.isRefreshing ? 1 : 0;
        case StatsSectionPostDetailsGraph:
            return 2;
        case StatsSectionPostDetailsAveragePerDay:
        case StatsSectionPostDetailsMonthsYears:
        case StatsSectionPostDetailsRecentWeeks:
        {
            StatsGroup *statsGroup = [self statsDataForStatsSection:statsSection];
            NSInteger numberOfRows = (NSInteger)statsGroup.numberOfRows;
            return 2 + numberOfRows + (numberOfRows == 0 ? 1 : 0);
        }
        default:
            return 0;
    }

    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *identifier = [self cellIdentifierForIndexPath:indexPath];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    
    StatsSection statsSection = [self statsSectionForTableViewSection:indexPath.section];

    if ([identifier isEqualToString:StatsTableGraphCellIdentifier]) {
        [self configureSectionGraphCell:cell];
    } else if ([identifier isEqualToString:StatsTableGraphSelectableCellIdentifier]) {
        [self configureSectionGraphSelectableCell:(StatsSelectableTableViewCell *)cell];
    } else if ([identifier isEqualToString:StatsTableGroupHeaderCellIdentifier]) {
        [self configureSectionGroupHeaderCell:(StatsStandardBorderedTableViewCell *)cell
                             withStatsSection:statsSection];
    } else if ([identifier isEqualToString:StatsTableTwoColumnCellIdentifier]) {
        StatsGroup *statsGroup = [self statsDataForStatsSection:statsSection];
        StatsItem *statsItem = [statsGroup statsItemForTableViewRow:indexPath.row];
        StatsItem *nextStatsItem = [statsGroup statsItemForTableViewRow:indexPath.row + 1];
        
        [self configureTwoColumnRowCell:cell
                        forStatsSection:statsSection
                          withStatsItem:statsItem
                       andNextStatsItem:nextStatsItem];
    } else if ([identifier isEqualToString:StatsTableTwoColumnHeaderCellIdentifier]) {
        StatsGroup *statsGroup = [self statsDataForStatsSection:statsSection];
        [self configureSectionTwoColumnHeaderCell:(StatsStandardBorderedTableViewCell *)cell withStatsGroup:statsGroup];
    } else if ([identifier isEqualToString:StatsTableLoadingIndicatorCellIdentifier]) {
        cell.backgroundColor = self.tableView.backgroundColor;
    }
    
    return cell;
}


- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    StatsSection statsSection = [self statsSectionForTableViewSection:indexPath.section];

    if (statsSection == StatsSectionPostDetailsGraph && indexPath.row > 0) {
        for (NSIndexPath *selectedIndexPath in [tableView indexPathsForSelectedRows]) {
            [tableView deselectRowAtIndexPath:selectedIndexPath animated:YES];
        }
        
        return indexPath;
    } else if ([[self cellIdentifierForIndexPath:indexPath] isEqualToString:StatsTableTwoColumnCellIdentifier]) {
        // Disable taps on rows without children
        StatsGroup *group = [self statsDataForStatsSection:statsSection];
        StatsItem *item = [group statsItemForTableViewRow:indexPath.row];
        
        BOOL hasChildItems = item.children.count > 0;
        // TODO :: Look for default action boolean
        BOOL hasDefaultAction = item.actions.count > 0;
        NSIndexPath *newIndexPath = (hasChildItems || hasDefaultAction) ? indexPath : nil;
        
        return newIndexPath;
    }
    
    return nil;
}


- (NSIndexPath *)tableView:(UITableView *)tableView willDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self statsSectionForTableViewSection:indexPath.section] == StatsSectionPostDetailsGraph && indexPath.row > 0) {
        return nil;
    }
    
    return indexPath;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    StatsSection statsSection = [self statsSectionForTableViewSection:indexPath.section];
    if (statsSection == StatsSectionPostDetailsGraph && indexPath.row > 0) {
        NSIndexPath *graphIndexPath = [NSIndexPath indexPathForItem:0 inSection:indexPath.section];
        [tableView beginUpdates];
        [tableView reloadRowsAtIndexPaths:@[graphIndexPath] withRowAnimation:UITableViewRowAnimationNone];
        [tableView endUpdates];
    } else if ([[self cellIdentifierForIndexPath:indexPath] isEqualToString:StatsTableTwoColumnCellIdentifier]) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        StatsGroup *statsGroup = [self statsDataForStatsSection:statsSection];
        StatsItem *statsItem = [statsGroup statsItemForTableViewRow:indexPath.row];
        
        if (statsItem.children.count > 0) {
            BOOL insert = !statsItem.isExpanded;
            NSInteger numberOfRowsBefore = (NSInteger)statsItem.numberOfRows - 1;
            statsItem.expanded = !statsItem.isExpanded;
            NSInteger numberOfRowsAfter = (NSInteger)statsItem.numberOfRows - 1;
            
            StatsTwoColumnTableViewCell *cell = (StatsTwoColumnTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
            cell.expanded = statsItem.isExpanded;
            [cell doneSettingProperties];
            
            NSMutableArray *indexPaths = [NSMutableArray new];
            
            NSInteger numberOfRows = insert ? numberOfRowsAfter : numberOfRowsBefore;
            for (NSInteger row = 1; row <= numberOfRows; ++row) {
                [indexPaths addObject:[NSIndexPath indexPathForRow:(row + indexPath.row) inSection:indexPath.section]];
            }
            
            // Reload row one above to get rid of the double border
            NSIndexPath *previousRowIndexPath = [NSIndexPath indexPathForRow:indexPath.row - 1 inSection:indexPath.section];
            
            [self.tableView beginUpdates];
            [self.tableView reloadRowsAtIndexPaths:@[previousRowIndexPath] withRowAnimation:UITableViewRowAnimationNone];
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            
            if (insert) {
                [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationMiddle];
            } else {
                [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
            }
            
            [self.tableView endUpdates];
        } else if (statsItem.actions.count > 0) {
            for (StatsItemAction *action in statsItem.actions) {
                if (action.defaultAction) {
                    if ([self.statsDelegate respondsToSelector:@selector(statsViewController:openURL:)]) {
                        WPStatsViewController *statsViewController = (WPStatsViewController *)self.navigationController;
                        [self.statsDelegate statsViewController:statsViewController openURL:action.url];
                    } else {
                        [AppExtensionUtils openURL:action.url fromController:self];
                    }
                    break;
                }
            }
        }
    }
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if ([self statsSectionForTableViewSection:section] != StatsSectionPostDetailsLoadingIndicator) {
        StatsTableSectionHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:StatsTableSectionHeaderSimpleBorder];
        
        return headerView;
    }
    
    return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if ([self statsSectionForTableViewSection:section] != StatsSectionPostDetailsLoadingIndicator) {
        StatsTableSectionHeaderView *footerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:StatsTableSectionHeaderSimpleBorder];
        footerView.footer = YES;
        
        return footerView;
    }
    
    return nil;
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 1.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 10.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = [self cellIdentifierForIndexPath:indexPath];
    
    if ([cellIdentifier isEqualToString:StatsTableGraphCellIdentifier]) {
        return StatsTableGraphHeight;
    } else if ([cellIdentifier isEqualToString:StatsTableGroupHeaderCellIdentifier]) {
        return StatsTableGroupHeaderHeight;
    } else if ([cellIdentifier isEqualToString:StatsTableNoResultsCellIdentifier]) {
        return StatsTableNoResultsHeight;
    }
    
    return 44.0f;
}


#pragma mark - Private methods

- (void)retrieveStats
{
    [AppExtensionUtils setNetworkActivityIndicatorVisible:YES fromController:self];

    if (self.refreshControl.isRefreshing == NO) {
        self.refreshControl = nil;
        self.isRefreshing = YES;
        [self.tableView reloadData];
    }
    
    __weak __typeof(self) weakSelf = self;
    
    [self.statsService retrievePostDetailsStatsForPostID:self.postID
                                   withCompletionHandler:^(StatsVisits *visits, StatsGroup *monthsYears, StatsGroup *averagePerDay, StatsGroup *recentWeeks, NSError *error)
    {
        [AppExtensionUtils setNetworkActivityIndicatorVisible:NO fromController:self];
        [weakSelf setupRefreshControl];
        [weakSelf.refreshControl endRefreshing];

        weakSelf.isRefreshing = NO;
        
        monthsYears.offsetRows = 2;
        averagePerDay.offsetRows = 2;
        recentWeeks.offsetRows = 2;

        weakSelf.sectionData[@(StatsSectionPostDetailsGraph)] = visits;
        weakSelf.sectionData[@(StatsSectionPostDetailsMonthsYears)] = monthsYears;
        weakSelf.sectionData[@(StatsSectionPostDetailsAveragePerDay)] = averagePerDay;
        weakSelf.sectionData[@(StatsSectionPostDetailsRecentWeeks)] = recentWeeks;

        weakSelf.selectedDate = [visits.statsData.lastObject date];
        [weakSelf.tableView reloadData];
        
        
        NSInteger sectionNumber = (NSInteger)[weakSelf.sections indexOfObject:@(StatsSectionPostDetailsGraph)];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:1 inSection:sectionNumber];
        [weakSelf.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }];
    
}


- (void)abortRetrieveStats
{
    [self.statsService cancelAnyRunningOperations];
    [AppExtensionUtils setNetworkActivityIndicatorVisible:NO fromController:self];
}


- (NSString *)cellIdentifierForIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = @"";
    StatsSection statsSection = [self statsSectionForTableViewSection:indexPath.section];
    
    if (statsSection == StatsSectionPostDetailsLoadingIndicator) {
        identifier = StatsTableLoadingIndicatorCellIdentifier;
    } else if (statsSection == StatsSectionPostDetailsGraph) {
        switch (indexPath.row) {
            case 0:
                identifier = StatsTableGraphCellIdentifier;
                break;
            case 1:
                identifier = StatsTableGraphSelectableCellIdentifier;
        }
    } else {
        switch (indexPath.row) {
            case 0:
                identifier = StatsTableGroupHeaderCellIdentifier;
                break;
            case 1:
                identifier = StatsTableTwoColumnHeaderCellIdentifier;
                break;
            default:
                identifier = StatsTableTwoColumnCellIdentifier;
                break;
        }
    }

    return identifier;
}


- (void)configureSectionGraphCell:(UITableViewCell *)cell
{
    if (![[cell.contentView subviews] containsObject:self.graphViewController.view]) {
        UIView *graphView = self.graphViewController.view;
        [graphView removeFromSuperview];
        graphView.frame = CGRectMake(8.0f, 0.0f, CGRectGetWidth(cell.contentView.bounds) - 16.0f, StatsTableGraphHeight - 1.0);
        graphView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [cell.contentView addSubview:graphView];
    }
    
    StatsVisits *visits = [self statsDataForStatsSection:StatsSectionPostDetailsGraph];
    [self.graphViewController setVisits:visits forSummaryType:StatsSummaryTypeViews withSelectedDate:self.selectedDate];
}


- (void)configureSectionGraphSelectableCell:(StatsSelectableTableViewCell *)cell
{
    StatsVisits *visits = [self statsDataForStatsSection:StatsSectionPostDetailsGraph];
    StatsSummary *summary = visits.statsDataByDate[self.selectedDate];
    
    cell.selected = YES;
    
    cell.cellType = StatsSelectableTableViewCellTypeViews;
    cell.valueLabel.text = summary.views;
}


- (void)configureSectionGroupHeaderCell:(StatsStandardBorderedTableViewCell *)cell withStatsSection:(StatsSection)statsSection
{
    StatsGroup *statsGroup = [self statsDataForStatsSection:statsSection];
    NSString *headerText = statsGroup.groupTitle;
    
    UILabel *label = (UILabel *)[cell.contentView viewWithTag:100];
    label.text = headerText;
    label.textColor = [WPStyleGuide darkGrey];

    cell.bottomBorderEnabled = NO;
}


- (void)configureTwoColumnRowCell:(UITableViewCell *)cell
                  forStatsSection:(StatsSection)statsSection
                    withStatsItem:(StatsItem *)statsItem
                 andNextStatsItem:(StatsItem *)nextStatsItem
{
    BOOL showCircularIcon = (statsSection == StatsSectionComments || statsSection == StatsSectionFollowers || statsSection == StatsSectionAuthors);
    
    StatsTwoColumnTableViewCellSelectType selectType = StatsTwoColumnTableViewCellSelectTypeDetail;
    if (statsItem.actions.count > 0 && (statsSection == StatsSectionReferrers || statsSection == StatsSectionClicks)) {
        selectType = StatsTwoColumnTableViewCellSelectTypeURL;
    } else if (statsSection == StatsSectionTagsCategories) {
        if ([statsItem.alternateIconValue isEqualToString:@"category"]) {
            selectType = StatsTwoColumnTableViewCellSelectTypeCategory;
        } else if ([statsItem.alternateIconValue isEqualToString:@"tag"]) {
            selectType = StatsTwoColumnTableViewCellSelectTypeTag;
        }
    }
    
    StatsTwoColumnTableViewCell *statsCell = (StatsTwoColumnTableViewCell *)cell;
    statsCell.leftText = statsItem.label;
    statsCell.rightText = statsItem.value;
    statsCell.imageURL = statsItem.iconURL;
    statsCell.showCircularIcon = showCircularIcon;
    statsCell.indentLevel = statsItem.depth;
    statsCell.indentable = NO;
    statsCell.expandable = statsItem.children.count > 0;
    statsCell.expanded = statsItem.expanded;
    statsCell.selectable = statsItem.actions.count > 0 || statsItem.children.count > 0;
    statsCell.selectType = selectType;
    statsCell.bottomBorderEnabled = !(nextStatsItem.isExpanded);
    
    [statsCell doneSettingProperties];
}


- (void)configureSectionTwoColumnHeaderCell:(StatsStandardBorderedTableViewCell *)cell withStatsGroup:(StatsGroup *)statsGroup
{
    StatsItem *statsItem = [statsGroup statsItemForTableViewRow:2];
    
    NSString *leftText = statsGroup.titlePrimary;
    NSString *rightText = statsGroup.titleSecondary;
    
    // Hide the bottom border if the first row is expanded
    cell.bottomBorderEnabled = !statsItem.isExpanded;
    
    UILabel *label1 = (UILabel *)[cell.contentView viewWithTag:100];
    label1.text = leftText;
    label1.textColor = [WPStyleGuide grey];

    UILabel *label2 = (UILabel *)[cell.contentView viewWithTag:200];
    label2.text = rightText;
    label2.textColor = [WPStyleGuide grey];
}


- (StatsSection)statsSectionForTableViewSection:(NSInteger)section
{
    return (StatsSection)[self.sections[(NSUInteger)section] integerValue];
}


- (id)statsDataForStatsSection:(StatsSection)statsSection
{
    return self.sectionData[@(statsSection)];
}


- (void)setupRefreshControl
{
    if (self.refreshControl) {
        return;
    }
    
    UIRefreshControl *refreshControl = [UIRefreshControl new];
    [refreshControl addTarget:self action:@selector(retrieveStats) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    self.isRefreshing = NO;
}


#pragma mark - WPStatsGraphViewControllerDelegate methods


- (void)statsGraphViewController:(WPStatsGraphViewController *)controller didSelectDate:(NSDate *)date
{
    self.selectedDate = date;
    
    [self.tableView reloadData];
    
    NSUInteger section = [self.sections indexOfObject:@(StatsSectionPostDetailsGraph)];
    if (section != NSNotFound) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:1 inSection:(NSInteger)section];
        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
}


- (void)setIsRefreshing:(BOOL)isRefreshing
{
    _isRefreshing = isRefreshing;
    
    if (_isRefreshing && [self.sections containsObject:@(StatsSectionPostDetailsLoadingIndicator)] == NO) {
        [self.sections insertObject:@(StatsSectionPostDetailsLoadingIndicator) atIndex:0];
    } else if (_isRefreshing == NO && [self.sections containsObject:@(StatsSectionPostDetailsLoadingIndicator)]) {
        [self.sections removeObject:@(StatsSectionPostDetailsLoadingIndicator)];
    }
}

@end
