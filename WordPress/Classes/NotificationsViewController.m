//
//  NotificationsViewController.m
//  WordPress
//
//  Created by Beau Collins on 11/05/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

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
#import "NoteService.h"

NSString * const NotificationsJetpackInformationURL = @"http://jetpack.me/about/";

@interface NotificationsViewController () {
    BOOL _retrievingNotifications;
    BOOL _viewHasAppeared;
}

@property (nonatomic, strong) id authListener;
@property (nonatomic, assign) BOOL isPushingViewController;

@end


@implementation NotificationsViewController

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {
    // We need to override the implementation in our superclass or else restoration fails - no blog!
    UIViewController *controller = [[self alloc] init];
    return controller;
}

- (id)init {
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
    WPWebViewController *webViewController = [[WPWebViewController alloc] init];
    [webViewController setUrl:[NSURL URLWithString:NotificationsJetpackInformationURL]];
    [self.navigationController pushViewController:webViewController animated:YES];
}

- (BOOL)showJetpackConnectMessage {
    return [WPAccount defaultWordPressComAccount] == nil;
}

- (void)dealloc {
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

- (void)viewWillAppear:(BOOL)animated {
    DDLogMethod();
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if (!_viewHasAppeared) {
        _viewHasAppeared = YES;
        [WPMobileStats incrementProperty:StatsPropertyNotificationsOpened forEvent:StatsEventAppClosed];
    }
    
    _isPushingViewController = NO;
    
    // If table is at the top (i.e. freshly opened), do some extra work
    if (self.tableView.contentOffset.y == 0) {
        [self pruneOldNotes];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (!_isPushingViewController)
        [self pruneOldNotes];
}

#pragma mark - NSObject(NSKeyValueObserving) methods

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if ([keyPath isEqualToString:@"applicationIconBadgeNumber"]) {
        [self updateTabBarBadgeNumber];
    }
}

#pragma mark - Custom methods

- (void)updateTabBarBadgeNumber {
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

- (void)updateLastSeenTime {
    // get the most recent note
    Note *note = [self.resultsController.fetchedObjects firstObject];
    if (note) {
        [[[WPAccount defaultWordPressComAccount] restApi] updateNoteLastSeenTime:note.timestamp success:nil failure:nil];
    }
}

- (void)pruneOldNotes {
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
    [WPMobileStats trackEventForWPCom:StatsEventNotificationsClickedManageNotifications];
    
    NotificationSettingsViewController *notificationSettingsViewController = [[NotificationSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:notificationSettingsViewController];
    navigationController.navigationBar.translucent = NO;
    navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeNotificationSettings)];
    notificationSettingsViewController.navigationItem.rightBarButtonItem = closeButton;
    
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)closeNotificationSettings {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Public methods

- (void)clearNotificationsBadgeAndSyncItems {
    if (![self isSyncing]) {
        [self syncItems];
    }
    [self refreshUnreadNotes];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    Note *note = [self.resultsController objectAtIndexPath:indexPath];
    return [NewNotificationsTableViewCell rowHeightForContentProvider:note andWidth:WPTableViewFixedWidth];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Note *note = [self.resultsController objectAtIndexPath:indexPath];
    
    BOOL hasDetailsView = [self noteHasDetailView:note];
    if (hasDetailsView) {
        [WPMobileStats incrementProperty:StatsPropertyNotificationsOpenedDetails forEvent:StatsEventAppClosed];

        _isPushingViewController = YES;
        if ([note isComment]) {
            NotificationsCommentDetailViewController *detailViewController = [[NotificationsCommentDetailViewController alloc] initWithNote:note];
            [self.navigationController pushViewController:detailViewController animated:YES];
        } else {
            NotificationsFollowDetailViewController *detailViewController = [[NotificationsFollowDetailViewController alloc] initWithNote:note];
            [self.navigationController pushViewController:detailViewController animated:YES];
        }
    } else if ([note statsEvent]) {
        NoteService *noteService = [[NoteService alloc] initWithManagedObjectContext:note.managedObjectContext];
        Blog *blog = [noteService blogForStatsEventNote:note];
        
        if (blog) {
            [[WordPressAppDelegate sharedWordPressApplicationDelegate] showStatsForBlog:blog];
        } else {
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
    } else {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    
    if(note.isUnread) {
        note.unread = [NSNumber numberWithInt:0];
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];

        if(hasDetailsView) {
            [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
        
        NoteService *noteService = [[NoteService alloc] initWithManagedObjectContext:note.managedObjectContext];
        [noteService markNoteAsRead:note
                            success:nil
                            failure:^(NSError *error) {
                                note.unread = [NSNumber numberWithInt:1];
                            }
         ];
    }
}

- (BOOL)noteHasDetailView:(Note *)note {
    if ([note isComment])
        return YES;
    
    NSDictionary *noteBody = [[note noteData] objectForKey:@"body"];
    if (noteBody) {
        NSString *noteTemplate = [noteBody objectForKey:@"template"];
        if ([noteTemplate isEqualToString:@"single-line-list"] || [noteTemplate isEqualToString:@"multi-line-list"])
            return YES;
    }
    
    return NO;
}

#pragma mark - WPTableViewController subclass methods

- (NSString *)entityName
{
    return @"Note";
}

- (NSDate *)lastSyncDate {
    // Force sync everytime: this app becomes visible + becomes active!
    return [NSDate distantPast];
}

- (NSFetchRequest *)fetchRequest {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Note"];
    NSSortDescriptor *dateSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO];
    fetchRequest.sortDescriptors = @[dateSortDescriptor];
    fetchRequest.fetchBatchSize = 10;
    return fetchRequest;
}

- (Class)cellClass {
    return [NewNotificationsTableViewCell class];
}

- (void)configureCell:(NewNotificationsTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    cell.contentProvider = [self.resultsController objectAtIndexPath:indexPath];
    
    Note *note = [self.resultsController objectAtIndexPath:indexPath];
    BOOL hasDetailsView = [self noteHasDetailView:note];
    BOOL isStatsNote = [note statsEvent];
    
    if (!hasDetailsView && !isStatsNote) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
}

- (BOOL)userCanRefresh {
    return [WPAccount defaultWordPressComAccount] != nil;
}

- (void)syncItemsViaUserInteraction:(BOOL)userInteraction success:(void (^)())success failure:(void (^)(NSError *error))failure {
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

- (BOOL)hasMoreContent {
    return YES;
}

- (BOOL)isSyncing {
    return _retrievingNotifications;
}

- (void)setSyncing:(BOOL)value {
    _retrievingNotifications = value;
}

- (void)loadMoreWithSuccess:(void (^)())success failure:(void (^)(NSError *))failure {
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

- (void)resetView {
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    if (selectedIndexPath) {
        [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:NO];
    }
}

@end
