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
#import "NotificationsManager.h"
#import "NotificationSettingsViewController.h"
#import "NotificationsBigBadgeViewController.h"
#import "NoteService.h"
#import "AccountService.h"
#import "ReaderPostService.h"
#import "ContextManager.h"
#import "StatsViewController.h"

#import "ReaderPost.h"
#import "ReaderPostDetailViewController.h"
#import "ContextManager.h"

NSString * const NotificationsJetpackInformationURL = @"http://jetpack.me/about/";

@interface NotificationsViewController ()

@property (nonatomic, strong) id    authListener;
@property (nonatomic, assign) BOOL  isPushingViewController;
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
    [webViewController setUrl:[NSURL URLWithString:NotificationsJetpackInformationURL]];
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
    [[UIApplication sharedApplication] removeObserver:self forKeyPath:@"applicationIconBadgeNumber"];
}

- (void)viewDidLoad
{
    DDLogMethod();
    [super viewDidLoad];
    
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 25, 0, 0);
    self.infiniteScrollEnabled = YES;
    
    if ([NotificationsManager deviceRegisteredForPushNotifications]) {
        UIBarButtonItem *pushSettings = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Manage", @"")
                                                                         style:UIBarButtonItemStylePlain
                                                                        target:self
                                                                        action:@selector(showNotificationSettings)];
        self.navigationItem.rightBarButtonItem = pushSettings;
    }
    
    // Watch for application badge number changes
    UIApplication *application = [UIApplication sharedApplication];
    [application addObserver:self
                  forKeyPath:@"applicationIconBadgeNumber"
                     options:NSKeyValueObservingOptionNew
                     context:nil];
    [self updateTabBarBadgeNumber];
}

- (void)viewWillAppear:(BOOL)animated
{
    DDLogMethod();
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (!_viewHasAppeared) {
        _viewHasAppeared = YES;
        [WPAnalytics track:WPAnalyticsStatNotificationsAccessed];
    }
    
    _isPushingViewController = NO;
    
    // If table is at the top (i.e. freshly opened), do some extra work
    if (self.tableView.contentOffset.y == 0) {
        [self pruneOldNotes];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if (!_isPushingViewController) {
        [self pruneOldNotes];
    }
}

#pragma mark - NSObject(NSKeyValueObserving) methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"applicationIconBadgeNumber"]) {
        [self updateTabBarBadgeNumber];
    }
}

#pragma mark - Custom methods

- (void)updateTabBarBadgeNumber
{
    UIApplication *application = [UIApplication sharedApplication];
    NSInteger count = application.applicationIconBadgeNumber;
    
    NSString *countString = count == 0 ? nil : [NSString stringWithFormat:@"%d", count];
    self.navigationController.tabBarItem.badgeValue = countString;
}

- (void)refreshUnreadNotes
{
    NoteService *noteService = [[NoteService alloc] initWithManagedObjectContext:self.resultsController.managedObjectContext];
    [noteService refreshUnreadNotes];
}

- (void)updateLastSeenTime
{
    // get the most recent note
    Note *note = [self.resultsController.fetchedObjects firstObject];
    if (note) {
        NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
        AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
        WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
        [[defaultAccount restApi] updateNoteLastSeenTime:note.timestamp success:nil failure:nil];
    }
}

- (void)pruneOldNotes
{
    NSNumber *pruneBefore;
    Note *lastVisibleNote = [[[self.tableView visibleCells] lastObject] contentProvider];
    if (lastVisibleNote) {
        pruneBefore = lastVisibleNote.timestamp;
    }

    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    if (selectedIndexPath) {
        Note *selectedNote = [self.resultsController objectAtIndexPath:selectedIndexPath];
        if (selectedNote) {
            // NSOrderedSame could mean either same timestamp, or lastVisibleNote is nil
            // so we overwrite the value
            if ([pruneBefore compare:selectedNote.timestamp] != NSOrderedAscending) {
                pruneBefore = selectedNote.timestamp;
            }
        }
    }

    NoteService *noteService = [[NoteService alloc] initWithManagedObjectContext:self.resultsController.managedObjectContext];
    [noteService pruneOldNotesBefore:pruneBefore];
}

- (void)showNotificationSettings {
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

#pragma mark - Public methods

- (void)clearNotificationsBadgeAndSyncItems
{
    if (![self isSyncing]) {
        [self syncItems];
    }
    [self refreshUnreadNotes];
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

        _isPushingViewController = YES;
        
        if ([note isComment]) {
            NotificationsCommentDetailViewController *commentDetailViewController = [[NotificationsCommentDetailViewController alloc] initWithNote:note];
            [self.navigationController pushViewController:commentDetailViewController animated:YES];
        } else if ([note isMatcher] && [note metaPostID] && [note metaSiteID]) {
            [self loadPostWithId:[note metaPostID] fromSite:[note metaSiteID] block:^(BOOL success, ReaderPost *post) {
                if (!success) {
                    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
                    return;
                }
                
                ReaderPostDetailViewController *controller = [[ReaderPostDetailViewController alloc] initWithPost:post avatarImageURL:note.avatarURLForDisplay];
                [self.navigationController pushViewController:controller animated:YES];
            }];
        } else if ([note templateType] == WPNoteTemplateMultiLineList || [note templateType] == WPNoteTemplateSingleLineList) {
            NotificationsFollowDetailViewController *detailViewController = [[NotificationsFollowDetailViewController alloc] initWithNote:note];
            [self.navigationController pushViewController:detailViewController animated:YES];
        } else if ([note templateType] == WPNoteTemplateBigBadge) {
            NotificationsBigBadgeViewController *bigBadgeViewController = [[NotificationsBigBadgeViewController alloc] initWithNote: note];
            [self.navigationController pushViewController:bigBadgeViewController animated:YES];
        }
    } else {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    
    if(note.isUnread) {
        note.unread = @(0);
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];

        if (hasDetailView) {
            [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
        
        NoteService *noteService = [[NoteService alloc] initWithManagedObjectContext:note.managedObjectContext];
        [noteService markNoteAsRead:note
                            success:nil
                            failure:^(NSError *error) {
                                note.unread = @(1);
                            }
         ];
    }
}

- (BOOL)noteHasDetailView:(Note *)note {
    if ([note isComment])
        return YES;
    
    if ([note templateType] != WPNoteTemplateUnknown)
        return YES;
    
    return NO;
}

- (void)loadPostWithId:(NSNumber *)postID fromSite:(NSNumber *)siteID block:(NotificationsLoadPostBlock)block
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
    ReaderPostService *service = [[ReaderPostService alloc] initWithManagedObjectContext:context];
    [service fetchPost:[postID integerValue] forSite:[siteID integerValue] success:^(ReaderPost *post) {
        block(YES, post);
    } failure:^(NSError *error) {
        DDLogError(@"[RestAPI] %@", error);
        block(NO, nil);
    }];

}

#pragma mark - WPTableViewController subclass methods

- (NSString *)entityName
{
    return @"Note";
}

- (NSDate *)lastSyncDate
{
    // Force sync everytime: this app becomes visible + becomes active!
    return [NSDate distantPast];
}

- (NSFetchRequest *)fetchRequest
{
    NSFetchRequest *fetchRequest    = [NSFetchRequest fetchRequestWithEntityName:@"Note"];
    fetchRequest.sortDescriptors    = @[ [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO] ];
    fetchRequest.fetchBatchSize     = 10;
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

- (BOOL)userCanRefresh
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

    return defaultAccount != nil;
}

- (void)syncItemsViaUserInteraction:(BOOL)userInteraction success:(void (^)())success failure:(void (^)(NSError *error))failure
{
    if (userInteraction) {
        [self pruneOldNotes];
    }
    
    Note *note = [[self.resultsController fetchedObjects] firstObject];
    NSNumber *timestamp = note.timestamp ?: nil;
    
    NoteService *noteService = [[NoteService alloc] initWithManagedObjectContext:self.resultsController.managedObjectContext];
    [noteService fetchNotificationsSince:timestamp success:^{
        [UIApplication sharedApplication].applicationIconBadgeNumber = 0;

        [self updateLastSeenTime];
        if (success) {
            success();
        }
    } failure:failure];
}

- (BOOL)hasMoreContent
{
    return YES;
}

- (BOOL)isSyncing
{
    return _retrievingNotifications;
}

- (void)setSyncing:(BOOL)value
{
    _retrievingNotifications = value;
}

- (void)loadMoreWithSuccess:(void (^)())success failure:(void (^)(NSError *))failure
{
    Note *lastNote = [self.resultsController.fetchedObjects lastObject];
    if (lastNote == nil) {
        return;
    }
    
    _retrievingNotifications = YES;
    
    NoteService *noteService = [[NoteService alloc] initWithManagedObjectContext:self.resultsController.managedObjectContext];
    [noteService fetchNotificationsBefore:lastNote.timestamp success:^{
        _retrievingNotifications = NO;
        if (success) {
            success();
        }
    } failure:^(NSError *error) {
        _retrievingNotifications = NO;
        if (failure) {
            failure(error);
        }
    }];
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
