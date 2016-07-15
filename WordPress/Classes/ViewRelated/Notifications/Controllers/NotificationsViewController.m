#import "NotificationsViewController+Internal.h"

#import <Simperium/Simperium.h>
#import "WordPressAppDelegate.h"
#import "ContextManager.h"
#import "Constants.h"
#import "WPGUIConstants.h"

#import "WPTableViewHandler.h"
#import "WPWebViewController.h"
#import "WPTabBarController.h"

#import "Notification.h"
#import "Meta.h"

#import "NotificationDetailsViewController.h"

#import "WPAccount.h"

#import "AccountService.h"

#import "ReaderPost.h"
#import "ReaderPostService.h"

#import "UIView+Subviews.h"

#import "WordPress-Swift.h"



#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

static CGFloat const NoteEstimatedHeight = 70;



#pragma mark ====================================================================================
#pragma mark NotificationsViewController
#pragma mark ====================================================================================

@implementation NotificationsViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.navigationItem.title = NSLocalizedString(@"Notifications", @"Notifications View Controller title");

        // Listen to Logout Notifications
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(handleDefaultAccountChangedNote:) name:WPAccountDefaultWordPressComAccountChangedNotification object:nil];
        
        // All of the data will be fetched during the FetchedResultsController init. Prevent overfetching
        self.lastReloadDate = [NSDate date];
        
        // Notifications that received a destructive action will allow the user to Undo this action.
        // Once the Timeout elapses, we'll move the NotificationID to the BeingDeleted collection,
        // so that it can be proactively filtered from the list.
        self.notificationDeletionBlocks         = [NSMutableDictionary dictionary];
        self.notificationIdsBeingDeleted        = [NSMutableSet set];
    }
    
    return self;
}


#pragma mark - UIViewController Methods

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setupNavigationBar];
    [self setupConstraints];
    [self setupTableView];
    [self setupTableHeaderView];
    [self setupTableFooterView];
    [self setupTableHandler];
    [self setupRatingsView];
    [self setupRefreshControl];
    [self setupNoResultsView];
    [self setupFiltersSegmentedControl];
    [self setupNotificationsBucketDelegate];
    
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Tracking
    [WPAnalytics track:WPAnalyticsStatOpenedNotificationsList];

    // Manually deselect the selected row. This is required due to a bug in iOS7 / iOS8
    [self.tableView deselectSelectedRowWithAnimation:YES];
    
    // While we're onscreen, please, update rows with animations
    self.tableViewHandler.updateRowAnimation = UITableViewRowAnimationFade;

    // Notifications
    [self startListeningToNotifications];
    [self updateLastSeenTime];
    [self resetApplicationBadge];

    // Refresh the UI
    [self reloadResultsControllerIfNeeded];
    [self showNoResultsViewIfNeeded];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self showRatingViewIfApplicable];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self stopListeningToNotifications];
    
    // If we're not onscreen, don't use row animations. Otherwise the fade animation might get animated incrementally
    self.tableViewHandler.updateRowAnimation = UITableViewRowAnimationNone;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.tableViewHandler clearCachedRowHeights];
}


#pragma mark - UITableViewDelegate

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [NoteTableHeaderView headerHeight];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.tableViewHandler.resultsController.sections objectAtIndex:section];
    
    NoteTableHeaderView *headerView = [NoteTableHeaderView new];
    headerView.title                = [Notification descriptionForSectionIdentifier:sectionInfo.name];
    headerView.separatorColor       = self.tableView.separatorColor;
    
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    // Make sure no SectionFooter is rendered
    return CGFLOAT_MIN;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    // Make sure no SectionFooter is rendered
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NoteTableViewCell *cell = (NoteTableViewCell *)[tableView dequeueReusableCellWithIdentifier:[NoteTableViewCell reuseIdentifier]];
    NSAssert([cell isKindOfClass:[NoteTableViewCell class]], nil);
    
    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NoteEstimatedHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Load the Subject + Snippet
    Notification *note          = [self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    NSAttributedString *subject = note.subjectBlock.attributedSubjectText;
    NSAttributedString *snippet = note.snippetBlock.attributedSnippetText;
    
    // Old School Height Calculation
    CGFloat tableWidth          = CGRectGetWidth(self.tableView.bounds);
    CGFloat cellHeight          = [NoteTableViewCell layoutHeightWithWidth:tableWidth subject:subject snippet:snippet];

    return cellHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Failsafe: Make sure that the Notification (still) exists
    NSArray *sections = self.tableViewHandler.resultsController.sections;
    if (indexPath.section >= sections.count) {
        [tableView deselectSelectedRowWithAnimation:YES];
        return;
    }
    
    id<NSFetchedResultsSectionInfo> sectionInfo = sections[indexPath.section];
    if (indexPath.row >= sectionInfo.numberOfObjects) {
        [tableView deselectSelectedRowWithAnimation:YES];
        return;
    }
    
    // Push the Details: Unless the note has a pending deletion!
    Notification *note = [self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    if ([self isNoteMarkedForDeletion:note.objectID]) {
        return;
    }
    
    [self showDetailsForNotification:note];
}


#pragma mark - Storyboard Helpers

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *detailsSegueID        = NSStringFromClass([NotificationDetailsViewController class]);
    NSString *readerSegueID         = [ReaderDetailViewController classNameWithoutNamespaces];
    Notification *note              = sender;
    __weak __typeof(self) weakSelf  = self;
    
    if([segue.identifier isEqualToString:detailsSegueID]) {
        NotificationDetailsViewController *detailsViewController = segue.destinationViewController;
        [detailsViewController setupWithNotification:note];
        detailsViewController.onDeletionRequestCallback = ^(NotificationDeletionActionBlock onUndoTimeout){
            [weakSelf showUndelete:note.objectID onTimeout:onUndoTimeout];
        };
        
    } else if([segue.identifier isEqualToString:readerSegueID]) {
        ReaderDetailViewController *readerViewController = segue.destinationViewController;
        [readerViewController setupWithPostID:note.metaPostID siteID:note.metaSiteID];
    }
}


- (void)setDeletionBlock:(NotificationDeletionActionBlock)deletionBlock forNoteObjectID:(NSManagedObjectID *)noteObjectID
{
    self.notificationDeletionBlocks[noteObjectID] = [deletionBlock copy];
}

@end
