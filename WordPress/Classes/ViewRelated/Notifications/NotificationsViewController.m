#import "NotificationsViewController.h"
#import "NotificationsCommentDetailViewController.h"
#import "NotificationsFollowDetailViewController.h"
#import "WordPressAppDelegate.h"
#import "WordPressComApi.h"
#import "EGORefreshTableHeaderView.h"
#import "NewNotificationsTableViewCell.h"
#import "WPTableViewControllerSubclass.h"
#import "NotificationSettingsViewController.h"
#import "WPAccount.h"
#import "WPWebViewController.h"
#import "Note.h"
#import "Meta.h"
#import <Simperium/Simperium.h>
#import "ContextManager.h"
#import "Constants.h"
#import "NotificationsManager.h"
#import "NotificationSettingsViewController.h"
#import "NotificationsBigBadgeDetailViewController.h"
#import "AccountService.h"
#import "ReaderPostService.h"
#import "ContextManager.h"
#import "StatsViewController.h"

#import "ReaderPost.h"
#import "ReaderPostDetailViewController.h"
#import "ContextManager.h"


@interface NotificationsViewController ()

@property (nonatomic, strong) id    authListener;
@property (nonatomic, assign) BOOL  viewHasAppeared;
@property (nonatomic, assign) BOOL  retrievingNotifications;

typedef void (^NotificationsLoadPostBlock)(BOOL success, ReaderPost *post);
- (void)loadPostWithId:(NSNumber *)postID fromSite:(NSNumber *)siteID block:(NotificationsLoadPostBlock)block;

@end


@implementation NotificationsViewController

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    // We need to override the implementation in our superclass or else restoration fails - no blog!
    return [[self alloc] init];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"Notifications", @"Notifications View Controller title");
    }
    return self;
}

- (NSString *)noResultsTitleText
{
    if ([self showJetpackConnectMessage]) {
        return NSLocalizedString(@"Connect to Jetpack", @"Displayed in the notifications view when a self-hosted user is not connected to Jetpack");
    } else {
        return NSLocalizedString(@"No notifications yet", @"Displayed when the user pulls up the notifications view and they have no items");
    }
}

- (NSString *)noResultsMessageText
{
    if ([self showJetpackConnectMessage]) {
        return NSLocalizedString(@"Jetpack supercharges your self-hosted WordPress site.", @"Displayed in the notifications view when a self-hosted user is not connected to Jetpack");
    } else {
        return nil;
    }
}

- (NSString *)noResultsButtonText
{
    if ([self showJetpackConnectMessage]) {
        return NSLocalizedString(@"Learn more", @"");
    } else {
        return nil;
    }
}

- (UIView *)noResultsAccessoryView
{
    if ([self showJetpackConnectMessage]) {
        return [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-jetpack-gray"]];
    } else {
        return nil;
    }
}

- (void)didTapNoResultsView:(WPNoResultsView *)noResultsView
{
    // Show Jetpack information screen
    [WPAnalytics track:WPAnalyticsStatSelectedLearnMoreInConnectToJetpackScreen withProperties:@{@"source": @"notifications"}];
    WPWebViewController *webViewController = [[WPWebViewController alloc] init];
	webViewController.url = [NSURL URLWithString:WPNotificationsJetpackInformationURL];
    [self.navigationController pushViewController:webViewController animated:YES];
}

- (BOOL)showJetpackConnectMessage
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

    return defaultAccount == nil;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIApplication sharedApplication] removeObserver:self forKeyPath:NSStringFromSelector(@selector(applicationIconBadgeNumber))];
}

- (void)viewDidLoad
{
    DDLogMethod();
    [super viewDidLoad];
    
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 25, 0, 0);
    self.infiniteScrollEnabled = NO;
    
    if ([NotificationsManager deviceRegisteredForPushNotifications]) {
        UIBarButtonItem *pushSettings = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Manage", @"")
                                                                         style:UIBarButtonItemStylePlain
                                                                        target:self
                                                                        action:@selector(showNotificationSettings)];
        self.navigationItem.rightBarButtonItem = pushSettings;
    }
    
    // Watch for application badge number changes
    UIApplication *application  = [UIApplication sharedApplication];
    NSString *badgeKeyPath      = NSStringFromSelector(@selector(applicationIconBadgeNumber));
    [application addObserver:self forKeyPath:badgeKeyPath options:NSKeyValueObservingOptionNew context:nil];
    
    [self updateTabBarBadgeNumber];
}

- (void)viewWillAppear:(BOOL)animated
{
    DDLogMethod();
    [super viewWillAppear:animated];
    
    // Reload!
    [self.tableView reloadData];
    
    // Listen to appDidBecomeActive Note
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(handleApplicationDidBecomeActiveNote:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (!self.viewHasAppeared) {
        self.viewHasAppeared = YES;
        [WPAnalytics track:WPAnalyticsStatNotificationsAccessed];
    }
    
    [self updateLastSeenTime];
    [self resetApplicationBadge];
}

- (void)viewWillDisappear:(BOOL)animated
{
    DDLogMethod();
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - NSObject(NSKeyValueObserving) Helpers

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(applicationIconBadgeNumber))]) {
        [self updateTabBarBadgeNumber];
    }
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


#pragma mark - Custom methods

- (void)resetApplicationBadge
{
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}

- (void)updateTabBarBadgeNumber
{
    NSInteger count         = [[UIApplication sharedApplication] applicationIconBadgeNumber];
    NSString *countString   = nil;
    
    if (count > 0) {
        countString = [NSString stringWithFormat:@"%d", count];
    }
    
    // Note: self.navigationViewController might be nil. Let's hit the UITabBarController instead
    UITabBarController *tabBarController    = [[WordPressAppDelegate sharedWordPressApplicationDelegate] tabBarController];
    UITabBarItem *tabBarItem                = tabBarController.tabBar.items[kNotificationsTabIndex];
    
    tabBarItem.badgeValue                   = countString;
}

- (void)updateLastSeenTime
{
    // Find the most recent note
    Note *note = [self.resultsController.fetchedObjects firstObject];
    if (!note) {
        return;
    }
    
    NSString *bucketName    = NSStringFromClass([Meta class]);
    Simperium *simperium    = [[WordPressAppDelegate sharedWordPressApplicationDelegate] simperium];
    Meta *metadata          = [[simperium bucketForName:bucketName] objectForKey:[bucketName lowercaseString]];
    if (!metadata) {
        return;
    }
    
    metadata.last_seen      = note.timestamp;
    [simperium save];
}

- (void)showNotificationSettings
{
    NotificationSettingsViewController *notificationSettingsViewController = [[NotificationSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:notificationSettingsViewController];
    navigationController.navigationBar.translucent = NO;
    navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeNotificationSettings)];
    notificationSettingsViewController.navigationItem.rightBarButtonItem = closeButton;
    
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)closeNotificationSettings
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Note *note = [self.resultsController objectAtIndexPath:indexPath];
    return [NewNotificationsTableViewCell rowHeightForContentProvider:note andWidth:WPTableViewFixedWidth];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Note *note = [self.resultsController objectAtIndexPath:indexPath];
    
    BOOL hasDetailView = [self noteHasDetailView:note];
    if (hasDetailView) {
        [WPAnalytics track:WPAnalyticsStatNotificationsOpenedNotificationDetails];
        
        if ([note isComment]) {
            NotificationsCommentDetailViewController *commentDetailViewController = [[NotificationsCommentDetailViewController alloc] initWithNote:note];
            [self.navigationController pushViewController:commentDetailViewController animated:YES];
        } else if ([note isMatcher] && [note metaPostID] && [note metaSiteID]) {
            [self loadPostWithId:[note metaPostID] fromSite:[note metaSiteID] block:^(BOOL success, ReaderPost *post) {
                if (!success || ![self.navigationController.topViewController isEqual:self]) {
                    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
                    return;
                }
            
                ReaderPostDetailViewController *controller = [[ReaderPostDetailViewController alloc] initWithPost:post];
                [self.navigationController pushViewController:controller animated:YES];
            }];
        } else if ([note templateType] == WPNoteTemplateMultiLineList || [note templateType] == WPNoteTemplateSingleLineList) {
            NotificationsFollowDetailViewController *detailViewController = [[NotificationsFollowDetailViewController alloc] initWithNote:note];
            [self.navigationController pushViewController:detailViewController animated:YES];
        } else if ([note templateType] == WPNoteTemplateBigBadge) {
            NotificationsBigBadgeDetailViewController *bigBadgeViewController = [[NotificationsBigBadgeDetailViewController alloc] initWithNote: note];
            [self.navigationController pushViewController:bigBadgeViewController animated:YES];
        }
    } else {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
	
    if(!note.isRead) {
        note.unread = @(0);
		[[ContextManager sharedInstance] saveContext:note.managedObjectContext];

        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];

        if (hasDetailView) {
            [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
    }
}

- (BOOL)noteHasDetailView:(Note *)note
{
    return ((note.isComment) || ([note templateType] != WPNoteTemplateUnknown));
}

- (void)loadPostWithId:(NSNumber *)postID fromSite:(NSNumber *)siteID block:(NotificationsLoadPostBlock)block
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    ReaderPostService *service = [[ReaderPostService alloc] initWithManagedObjectContext:context];
    [service fetchPost:postID.integerValue forSite:siteID.integerValue success:^(ReaderPost *post) {
        [[ContextManager sharedInstance] saveContext:context];
        block(YES, post);
    } failure:^(NSError *error) {
        DDLogError(@"[RestAPI] %@", error);
        block(NO, nil);
    }];

}

#pragma mark - WPTableViewController subclass methods

- (NSString *)entityName
{
    return @"NoteSimperium";
}

- (NSDate *)lastSyncDate
{
    return [NSDate date];
}

- (NSFetchRequest *)fetchRequest
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[self entityName]];
    fetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO] ];
    fetchRequest.fetchBatchSize = 10;
    return fetchRequest;
}

- (Class)cellClass
{
    return [NewNotificationsTableViewCell class];
}

- (void)configureCell:(NewNotificationsTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    cell.contentProvider = [self.resultsController objectAtIndexPath:indexPath];
    
    Note *note = [self.resultsController objectAtIndexPath:indexPath];
    BOOL hasDetailsView = [self noteHasDetailView:note];
    
    if (!hasDetailsView) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
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

#pragma mark - DetailViewDelegate

- (void)resetView
{
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    if (selectedIndexPath) {
        [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:NO];
    }
}

@end
