#import "StatsViewAllTableViewController.h"
#import "StatsGroup.h"
#import <WordPressKit/StatsItem.h>
#import <WordPressKit/StatsItemAction.h>
#import "StatsTwoColumnTableViewCell.h"
#import "WPStyleGuide+Stats.h"
#import "StatsTableSectionHeaderView.h"
#import <WordPressComAnalytics/WPAnalytics.h>
#import "AppExtensionUtils.h"

static NSString *const StatsTableSectionHeaderSimpleBorder = @"StatsTableSectionHeaderSimpleBorder";
static NSString *const StatsTableGroupHeaderCellIdentifier = @"GroupHeader";
static NSString *const StatsTableTwoColumnHeaderCellIdentifier = @"TwoColumnHeader";
static NSString *const StatsTableTwoColumnCellIdentifier = @"TwoColumnRow";
static NSString *const StatsTableLoadingIndicatorCellIdentifier = @"LoadingIndicator";

@interface StatsViewAllTableViewController ()

@property (nonatomic, strong) StatsGroup *statsGroup;

@end

@implementation StatsViewAllTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerClass:[StatsTableSectionHeaderView class] forHeaderFooterViewReuseIdentifier:StatsTableSectionHeaderSimpleBorder];

    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 20.0f)];
    self.tableView.backgroundColor = [WPStyleGuide itsEverywhereGrey];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    UIRefreshControl *refreshControl = [UIRefreshControl new];
    [refreshControl addTarget:self action:@selector(retrieveStats) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    
    self.statsGroup = [[StatsGroup alloc] initWithStatsSection:self.statsSection andStatsSubSection:self.statsSubSection];
    self.title = self.statsGroup.groupTitle;
    
    [WPAnalytics track:WPAnalyticsStatStatsViewAllAccessed withProperties:@{ @"blog_id" : self.statsService.siteId}];
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


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    BOOL isDataLoaded = self.statsGroup.items != nil;
    NSInteger numberOfRows = 1 + (isDataLoaded ? (NSInteger)self.statsGroup.numberOfRows : 1);
    
    return numberOfRows;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *identifier;
    switch (indexPath.row) {
        case 0:
            identifier = StatsTableTwoColumnHeaderCellIdentifier;
            break;
        case 1:
            if (self.statsGroup.items == nil) {
                identifier = StatsTableLoadingIndicatorCellIdentifier;
                break;
            }
        default:
            identifier = StatsTableTwoColumnCellIdentifier;
            break;
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    
    if ([identifier isEqualToString:StatsTableTwoColumnCellIdentifier]) {
        StatsItem *item = [self.statsGroup statsItemForTableViewRow:indexPath.row];
        StatsItem *nextItem = [self.statsGroup statsItemForTableViewRow:indexPath.row + 1];
       
        [self configureTwoColumnRowCell:cell
                        forStatsSection:self.statsSection
                          withStatsItem:item
                       andNextStatsItem:nextItem];
    } else if ([identifier isEqualToString:StatsTableLoadingIndicatorCellIdentifier]) {
        UIActivityIndicatorView *indicator = (UIActivityIndicatorView *)[cell.contentView viewWithTag:100];
        [indicator startAnimating];
    } else if ([identifier isEqualToString:StatsTableTwoColumnHeaderCellIdentifier]) {
        [self configureSectionTwoColumnHeaderCell:(StatsStandardBorderedTableViewCell *)cell];
    }
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    StatsItem *statsItem = [self.statsGroup statsItemForTableViewRow:indexPath.row];
    
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


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    StatsTableSectionHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:StatsTableSectionHeaderSimpleBorder];
    
    return headerView;
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    StatsTableSectionHeaderView *footerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:StatsTableSectionHeaderSimpleBorder];
    footerView.footer = YES;
    
    return footerView;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.0f;
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 1.0f;
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 10.0f;
}


#pragma mark - Private methods

- (void)retrieveStats
{
    [AppExtensionUtils setNetworkActivityIndicatorVisible:YES fromController:self];

    if (self.statsGroup) {
        self.statsGroup = [[StatsGroup alloc] initWithStatsSection:self.statsSection andStatsSubSection:self.statsSubSection];
        [self.tableView reloadData];
    }
    
    __weak __typeof(self) weakSelf = self;
    
    StatsGroupCompletion completion = ^(StatsGroup *group, NSError *error) {
        [AppExtensionUtils setNetworkActivityIndicatorVisible:NO fromController:self];
        [weakSelf.refreshControl endRefreshing];

        if (error != nil) {
            return;
        }

        weakSelf.statsGroup = group;
        weakSelf.statsGroup.offsetRows = 1;
        
        NSMutableArray *indexPaths = [NSMutableArray new];
        for (NSInteger row = 1; row < (NSInteger)(1 + weakSelf.statsGroup.items.count); ++row) {
            [indexPaths addObject:[NSIndexPath indexPathForRow:row inSection:0]];
        }
        
        [weakSelf.tableView beginUpdates];
        [weakSelf.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
        [weakSelf.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
        [weakSelf.tableView endUpdates];
    };
    
    if (self.statsSection == StatsSectionPosts) {
        [self.statsService retrievePostsForDate:self.selectedDate andUnit:self.periodUnit withCompletionHandler:completion];
    } else if (self.statsSection == StatsSectionReferrers) {
        [self.statsService retrieveReferrersForDate:self.selectedDate andUnit:self.periodUnit withCompletionHandler:completion];
    } else if (self.statsSection == StatsSectionClicks) {
        [self.statsService retrieveClicksForDate:self.selectedDate andUnit:self.periodUnit withCompletionHandler:completion];
    } else if (self.statsSection == StatsSectionCountry) {
        [self.statsService retrieveCountriesForDate:self.selectedDate andUnit:self.periodUnit withCompletionHandler:completion];
    } else if (self.statsSection == StatsSectionVideos) {
        [self.statsService retrieveVideosForDate:self.selectedDate andUnit:self.periodUnit withCompletionHandler:completion];
    } else if (self.statsSection == StatsSectionAuthors) {
        [self.statsService retrieveAuthorsForDate:self.selectedDate andUnit:self.periodUnit withCompletionHandler:completion];
    } else if (self.statsSection == StatsSectionSearchTerms) {
        [self.statsService retrieveSearchTermsForDate:self.selectedDate andUnit:self.periodUnit withCompletionHandler:completion];
    } else if (self.statsSection == StatsSectionFollowers) {
        StatsFollowerType followerType = self.statsSubSection == StatsSubSectionFollowersDotCom ? StatsFollowerTypeDotCom : StatsFollowerTypeEmail;
        [self.statsService retrieveFollowersOfType:followerType withCompletionHandler:completion];
    }
}


- (void)abortRetrieveStats
{
    [self.statsService cancelAnyRunningOperations];
    [AppExtensionUtils setNetworkActivityIndicatorVisible:NO fromController:self];
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


- (void)configureSectionTwoColumnHeaderCell:(StatsStandardBorderedTableViewCell *)cell
{
    StatsItem *statsItem = [self.statsGroup statsItemForTableViewRow:1];
    
    NSString *leftText = self.statsGroup.titlePrimary;
    NSString *rightText = self.statsGroup.titleSecondary;
    
    // Hide the bottom border if the first row is expanded
    cell.bottomBorderEnabled = !statsItem.isExpanded;
    
    UILabel *label1 = (UILabel *)[cell.contentView viewWithTag:100];
    label1.text = leftText;
    label1.textColor = [WPStyleGuide grey];
    
    UILabel *label2 = (UILabel *)[cell.contentView viewWithTag:200];
    label2.text = rightText;
    label2.textColor = [WPStyleGuide grey];
}


@end
