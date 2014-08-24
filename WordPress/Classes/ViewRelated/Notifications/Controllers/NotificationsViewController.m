#import "NotificationsViewController.h"

#import <Simperium/Simperium.h>
#import "WordPressAppDelegate.h"
#import "ContextManager.h"
#import "Constants.h"

#import "WPTableViewSectionHeaderView.h"
#import "WPTableViewControllerSubclass.h"
#import "WPWebViewController.h"
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

#import "WordPress-Swift.h"



#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

static NSTimeInterval const NotificationPushMaxWait = 1;
static CGFloat const NoteEstimatedHeight            = 70;
static UIEdgeInsets NotificationTableInsetsPad      = {40.0f, 0.0f, 48.0f, 0.0f};


#pragma mark ====================================================================================
#pragma mark Private Properties
#pragma mark ====================================================================================

@interface NotificationsViewController () <SPBucketDelegate>
@property (nonatomic, assign) dispatch_once_t       trackedViewDisplay;
@property (nonatomic, strong) NSString              *pushNotificationID;
@property (nonatomic, strong) NSDate                *pushNotificationDate;
@property (nonatomic, strong) NSMutableDictionary   *cachedRowHeights;
@property (nonatomic, strong) UINib                 *tableViewCellNib;
@end

#pragma mark ====================================================================================
#pragma mark NotificationsViewController
#pragma mark ====================================================================================

@implementation NotificationsViewController

- (void)dealloc
{
    DDLogMethod();
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIApplication sharedApplication] removeObserver:self forKeyPath:NSStringFromSelector(@selector(applicationIconBadgeNumber))];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.title              = NSLocalizedString(@"Notifications", @"Notifications View Controller title");

        // Watch for application badge number changes
        NSString *badgeKeyPath  = NSStringFromSelector(@selector(applicationIconBadgeNumber));
        [[UIApplication sharedApplication] addObserver:self forKeyPath:badgeKeyPath options:NSKeyValueObservingOptionNew context:nil];
        
        // Cache Row Heights!
        self.cachedRowHeights   = [NSMutableDictionary dictionary];
        
        // Watch for new Notifications
        Simperium *simperium    = [[WordPressAppDelegate sharedWordPressApplicationDelegate] simperium];
        SPBucket *notesBucket   = [simperium bucketForName:self.entityName];
        notesBucket.delegate    = self;
    }
    
    return self;
}


#pragma mark - UIViewController Methods

- (void)viewDidLoad
{
    [super viewDidLoad];

    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    
    self.infiniteScrollEnabled = NO;

    // Register the cells
    NSString *cellNibName       = [NoteTableViewCell classNameWithoutNamespaces];
    self.tableViewCellNib       = [UINib nibWithNibName:cellNibName bundle:[NSBundle mainBundle]];
    [self.tableView registerNib:_tableViewCellNib forCellReuseIdentifier:[NoteTableViewCell layoutIdentifier]];
    [self.tableView registerNib:_tableViewCellNib forCellReuseIdentifier:[NoteTableViewCell reuseIdentifier]];
    
    //  This is a workaround:
    //  We're using an empty tableHeader to ensure a top margin. contentInsets won't do the trick, since it produces an
    //  undesired behavior when using sectionViews (the section view respects the topInsets, while the cells won't)
    //
    if (UIDevice.isPad) {
        self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, NotificationTableInsetsPad.top)];
        self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, NotificationTableInsetsPad.bottom)];
    }

    // Don't show 'Notifications' in the next-view back button
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:[NSString string] style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem = backButton;
    
    // Refresh Badge
    [self updateTabBarBadgeNumber];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Reload!
    [self.tableView reloadData];

    // Listen to appDidBecomeActive Note
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(handleApplicationDidBecomeActiveNote:) name:UIApplicationDidBecomeActiveNotification object:nil];

    // Hit the Tracker
    dispatch_once(&_trackedViewDisplay, ^{
        [WPAnalytics track:WPAnalyticsStatNotificationsAccessed];
    });

    // Badge + Metadata
    [self updateLastSeenTime];
    [self resetApplicationBadge];
    [self showManageButtonIfNeeded];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.cachedRowHeights removeAllObjects];
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
        
        // Cleanup
        self.pushNotificationID     = nil;
        self.pushNotificationDate   = nil;
    }
    
    // Always nuke the cellHeight Cache's
    [self.cachedRowHeights removeAllObjects];
}


#pragma mark - NSNotification Helpers

- (void)handleApplicationDidBecomeActiveNote:(NSNotification *)note
{
    // Let's reset the badge, whenever the app comes back to FG, and this view was upfront!
    if (!self.isViewLoaded || !self.view.window) {
        return;
    }

    // Reload
    [self.tableView reloadData];

    // Reset the badge: the notifications are visible!
    [self resetApplicationBadge];
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
    }
}


#pragma mark - Helper methods

- (void)resetApplicationBadge
{
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}

- (void)updateTabBarBadgeNumber
{
    // Note: self.navigationViewController might be nil. Let's hit the UITabBarController instead
    UITabBarController *tabBarController    = [[WordPressAppDelegate sharedWordPressApplicationDelegate] tabBarController];
    UITabBarItem *tabBarItem                = tabBarController.tabBar.items[kNotificationsTabIndex];
 
    NSInteger count                         = [[UIApplication sharedApplication] applicationIconBadgeNumber];
    NSString *countString                   = (count > 0) ? [NSString stringWithFormat:@"%d", count] : nil;

    tabBarItem.badgeValue                   = countString;
}

- (void)updateLastSeenTime
{
    Notification *note      = [self.resultsController.fetchedObjects firstObject];
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

- (void)showNotificationSettings
{
    NotificationSettingsViewController *vc          = [[NotificationSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    vc.showCloseButton                              = YES;
    
    UINavigationController *navigationController    = [[UINavigationController alloc] initWithRootViewController:vc];
    navigationController.navigationBar.translucent  = NO;
    navigationController.modalPresentationStyle     = UIModalPresentationFormSheet;

    [self presentViewController:navigationController animated:YES completion:nil];
}


#pragma mark - Segue Helpers

- (void)showDetailsForNotification:(Notification *)note
{
    [WPAnalytics track:WPAnalyticsStatNotificationsOpenedNotificationDetails];
    
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
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.resultsController sections] objectAtIndex:section];
    
    NoteTableHeaderView *headerView = [[NoteTableHeaderView alloc] initWithWidth:CGRectGetWidth(tableView.bounds)];
    headerView.title                = [Notification descriptionForSectionIdentifier:sectionInfo.name];
    
    return headerView;
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
    NSNumber *rowCacheValue = self.cachedRowHeights[indexPath];
    if (rowCacheValue) {
        return rowCacheValue.floatValue;
    }

    return NoteEstimatedHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    // Hit the cache first
    NSNumber *rowCacheValue = self.cachedRowHeights[indexPath];
    if (rowCacheValue) {
        return rowCacheValue.floatValue;
    }
    
    // Setup the cell
    NoteTableViewCell *layoutCell = [tableView dequeueReusableCellWithIdentifier:[NoteTableViewCell layoutIdentifier]];
    [self configureCell:layoutCell atIndexPath:indexPath];
    
    CGFloat height = [layoutCell layoutHeightWithWidth:CGRectGetWidth(self.tableView.bounds)];
    
    // Cache
    self.cachedRowHeights[indexPath] = @(height);

    return height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Notification *note = [self.resultsController objectAtIndexPath:indexPath];
    if (!note) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    
    // Mark as Read, if needed
    if(!note.read.boolValue) {
        note.read = @(1);
        [[ContextManager sharedInstance] saveContext:note.managedObjectContext];
        
        // Refresh the UI as well
        NoteTableViewCell *cell = (NoteTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
        cell.read = note.read;
    }
    
    // At last, push the details
    [self showDetailsForNotification:note];
}


#pragma mark - Storyboard Helpers

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *detailsSegueID    = NSStringFromClass([NotificationDetailsViewController class]);
    NSString *readerSegueID     = NSStringFromClass([ReaderPostDetailViewController class]);
    Notification *note          = sender;
    
    if([segue.identifier isEqualToString:detailsSegueID]) {
        NotificationDetailsViewController *detailsViewController = segue.destinationViewController;
        detailsViewController.note = note;
    
    } else if([segue.identifier isEqualToString:readerSegueID]) {
        ReaderPostDetailViewController *readerViewController = segue.destinationViewController;
        [readerViewController setupWithPostID:note.metaPostID siteID:note.metaSiteID];
    }
}


#pragma mark - WPTableViewController subclass methods

- (NSString *)entityName
{
    return NSStringFromClass([Notification class]);
}

- (NSString *)sectionNameKeyPath
{
    return NSStringFromSelector(@selector(sectionIdentifier));
}

- (NSDate *)lastSyncDate
{
    return [NSDate date];
}

- (NSFetchRequest *)fetchRequest
{
    NSString *sortKey               = NSStringFromSelector(@selector(timestamp));
    NSFetchRequest *fetchRequest    = [NSFetchRequest fetchRequestWithEntityName:self.entityName];
    fetchRequest.sortDescriptors    = @[[NSSortDescriptor sortDescriptorWithKey:sortKey ascending:NO] ];
    
    return fetchRequest;
}

- (Class)cellClass
{
    return [NoteTableViewCell class];
}

- (void)configureCell:(NoteTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Notification *note          = [self.resultsController objectAtIndexPath:indexPath];
    NotificationBlock *subject  = note.subjectBlocks.firstObject;
    cell.attributedSubject      = subject.attributedSubject;
    cell.read                   = note.read.boolValue;
    cell.noticon                = note.noticon;
    
    [cell downloadGravatarWithURL:note.iconURL];
}

- (void)syncItems
{
    // No-Op. Handled by Simperium!
}

- (void)syncItemsViaUserInteraction:(BOOL)userInteraction success:(void (^)())success failure:(void (^)(NSError *))failure
{
    // No-Op. Handled by Simperium!
    success();
}


#pragma mark - No Results Helpers

- (NSString *)noResultsTitleText
{
    if (self.showJetpackConnectMessage) {
        return NSLocalizedString(@"Connect to Jetpack", @"Displayed in the notifications view when a self-hosted user is not connected to Jetpack");
    } else {
        return NSLocalizedString(@"No notifications yet", @"Displayed when the user pulls up the notifications view and they have no items");
    }
}

- (NSString *)noResultsMessageText
{
    if (self.showJetpackConnectMessage) {
        return NSLocalizedString(@"Jetpack supercharges your self-hosted WordPress site.", @"Displayed in the notifications view when a self-hosted user is not connected to Jetpack");
    } else {
        return nil;
    }
}

- (NSString *)noResultsButtonText
{
    if (self.showJetpackConnectMessage) {
        return NSLocalizedString(@"Learn more", @"");
    } else {
        return nil;
    }
}

- (UIView *)noResultsAccessoryView
{
    if (self.showJetpackConnectMessage) {
        return [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-jetpack-gray"]];
    } else {
        return nil;
    }
}

- (void)didTapNoResultsView:(WPNoResultsView *)noResultsView
{
    WPWebViewController *webViewController  = [[WPWebViewController alloc] init];
	webViewController.url                   = [NSURL URLWithString:WPNotificationsJetpackInformationURL];
    
    [self.navigationController pushViewController:webViewController animated:YES];
    
    [WPAnalytics track:WPAnalyticsStatSelectedLearnMoreInConnectToJetpackScreen withProperties:@{@"source": @"notifications"}];
}

- (BOOL)showJetpackConnectMessage
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService  = [[AccountService alloc] initWithManagedObjectContext:context];
    
    return ![accountService defaultWordPressComAccount];
}

@end
