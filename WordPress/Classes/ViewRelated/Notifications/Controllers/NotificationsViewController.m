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

static NSTimeInterval const NotificationPushMaxWait     = 1;
static CGFloat const NoteEstimatedHeight                = 70;
static NSTimeInterval NotificationsUndoTimeout          = 4;



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
    
    // Manually deselect the selected row. This is required due to a bug in iOS7 / iOS8
    [self.tableView deselectSelectedRowWithAnimation:YES];
    
    // While we're onscreen, please, update rows with animations
    self.tableViewHandler.updateRowAnimation = UITableViewRowAnimationFade;
    
    // Tracking
    [self trackAppeared];
    [self updateLastSeenTime];
    
    // Notifications
    [self hookApplicationStateNotes];
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
    [self unhookApplicationStateNotes];
    
    // If we're not onscreen, don't use row animations. Otherwise the fade animation might get animated incrementally
    self.tableViewHandler.updateRowAnimation = UITableViewRowAnimationNone;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.tableViewHandler clearCachedRowHeights];
}


#pragma mark - NSNotification Helpers

- (void)hookApplicationStateNotes
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(handleApplicationDidBecomeActiveNote:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [nc addObserver:self selector:@selector(handleApplicationWillResignActiveNote:) name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)unhookApplicationStateNotes
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [nc removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)handleApplicationDidBecomeActiveNote:(NSNotification *)note
{
    // Let's reset the badge, whenever the app comes back to FG, and this view was upfront!
    if (!self.isViewLoaded || !self.view.window) {
        return;
    }

    // Reset the badge: the notifications are visible!
    [self resetApplicationBadge];
    [self updateLastSeenTime];
    [self reloadResultsControllerIfNeeded];
}

- (void)handleApplicationWillResignActiveNote:(NSNotification *)note
{
    [self stopSyncTimeoutTimer];
}

- (void)handleDefaultAccountChangedNote:(NSNotification *)note
{
    [self resetApplicationBadge];
}


#pragma mark - Helper methods

- (void)reloadResultsControllerIfNeeded
{
    // Note:
    // NSFetchedResultsController groups notifications based on a transient property ("sectionIdentifier").
    // Simply calling reloadData doesn't make the FRC recalculate the sections.
    // For that reason, let's force a reload, only when 1 day has elapsed, and sections would have changed.
    //
    NSInteger daysElapsed = [[NSCalendar currentCalendar] daysElapsedSinceDate:self.lastReloadDate];
    if (daysElapsed == 0) {
        return;
    }
    
    [self reloadResultsController];
}

- (void)reloadResultsController
{
    // Update the Predicate: We can't replace the previous fetchRequest, since it's readonly!
    NSFetchRequest *fetchRequest = self.tableViewHandler.resultsController.fetchRequest;
    fetchRequest.predicate = [self predicateForSelectedFilters];
    
    /// Refetch + Reload
    [self.tableViewHandler clearCachedRowHeights];
    [self.tableViewHandler.resultsController performFetch:nil];
    [self.tableView reloadData];
    
    // Empty State?
    [self showNoResultsViewIfNeeded];
    
    // Don't overwork!
    self.lastReloadDate = [NSDate date];
}

- (void)reloadRowForNotificationWithID:(NSManagedObjectID *)noteObjectID
{
    // Failsafe
    if (!noteObjectID) {
        return;
    }
    
    // Load the Notification and its indexPath
    NSError *error                  = nil;
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    Notification *note              = (Notification *)[context existingObjectWithID:noteObjectID error:&error];
    if (error) {
        DDLogError(@"Error refreshing Notification Row: %@", error);
        return;
    }
    
    NSIndexPath *indexPath = [self.tableViewHandler.resultsController indexPathForObject:note];
    if (indexPath) {
        [self.tableView reloadRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationFade];
    }
}


#pragma mark - Undelete Mechanism

- (void)showUndeleteForNoteWithID:(NSManagedObjectID *)noteObjectID onTimeout:(NotificationDeletionActionBlock)onTimeout
{
    // Mark this note as Pending Deletion and Reload
    self.notificationDeletionBlocks[noteObjectID] = [onTimeout copy];
    [self reloadRowForNotificationWithID:noteObjectID];
    
    // Dispatch the Action block
    [self performSelector:@selector(performDeletionActionForNoteWithID:) withObject:noteObjectID afterDelay:NotificationsUndoTimeout];
}

- (void)performDeletionActionForNoteWithID:(NSManagedObjectID *)noteObjectID
{
    // Was the Deletion Cancelled?
    NotificationDeletionActionBlock deletionBlock = self.notificationDeletionBlocks[noteObjectID];
    if (!deletionBlock) {
        return;
    }
    
    // Hide the Notification
    [self.notificationIdsBeingDeleted addObject:noteObjectID];
    [self reloadResultsController];

    // Hit the Deletion Block
    deletionBlock(^(BOOL success) {
        // Cleanup
        [self.notificationDeletionBlocks removeObjectForKey:noteObjectID];
        [self.notificationIdsBeingDeleted removeObject:noteObjectID];
        
        // Error: let's unhide the row
        if (!success) {
            [self reloadResultsController];
        }
    });
}

- (void)cancelDeletionForNoteWithID:(NSManagedObjectID *)noteObjectID
{
    [self.notificationDeletionBlocks removeObjectForKey:noteObjectID];
    [self reloadRowForNotificationWithID:noteObjectID];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(performDeletionActionForNoteWithID:) object:noteObjectID];
}

- (BOOL)isNoteMarkedForDeletion:(NSManagedObjectID *)noteObjectID
{
    return [self.notificationDeletionBlocks objectForKey:noteObjectID] != nil;
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
            [weakSelf showUndeleteForNoteWithID:note.objectID onTimeout:onUndoTimeout];
        };
        
    } else if([segue.identifier isEqualToString:readerSegueID]) {
        ReaderDetailViewController *readerViewController = segue.destinationViewController;
        [readerViewController setupWithPostID:note.metaPostID siteID:note.metaSiteID];
    }
}

@end
