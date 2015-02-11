#import "NotificationsViewController.h"

#import <Simperium/Simperium.h>
#import "WordPressAppDelegate.h"
#import "ContextManager.h"
#import "Constants.h"

#import "WPTableViewHandler.h"
#import "WPWebViewController.h"
#import "WPNoResultsView.h"
#import "WPTabBarController.h"

#import "Notification.h"
#import "Meta.h"

#import "NotificationsManager.h"
#import "NotificationDetailsViewController.h"
#import "NotificationSettingsViewController.h"

#import "WPAccount.h"

#import "AccountService.h"

#import "ReaderPost.h"
#import "ReaderPostService.h"
#import "ReaderPostDetailViewController.h"

#import "UIView+Subviews.h"

#import "AppRatingUtility.h"

#import <WordPress-AppbotX/ABXPromptView.h>
#import <WordPress-AppbotX/ABXAppStore.h>
#import <WordPress-AppbotX/ABXFeedbackViewController.h>

#import "WordPress-Swift.h"



#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

static NSTimeInterval const NotificationPushMaxWait     = 1;
static CGFloat const NoteEstimatedHeight                = 70;
static CGRect NotificationsTableHeaderFrame             = {0.0f, 0.0f, 0.0f, 40.0f};
static CGRect NotificationsTableFooterFrame             = {0.0f, 0.0f, 0.0f, 48.0f};
static NSTimeInterval NotificationsSyncTimeout          = 10;


#pragma mark ====================================================================================
#pragma mark Private Properties
#pragma mark ====================================================================================

@interface NotificationsViewController () <SPBucketDelegate, WPTableViewHandlerDelegate, ABXPromptViewDelegate,
                                            ABXFeedbackViewControllerDelegate, WPNoResultsViewDelegate>
@property (nonatomic, strong) WPTableViewHandler    *tableViewHandler;
@property (nonatomic, strong) WPNoResultsView       *noResultsView;
@property (nonatomic, assign) BOOL                  trackedViewDisplay;
@property (nonatomic, strong) NSString              *pushNotificationID;
@property (nonatomic, strong) NSDate                *pushNotificationDate;
@property (nonatomic, strong) UINib                 *tableViewCellNib;
@property (nonatomic, strong) NSDate                *lastReloadDate;
@end

#pragma mark ====================================================================================
#pragma mark NotificationsViewController
#pragma mark ====================================================================================

@implementation NotificationsViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIApplication sharedApplication] removeObserver:self forKeyPath:NSStringFromSelector(@selector(applicationIconBadgeNumber))];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.title = NSLocalizedString(@"Notifications", @"Notifications View Controller title");

        // Watch for application badge number changes
        NSString *badgeKeyPath = NSStringFromSelector(@selector(applicationIconBadgeNumber));
        [[UIApplication sharedApplication] addObserver:self forKeyPath:badgeKeyPath options:NSKeyValueObservingOptionNew context:nil];

        // Listen to Logout Notifications
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(handleDefaultAccountChangedNote:)   name:WPAccountDefaultWordPressComAccountChangedNotification object:nil];
        [nc addObserver:self selector:@selector(handleRegisteredDeviceTokenNote:)   name:NotificationsManagerDidRegisterDeviceToken object:nil];
        [nc addObserver:self selector:@selector(handleUnregisteredDeviceTokenNote:) name:NotificationsManagerDidUnregisterDeviceToken object:nil];
        
        // All of the data will be fetched during the FetchedResultsController init. Prevent overfetching
        self.lastReloadDate = [NSDate date];
    }
    
    return self;
}


#pragma mark - UIViewController Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Register the cells
    NSString *cellNibName = [NoteTableViewCell classNameWithoutNamespaces];
    self.tableViewCellNib = [UINib nibWithNibName:cellNibName bundle:[NSBundle mainBundle]];
    [self.tableView registerNib:_tableViewCellNib forCellReuseIdentifier:[NoteTableViewCell reuseIdentifier]];
    
    // iPad Fix: contentInset breaks tableSectionViews
    if (UIDevice.isPad) {
        self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:NotificationsTableHeaderFrame];
        self.tableView.tableFooterView = [[UIView alloc] initWithFrame:NotificationsTableFooterFrame];
    
    // iPhone Fix: Hide the cellSeparators, when the table is empty
    } else {
        self.tableView.tableFooterView = [UIView new];
    }
    
    // UITableView
    self.tableView.accessibilityIdentifier  = @"Notifications Table";
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    
    // WPTableViewHandler
    WPTableViewHandler *tableViewHandler = [[WPTableViewHandler alloc] initWithTableView:self.tableView];
    tableViewHandler.cacheRowHeights = YES;
    tableViewHandler.delegate = self;
    self.tableViewHandler = tableViewHandler;
    
    // Reload the tableView right away: setting the new dataSource doesn't nuke the row + section count cache
    [self.tableView reloadData];
    
    // UIRefreshControl
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;

    // Don't show 'Notifications' in the next-view back button
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:[NSString string] style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem = backButton;
    
    [self updateTabBarBadgeNumber];
    [self showNoResultsViewIfNeeded];
    [self showManageButtonIfNeeded];
    [self showBucketNameIfNeeded];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Manually deselect the selected row. This is required due to a bug in iOS7 / iOS8
    [self.tableView deselectSelectedRowWithAnimation:YES];
    
    // Refresh the UI
    [self hookApplicationStateNotes];
    [self trackAppearedIfNeeded];
    [self updateLastSeenTime];
    [self resetApplicationBadge];
    [self setupNotificationsBucketDelegate];
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
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.tableViewHandler clearCachedRowHeights];
}


#pragma mark - AppBotX Helpers

- (void)showRatingViewIfApplicable
{
    if ([AppRatingUtility shouldPromptForAppReviewForSection:@"notifications"]) {
        if ([self.tableView.tableHeaderView isKindOfClass:[ABXPromptView class]]) {
            // Rating View is already visible, don't bother to do anything
            return;
        }
        
        ABXPromptView *appRatingView = [[ABXPromptView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 100.0)];
        UIFont *appRatingFont = [WPFontManager openSansRegularFontOfSize:15.0];
        appRatingView.label.font = appRatingFont;
        appRatingView.leftButton.titleLabel.font = appRatingFont;
        appRatingView.rightButton.titleLabel.font = appRatingFont;
        appRatingView.delegate = self;
        appRatingView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
        appRatingView.alpha = 0.0;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationCurveEaseIn animations:^{
                self.tableView.tableHeaderView = appRatingView;
                self.tableView.tableHeaderView.alpha = 1.0;
            } completion:nil];
        });
        [WPAnalytics track:WPAnalyticsStatAppReviewsSawPrompt];
    }
}

- (void)hideRatingView
{
    [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationCurveEaseOut animations:^{
        self.tableView.tableHeaderView = nil;
    } completion:nil];
}


#pragma mark - NSObject(NSKeyValueObserving) Helpers

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(applicationIconBadgeNumber))]) {
        [self updateTabBarBadgeNumber];
    }
}


#pragma mark - SPBucketDelegate Methods

- (void)bucket:(SPBucket *)bucket didChangeObjectForKey:(NSString *)key forChangeType:(SPBucketChangeType)changeType memberNames:(NSArray *)memberNames
{
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

- (void)handleRegisteredDeviceTokenNote:(NSNotification *)note
{
    [self showManageButtonIfNeeded];
}

- (void)handleUnregisteredDeviceTokenNote:(NSNotification *)note
{
    [self removeManageButton];
}


#pragma mark - Public Methods

- (void)showDetailsForNoteWithID:(NSString *)notificationID
{
    Simperium *simperium        = [[WordPressAppDelegate sharedWordPressApplicationDelegate] simperium];
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
    BOOL isConnected = [[WordPressAppDelegate sharedWordPressApplicationDelegate] connectionAvailable];
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
    [WPAnalytics track:WPAnalyticsStatNotificationsMissingSyncWarning];
}


#pragma mark - Helper methods

- (void)setupNotificationsBucketDelegate
{
    Simperium *simperium            = [[WordPressAppDelegate sharedWordPressApplicationDelegate] simperium];
    SPBucket *notesBucket           = [simperium bucketForName:self.entityName];
    notesBucket.delegate            = self;
    notesBucket.notifyWhileIndexing = YES;
}

- (void)resetApplicationBadge
{
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}

- (void)updateTabBarBadgeNumber
{
    // Note: self.navigationViewController might be nil. Let's hit the UITabBarController instead
    UITabBarController *tabBarController    = [WPTabBarController sharedInstance];
    UITabBarItem *tabBarItem                = tabBarController.tabBar.items[WPTabNotifications];

    NSInteger count                         = [[UIApplication sharedApplication] applicationIconBadgeNumber];
    NSString *countString                   = (count > 0) ? [NSString stringWithFormat:@"%d", count] : nil;

    tabBarItem.badgeValue                   = countString;
}

- (void)updateLastSeenTime
{
    Notification *note      = [self.tableViewHandler.resultsController.fetchedObjects firstObject];
    if (!note) {
        return;
    }

    NSString *bucketName    = NSStringFromClass([Meta class]);
    Simperium *simperium    = [[WordPressAppDelegate sharedWordPressApplicationDelegate] simperium];
    Meta *metadata          = [[simperium bucketForName:bucketName] objectForKey:bucketName.lowercaseString];
    if (!metadata) {
        return;
    }

    metadata.last_seen      = @(note.timestampAsDate.timeIntervalSince1970);
    [simperium save];
}

- (void)showManageButtonIfNeeded
{
    if (![NotificationsManager deviceRegisteredForPushNotifications]) {
        return;
    }

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Manage", @"")
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(showNotificationSettings)];
}

- (void)showBucketNameIfNeeded
{
    // This is only required for debugging:
    // If we're sync'ing against a custom bucket, we should let the user know about it!
    Simperium *simperium    = [[WordPressAppDelegate sharedWordPressApplicationDelegate] simperium];
    NSString *name          = simperium.bucketOverrides[NSStringFromClass([Notification class])];
    if ([name isEqualToString:WPNotificationsBucketName]) {
        return;
    }

    self.title = [NSString stringWithFormat:@"Notifications from [%@]", name];
}

- (void)removeManageButton
{
    self.navigationItem.rightBarButtonItem = nil;
}

- (void)showNotificationSettings
{
    NotificationSettingsViewController *vc          = [[NotificationSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    vc.showCloseButton                              = YES;
    
    UINavigationController *navigationController    = [[UINavigationController alloc] initWithRootViewController:vc];
    navigationController.navigationBar.translucent  = NO;
    navigationController.modalPresentationStyle     = UIModalPresentationFormSheet;

    [self presentViewController:navigationController animated:YES completion:nil];
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
    
    [self.tableViewHandler.resultsController performFetch:nil];
    [self.tableView reloadData];
    self.lastReloadDate = [NSDate date];
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

- (void)trackAppearedIfNeeded
{
    if (self.trackedViewDisplay) {
        return;
    }
    
    [WPAnalytics track:WPAnalyticsStatNotificationsAccessed];
    self.trackedViewDisplay = YES;
}


#pragma mark - Segue Helpers

- (void)showDetailsForNotification:(Notification *)note
{
    [WPAnalytics track:WPAnalyticsStatNotificationsOpenedNotificationDetails];
    
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
        [self performSegueWithIdentifier:NSStringFromClass([ReaderPostDetailViewController class]) sender:note];
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
    
    NoteTableHeaderView *headerView = [[NoteTableHeaderView alloc] initWithWidth:CGRectGetWidth(tableView.bounds)];
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
    NSAttributedString *subject = note.subjectBlock.subjectAttributedText;
    NSAttributedString *snippet = note.snippetBlock.snippetAttributedText;
    
    // Old School Height Calculation
    CGFloat tableWidth          = CGRectGetWidth(self.tableView.bounds);
    CGFloat cellHeight          = [NoteTableViewCell layoutHeightWithWidth:tableWidth subject:subject snippet:snippet];

    return cellHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Notification *note = [self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    if (!note) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }

    // At last, push the details
    [self showDetailsForNotification:note];
}


#pragma mark - Storyboard Helpers

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *detailsSegueID    = NSStringFromClass([NotificationDetailsViewController class]);
    NSString *readerSegueID     = NSStringFromClass([ReaderPostDetailViewController class]);
    Notification *note          = sender;
    
    if([segue.identifier isEqualToString:detailsSegueID]) {
        NotificationDetailsViewController *detailsViewController = segue.destinationViewController;
        [detailsViewController setupWithNotification:note];
    
    } else if([segue.identifier isEqualToString:readerSegueID]) {
        ReaderPostDetailViewController *readerViewController = segue.destinationViewController;
        [readerViewController setupWithPostID:note.metaPostID siteID:note.metaSiteID];
    }
}


#pragma mark - WPTableViewHandlerDelegate methods

- (NSManagedObjectContext *)managedObjectContext
{
    return [[ContextManager sharedInstance] mainContext];
}

- (NSFetchRequest *)fetchRequest
{
    NSString *sortKey               = NSStringFromSelector(@selector(timestamp));
    NSFetchRequest *fetchRequest    = [NSFetchRequest fetchRequestWithEntityName:self.entityName];
    fetchRequest.sortDescriptors    = @[[NSSortDescriptor sortDescriptorWithKey:sortKey ascending:NO] ];
    
    return fetchRequest;
}

- (void)configureCell:(NoteTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    // Note:
    // iOS 8 has a nice bug in which, randomly, the last cell per section was getting an extra separator.
    // For that reason, we draw our own separators.
    
    Notification *note                      = [self.tableViewHandler.resultsController objectAtIndexPath:indexPath];

    cell.attributedSubject                  = note.subjectBlock.subjectAttributedText;
    cell.attributedSnippet                  = note.snippetBlock.snippetAttributedText;
    cell.read                               = note.read.boolValue;
    cell.noticon                            = note.noticon;
    cell.unapproved                         = note.isUnapprovedComment;
    cell.showsSeparator                     = ![self isRowLastRowForSection:indexPath];
    
    [cell downloadGravatarWithURL:note.iconURL];
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
        NoteTableViewCell *cell = (NoteTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        cell.showsSeparator     = ![self isRowLastRowForSection:indexPath];
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
    if (self.tableViewHandler.resultsController.fetchedObjects.count) {
        [self.noResultsView removeFromSuperview];
        return;
    }
    
    // Attach the view
    WPNoResultsView *noResultsView  = self.noResultsView;
    if (!noResultsView.superview) {
        [self.tableView addSubviewWithFadeAnimation:noResultsView];
    }
    
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
    NSString *jetapackMessage   = NSLocalizedString(@"Connect to Jetpack", @"Notifications title displayed when a self-hosted user is not connected to Jetpack");
    NSString *emptyMessage      = NSLocalizedString(@"No notifications yet", @"Displayed when the user pulls up the notifications view and they have no items");
    return self.showsJetpackMessage ? jetapackMessage : emptyMessage;
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

- (void)didTapNoResultsView:(WPNoResultsView *)noResultsView
{
    WPWebViewController *webViewController  = [[WPWebViewController alloc] init];
	webViewController.url                   = [NSURL URLWithString:WPNotificationsJetpackInformationURL];
 
    [self.navigationController pushViewController:webViewController animated:YES];
 
    [WPAnalytics track:WPAnalyticsStatSelectedLearnMoreInConnectToJetpackScreen withProperties:@{@"source": @"notifications"}];
}



#pragma mark - ABXPromptViewDelegate

- (void)appbotPromptForReview
{
    [WPAnalytics track:WPAnalyticsStatAppReviewsRatedApp];
    [ABXAppStore openAppStoreReviewForApp:WPiTunesAppId];
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
