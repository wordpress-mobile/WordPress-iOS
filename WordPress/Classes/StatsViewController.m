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
#import "StatsBarGraphCell.h"
#import "StatsSummary.h"
#import "StatsTitleCountItem.h"
#import "StatsTodayYesterdayButtonCell.h"
#import "StatsTwoLabelCell.h"

static NSString *const VisitorsUnitButtonCellReuseIdentifier = @"VisitorsUnitButtonCellReuseIdentifier";
static NSString *const TodayYesterdayButtonCellReuseIdentifier = @"TodayYesterdayButtonCellReuseIdentifier";
static NSString *const GraphCellReuseIdentifier = @"GraphCellReuseIdentifier";
static NSString *const CountCellReuseIdentifier = @"DoubleCountCellReuseIdentifier";
static NSString *const TwoLabelCellReuseIdentifier = @"TwoLabelCellReuseIdentifier";
static NSString *const StatSectionHeaderViewIdentifier = @"StatSectionHeaderViewIdentifier";
static NSString *const NoResultsCellIdentifier = @"NoResultsCellIdentifier";
static NSString *const ResultRowCellIdentifier = @"ResultRowCellIdentifier";
static NSString *const GraphCellIdentifier = @"GraphCellIdentifier";

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
@property (nonatomic, strong) ContextManager *contextManager;
@property (nonatomic, strong) NSMutableDictionary *statModels;
@property (nonatomic, strong) NSMutableDictionary *showingToday;
@property (nonatomic, strong) NSNumberFormatter *numberFormatter;


@end

@implementation StatsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Stats", nil);
    self.view.backgroundColor = [WPStyleGuide itsEverywhereGrey];
    
    self.tableView.backgroundColor = [WPStyleGuide itsEverywhereGrey];
    [self.tableView registerClass:[UITableViewHeaderFooterView class] forHeaderFooterViewReuseIdentifier:StatSectionHeaderViewIdentifier];
    [self.tableView registerClass:[StatsButtonCell class] forCellReuseIdentifier:VisitorsUnitButtonCellReuseIdentifier];
    [self.tableView registerClass:[StatsTodayYesterdayButtonCell class] forCellReuseIdentifier:TodayYesterdayButtonCellReuseIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:GraphCellReuseIdentifier];
    [self.tableView registerClass:[StatsCounterCell class] forCellReuseIdentifier:CountCellReuseIdentifier];
    [self.tableView registerClass:[StatsTwoLabelCell class] forCellReuseIdentifier:TwoLabelCellReuseIdentifier];
    [self.tableView registerClass:[StatsNoResultsCell class] forCellReuseIdentifier:NoResultsCellIdentifier];
    [self.tableView registerClass:[StatsTwoLabelCell class] forCellReuseIdentifier:ResultRowCellIdentifier];
    [self.tableView registerClass:[StatsBarGraphCell class] forCellReuseIdentifier:GraphCellIdentifier];
    
    _statModels = [NSMutableDictionary dictionary];
    
    // By default, show data for Today
    _showingToday = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                     @(YES), @(StatsSectionTopPosts),
                     @(YES), @(StatsSectionViewsByCountry),
                     @(YES), @(StatsSectionSearchTerms),
                     @(YES), @(StatsSectionClicks),
                     @(YES), @(StatsSectionReferrers), nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setBlog:(Blog *)blog {
    _blog = blog;
    DDLogInfo(@"Loading Stats for the following blog: %@", [blog url]);
    WordPressAppDelegate *appDelegate = [WordPressAppDelegate sharedWordPressApplicationDelegate];
    self.statsApiHelper = [[StatsApiHelper alloc] initWithSiteID:self.blog.blogID];
    if (!appDelegate.connectionAvailable) {
        // no network connection
    } else {
        [self initStats];
    }
}

- (void)initStats {
    if ([self.blog isWPcom]) {
        [self loadStats];
        return;
    }
    //Jetpack
    BOOL noCredentials = ![self.blog jetpackBlogID] || ![self.blog.jetpackUsername length] || ![self.blog.jetpackPassword length];
    if (noCredentials) {
        [self promptForCredentials];
    } else {
        [self loadStats];
    }
}

- (void)promptForCredentials {
    if (![self.blog isWPcom]) {
        JetpackSettingsViewController *controller = [[JetpackSettingsViewController alloc] initWithBlog:self.blog];
        controller.showFullScreen = NO;
        __weak JetpackSettingsViewController *safeController = controller;
        [controller setCompletionBlock:^(BOOL didAuthenticate) {
            if (didAuthenticate) {
                [safeController.view removeFromSuperview];
                [safeController removeFromParentViewController];
                [self loadStats];
            }
        }];
        [self addChildViewController:controller];
        [self.view addSubview:controller.view];
        controller.view.frame = self.view.bounds;
    }
}

- (void)loadStats {
    [self.statsApiHelper fetchSummaryWithSuccess:^(StatsSummary *summary) {
        [_statModels setObject:summary forKey:@(StatsSectionVisitors)];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:StatsSectionVisitors] withRowAnimation:UITableViewRowAnimationNone];
    } failure:^(NSError *error) {
        DDLogError(@"Stats: Error fetching summary %@", error);
    }];

    [self.statsApiHelper fetchTopPostsWithSuccess:^(NSDictionary *todayAndYesterdayTopPosts) {
        [_statModels setObject:todayAndYesterdayTopPosts forKey:@(StatsSectionTopPosts)];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:StatsSectionTopPosts] withRowAnimation:UITableViewRowAnimationNone];
    } failure:^(NSError *error) {
        
    }];
    
    [self.statsApiHelper fetchClicksWithSuccess:^(NSDictionary *clicks) {
        [_statModels setObject:clicks forKey:@(StatsSectionClicks)];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:StatsSectionClicks] withRowAnimation:UITableViewRowAnimationNone];
    } failure:^(NSError *error) {
        
    }];
    
    [self.statsApiHelper fetchCountryViewsWithSuccess:^(NSDictionary *views) {
        [_statModels setObject:views forKey:@(StatsSectionViewsByCountry)];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:StatsSectionViewsByCountry] withRowAnimation:UITableViewRowAnimationNone];
    } failure:^(NSError *error) {
        
    }];
    
    [self.statsApiHelper fetchReferrerWithSuccess:^(NSDictionary *referrers) {
        [_statModels setObject:referrers forKey:@(StatsSectionReferrers)];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:StatsSectionReferrers] withRowAnimation:UITableViewRowAnimationNone];
    } failure:^(NSError *error) {
        
    }];
    
    [self.statsApiHelper fetchSearchTermsWithSuccess:^(NSDictionary *terms) {
        [_statModels setObject:terms forKey:@(StatsSectionSearchTerms)];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:StatsSectionSearchTerms]withRowAnimation:UITableViewRowAnimationNone];
    } failure:^(NSError *error) {
        
    }];
    
}

- (BOOL)showingTodayForSection:(StatsSection)section {
    return [_showingToday[@(section)] boolValue];
}

- (NSArray *)resultsForSection:(StatsSection)section {
    NSDictionary *data = _statModels[@(section)];
    return [self showingTodayForSection:section] ? data[@"today"] : data[@"yesterday"];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return StatsSectionTotalCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case StatsSectionVisitors:
            return VisitorSectionTotalRows;
        case StatsSectionTotalsFollowersShares:
            return TotalFollowersShareRowTotalRows;
        default:
        {
            NSInteger numberOfResults = [self resultsForSection:section].count;
            return numberOfResults ? 2 + numberOfResults : 3;
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
                    return [StatsBarGraphCell heightForRow];
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
                    return [StatsTwoLabelCell heightForRow];
                default:
                    return [self resultsForSection:indexPath.section].count > 0 ? [StatsTwoLabelCell heightForRow] : [StatsNoResultsCell heightForRow];
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
                    [cell addButtonWithTitle:NSLocalizedString(@"Months", nil) target:self action:@selector(monthSelected:) section:indexPath.section];
                    [cell addButtonWithTitle:NSLocalizedString(@"Years", nil) target:self action:@selector(yearSelected:) section:indexPath.section];
                    return cell;
                }
                case VisitorRowGraph:
                {
                    StatsBarGraphCell *cell = [tableView dequeueReusableCellWithIdentifier:GraphCellIdentifier];
                    cell.contentView.backgroundColor = [UIColor magentaColor];
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
            dataTitleRowLeft = NSLocalizedString(@"Referrer", nil);
            dataTitleRowRight = NSLocalizedString(@"Clicks", nil);
            break;
        case StatsSectionReferrers:
            dataTitleRowLeft = NSLocalizedString(@"Referrers", nil);
            break;
        case StatsSectionSearchTerms:
            dataTitleRowLeft = NSLocalizedString(@"Search", nil);
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
            [(StatsTwoLabelCell *)cell setLeft:dataTitleRowLeft right:dataTitleRowRight titleCell:YES];
            break;
        }
        default:
        {
            if ([self resultsForSection:section].count == 0) {
                cell = [self.tableView dequeueReusableCellWithIdentifier:NoResultsCellIdentifier];
                [(StatsNoResultsCell *)cell configureForSection:section];
            } else {
                cell = [self.tableView dequeueReusableCellWithIdentifier:ResultRowCellIdentifier];
                StatsTitleCountItem *data = [self resultsForSection:section][index-2];
                self.numberFormatter = [[NSNumberFormatter alloc]init];
                self.numberFormatter.locale = [NSLocale currentLocale];
                self.numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
                self.numberFormatter.usesGroupingSeparator = YES;
                [(StatsTwoLabelCell *)cell setLeft:data.title right:[self.numberFormatter stringFromNumber:data.count]];
            }
        }
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 36.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = [tableView dequeueReusableHeaderFooterViewWithIdentifier:StatSectionHeaderViewIdentifier];
    [header.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    header.contentView.backgroundColor = [WPStyleGuide itsEverywhereGrey];
    
    UILabel *sectionName = [[UILabel alloc] initWithFrame:CGRectMake(5.0f, 10.0f, 0, 30.0f)];
    sectionName.textColor = [WPStyleGuide littleEddieGrey];
    sectionName.backgroundColor = [WPStyleGuide itsEverywhereGrey];
    sectionName.opaque = YES;
    sectionName.font = [WPStyleGuide postTitleFont];
    
    switch (section) {
        case StatsSectionVisitors:
            sectionName.text = NSLocalizedString(@"Visitors and Views",nil);
            break;
        case StatsSectionTopPosts:
            sectionName.text = NSLocalizedString(@"Top Posts",nil);
            break;
        case StatsSectionViewsByCountry:
            sectionName.text = NSLocalizedString(@"Views By Country",nil);
            break;
        case StatsSectionTotalsFollowersShares:
            sectionName.text = NSLocalizedString(@"Totals, Followers & Shares", nil);
            break;
        case StatsSectionClicks:
            sectionName.text = NSLocalizedString(@"Clicks", nil);
            break;
        case StatsSectionReferrers:
            sectionName.text = NSLocalizedString(@"Referrers", nil);
            break;
        case StatsSectionSearchTerms:
            sectionName.text = NSLocalizedString(@"Search Engine Terms", nil);
            break;
        default:
            sectionName.text = @"";
            break;
    }
    
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

- (void)daySelected:(UIButton *)sender {

}

- (void)monthSelected:(UIButton *)sender {
    
}

- (void)yearSelected:(UIButton *)sender {
    
}

@end
