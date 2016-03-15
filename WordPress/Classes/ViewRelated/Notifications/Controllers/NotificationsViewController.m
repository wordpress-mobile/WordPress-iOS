#import "NotificationsViewController+Internal.h"

#import <Simperium/Simperium.h>
#import "WordPressAppDelegate.h"
#import "ContextManager.h"
#import "Constants.h"
#import "WPGUIConstants.h"

#import "WPTableViewHandler.h"
#import "WPWebViewController.h"
#import "WPNoResultsView.h"
#import "WPTabBarController.h"

#import "Notification.h"
#import "Meta.h"

#import "NotificationDetailsViewController.h"

#import "WPAccount.h"

#import "AccountService.h"

#import "ReaderPost.h"
#import "ReaderPostService.h"

#import "UIView+Subviews.h"

#import "AppRatingUtility.h"

#import <WordPress_AppbotX/ABXPromptView.h>
#import <WordPress_AppbotX/ABXAppStore.h>
#import <WordPress_AppbotX/ABXFeedbackViewController.h>

#import "WordPress-Swift.h"



#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

static NSTimeInterval const NotificationPushMaxWait     = 1;
static CGFloat const NoteEstimatedHeight                = 70;
static NSTimeInterval NotificationsSyncTimeout          = 10;
static NSTimeInterval NotificationsUndoTimeout          = 4;
static NSString const *NotificationsNetworkStatusKey    = @"network_status";

static CGFloat const RatingsViewHeight                  = 100.0;

typedef NS_ENUM(NSUInteger, NotificationFilter)
{
    NotificationFilterNone,
    NotificationFilterUnread,
    NotificationFilterComment,
    NotificationFilterFollow,
    NotificationFilterLike
};


#pragma mark ====================================================================================
#pragma mark Protocols
#pragma mark ====================================================================================

@interface NotificationsViewController (Protocols) <SPBucketDelegate,
                                                    WPNoResultsViewDelegate,
                                                    WPTableViewHandlerDelegate,
                                                    ABXPromptViewDelegate,
                                                    ABXFeedbackViewControllerDelegate>

@end



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

    [self setupConstraints];
    [self setupTableView];
    [self setupTableHeaderView];
    [self setupTableFooterView];
    [self setupTableHandler];
    [self setupRatingsView];
    [self setupRefreshControl];
    [self setupNavigationBar];
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


#pragma mark - Setup Helpers

- (void)setupConstraints
{
    NSParameterAssert(self.ratingsTopConstraint);
    NSParameterAssert(self.ratingsHeightConstraint);
    
    // Fix: contentInset breaks tableSectionViews. Let's just increase the headerView's height
    self.ratingsTopConstraint.constant = UIDevice.isPad ? CGRectGetHeight(WPTableHeaderPadFrame) : 0.0f;
    
    // Ratings is initially hidden!
    self.ratingsHeightConstraint.constant = 0;
}

- (void)setupTableView
{
    NSParameterAssert(self.tableView);
    
    // Register the cells
    NSArray *cellNibs = @[ [NoteTableViewCell classNameWithoutNamespaces] ];
    
    for (NSString *nibName in cellNibs) {
        UINib *tableViewCellNib = [UINib nibWithNibName:nibName bundle:[NSBundle mainBundle]];
        [self.tableView registerNib:tableViewCellNib forCellReuseIdentifier:nibName];
    }
    
    // UITableView
    self.tableView.accessibilityIdentifier  = @"Notifications Table";
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
}

- (void)setupTableHeaderView
{
    NSParameterAssert(self.tableHeaderView);
    
    // Fix: Update the Frame manually: Autolayout doesn't really help us, when it comes to Table Headers
    CGRect headerFrame          = self.tableHeaderView.frame;
    CGSize requiredSize         = [self.tableHeaderView systemLayoutSizeFittingSize:self.view.bounds.size];
    headerFrame.size.height     = requiredSize.height;
    
    self.tableHeaderView.frame  = headerFrame;
    [self.tableHeaderView layoutIfNeeded];
    
    // Due to iOS awesomeness, unless we re-assign the tableHeaderView, iOS might never refresh the UI
    self.tableView.tableHeaderView = self.tableHeaderView;
    [self.tableView setNeedsLayout];
}

- (void)setupTableFooterView
{
    NSParameterAssert(self.tableView);
    
    //  Fix: Hide the cellSeparators, when the table is empty
    CGRect footerFrame = UIDevice.isPad ? CGRectZero : WPTableFooterPadFrame;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:footerFrame];
}

- (void)setupTableHandler
{
    NSParameterAssert(self.tableView);
    
    WPTableViewHandler *tableViewHandler = [[WPTableViewHandler alloc] initWithTableView:self.tableView];
    tableViewHandler.cacheRowHeights = YES;
    tableViewHandler.delegate = self;
    self.tableViewHandler = tableViewHandler;
}

- (void)setupRatingsView
{
    NSParameterAssert(self.ratingsView);
    
    UIFont *ratingsFont                             = [WPFontManager systemRegularFontOfSize:15.0];
    self.ratingsView.label.font                     = ratingsFont;
    self.ratingsView.leftButton.titleLabel.font     = ratingsFont;
    self.ratingsView.rightButton.titleLabel.font    = ratingsFont;
    self.ratingsView.delegate                       = self;
    self.ratingsView.alpha                          = WPAlphaZero;
}

- (void)setupRefreshControl
{
    UIRefreshControl *refreshControl = [UIRefreshControl new];
    [refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
}

- (void)setupNavigationBar
{
    // Don't show 'Notifications' in the next-view back button
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:[NSString string] style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem = backButton;
    
    // This is only required for debugging:
    // If we're sync'ing against a custom bucket, we should let the user know about it!
    Simperium *simperium    = [[WordPressAppDelegate sharedInstance] simperium];
    NSString *name          = simperium.bucketOverrides[NSStringFromClass([Notification class])];
    if ([name isEqualToString:WPNotificationsBucketName]) {
        return;
    }
    
    self.title = [NSString stringWithFormat:@"Notifications from [%@]", name];
}

- (void)setupFiltersSegmentedControl
{
    NSParameterAssert(self.filtersSegmentedControl);
    
    NSArray *titles = @[
        NSLocalizedString(@"All",       @"Displays all of the Notifications, unfiltered"),
        NSLocalizedString(@"Unread",    @"Filters Unread Notifications"),
        NSLocalizedString(@"Comments",  @"Filters Comments Notifications"),
        NSLocalizedString(@"Follows",   @"Filters Follows Notifications"),
        NSLocalizedString(@"Likes",     @"Filters Likes Notifications")
    ];
    
    NSInteger index = 0;
    for (NSString *title in titles) {
        [self.filtersSegmentedControl setTitle:title forSegmentAtIndex:index++];
    }
    
    [WPStyleGuide configureSegmentedControl:self.filtersSegmentedControl];
}

- (void)showFiltersSegmentedControlIfApplicable
{
    if (self.tableHeaderView.alpha == WPAlphaZero && self.shouldDisplayFilters) {
        [UIView animateWithDuration:WPAnimationDurationDefault delay:0.0 options:UIViewAnimationCurveEaseIn animations:^{
            self.tableHeaderView.alpha = WPAlphaFull;
        } completion:nil];
    }
}

- (void)hideFiltersSegmentedControlIfApplicable
{
    if (self.tableHeaderView.alpha == WPAlphaFull && !self.shouldDisplayFilters) {
        self.tableHeaderView.alpha  = WPAlphaZero;
    }
}

- (void)setupNotificationsBucketDelegate
{
    Simperium *simperium            = [[WordPressAppDelegate sharedInstance] simperium];
    SPBucket *notesBucket           = [simperium bucketForName:self.entityName];
    notesBucket.delegate            = self;
    notesBucket.notifyWhileIndexing = YES;
}

- (BOOL)shouldDisplayFilters
{
    return !self.showsJetpackMessage && !self.showsEmptyStateLegend;
}


#pragma mark - AppBotX Helpers

- (void)showRatingViewIfApplicable
{
    if (![AppRatingUtility shouldPromptForAppReviewForSection:@"notifications"]) {
        return;
    }
    
    // Rating View is already visible, don't bother to do anything
    if (self.ratingsHeightConstraint.constant == RatingsViewHeight && self.ratingsView.alpha == WPAlphaFull) {
        return;
    }
    
    // Animate FadeIn + Enhance
    self.ratingsView.alpha = WPAlphaZero;
    
    CGFloat const delay = 0.5f;
    
    [UIView animateWithDuration:WPAnimationDurationDefault delay:delay options:UIViewAnimationCurveEaseIn animations:^{
        self.ratingsView.alpha                  = WPAlphaFull;
        self.ratingsHeightConstraint.constant   = RatingsViewHeight;
                    
        [self setupTableHeaderView];
    } completion:nil];
    
    [WPAnalytics track:WPAnalyticsStatAppReviewsSawPrompt];
}

- (void)hideRatingView
{
    [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationCurveEaseOut animations:^{
        self.ratingsView.alpha                  = WPAlphaZero;
        self.ratingsHeightConstraint.constant   = 0;
                
        [self setupTableHeaderView];
    } completion:nil];
}


#pragma mark - SPBucketDelegate Methods

- (void)bucket:(SPBucket *)bucket didChangeObjectForKey:(NSString *)key forChangeType:(SPBucketChangeType)changeType memberNames:(NSArray *)memberNames
{
    UIApplication *application = [UIApplication sharedApplication];
    
    // Did the user tap on a push notification?
    if (changeType == SPBucketChangeInsert && [self.pushNotificationID isEqualToString:key]) {

        // Show the details only if NotificationPushMaxWait hasn't elapsed
        if (ABS(self.pushNotificationDate.timeIntervalSinceNow) <= NotificationPushMaxWait) {
            [self showDetailsForNoteWithID:key];
        }
        
        // Stop the sync timeout: we've got activity!
        [self stopSyncTimeoutTimer];
        
        // Cleanup
        self.pushNotificationID     = nil;
        self.pushNotificationDate   = nil;
    }
    
    // Mark as read immediately if:
    //  -   We're onscreen
    //  -   The app is in Foreground
    //
    // We need to make sure that the app is in FG, since this method might get called during a Background Fetch OS event,
    // which would cause the badge to get reset on its own.
    //
    if (changeType == SPBucketChangeInsert && self.isViewOnScreen && application.applicationState == UIApplicationStateActive) {
        [self resetApplicationBadge];
        [self updateLastSeenTime];
    }
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


#pragma mark - Public Methods

- (void)showDetailsForNoteWithID:(NSString *)notificationID
{
    Simperium *simperium        = [[WordPressAppDelegate sharedInstance] simperium];
    SPBucket *notesBucket       = [simperium bucketForName:self.entityName];
    Notification *notification  = [notesBucket objectForKey:notificationID];
    
    if (notification) {
        DDLogInfo(@"Pushing Notification Details for: [%@]", notificationID);
        
        [self showDetailsForNotification:notification];
    } else {
        DDLogInfo(@"Notification Details for [%@] cannot be pushed right now. Waiting %f secs", notificationID, NotificationPushMaxWait);
        
        self.pushNotificationID     = notificationID;
        self.pushNotificationDate   = [NSDate date];
        
        [self startSyncTimeoutTimer];
    }
}


#pragma mark - Stats Helpers

- (void)startSyncTimeoutTimer
{
    // Don't proceed if we're not even connected
    BOOL isConnected = [[WordPressAppDelegate sharedInstance] connectionAvailable];
    if (!isConnected) {
        return;
    }
    
    [self stopSyncTimeoutTimer];
    [self performSelector:@selector(trackSyncTimeout) withObject:nil afterDelay:NotificationsSyncTimeout];
}

- (void)stopSyncTimeoutTimer
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(trackSyncTimeout) object:nil];
}

- (void)trackSyncTimeout
{
    Simperium *simperium = [[WordPressAppDelegate sharedInstance] simperium];
    NSDictionary *properties = @{ NotificationsNetworkStatusKey : simperium.networkStatus };
    
    [WPAnalytics track:WPAnalyticsStatNotificationsMissingSyncWarning withProperties:properties];
}


#pragma mark - Helper methods

- (void)resetApplicationBadge
{
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}

- (void)updateLastSeenTime
{
    Notification *note      = [self.tableViewHandler.resultsController.fetchedObjects firstObject];
    if (!note) {
        return;
    }

    NSString *bucketName    = NSStringFromClass([Meta class]);
    Simperium *simperium    = [[WordPressAppDelegate sharedInstance] simperium];
    Meta *metadata          = [[simperium bucketForName:bucketName] objectForKey:bucketName.lowercaseString];
    if (!metadata) {
        return;
    }

    metadata.last_seen      = @(note.timestampAsDate.timeIntervalSince1970);
    [simperium save];
}

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

- (BOOL)isRowLastRowForSection:(NSIndexPath *)indexPath
{
    // Failsafe!
    if (indexPath.section >= self.tableViewHandler.resultsController.sections.count) {
        return false;
    }
    
    id<NSFetchedResultsSectionInfo> sectionInfo = [self.tableViewHandler.resultsController.sections objectAtIndex:indexPath.section];
    return indexPath.row == (sectionInfo.numberOfObjects - 1);
}

- (void)trackAppeared
{
    [WPAnalytics track:WPAnalyticsStatOpenedNotificationsList];
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


#pragma mark - Segue Helpers

- (void)showDetailsForNotification:(Notification *)note
{
    [WPAnalytics track:WPAnalyticsStatOpenedNotificationDetails withProperties:@{ @"notification_type" : note.type ?: @"unknown"}];
    
    // Mark as Read, if needed
    if(!note.read.boolValue) {
        note.read = @(1);
        [[ContextManager sharedInstance] saveContext:note.managedObjectContext];
    }
    
    // Failsafe: Don't push nested!
    if (self.navigationController.visibleViewController != self) {
        [self.navigationController popToRootViewControllerAnimated:NO];
    }
    
    if (note.isMatcher && note.metaPostID && note.metaSiteID) {
        [self performSegueWithIdentifier:[ReaderDetailViewController classNameWithoutNamespaces] sender:note];
    } else {
        [self performSegueWithIdentifier:NSStringFromClass([NotificationDetailsViewController class]) sender:note];
    }
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


#pragma mark - UISegmentedControl Methods

- (IBAction)segmentedControlDidChange:(UISegmentedControl *)sender
{
    [self reloadResultsController];
    
    // It's a long way, to the top (if you wanna rock'n roll!)
    if (self.tableViewHandler.resultsController.fetchedObjects.count == 0) {
        return;
    }
    
    NSIndexPath *path = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}


#pragma mark - WPTableViewHandlerDelegate Methods

- (NSManagedObjectContext *)managedObjectContext
{
    return [[ContextManager sharedInstance] mainContext];
}

- (NSFetchRequest *)fetchRequest
{
    NSString *sortKey               = NSStringFromSelector(@selector(timestamp));
    NSFetchRequest *fetchRequest    = [NSFetchRequest fetchRequestWithEntityName:self.entityName];
    fetchRequest.sortDescriptors    = @[[NSSortDescriptor sortDescriptorWithKey:sortKey ascending:NO] ];
    fetchRequest.predicate          = [self predicateForSelectedFilters];
    
    return fetchRequest;
}

- (NSPredicate *)predicateForSelectedFilters
{
    NSDictionary *filtersMap = @{
        @(NotificationFilterUnread)     : @" AND (read = NO)",
        @(NotificationFilterComment)    : [NSString stringWithFormat:@" AND (type = '%@')", NoteTypeComment],
        @(NotificationFilterFollow)     : [NSString stringWithFormat:@" AND (type = '%@')", NoteTypeFollow],
        @(NotificationFilterLike)       : [NSString stringWithFormat:@" AND (type = '%@' OR type = '%@')",
                                            NoteTypeLike, NoteTypeCommentLike]
    };
 
    NSString *condition = filtersMap[@(self.filtersSegmentedControl.selectedSegmentIndex)] ?: [NSString string];
    NSString *format    = [@"NOT (SELF IN %@)" stringByAppendingString:condition];
    
    return [NSPredicate predicateWithFormat:format, self.notificationIdsBeingDeleted.allObjects];
}

- (void)configureCell:(NoteTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    // Note:
    // iOS 8 has a nice bug in which, randomly, the last cell per section was getting an extra separator.
    // For that reason, we draw our own separators.
 
    Notification *note              = [self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    BOOL isMarkedForDeletion        = [self isNoteMarkedForDeletion:note.objectID];
    BOOL isLastRow                  = [self isRowLastRowForSection:indexPath];
    __weak __typeof(self) weakSelf  = self;
    
    cell.attributedSubject          = note.subjectBlock.attributedSubjectText;
    cell.attributedSnippet          = note.snippetBlock.attributedSnippetText;
    cell.read                       = note.read.boolValue;
    cell.noticon                    = note.noticon;
    cell.unapproved                 = note.isUnapprovedComment;
    cell.markedForDeletion          = isMarkedForDeletion;
    cell.showsBottomSeparator       = !isLastRow && !isMarkedForDeletion;
    cell.selectionStyle             = isMarkedForDeletion ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleGray;
    cell.onUndelete                 = ^{
        [weakSelf cancelDeletionForNoteWithID:note.objectID];
    };

    [cell downloadIconWithURL:note.iconURL];
}

- (NSString *)sectionNameKeyPath
{
    return NSStringFromSelector(@selector(sectionIdentifier));
}

- (NSString *)entityName
{
    return NSStringFromClass([Notification class]);
}

- (void)tableViewDidChangeContent:(UITableView *)tableView
{
    // Update Separators:
    // Due to an UIKit bug, we need to draw our own separators (Issue #2845). Let's update the separator status
    // after a DB OP. This loop has been measured in the order of milliseconds (iPad Mini)
    for (NSIndexPath *indexPath in self.tableView.indexPathsForVisibleRows)
    {
        NoteTableViewCell *cell     = (NoteTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        cell.showsBottomSeparator   = ![self isRowLastRowForSection:indexPath];
    }
    
    // Update NoResults View
    [self showNoResultsViewIfNeeded];
}


#pragma mark - UIRefreshControl Methods

- (void)refresh
{
    // Yes. This is dummy. Simperium handles sync for us!
    [self.refreshControl endRefreshing];
}


#pragma mark - No Results Helpers

- (void)showNoResultsViewIfNeeded
{
    // Remove If Needed
    if (!self.showsEmptyStateLegend) {
        [self.noResultsView removeFromSuperview];
        
        // Show filters if we have results
        [self showFiltersSegmentedControlIfApplicable];
        
        return;
    }
    
    // Attach the view
    WPNoResultsView *noResultsView  = self.noResultsView;
    if (!noResultsView.superview) {
        [self.tableView addSubviewWithFadeAnimation:noResultsView];
    }
    
    // Hide the filter header if we're showing the Jetpack prompt
    [self hideFiltersSegmentedControlIfApplicable];
    
    // Refresh its properties: The user may have signed into WordPress.com
    noResultsView.titleText         = self.noResultsTitleText;
    noResultsView.messageText       = self.noResultsMessageText;
    noResultsView.accessoryView     = self.noResultsAccessoryView;
    noResultsView.buttonTitle       = self.noResultsButtonText;
}

- (WPNoResultsView *)noResultsView
{
    if (!_noResultsView) {
        _noResultsView          = [WPNoResultsView new];
        _noResultsView.delegate = self;
    }
    return _noResultsView;
}

- (NSString *)noResultsTitleText
{
    if (self.showsJetpackMessage) {
        return NSLocalizedString(@"Connect to Jetpack", @"Notifications title displayed when a self-hosted user is not connected to Jetpack");
    }
    
    NSDictionary *messageMap = @{
        @(NotificationFilterNone)       : NSLocalizedString(@"No notifications yet", @"Displayed in the Notifications Tab, when there are no notifications"),
        @(NotificationFilterUnread)     : NSLocalizedString(@"No unread notifications", @"Displayed in the Notifications Tab, when the Unread Filter shows no notifications"),
        @(NotificationFilterComment)    : NSLocalizedString(@"No comments notifications", @"Displayed in the Notifications Tab, when the Comments Filter shows no notifications"),
        @(NotificationFilterFollow)     : NSLocalizedString(@"No new followers notifications", @"Displayed in the Notifications Tab, when the Follow Filter shows no notifications"),
        @(NotificationFilterLike)       : NSLocalizedString(@"No like notifications", @"Displayed in the Notifications Tab, when the Likes Filter shows no notifications"),
    };

    return messageMap[@(self.filtersSegmentedControl.selectedSegmentIndex)];
}

- (NSString *)noResultsMessageText
{
    NSString *jetapackMessage   = NSLocalizedString(@"Jetpack supercharges your self-hosted WordPress site.", @"Notifications message displayed when a self-hosted user is not connected to Jetpack");
    return self.showsJetpackMessage ? jetapackMessage : nil;
}

- (UIView *)noResultsAccessoryView
{
    return self.showsJetpackMessage ? [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-jetpack-gray"]] : nil;
}
 
- (NSString *)noResultsButtonText
{
    return self.showsJetpackMessage ? NSLocalizedString(@"Learn more", @"") : nil;
}
 
- (BOOL)showsJetpackMessage
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService  = [[AccountService alloc] initWithManagedObjectContext:context];
    BOOL showsJetpackMessage        = ![accountService defaultWordPressComAccount];
    
    return showsJetpackMessage;
}

- (BOOL)showsEmptyStateLegend
{
    return (self.tableViewHandler.resultsController.fetchedObjects.count == 0);
}

- (void)didTapNoResultsView:(WPNoResultsView *)noResultsView
{
    NSURL *targetURL                        = [NSURL URLWithString:WPJetpackInformationURL];
    WPWebViewController *webViewController  = [WPWebViewController webViewControllerWithURL:targetURL];
 
    UINavigationController *navController   = [[UINavigationController alloc] initWithRootViewController:webViewController];
    [self presentViewController:navController animated:YES completion:nil];
 
    [WPAnalytics track:WPAnalyticsStatSelectedLearnMoreInConnectToJetpackScreen withProperties:@{@"source": @"notifications"}];
}



#pragma mark - ABXPromptViewDelegate

- (void)appbotPromptForReview
{
    [WPAnalytics track:WPAnalyticsStatAppReviewsRatedApp];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[AppRatingUtility appReviewUrl]]];
    [AppRatingUtility ratedCurrentVersion];
    [self hideRatingView];
}

- (void)appbotPromptForFeedback
{
    [WPAnalytics track:WPAnalyticsStatAppReviewsOpenedFeedbackScreen];
    [ABXFeedbackViewController showFromController:self placeholder:nil delegate:self];
    [AppRatingUtility gaveFeedbackForCurrentVersion];
    [self hideRatingView];
}

- (void)appbotPromptClose
{
    [WPAnalytics track:WPAnalyticsStatAppReviewsDeclinedToRateApp];
    [AppRatingUtility declinedToRateCurrentVersion];
    [self hideRatingView];
}

- (void)appbotPromptLiked
{
    [AppRatingUtility likedCurrentVersion];
    [WPAnalytics track:WPAnalyticsStatAppReviewsLikedApp];
}

- (void)appbotPromptDidntLike
{
    [AppRatingUtility dislikedCurrentVersion];
    [WPAnalytics track:WPAnalyticsStatAppReviewsDidntLikeApp];
}

- (void)abxFeedbackDidSendFeedback
{
    [WPAnalytics track:WPAnalyticsStatAppReviewsSentFeedback];
}

- (void)abxFeedbackDidntSendFeedback
{
    [WPAnalytics track:WPAnalyticsStatAppReviewsCanceledFeedbackScreen];
}

@end
