#import "Logging.h"
#import "InsightsTableViewController.h"
#import "WPStyleGuide+Stats.h"
#import "StatsTableSectionHeaderView.h"
#import "InsightsSectionHeaderTableViewCell.h"
#import "InsightsAllTimeTableViewCell.h"
#import "InsightsMostPopularTableViewCell.h"
#import "InsightsPostingActivityTableViewCell.h"
#import "InsightsTodaysStatsTableViewCell.h"
#import "StatsTableSectionHeaderView.h"
#import "StatsSection.h"
#import <WordPressComAnalytics/WPAnalytics.h>
#import "StatsTwoColumnTableViewCell.h"
#import "StatsItemAction.h"
#import "StatsViewAllTableViewController.h"
#import "StatsPostDetailsTableViewController.h"
#import "UIViewController+SizeClass.h"
#import "NSBundle+StatsBundleHelper.h"
#import <WordPressShared/WPFontManager.h>
#import "StatsStreakItem.h"
#import "InsightsPostingActivityCollectionViewController.h"
#import "AppExtensionUtils.h"

@interface InlineTextAttachment : NSTextAttachment

@property (nonatomic, assign) CGFloat fontDescender;

@end

@implementation InlineTextAttachment

- (CGRect)attachmentBoundsForTextContainer:(NSTextContainer *)textContainer proposedLineFragment:(CGRect)lineFrag glyphPosition:(CGPoint)position characterIndex:(NSUInteger)charIndex {
    CGRect superRect = [super attachmentBoundsForTextContainer:textContainer proposedLineFragment:lineFrag glyphPosition:position characterIndex:charIndex];
    superRect.origin.y = self.fontDescender;
    return superRect;
}

@end

static CGFloat const StatsTableNoResultsHeight = 100.0f;
static CGFloat const StatsTableGroupHeaderHeight = 30.0f;
static NSInteger const StatsTableRowDataOffsetStandard = 2;
static NSInteger const StatsTableRowDataOffsetWithoutGroupHeader = 1;
static NSInteger const StatsTableRowDataOffsetWithGroupSelector = 3;
static NSInteger const StatsTableRowDataOffsetWithGroupSelectorAndTotal = 4;

static NSString *const StatsTableSectionHeaderSimpleBorder = @"StatsTableSectionHeaderSimpleBorder";
static NSString *const InsightsTableSectionHeaderCellIdentifier = @"HeaderRow";
static NSString *const InsightsTableMostPopularDetailsCellIdentifier = @"MostPopularDetails";
static NSString *const InsightsTablePostActivityCellIdentifier = @"PostingActivityDetails";
static NSString *const InsightsTableAllTimeDetailsCellIdentifier = @"AllTimeDetails";
static NSString *const InsightsTableAllTimeDetailsiPadCellIdentifier = @"AllTimeDetailsPad";
static NSString *const InsightsTableTodaysStatsDetailsiPadCellIdentifier = @"TodaysStatsDetailsPad";
static NSString *const InsightsTableLatestPostSummaryDetailsiPadCellIdentifier = @"LatestPostDetailsPad";
static NSString *const InsightsTableWrappingTextCellIdentifier = @"WrappingText";
static NSString *const InsightsTableWrappingTextLayoutCellIdentifier = @"WrappingTextLayout";
static NSString *const StatsTableSelectableCellIdentifier = @"SelectableRow";
static NSString *const StatsTableGroupHeaderCellIdentifier = @"GroupHeader";
static NSString *const StatsTableGroupSelectorCellIdentifier = @"GroupSelector";
static NSString *const StatsTableGroupTotalsCellIdentifier = @"GroupTotalsRow";
static NSString *const StatsTableTwoColumnHeaderCellIdentifier = @"TwoColumnHeader";
static NSString *const StatsTableTwoColumnCellIdentifier = @"TwoColumnRow";
static NSString *const StatsTableViewAllCellIdentifier = @"MoreRow";
static NSString *const StatsTableNoResultsCellIdentifier = @"NoResultsRow";
static NSString *const StatsTablePeriodHeaderCellIdentifier = @"PeriodHeader";

static NSString *const SeguePostActivity = @"PostingActivity";
static NSString *const SegueLatestPostDetails = @"LatestPostDetails";
static NSString *const SegueLatestPostDetailsiPad = @"LatestPostDetailsPad";

static CGFloat const InsightsTableSectionHeaderHeight = 1.0f;
static CGFloat const InsightsTableSectionFooterHeight = 10.0f;

@interface InsightsTableViewController ()

@property (nonatomic, strong) NSArray *sections;
@property (nonatomic, strong) NSDictionary *subSections;
@property (nonatomic, strong) NSMutableDictionary *sectionData;
@property (nonatomic, strong) NSMutableDictionary *selectedSubsections;

@end

@implementation InsightsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSBundle *bundle = [NSBundle statsBundle];

    [self.tableView registerClass:[StatsTableSectionHeaderView class] forHeaderFooterViewReuseIdentifier:StatsTableSectionHeaderSimpleBorder];
    [self.tableView registerNib:[UINib nibWithNibName:@"InsightsWrappingTextCell" bundle:bundle] forCellReuseIdentifier:InsightsTableWrappingTextCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:@"InsightsWrappingTextCell" bundle:bundle] forCellReuseIdentifier:InsightsTableWrappingTextLayoutCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:@"StatsNoResultsRowTableViewCell" bundle:bundle] forCellReuseIdentifier:StatsTableNoResultsCellIdentifier];

    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 20.0f)];
    self.tableView.backgroundColor = [WPStyleGuide itsEverywhereGrey];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    self.sections = @[@(StatsSectionInsightsLatestPostSummary),
                      @(StatsSectionInsightsTodaysStats),
                      @(StatsSectionInsightsAllTime),
                      @(StatsSectionInsightsMostPopular),
                      @(StatsSectionInsightsPostActivity),
                      @(StatsSectionPeriodHeader),
                      @(StatsSectionComments),
                      @(StatsSectionTagsCategories),
                      @(StatsSectionFollowers),
                      @(StatsSectionPublicize)];
    self.subSections =  @{ @(StatsSectionComments)  : @[@(StatsSubSectionCommentsByAuthor), @(StatsSubSectionCommentsByPosts)],
                           @(StatsSectionFollowers) : @[@(StatsSubSectionFollowersDotCom),  @(StatsSubSectionFollowersEmail)]};
    self.selectedSubsections = [@{ @(StatsSectionComments)  : @(StatsSubSectionCommentsByAuthor),
                                   @(StatsSectionFollowers) : @(StatsSubSectionFollowersDotCom)} mutableCopy];

    [self wipeDataAndSeedGroups];

    [self setupRefreshControl];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self retrieveStats];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [WPAnalytics track:WPAnalyticsStatStatsInsightsAccessed withProperties:@{ @"blog_id" : self.statsService.siteId}];
}


#pragma mark - UITraitEnvironment methods

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    [self.tableView reloadData];
}


#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return (NSInteger)self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    StatsSection statsSection = [self statsSectionForTableViewSection:section];
    id data = [self statsDataForStatsSection:statsSection];
    
    switch (statsSection) {
        case StatsSectionInsightsAllTime:
        case StatsSectionInsightsMostPopular:
            return 2;
        case StatsSectionInsightsPostActivity:
            return 2;
        case StatsSectionInsightsTodaysStats:
            return self.isViewHorizontallyCompact ? 5 : 2;
        case StatsSectionPeriodHeader:
            return 1;
        case StatsSectionInsightsLatestPostSummary:
            if (!data) {
                // Show only header and text description if no data is present
                return 2;
            } else {
                return self.isViewHorizontallyCompact ? 5 : 3;
            }
            
            // TODO :: Pull offset from StatsGroup
        default:
        {
            StatsGroup *group = (StatsGroup *)[self statsDataForStatsSection:statsSection];
            NSInteger count = (NSInteger)group.numberOfRows;
            
            if (statsSection == StatsSectionComments) {
                count += StatsTableRowDataOffsetWithGroupSelector;
            } else if (statsSection == StatsSectionFollowers) {
                count += StatsTableRowDataOffsetWithGroupSelectorAndTotal;
                
                if (group.errorWhileRetrieving || count == StatsTableRowDataOffsetWithGroupSelectorAndTotal) {
                    count--;
                }
            } else if (statsSection == StatsSectionEvents) {
                if (count == 0) {
                    count = StatsTableRowDataOffsetStandard;
                } else {
                    count += StatsTableRowDataOffsetWithoutGroupHeader;
                }
            } else {
                count += StatsTableRowDataOffsetStandard;
            }
            
            if (group.moreItemsExist) {
                count++;
            }
            
            return count;
        }
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = [self cellIdentifierForIndexPath:indexPath];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    
    [self configureCell:cell forIndexPath:indexPath];
    
    return cell;
}


#pragma mark - UITableViewDelegate methods

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if ([self statsSectionForTableViewSection:section] != StatsSectionPeriodHeader) {
        StatsTableSectionHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:StatsTableSectionHeaderSimpleBorder];
        
        return headerView;
    }
    
    return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if ([self statsSectionForTableViewSection:section] != StatsSectionPeriodHeader) {
        StatsTableSectionHeaderView *footerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:StatsTableSectionHeaderSimpleBorder];
        footerView.footer = YES;
        
        return footerView;
    }
    
    return nil;
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return InsightsTableSectionHeaderHeight;
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return InsightsTableSectionFooterHeight;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = [self cellIdentifierForIndexPath:indexPath];
    
    if ([identifier isEqualToString:InsightsTableSectionHeaderCellIdentifier]) {
        return 44.0f;    
    } else if ([identifier isEqualToString:InsightsTableMostPopularDetailsCellIdentifier]) {
        return 150.0f;
    } else if ([identifier isEqualToString:InsightsTablePostActivityCellIdentifier]) {
        return 150.0f;
    } else if ([identifier isEqualToString:InsightsTableAllTimeDetailsCellIdentifier]) {
        return 185.0f;
    } else if ([identifier isEqualToString:InsightsTableAllTimeDetailsiPadCellIdentifier]) {
        return 100.0f;
    } else if ([identifier isEqualToString:InsightsTableTodaysStatsDetailsiPadCellIdentifier] ||
               [identifier isEqualToString:InsightsTableLatestPostSummaryDetailsiPadCellIdentifier]) {
        return 66.0f;
    } else if ([identifier isEqualToString:StatsTableGroupHeaderCellIdentifier]) {
        return StatsTableGroupHeaderHeight;
    } else if ([identifier isEqualToString:StatsTableNoResultsCellIdentifier]) {
        return StatsTableNoResultsHeight;
    } else if ([identifier isEqualToString:InsightsTableWrappingTextCellIdentifier]) {
        StatsStandardBorderedTableViewCell *cell = (StatsStandardBorderedTableViewCell *)[tableView dequeueReusableCellWithIdentifier:InsightsTableWrappingTextLayoutCellIdentifier];
        cell.bounds = CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
        
        UILabel *label = (UILabel *)[cell.contentView viewWithTag:100];
        label.preferredMaxLayoutWidth = CGRectGetWidth(tableView.bounds) - 46.0f;
        label.attributedText = [self latestPostSummaryAttributedString];
        [cell setNeedsLayout];
        [cell layoutIfNeeded];
        
        CGSize size = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];

        return size.height;
    }

    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}


- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    StatsSection statsSection = [self statsSectionForTableViewSection:indexPath.section];
    NSString *identifier = [self cellIdentifierForIndexPath:indexPath];
    
    if ([identifier isEqualToString:StatsTableViewAllCellIdentifier] ||
        (statsSection == StatsSectionInsightsTodaysStats) ||
        (statsSection == StatsSectionInsightsPostActivity) ||
        (statsSection == StatsSectionInsightsLatestPostSummary)) {
        return indexPath;
    } else if ([identifier isEqualToString:StatsTableTwoColumnCellIdentifier]) {
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


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *identifier = [self cellIdentifierForIndexPath:indexPath];
    
    StatsSection statsSection = [self statsSectionForTableViewSection:indexPath.section];
    id data = [self statsDataForStatsSection:statsSection];
    
    if ([[self cellIdentifierForIndexPath:indexPath] isEqualToString:StatsTableTwoColumnCellIdentifier]) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        StatsGroup *statsGroup = [self statsDataForStatsSection:statsSection];
        StatsItem *statsItem = [statsGroup statsItemForTableViewRow:indexPath.row];
        
        // Do nothing for posts - handled by segue to show post details
        if (statsSection == StatsSectionPosts || (statsSection == StatsSectionAuthors && statsItem.parent != nil)) {
            return;
        }
        
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
    } else if (statsSection == StatsSectionInsightsTodaysStats &&
               ([identifier isEqualToString:InsightsTableSectionHeaderCellIdentifier] || [identifier isEqualToString:InsightsTableTodaysStatsDetailsiPadCellIdentifier])) {
        if ([self.statsTypeSelectionDelegate conformsToProtocol:@protocol(WPStatsSummaryTypeSelectionDelegate)]) {
            [self.statsTypeSelectionDelegate viewController:self changeStatsSummaryTypeSelection:StatsSummaryTypeViews];
        }
    } else if (statsSection == StatsSectionInsightsTodaysStats && self.isViewHorizontallyCompact && [self.statsTypeSelectionDelegate conformsToProtocol:@protocol(WPStatsSummaryTypeSelectionDelegate)]) {
        switch (indexPath.row) {
            case 0:
            case 1:
                [self.statsTypeSelectionDelegate viewController:self changeStatsSummaryTypeSelection:StatsSummaryTypeViews];
                break;
            case 2:
                [self.statsTypeSelectionDelegate viewController:self changeStatsSummaryTypeSelection:StatsSummaryTypeVisitors];
                break;
            case 3:
                [self.statsTypeSelectionDelegate viewController:self changeStatsSummaryTypeSelection:StatsSummaryTypeLikes];
                break;
            case 4:
                [self.statsTypeSelectionDelegate viewController:self changeStatsSummaryTypeSelection:StatsSummaryTypeComments];
                break;
            default:
                break;
        }
    } else if (statsSection == StatsSectionInsightsPostActivity && [identifier isEqualToString:InsightsTableSectionHeaderCellIdentifier] && !!data) {
        [self performSegueWithIdentifier:SeguePostActivity sender:[tableView cellForRowAtIndexPath:indexPath]];
    } else if (statsSection == StatsSectionInsightsLatestPostSummary && [identifier isEqualToString:InsightsTableSectionHeaderCellIdentifier] && !!data) {
        [self performSegueWithIdentifier:SegueLatestPostDetailsiPad sender:[tableView cellForRowAtIndexPath:indexPath]];
    } else if (statsSection == StatsSectionInsightsLatestPostSummary && [identifier isEqualToString:InsightsTableWrappingTextCellIdentifier]) {
        StatsLatestPostSummary *summary = [self statsDataForStatsSection:statsSection];
        if ([self.statsDelegate respondsToSelector:@selector(statsViewController:openURL:)]) {
            WPStatsViewController *statsViewController = (WPStatsViewController *)self.navigationController;
            [self.statsDelegate statsViewController:statsViewController openURL:summary.postURL];
        } else {
            [AppExtensionUtils openURL:summary.postURL fromController:self];
        }
    }
}


#pragma mark - Segue methods

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(UITableViewCell *)sender
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    StatsSection statsSection = [self statsSectionForTableViewSection:indexPath.section];
    id data = [self statsDataForStatsSection:statsSection];

    if ([identifier isEqualToString:SegueLatestPostDetails]) {
        return statsSection == StatsSectionInsightsLatestPostSummary && indexPath.row == 2 && !!data;
    } else if ([identifier isEqualToString:SegueLatestPostDetailsiPad]) {
        return statsSection == StatsSectionInsightsLatestPostSummary && !!data;
    } else if ([identifier isEqualToString:SeguePostActivity]) {
        return statsSection == StatsSectionInsightsPostActivity && !!data;
    }
    
    return YES;
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [super prepareForSegue:segue sender:sender];
    
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    StatsSection statsSection = [self statsSectionForTableViewSection:indexPath.section];
    StatsSubSection statsSubSection = [self statsSubSectionForStatsSection:statsSection];
    
    if ([segue.destinationViewController isKindOfClass:[StatsViewAllTableViewController class]]) {
        StatsViewAllTableViewController *viewAllVC = (StatsViewAllTableViewController *)segue.destinationViewController;
        viewAllVC.selectedDate = nil;
        viewAllVC.periodUnit = StatsPeriodUnitDay;
        viewAllVC.statsSection = statsSection;
        viewAllVC.statsSubSection = statsSubSection;
        viewAllVC.statsService = self.statsService;
        viewAllVC.statsDelegate = self.statsDelegate;
    } else if ([segue.identifier isEqualToString:SeguePostActivity]) {
        InsightsPostingActivityCollectionViewController *postActivityCollectionVC = (InsightsPostingActivityCollectionViewController *)segue.destinationViewController;
        StatsStreak *streak = [self statsDataForStatsSection:StatsSectionInsightsPostActivity];
        postActivityCollectionVC.streakData = streak;
    } else if ([segue.identifier isEqualToString:SegueLatestPostDetails] ||
               [segue.identifier isEqualToString:SegueLatestPostDetailsiPad]) {
        // This is kind of a hack since we trigger this seque programmatically sometimes
        // and don't have a reference to the UITableViewCell for section calculation always
        StatsLatestPostSummary *summary = [self statsDataForStatsSection:StatsSectionInsightsLatestPostSummary];
        
        StatsPostDetailsTableViewController *postVC = (StatsPostDetailsTableViewController *)segue.destinationViewController;
        postVC.postID = summary.postID;
        postVC.postTitle = summary.postTitle;
        postVC.statsService = self.statsService;
        postVC.statsDelegate = self.statsDelegate;
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}


#pragma mark - Private cell configuration methods

- (NSString *)cellIdentifierForIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = @"";
    
    StatsSection statsSection = [self statsSectionForTableViewSection:indexPath.section];
    
    switch (statsSection) {
        case StatsSectionInsightsAllTime:
            if (indexPath.row == 0) {
                identifier = InsightsTableSectionHeaderCellIdentifier;
            } else {
                identifier = self.isViewHorizontallyCompact ? InsightsTableAllTimeDetailsCellIdentifier : InsightsTableAllTimeDetailsiPadCellIdentifier;
            }
            break;
    
        case StatsSectionInsightsMostPopular:
            if (indexPath.row == 0) {
                identifier = InsightsTableSectionHeaderCellIdentifier;
            } else {
                identifier = InsightsTableMostPopularDetailsCellIdentifier;
            }
            break;

        case StatsSectionInsightsPostActivity:
        {
            id data = (StatsStreak *)[self statsDataForStatsSection:statsSection];
            if (indexPath.row == 0) {
                identifier = InsightsTableSectionHeaderCellIdentifier;
            } else if (data) {
                identifier = InsightsTablePostActivityCellIdentifier;
            } else {
                identifier = StatsTableNoResultsCellIdentifier;
            }
            break;
        }
            
        case StatsSectionInsightsTodaysStats:
            if (indexPath.row == 0) {
                identifier = InsightsTableSectionHeaderCellIdentifier;
            } else if (!self.isViewHorizontallyCompact) {
                identifier = InsightsTableTodaysStatsDetailsiPadCellIdentifier;
            } else {
                identifier = StatsTableSelectableCellIdentifier;
            }
            break;

        case StatsSectionInsightsLatestPostSummary:
            if (indexPath.row == 0) {
                identifier = InsightsTableSectionHeaderCellIdentifier;
            } else if (indexPath.row == 1) {
                identifier = InsightsTableWrappingTextCellIdentifier;
            } else {
                identifier = self.isViewHorizontallyCompact ? StatsTableSelectableCellIdentifier : InsightsTableLatestPostSummaryDetailsiPadCellIdentifier;
            }
            break;
            
        case StatsSectionPeriodHeader:
            return StatsTablePeriodHeaderCellIdentifier;

        case StatsSectionTagsCategories:
        case StatsSectionPublicize:
        {
            StatsGroup *group = (StatsGroup *)[self statsDataForStatsSection:statsSection];
            if (indexPath.row == 0) {
                identifier = StatsTableGroupHeaderCellIdentifier;
            } else if (indexPath.row == 1 && group.numberOfRows > 0) {
                identifier = StatsTableTwoColumnHeaderCellIdentifier;
            } else if (indexPath.row == 1) {
                identifier = StatsTableNoResultsCellIdentifier;
            } else if (group.moreItemsExist && indexPath.row == (NSInteger)(group.numberOfRows + StatsTableRowDataOffsetStandard)) {
                identifier = StatsTableViewAllCellIdentifier;
            } else {
                identifier = StatsTableTwoColumnCellIdentifier;
            }
            break;
        }
            
        case StatsSectionFollowers:
        {
            StatsGroup *group = [self statsDataForStatsSection:statsSection];
            
            if (indexPath.row == 0) {
                identifier = StatsTableGroupHeaderCellIdentifier;
            } else if (indexPath.row == 1) {
                identifier = StatsTableGroupSelectorCellIdentifier;
            } else if (indexPath.row == 2) {
                if (group.numberOfRows > 0) {
                    identifier = StatsTableGroupTotalsCellIdentifier;
                } else {
                    identifier = StatsTableNoResultsCellIdentifier;
                }
            } else if (indexPath.row == 3) {
                identifier = StatsTableTwoColumnHeaderCellIdentifier;
            } else {
                if (group.moreItemsExist && indexPath.row == (NSInteger)(group.numberOfRows + StatsTableRowDataOffsetWithGroupSelectorAndTotal)) {
                    identifier = StatsTableViewAllCellIdentifier;
                } else {
                    identifier = StatsTableTwoColumnCellIdentifier;
                }
            }
            
            break;
        }
            
        case StatsSectionComments:
        {
            StatsGroup *group = [self statsDataForStatsSection:statsSection];
            
            if (indexPath.row == 0) {
                identifier = StatsTableGroupHeaderCellIdentifier;
            } else if (indexPath.row == 1) {
                identifier = StatsTableGroupSelectorCellIdentifier;
            } else if (indexPath.row == 2) {
                if (group.numberOfRows > 0) {
                    identifier = StatsTableTwoColumnHeaderCellIdentifier;
                } else {
                    identifier = StatsTableNoResultsCellIdentifier;
                }
            } else {
                if (group.moreItemsExist && indexPath.row == (NSInteger)(group.numberOfRows + StatsTableRowDataOffsetWithGroupSelector)) {
                    identifier = StatsTableViewAllCellIdentifier;
                } else {
                    identifier = StatsTableTwoColumnCellIdentifier;
                }
            }
            
            break;
        }
            
        case StatsSectionGraph:
        case StatsSectionEvents:
        case StatsSectionPosts:
        case StatsSectionReferrers:
        case StatsSectionClicks:
        case StatsSectionCountry:
        case StatsSectionVideos:
        case StatsSectionAuthors:
        case StatsSectionSearchTerms:
        case StatsSectionWebVersion:
        case StatsSectionPostDetailsAveragePerDay:
        case StatsSectionPostDetailsGraph:
        case StatsSectionPostDetailsLoadingIndicator:
        case StatsSectionPostDetailsMonthsYears:
        case StatsSectionPostDetailsRecentWeeks:
            break;
    }
    
    return identifier;
}


- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    StatsSection statsSection = [self statsSectionForTableViewSection:indexPath.section];
    NSString *identifier = cell.reuseIdentifier;
    
    if ([identifier isEqualToString:InsightsTableSectionHeaderCellIdentifier]) {
        [self configureSectionHeaderCell:(InsightsSectionHeaderTableViewCell *)cell forSection:indexPath.section];
    } else if ([identifier isEqualToString:InsightsTableAllTimeDetailsCellIdentifier] || [identifier isEqualToString:InsightsTableAllTimeDetailsiPadCellIdentifier]) {
        [self configureAllTimeCell:(InsightsAllTimeTableViewCell *)cell];
    } else if ([identifier isEqualToString:InsightsTableMostPopularDetailsCellIdentifier]) {
        [self configureMostPopularCell:(InsightsMostPopularTableViewCell *)cell];
    } else if ([identifier isEqualToString:InsightsTablePostActivityCellIdentifier]) {
        [self configurePostingActivity:(InsightsPostingActivityTableViewCell *)cell];
    } else if ([identifier isEqualToString:InsightsTableTodaysStatsDetailsiPadCellIdentifier] || [identifier isEqualToString:InsightsTableLatestPostSummaryDetailsiPadCellIdentifier]) {
        [self configureTodaysStatsCell:(InsightsTodaysStatsTableViewCell *)cell forStatsSection:statsSection];
    } else if ([identifier isEqualToString:StatsTableSelectableCellIdentifier]) {
        [self configureSectionSelectableCell:(StatsSelectableTableViewCell *)cell forIndexPath:indexPath];
    } else if ([identifier isEqualToString:StatsTablePeriodHeaderCellIdentifier]) {
        cell.backgroundColor = self.tableView.backgroundColor;
        UILabel *label = (UILabel *)[cell.contentView viewWithTag:100];
        label.text = NSLocalizedString(@"Other Recent Stats", @"Non-periodic stats module header in Insights");
    } else if ([identifier isEqualToString:StatsTableGroupHeaderCellIdentifier]) {
        [self configureSectionGroupHeaderCell:(StatsStandardBorderedTableViewCell *)cell
                             withStatsSection:statsSection];
    } else if ([identifier isEqualToString:StatsTableGroupSelectorCellIdentifier]) {
        [self configureSectionGroupSelectorCell:(StatsStandardBorderedTableViewCell *)cell withStatsSection:statsSection];
    } else if ([identifier isEqualToString:StatsTableTwoColumnHeaderCellIdentifier]) {
        [self configureSectionTwoColumnHeaderCell:(StatsStandardBorderedTableViewCell *)cell
                                 withStatsSection:statsSection];
    } else if ([identifier isEqualToString:StatsTableGroupTotalsCellIdentifier]) {
        StatsGroup *group = [self statsDataForStatsSection:statsSection];
        [self configureSectionGroupTotalCell:cell withStatsSection:statsSection andTotal:group.totalCount];
    } else if ([identifier isEqualToString:StatsTableNoResultsCellIdentifier]) {
        [self configureNoResultsCell:cell withStatsSection:statsSection];
    } else if ([identifier isEqualToString:StatsTableViewAllCellIdentifier]) {
        UILabel *label = (UILabel *)[cell.contentView viewWithTag:100];
        label.text = NSLocalizedString(@"View All", @"View All button in stats for larger list");
        label.textColor = [WPStyleGuide wordPressBlue];
    } else if ([identifier isEqualToString:StatsTableTwoColumnCellIdentifier]) {
        StatsGroup *group = [self statsDataForStatsSection:statsSection];
        StatsItem *item = [group statsItemForTableViewRow:indexPath.row];
        StatsItem *nextItem = [group statsItemForTableViewRow:indexPath.row + 1];
        
        [self configureTwoColumnRowCell:cell
                        forStatsSection:statsSection
                          withStatsItem:item
                       andNextStatsItem:nextItem];
    } else if ([identifier isEqualToString:InsightsTableWrappingTextCellIdentifier]) {
        [self configureInsightsWrappingTextCell:(StatsStandardBorderedTableViewCell *)cell];
    } else {
        DDLogWarn(@"ConfigureCell called with unknown cell identifier: %@", identifier);
    }
}


- (void)configureSectionHeaderCell:(InsightsSectionHeaderTableViewCell *)cell forSection:(NSInteger)section
{
    StatsSection statsSection = [self statsSectionForTableViewSection:section];
    id data = [self statsDataForStatsSection:statsSection];

    cell.sectionHeaderLabel.textColor = [WPStyleGuide darkGrey];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.bottomBorderEnabled = YES;
    
    switch (statsSection) {
        case StatsSectionInsightsAllTime:
            cell.sectionHeaderLabel.text = NSLocalizedString(@"All-time posts, views, and visitors", @"Insights all time section header");
            break;
        case StatsSectionInsightsMostPopular:
            cell.sectionHeaderLabel.text = NSLocalizedString(@"Most popular day and hour", @"Insights popular section header");
            break;
        case StatsSectionInsightsPostActivity:
            cell.sectionHeaderLabel.text = NSLocalizedString(@"Posting Activity", @"Insights posting activity header");
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            break;
        case StatsSectionInsightsTodaysStats:
            cell.sectionHeaderLabel.text = NSLocalizedString(@"Today's Stats", @"Insights today section header");
            cell.sectionHeaderLabel.textColor = [WPStyleGuide wordPressBlue];
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            break;
        case StatsSectionInsightsLatestPostSummary:
            cell.sectionHeaderLabel.text = NSLocalizedString(@"Latest Post Summary", @"Insights latest post summary section header");
            cell.sectionHeaderLabel.textColor = [WPStyleGuide wordPressBlue];
            cell.selectionStyle = !!data ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
            cell.bottomBorderEnabled = NO;
            break;
        default:
            break;
    }
}


- (void)configureAllTimeCell:(InsightsAllTimeTableViewCell *)cell
{
    StatsAllTime *statsAllTime = self.sectionData[@(StatsSectionInsightsAllTime)];
    
    if (!statsAllTime) {
        cell.allTimePostsValueLabel.text = @"-";
        cell.allTimePostsValueLabel.textColor = [WPStyleGuide greyLighten20];
        cell.allTimeViewsValueLabel.text = @"-";
        cell.allTimeViewsValueLabel.textColor = [WPStyleGuide greyLighten20];
        cell.allTimeVisitorsValueLabel.text = @"-";
        cell.allTimeVisitorsValueLabel.textColor = [WPStyleGuide greyLighten20];
        cell.allTimeBestViewsValueLabel.text = @"-";
        cell.allTimeBestViewsValueLabel.textColor = [WPStyleGuide greyLighten20];
        cell.allTimeBestViewsOnValueLabel.text = NSLocalizedString(@"Unknown", @"Unknown data in value label");
        cell.allTimeBestViewsOnValueLabel.textColor = [WPStyleGuide greyLighten20];
    } else {
        cell.allTimePostsValueLabel.textColor = [WPStyleGuide darkGrey];
        cell.allTimePostsValueLabel.text = statsAllTime.numberOfPosts;
        cell.allTimeViewsValueLabel.textColor = [WPStyleGuide darkGrey];
        cell.allTimeViewsValueLabel.text = statsAllTime.numberOfViews;
        cell.allTimeVisitorsValueLabel.textColor = [WPStyleGuide darkGrey];
        cell.allTimeVisitorsValueLabel.text = statsAllTime.numberOfVisitors;
        cell.allTimeBestViewsValueLabel.textColor = [WPStyleGuide darkGrey];
        cell.allTimeBestViewsValueLabel.text = statsAllTime.bestNumberOfViews;
        cell.allTimeBestViewsOnValueLabel.textColor = [WPStyleGuide darkGrey];
        cell.allTimeBestViewsOnValueLabel.text = statsAllTime.bestViewsOn;
    }
}


- (void)configureMostPopularCell:(InsightsMostPopularTableViewCell *)cell
{
    cell.mostPopularDayLabel.text = [NSLocalizedString(@"Most popular day", @"Insights most popular day section label") uppercaseStringWithLocale:[NSLocale currentLocale]];
    cell.mostPopularDayLabel.textColor = [WPStyleGuide darkGrey];
    cell.mostPopularHourLabel.text = [NSLocalizedString(@"Most popular hour", @"Insights most popular hour section label") uppercaseStringWithLocale:[NSLocale currentLocale]];
    cell.mostPopularHourLabel.textColor = [WPStyleGuide darkGrey];

    StatsInsights *statsInsights = self.sectionData[@(StatsSectionInsightsMostPopular)];
    
    cell.mostPopularDayPercentWeeklyViews.textColor = [WPStyleGuide darkGrey];
    cell.mostPopularHourPercentDailyViews.textColor = [WPStyleGuide darkGrey];

    if (!statsInsights) {
        cell.mostPopularDay.text = @"-";
        cell.mostPopularDay.textColor = [WPStyleGuide greyLighten20];
        cell.mostPopularDayPercentWeeklyViews.text = [NSString stringWithFormat:NSLocalizedString(@"%@ of views", @"Insights Percent of views label with value"), @"-"];
        cell.mostPopularHour.text = @"-";
        cell.mostPopularHour.textColor = [WPStyleGuide greyLighten20];
        cell.mostPopularHourPercentDailyViews.text = [NSString stringWithFormat:NSLocalizedString(@"%@ of views", @"Insights Percent of views label with value"), @"-"];
    } else {
        cell.mostPopularDay.text = statsInsights.highestDayOfWeek;
        cell.mostPopularDay.textColor = [WPStyleGuide greyDarken30];
        cell.mostPopularHour.text = statsInsights.highestHour;
        cell.mostPopularHour.textColor = [WPStyleGuide greyDarken30];
        cell.mostPopularDayPercentWeeklyViews.text = [NSString stringWithFormat:NSLocalizedString(@"%@ of views", @"Insights Percent of views label with value"), statsInsights.highestDayPercent];
        cell.mostPopularHourPercentDailyViews.text = [NSString stringWithFormat:NSLocalizedString(@"%@ of views", @"Insights Percent of views label with value"), statsInsights.highestHourPercent];
    }
    
}

- (void)configurePostingActivity:(InsightsPostingActivityTableViewCell *)cell
{
    id data = self.sectionData[@(StatsSectionInsightsPostActivity)];
    if (data) {
        StatsStreak *streak = (StatsStreak *)data;
        NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        NSDate *twoMonthsAgo = [gregorian dateByAddingUnit:NSCalendarUnitMonth value:-2 toDate:[NSDate date] options:0];
        
        cell.contributionGraphLeft.monthForGraph = twoMonthsAgo;
        StatsStreak *streakLeft = [streak copy];
        [streakLeft pruneItemsOutsideOfMonth:twoMonthsAgo];
        cell.contributionGraphLeft.graphData = streakLeft;
        
        cell.contributionGraphCenter.monthForGraph = [gregorian dateByAddingUnit:NSCalendarUnitMonth value:1 toDate:twoMonthsAgo options:0];
        StatsStreak *streakCenter = [streak copy];
        [streakCenter pruneItemsOutsideOfMonth:cell.contributionGraphCenter.monthForGraph];
        cell.contributionGraphCenter.graphData = streakCenter;
        
        cell.contributionGraphRight.monthForGraph = [gregorian dateByAddingUnit:NSCalendarUnitMonth value:2 toDate:twoMonthsAgo options:0];
        StatsStreak *streakRight = [streak copy];
        [streakRight pruneItemsOutsideOfMonth:cell.contributionGraphRight.monthForGraph];
        cell.contributionGraphRight.graphData = streakRight;
        
        cell.selectable = YES;
        [cell doneSettingProperties];
    }
}

- (void)configureTodaysStatsCell:(InsightsTodaysStatsTableViewCell *)cell forStatsSection:(StatsSection)statsSection
{
    id data = [self statsDataForStatsSection:statsSection];
    
    if (!data) {
        // Default values for no data
        [cell.todayViewsValueButton setTitle:@"-" forState:UIControlStateNormal];
        [cell.todayViewsValueButton setTitleColor:[WPStyleGuide greyLighten20] forState:UIControlStateNormal];
        [cell.todayVisitorsValueButton setTitle:@"-" forState:UIControlStateNormal];
        [cell.todayVisitorsValueButton setTitleColor:[WPStyleGuide greyLighten20] forState:UIControlStateNormal];
        [cell.todayLikesValueButton setTitle:@"-" forState:UIControlStateNormal];
        [cell.todayLikesValueButton setTitleColor:[WPStyleGuide greyLighten20] forState:UIControlStateNormal];
        [cell.todayCommentsValueButton setTitle:@"-" forState:UIControlStateNormal];
        [cell.todayCommentsValueButton setTitleColor:[WPStyleGuide greyLighten20] forState:UIControlStateNormal];
    } else if (statsSection == StatsSectionInsightsTodaysStats) {
        StatsSummary *todaySummary = (StatsSummary *)data;
        [cell.todayViewsValueButton setTitle:todaySummary.views forState:UIControlStateNormal];
        [cell.todayViewsValueButton setTitleColor:todaySummary.viewsValue.integerValue == 0 ? [WPStyleGuide grey] : [WPStyleGuide wordPressBlue] forState:UIControlStateNormal];
        [cell.todayVisitorsValueButton setTitle:todaySummary.visitors forState:UIControlStateNormal];
        [cell.todayVisitorsValueButton setTitleColor:todaySummary.visitorsValue.integerValue == 0 ? [WPStyleGuide grey] : [WPStyleGuide wordPressBlue] forState:UIControlStateNormal];
        [cell.todayLikesValueButton setTitle:todaySummary.likes forState:UIControlStateNormal];
        [cell.todayLikesValueButton setTitleColor:todaySummary.likesValue.integerValue == 0 ? [WPStyleGuide grey] : [WPStyleGuide wordPressBlue] forState:UIControlStateNormal];
        [cell.todayCommentsValueButton setTitle:todaySummary.comments forState:UIControlStateNormal];
        [cell.todayCommentsValueButton setTitleColor:todaySummary.commentsValue.integerValue == 0 ? [WPStyleGuide grey] : [WPStyleGuide wordPressBlue] forState:UIControlStateNormal];
    } else if (statsSection == StatsSectionInsightsLatestPostSummary) {
        StatsLatestPostSummary *latestPostSummary = (StatsLatestPostSummary *)data;
        [cell.todayViewsValueButton setTitle:latestPostSummary.views forState:UIControlStateNormal];
        [cell.todayViewsValueButton setTitleColor:latestPostSummary.viewsValue.integerValue == 0 ? [WPStyleGuide grey] : [WPStyleGuide wordPressBlue] forState:UIControlStateNormal];
        [cell.todayLikesValueButton setTitle:latestPostSummary.likes forState:UIControlStateNormal];
        [cell.todayLikesValueButton setTitleColor:latestPostSummary.likesValue.integerValue == 0 ? [WPStyleGuide grey] : [WPStyleGuide wordPressBlue] forState:UIControlStateNormal];
        [cell.todayCommentsValueButton setTitle:latestPostSummary.comments forState:UIControlStateNormal];
        [cell.todayCommentsValueButton setTitleColor:latestPostSummary.commentsValue.integerValue == 0 ? [WPStyleGuide grey] : [WPStyleGuide wordPressBlue] forState:UIControlStateNormal];
    }

}

- (void)configureSectionSelectableCell:(StatsSelectableTableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    cell.selectedIsLighter = NO;
    cell.unselectedCellValueColor = [WPStyleGuide wordPressBlue];
    
    StatsSection statsSection = [self statsSectionForTableViewSection:indexPath.section];

    if (statsSection == StatsSectionInsightsTodaysStats) {
        StatsSummary *todaySummary = [self statsDataForStatsSection:statsSection];
        
        switch (indexPath.row) {
            case 1: // Views
            {
                cell.cellType = StatsSelectableTableViewCellTypeViews;
                cell.valueLabel.text = todaySummary.views ?: @"-";
                break;
            }
                
            case 2: // Visitors
            {
                cell.cellType = StatsSelectableTableViewCellTypeVisitors;
                cell.valueLabel.text = todaySummary.visitors ?: @"-";
                break;
            }
                
            case 3: // Likes
            {
                cell.cellType = StatsSelectableTableViewCellTypeLikes;
                cell.valueLabel.text = todaySummary.likes ?: @"-";
                break;
            }
                
            case 4: // Comments
            {
                cell.cellType = StatsSelectableTableViewCellTypeComments;
                cell.valueLabel.text = todaySummary.comments ?: @"-";
                break;
            }
                
            default:
                break;
        }
    } else if (statsSection == StatsSectionInsightsLatestPostSummary) {
        StatsLatestPostSummary *latestPostSummary = [self statsDataForStatsSection:statsSection];
        switch (indexPath.row) {
            case 2: // Views
            {
                cell.cellType = StatsSelectableTableViewCellTypeViews;
                cell.valueLabel.text = latestPostSummary.views ?: @"-";
                break;
            }
                
            case 3: // Likes
            {
                cell.cellType = StatsSelectableTableViewCellTypeLikes;
                cell.valueLabel.text = latestPostSummary.likes ?: @"-";
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                break;
            }
                
            case 4: // Comments
            {
                cell.cellType = StatsSelectableTableViewCellTypeComments;
                cell.valueLabel.text = latestPostSummary.comments ?: @"-";
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                break;
            }
                
            default:
                break;
        }
    }
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


- (void)configureSectionTwoColumnHeaderCell:(StatsStandardBorderedTableViewCell *)cell withStatsSection:(StatsSection)statsSection
{
    StatsGroup *statsGroup = [self statsDataForStatsSection:statsSection];
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


- (void)configureSectionGroupTotalCell:(UITableViewCell *)cell withStatsSection:(StatsSection)statsSection andTotal:(NSString *)total
{
    NSString *title;
    StatsSubSection selectedSubsection = [self statsSubSectionForStatsSection:statsSection];
    
    switch (selectedSubsection) {
        case StatsSubSectionFollowersDotCom:
            title = [NSString stringWithFormat:NSLocalizedString(@"Total WordPress.com Followers: %@", @"Label of Total count of WordPress.com followers with value"), total];
            break;
        case StatsSubSectionFollowersEmail:
            title = [NSString stringWithFormat:NSLocalizedString(@"Total Email Followers: %@", @"Label of Total count of email followers with value"), total];
            break;
        default:
            break;
    }
    
    UILabel *label = (UILabel *)[cell.contentView viewWithTag:100];
    label.text = title;
}


- (void)configureSectionGroupSelectorCell:(StatsStandardBorderedTableViewCell *)cell withStatsSection:(StatsSection)statsSection
{
    NSArray *titles;
    NSInteger selectedIndex = 0;
    StatsSubSection selectedSubsection = [self statsSubSectionForStatsSection:statsSection];
    
    switch (statsSection) {
        case StatsSectionComments:
            titles = @[NSLocalizedString(@"By Authors", @"Authors segmented control for stats"),
                       NSLocalizedString(@"By Posts & Pages", @"Posts & Pages segmented control for stats")];
            selectedIndex = selectedSubsection == StatsSubSectionCommentsByAuthor ? 0 : 1;
            break;
        case StatsSectionFollowers:
            titles = @[NSLocalizedString(@"WordPress.com", @"WordPress.com segmented control for stats"),
                       NSLocalizedString(@"Email", @"Email segmented control for stats")];
            selectedIndex = selectedSubsection == StatsSubSectionFollowersDotCom ? 0 : 1;
            break;
        default:
            break;
    }
    
    UISegmentedControl *control = (UISegmentedControl *)[cell.contentView viewWithTag:100];
    cell.bottomBorderEnabled = NO;
    cell.contentView.tag = statsSection;
    
    [control removeAllSegments];
    
    for (NSString *title in [titles reverseObjectEnumerator]) {
        [control insertSegmentWithTitle:title atIndex:0 animated:NO];
    }
    
    control.selectedSegmentIndex = selectedIndex;
}


- (void)configureNoResultsCell:(UITableViewCell *)cell withStatsSection:(StatsSection)statsSection
{
    NSString *text;
    id data = [self statsDataForStatsSection:statsSection];
    
    if (!data) {
        text = NSLocalizedString(@"Waiting for data...", @"Message displayed in stats while waiting for remote operations to finish.");
    } else if ([data errorWhileRetrieving] == YES) {
        text = NSLocalizedString(@"An error occurred while retrieving data. Retry in a bit!", @"Error message in section when data failed.");
    } else {
        switch (statsSection) {
            case StatsSectionComments:
                text = NSLocalizedString(@"No comments posted", @"");
                break;
            case StatsSectionFollowers:
                text = NSLocalizedString(@"No followers", @"");
                break;
            case StatsSectionPublicize:
                text = NSLocalizedString(@"No publicize followers recorded", @"");
                break;
            case StatsSectionTagsCategories:
                text = NSLocalizedString(@"No tagged posts or pages viewed", @"");
                break;
            case StatsSectionInsightsPostActivity:
                text = NSLocalizedString(@"No post activity data available", @"");
                break;
            case StatsSectionAuthors:
            case StatsSectionClicks:
            case StatsSectionCountry:
            case StatsSectionEvents:
            case StatsSectionGraph:
            case StatsSectionPosts:
            case StatsSectionReferrers:
            case StatsSectionSearchTerms:
            case StatsSectionVideos:
            case StatsSectionInsightsAllTime:
            case StatsSectionInsightsMostPopular:
            case StatsSectionInsightsTodaysStats:
            case StatsSectionInsightsLatestPostSummary:
            case StatsSectionPeriodHeader:
            case StatsSectionWebVersion:
            case StatsSectionPostDetailsAveragePerDay:
            case StatsSectionPostDetailsGraph:
            case StatsSectionPostDetailsLoadingIndicator:
            case StatsSectionPostDetailsMonthsYears:
            case StatsSectionPostDetailsRecentWeeks:
                break;
        }
    }
    
    UILabel *label = (UILabel *)[cell.contentView viewWithTag:100];
    label.text = text;
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


- (void)configureInsightsWrappingTextCell:(StatsStandardBorderedTableViewCell *)cell
{
    UILabel *label = (UILabel *)[cell.contentView viewWithTag:100];
    label.attributedText = [self latestPostSummaryAttributedString];
    label.preferredMaxLayoutWidth = CGRectGetWidth(self.tableView.bounds) - 46.0f;
}



#pragma mark - Private methods


- (IBAction)refreshCurrentStats:(UIRefreshControl *)sender
{
    [self.statsService expireAllItemsInCacheForInsights];
    [self retrieveStats];
}


- (void)retrieveStats
{
    if ([self.statsProgressViewDelegate respondsToSelector:@selector(statsViewControllerDidBeginLoadingStats:)]
        && self.refreshControl.isRefreshing == NO) {
        self.refreshControl = nil;
    }

    __weak __typeof(self) weakSelf = self;
    
    [self.statsService retrieveInsightsStatsWithAllTimeStatsCompletionHandler:^(StatsAllTime *allTime, NSError *error)
     {
         if (allTime) {
             weakSelf.sectionData[@(StatsSectionInsightsAllTime)] = allTime;
         }
     }
                                                    insightsCompletionHandler:^(StatsInsights *insights, NSError *error)
     {
         if (insights) {
             weakSelf.sectionData[@(StatsSectionInsightsMostPopular)] = insights;
         }
     }
                                                todaySummaryCompletionHandler:^(StatsSummary *summary, NSError *error)
     {
         if (summary) {
             weakSelf.sectionData[@(StatsSectionInsightsTodaysStats)] = summary;
         }
     }
                                           latestPostSummaryCompletionHandler:^(StatsLatestPostSummary *summary, NSError *error)
     {
         weakSelf.sectionData[@(StatsSectionInsightsLatestPostSummary)] = summary;
         [weakSelf.tableView beginUpdates];
         
         NSUInteger sectionNumber = [weakSelf.sections indexOfObject:@(StatsSectionInsightsLatestPostSummary)];
         NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:sectionNumber];
         [weakSelf.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
         
         [weakSelf.tableView endUpdates];

     }                                               commentsAuthorCompletionHandler:^(StatsGroup *group, NSError *error)
     {
         group.offsetRows = StatsTableRowDataOffsetWithGroupSelector;
         weakSelf.sectionData[@(StatsSectionComments)][@(StatsSubSectionCommentsByAuthor)] = group;
         
         if ([weakSelf.selectedSubsections[@(StatsSectionComments)] isEqualToNumber:@(StatsSubSectionCommentsByAuthor)]) {
             [weakSelf.tableView beginUpdates];
             
             NSUInteger sectionNumber = [weakSelf.sections indexOfObject:@(StatsSectionComments)];
             NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:sectionNumber];
             [weakSelf.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
             
             [weakSelf.tableView endUpdates];
         }
     }
                                               commentsPostsCompletionHandler:^(StatsGroup *group, NSError *error)
     {
         group.offsetRows = StatsTableRowDataOffsetWithGroupSelector;
         weakSelf.sectionData[@(StatsSectionComments)][@(StatsSubSectionCommentsByPosts)] = group;
         
         if ([weakSelf.selectedSubsections[@(StatsSectionComments)] isEqualToNumber:@(StatsSubSectionCommentsByPosts)]) {
             [weakSelf.tableView beginUpdates];
             
             NSUInteger sectionNumber = [weakSelf.sections indexOfObject:@(StatsSectionComments)];
             NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:sectionNumber];
             [weakSelf.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
             
             [weakSelf.tableView endUpdates];
         }
     }
                                              tagsCategoriesCompletionHandler:^(StatsGroup *group, NSError *error)
     {
         group.offsetRows = StatsTableRowDataOffsetStandard;
         weakSelf.sectionData[@(StatsSectionTagsCategories)] = group;
         
         [weakSelf.tableView beginUpdates];
         
         NSUInteger sectionNumber = [weakSelf.sections indexOfObject:@(StatsSectionTagsCategories)];
         NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:sectionNumber];
         [weakSelf.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
         
         [weakSelf.tableView endUpdates];
     }
                                             followersDotComCompletionHandler:^(StatsGroup *group, NSError *error)
     {
         group.offsetRows = StatsTableRowDataOffsetWithGroupSelectorAndTotal;
         weakSelf.sectionData[@(StatsSectionFollowers)][@(StatsSubSectionFollowersDotCom)] = group;
         
         if ([weakSelf.selectedSubsections[@(StatsSectionFollowers)] isEqualToNumber:@(StatsSubSectionFollowersDotCom)]) {
             [weakSelf.tableView beginUpdates];
             
             NSUInteger sectionNumber = [weakSelf.sections indexOfObject:@(StatsSectionFollowers)];
             NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:sectionNumber];
             [weakSelf.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
             
             [weakSelf.tableView endUpdates];
         }
     }
                                              followersEmailCompletionHandler:^(StatsGroup *group, NSError *error)
     {
         group.offsetRows = StatsTableRowDataOffsetWithGroupSelectorAndTotal;
         weakSelf.sectionData[@(StatsSectionFollowers)][@(StatsSubSectionFollowersEmail)] = group;
         
         if ([weakSelf.selectedSubsections[@(StatsSectionFollowers)] isEqualToNumber:@(StatsSubSectionFollowersEmail)]) {
             [weakSelf.tableView beginUpdates];
             
             NSUInteger sectionNumber = [weakSelf.sections indexOfObject:@(StatsSectionFollowers)];
             NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:sectionNumber];
             [weakSelf.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
             
             [weakSelf.tableView endUpdates];
         }
     }
                                                   publicizeCompletionHandler:^(StatsGroup *group, NSError *error)
     {
         group.offsetRows = StatsTableRowDataOffsetStandard;
         weakSelf.sectionData[@(StatsSectionPublicize)] = group;
         
         [weakSelf.tableView beginUpdates];
         
         NSUInteger sectionNumber = [weakSelf.sections indexOfObject:@(StatsSectionPublicize)];
         NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:sectionNumber];
         [weakSelf.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
         
         [weakSelf.tableView endUpdates];
     }
                                                      streakCompletionHandler:^(StatsStreak *streak, NSError *error)
     {
         weakSelf.sectionData[@(StatsSectionInsightsPostActivity)] = streak;
         [weakSelf.tableView beginUpdates];
         
         NSUInteger sectionNumber = [weakSelf.sections indexOfObject:@(StatsSectionInsightsPostActivity)];
         NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:sectionNumber];
         [weakSelf.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
         
         [weakSelf.tableView endUpdates];

     }
                                                                progressBlock:^(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations)
     {
         if (numberOfFinishedOperations == 0 && [weakSelf.statsProgressViewDelegate respondsToSelector:@selector(statsViewControllerDidBeginLoadingStats:)]) {
             [weakSelf.statsProgressViewDelegate statsViewControllerDidBeginLoadingStats:weakSelf];
         }
         
         if (numberOfFinishedOperations > 0 && [weakSelf.statsProgressViewDelegate respondsToSelector:@selector(statsViewController:loadingProgressPercentage:)]) {
             CGFloat percentage = (CGFloat)numberOfFinishedOperations / (CGFloat)totalNumberOfOperations;
             [weakSelf.statsProgressViewDelegate statsViewController:weakSelf loadingProgressPercentage:percentage];
         }
     }
                                                  andOverallCompletionHandler:^
     {
         // Set the colors to what they should be (previous color for unknown data)
         
         [weakSelf setupRefreshControl];
         [weakSelf.refreshControl endRefreshing];
         
         
         // FIXME - Do something elegant possibly
         [weakSelf.tableView reloadData];
         
         if ([weakSelf.statsProgressViewDelegate respondsToSelector:@selector(statsViewControllerDidEndLoadingStats:)]) {
             [weakSelf.statsProgressViewDelegate statsViewControllerDidEndLoadingStats:weakSelf];
         }
     }];
}

- (void)setupRefreshControl
{
    if (self.refreshControl) {
        return;
    }
    
    UIRefreshControl *refreshControl = [UIRefreshControl new];
    [refreshControl addTarget:self action:@selector(refreshCurrentStats:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
}


- (IBAction)sectionGroupSelectorDidChange:(UISegmentedControl *)control
{
    StatsSection statsSection = (StatsSection)control.superview.tag;
    NSInteger section = (NSInteger)[self.sections indexOfObject:@(statsSection)];
    
    NSInteger oldSectionCount = [self tableView:self.tableView numberOfRowsInSection:section];
    StatsSubSection subSection;
    
    switch (statsSection) {
        case StatsSectionComments:
            subSection = control.selectedSegmentIndex == 0 ? StatsSubSectionCommentsByAuthor : StatsSubSectionCommentsByPosts;
            break;
        case StatsSectionFollowers:
            subSection = control.selectedSegmentIndex == 0 ? StatsSubSectionFollowersDotCom : StatsSubSectionFollowersEmail;
            break;
        default:
            subSection = StatsSubSectionNone;
            break;
    }
    
    self.selectedSubsections[@(statsSection)] = @(subSection);
    NSInteger newSectionCount = [self tableView:self.tableView numberOfRowsInSection:section];
    
    NSInteger sectionNumber = (NSInteger)[self.sections indexOfObject:@(statsSection)];
    NSMutableArray *oldIndexPaths = [NSMutableArray new];
    NSMutableArray *newIndexPaths = [NSMutableArray new];
    
    for (NSInteger row = StatsTableRowDataOffsetWithGroupSelector; row < oldSectionCount; ++row) {
        [oldIndexPaths addObject:[NSIndexPath indexPathForRow:row inSection:sectionNumber]];
    }
    for (NSInteger row = StatsTableRowDataOffsetWithGroupSelector; row < newSectionCount; ++row) {
        [newIndexPaths addObject:[NSIndexPath indexPathForRow:row inSection:sectionNumber]];
    }
    
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:section]] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView deleteRowsAtIndexPaths:oldIndexPaths withRowAnimation:UITableViewRowAnimationTop];
    [self.tableView insertRowsAtIndexPaths:newIndexPaths withRowAnimation:UITableViewRowAnimationMiddle];
    [self.tableView endUpdates];
}


#pragma mark - Actions for today stats


- (IBAction)switchToTodayViews:(UIButton *)button
{
    if ([self.statsTypeSelectionDelegate conformsToProtocol:@protocol(WPStatsSummaryTypeSelectionDelegate)]) {
        [self.statsTypeSelectionDelegate viewController:self changeStatsSummaryTypeSelection:StatsSummaryTypeViews];
    }
}

- (IBAction)switchToTodayVisitors:(UIButton *)button
{
    if ([self.statsTypeSelectionDelegate conformsToProtocol:@protocol(WPStatsSummaryTypeSelectionDelegate)]) {
        [self.statsTypeSelectionDelegate viewController:self changeStatsSummaryTypeSelection:StatsSummaryTypeVisitors];
    }
}

- (IBAction)switchToTodayLikes:(UIButton *)button
{
    if ([self.statsTypeSelectionDelegate conformsToProtocol:@protocol(WPStatsSummaryTypeSelectionDelegate)]) {
        [self.statsTypeSelectionDelegate viewController:self changeStatsSummaryTypeSelection:StatsSummaryTypeLikes];
    }
}

- (IBAction)switchToTodayComments:(UIButton *)button
{
    if ([self.statsTypeSelectionDelegate conformsToProtocol:@protocol(WPStatsSummaryTypeSelectionDelegate)]) {
        [self.statsTypeSelectionDelegate viewController:self changeStatsSummaryTypeSelection:StatsSummaryTypeComments];
    }
}

- (IBAction)viewPostDetailsForLatestPostSummary:(UIButton *)button
{
    [self performSegueWithIdentifier:SegueLatestPostDetailsiPad sender:button];
}


#pragma mark - Attributed String generation methods

- (NSAttributedString *)latestPostSummaryAttributedString
{
    StatsLatestPostSummary *summary = [self statsDataForStatsSection:StatsSectionInsightsLatestPostSummary];
    NSMutableAttributedString *text;
    
    if (!summary) {
        text = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"You have not published any posts yet.", @"Placeholder text when no latest post summary exists") attributes:@{NSFontAttributeName : [WPFontManager systemRegularFontOfSize:13.0]}];
    } else {
        NSString *postTitle = summary.postTitle ?: @"";
        NSString *time = summary.postAge;
        NSString *unformattedString = [NSString stringWithFormat:NSLocalizedString(@"It's been %@ since %@ was published. Here's how the post has performed so far...", @"Latest post summary text including placeholder for time and the post title."), time, postTitle];
        text = [[NSMutableAttributedString alloc] initWithString:unformattedString attributes:@{NSFontAttributeName : [WPFontManager systemRegularFontOfSize:13.0]}];
        [text addAttributes:@{NSFontAttributeName : [WPFontManager systemBoldFontOfSize:13.0], NSForegroundColorAttributeName : [WPStyleGuide wordPressBlue]} range:[unformattedString rangeOfString:postTitle]];
    }
    
    return text;
}

#pragma mark - Image methods

- (UIImage *)postsImage
{
    UIImage *postsImage = [UIImage imageNamed:@"icon-text_normal.png"];
    
    return postsImage;
}

- (UIImage *)viewsImage
{
    UIImage *viewsImage = [UIImage imageNamed:@"icon-eye-16x16.png"];
    
    return viewsImage;
}

- (UIImage *)visitorsImage
{
    UIImage *visitorsImage = [UIImage imageNamed:@"icon-user_normal.png"];
    
    return visitorsImage;
}

- (UIImage *)bestViewsImage
{
    UIImage *bestViewsImage = [UIImage imageNamed:@"icon-trophy_normal.png"];
    
    return bestViewsImage;
}

- (UIImage *)likesImage
{
    UIImage *likesImage = [UIImage imageNamed:@"icon-star_normal.png"];
    
    return likesImage;
}

- (UIImage *)commentsImage
{
    UIImage *commentsImage = [UIImage imageNamed:@"icon-comment_normal.png"];
    
    return commentsImage;
}

#pragma mark - Row and section calculation methods

- (id)statsDataForStatsSection:(StatsSection)statsSection
{
    id data;
    
    if ( statsSection == StatsSectionComments || statsSection == StatsSectionFollowers) {
        StatsSubSection selectedSubsection = [self statsSubSectionForStatsSection:statsSection];
        data = self.sectionData[@(statsSection)][@(selectedSubsection)];
    } else {
        data = self.sectionData[@(statsSection)];
    }
    
    return data;
}


- (StatsSection)statsSectionForTableViewSection:(NSInteger)section
{
    return (StatsSection)[self.sections[(NSUInteger)section] integerValue];
}


- (StatsSubSection)statsSubSectionForStatsSection:(StatsSection)statsSection
{
    NSNumber *subSectionValue = self.selectedSubsections[@(statsSection)];
    
    if (!subSectionValue) {
        return StatsSubSectionNone;
    }
    
    return (StatsSubSection)[subSectionValue integerValue];
}


- (void)wipeDataAndSeedGroups
{
    if (self.sectionData) {
        [self.sectionData removeAllObjects];
    } else {
        self.sectionData = [NSMutableDictionary new];
    }
    
    self.sectionData[@(StatsSectionComments)] = [NSMutableDictionary new];
    self.sectionData[@(StatsSectionFollowers)] = [NSMutableDictionary new];
    
    for (NSNumber *statsSectionNumber in self.sections) {
        StatsSection statsSection = (StatsSection)statsSectionNumber.integerValue;
        StatsSubSection statsSubSection = StatsSubSectionNone;
        
        if ([self.subSections objectForKey:statsSectionNumber] != nil) {
            for (NSNumber *statsSubSectionNumber in self.subSections[statsSectionNumber]) {
                statsSubSection = (StatsSubSection)statsSubSectionNumber.integerValue;
                StatsGroup *group = [[StatsGroup alloc] initWithStatsSection:statsSection andStatsSubSection:statsSubSection];
                self.sectionData[statsSectionNumber][statsSubSectionNumber] = group;
            }
        } else if (statsSection != StatsSectionInsightsAllTime
                   && statsSection != StatsSectionInsightsMostPopular
                   && statsSection != StatsSectionInsightsPostActivity
                   && statsSection != StatsSectionInsightsTodaysStats
                   && statsSection != StatsSectionInsightsLatestPostSummary) {
            StatsGroup *group = [[StatsGroup alloc] initWithStatsSection:statsSection andStatsSubSection:StatsSubSectionNone];
            self.sectionData[statsSectionNumber] = group;
        }
    }
}

@end
