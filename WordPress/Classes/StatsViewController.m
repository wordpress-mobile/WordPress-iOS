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
#import "StatsResultCell.h"
#import "StatsBarGraphCell.h"

static NSString *const ButtonCellReuseIdentifier = @"ButtonCellReuseIdentifier";
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


@interface StatsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) Blog *blog;
@property (nonatomic, strong) StatsApiHelper *statsApiHelper;
@property (nonatomic, strong) ContextManager *contextManager;

@end

@implementation StatsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Stats", nil);
    
    [self.tableView registerClass:[UITableViewHeaderFooterView class] forHeaderFooterViewReuseIdentifier:StatSectionHeaderViewIdentifier];
    
    [self.tableView registerClass:[StatsButtonCell class] forCellReuseIdentifier:ButtonCellReuseIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:GraphCellReuseIdentifier];
    [self.tableView registerClass:[StatsCounterCell class] forCellReuseIdentifier:CountCellReuseIdentifier];
    [self.tableView registerClass:[StatsTwoLabelCell class] forCellReuseIdentifier:TwoLabelCellReuseIdentifier];
    [self.tableView registerClass:[StatsNoResultsCell class] forCellReuseIdentifier:NoResultsCellIdentifier];
    [self.tableView registerClass:[StatsResultCell class] forCellReuseIdentifier:ResultRowCellIdentifier];
    [self.tableView registerClass:[StatsBarGraphCell class] forCellReuseIdentifier:GraphCellIdentifier];
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

- (void)loadStats {
    [self.statsApiHelper fetchSummaryWithSuccess:^(NSDictionary *summary) {
        
    } failure:^(NSError *error) {
        
    }];

    [self.statsApiHelper fetchTopPostsWithSuccess:^(NSDictionary *todayAndYesterdayTopPosts) {
   
    } failure:^(NSError *error) {
        
    }];
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

- (NSInteger)numberOfResultsForSection:(StatsSection)section {
    switch (section) {
        case StatsSectionTopPosts:
        case StatsSectionViewsByCountry:
        case StatsSectionClicks:
        case StatsSectionReferrers:
        case StatsSectionSearchTerms:
        default:
            return 0;
    }
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
            NSInteger numberOfResults = [self numberOfResultsForSection:section];
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
                    return [self numberOfResultsForSection:StatsSectionTopPosts] > 0 ? [StatsTwoLabelCell heightForRow] : [StatsNoResultsCell heightForRow];
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
                    StatsButtonCell *cell = [tableView dequeueReusableCellWithIdentifier:ButtonCellReuseIdentifier];
                    [cell addButtonWithTitle:NSLocalizedString(@"Day", nil) target:self action:@selector(reloadData)];
                    [cell addButtonWithTitle:NSLocalizedString(@"Month", nil) target:self action:@selector(reloadData)];
                    [cell addButtonWithTitle:NSLocalizedString(@"Year", nil) target:self action:@selector(reloadData)];
                    return cell;
                }
                case VisitorRowGraph:
                {
                    StatsBarGraphCell *cell = [tableView dequeueReusableCellWithIdentifier:GraphCellIdentifier];
                    cell.backgroundColor = [UIColor magentaColor];
                    return cell;
                }
                case VisitorRowTodayStats:
                {
                    StatsCounterCell *cell = [tableView dequeueReusableCellWithIdentifier:CountCellReuseIdentifier];
                    [cell setTitle:NSLocalizedString(@"Today", @"Title for Today cell")];
                    [cell addCount:@0 withLabel:NSLocalizedString(@"Visitors", @"Visitor label for Today cell")];
                    [cell addCount:@0 withLabel:NSLocalizedString(@"Views", @"View label for Today cell")];
                    return cell;
                }
                case VisitorRowBestEver:
                {
                    StatsCounterCell *cell = [tableView dequeueReusableCellWithIdentifier:CountCellReuseIdentifier];
                    [cell setTitle:NSLocalizedString(@"Best Ever", nil)];
                    [cell addCount:@1337 withLabel:NSLocalizedString(@"Views", nil)];
                    return cell;
                }
                case VisitorRowAllTime:
                {
                    StatsCounterCell *cell = [tableView dequeueReusableCellWithIdentifier:CountCellReuseIdentifier];
                    [cell setTitle:NSLocalizedString(@"All Time", nil)];
                    [cell addCount:@10 withLabel:NSLocalizedString(@"Views", nil)];
                    [cell addCount:@3 withLabel:NSLocalizedString(@"Comments", nil)];
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
            return [self cellForDataSection:indexPath.section rowIndex:indexPath.row];
        default:
            return nil;
    }
    NSAssert(NO, @"There must be a cell");
    return nil;
}

- (UITableViewCell *)cellForTotalsFollowersSharesRowWithIndex:(NSInteger)index {
    NSString *title;
    NSString *leftLabel;
    NSString *rightLabel;
    NSNumber *count;
    
    switch (index) {
        case TotalFollowersShareRowContentPost:
            title = @"Content";
            leftLabel = @"Posts";
            count = @0;
            break;
        case TotalFollowersShareRowContentCategoryTag:
            leftLabel = @"Categories";
            rightLabel = @"Tags";
            count = @0;
            break;
        case TotalFollowersShareRowFollowers:
            title = @"Followers";
            leftLabel = @"Blog";
            rightLabel = @"Comments";
            count = @0;
            break;
        case TotalFollowersShareRowShare:
            title = @"Shares";
            leftLabel = @"Shares";
            count = @0;
            break;
    }
    
    StatsCounterCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CountCellReuseIdentifier];
    [cell setTitle:NSLocalizedString(title,@"Title for the data cell")];
    [cell addCount:@0 withLabel:NSLocalizedString(leftLabel,@"Label for the count")];
    if (rightLabel) {
        [cell addCount:@0 withLabel:NSLocalizedString(rightLabel,@"Label for the right count")];
    }
    return cell;
}

- (UITableViewCell *)cellForDataSection:(StatsSection)section rowIndex:(NSInteger)index {
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
            cell = [self.tableView dequeueReusableCellWithIdentifier:ButtonCellReuseIdentifier];
            [(StatsButtonCell *)cell addButtonWithTitle:NSLocalizedString(@"Today",nil) target:self.tableView action:@selector(reloadData)];
            [(StatsButtonCell *)cell addButtonWithTitle:NSLocalizedString(@"Yesterday",nil) target:self.tableView action:@selector(reloadData)];
            break;
        }
        case StatsDataRowTitle:
        {
            cell = [self.tableView dequeueReusableCellWithIdentifier:TwoLabelCellReuseIdentifier];
            [(StatsTwoLabelCell *)cell setLeftLabelText:dataTitleRowLeft];
            [(StatsTwoLabelCell *)cell setRightLabelText:dataTitleRowRight];
            break;
        }
        default:
        {
            if ([self numberOfResultsForSection:section] == 0) {
                cell = [self.tableView dequeueReusableCellWithIdentifier:NoResultsCellIdentifier];
                [(StatsNoResultsCell *)cell configureForSection:section];
            } else {
                cell = [self.tableView dequeueReusableCellWithIdentifier:ResultRowCellIdentifier];
                // from data array...
                [(StatsResultCell *)cell setResultTitle:@"Post title!"];
                [(StatsResultCell *)cell setResultCount:@9];
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
    header.backgroundColor = [WPStyleGuide itsEverywhereGrey];
    
    UILabel *sectionName = [[UILabel alloc] initWithFrame:CGRectMake(0, 6.0f, 0, 30.0f)];
    sectionName.backgroundColor = [WPStyleGuide darkAsNightGrey];
    sectionName.textColor = [UIColor whiteColor];
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
            sectionName.text = @"Pokemon";
            break;
    }
    
    CGSize size = [sectionName.text sizeWithAttributes:[WPStyleGuide postTitleAttributes]];
    sectionName.frame = (CGRect) {
        .size = CGSizeMake(size.width, sectionName.frame.size.height),
        .origin = sectionName.frame.origin
    };
    [header.contentView addSubview:sectionName];
    return header;
}

@end
