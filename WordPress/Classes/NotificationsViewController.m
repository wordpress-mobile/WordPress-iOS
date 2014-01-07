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

NSString * const NotificationsLastSyncDateKey = @"NotificationsLastSyncDate";
NSString * const NotificationsJetpackInformationURL = @"http://jetpack.me/about/";

@interface NotificationsViewController () {
    BOOL _retrievingNotifications;
    BOOL _viewHasAppeared;
}

@property (nonatomic, strong) id authListener;
@property (nonatomic, assign) BOOL isPushingViewController;

@end


@implementation NotificationsViewController

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
}

- (void)viewDidLoad
{
    DDLogMethod();
    [super viewDidLoad];
    
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    
    self.infiniteScrollEnabled = YES;
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

    [self syncItems];
    [self refreshUnreadNotes];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (!_isPushingViewController)
        [self pruneOldNotes];
}


#pragma mark - Custom methods

- (void)refreshUnreadNotes {
    [Note refreshUnreadNotesWithContext:self.resultsController.managedObjectContext];
}

- (void)updateSyncDate {
    // get the most recent note
    NSArray *notes = self.resultsController.fetchedObjects;
    if ([notes count] > 0) {
        Note *note = [notes objectAtIndex:0];
        [[[WPAccount defaultWordPressComAccount] restApi] updateNoteLastSeenTime:note.timestamp success:nil failure:nil];
    }

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSDate date] forKey:NotificationsLastSyncDateKey];
    [defaults synchronize];
}

- (void)pruneOldNotes {
    NSNumber *pruneBefore;
    Note *lastVisibleNote = [[[self.tableView visibleCells] lastObject] note];
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
    [Note pruneOldNotesBefore:pruneBefore withContext:self.resultsController.managedObjectContext];
}

#pragma mark - Public methods

- (void)refreshFromPushNotification {
    if (IS_IPHONE)
        [self.navigationController popToRootViewControllerAnimated:YES];
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
    if (![self isSyncing]) {
        [self syncItems];
    }
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    Note *note = [self.resultsController objectAtIndexPath:indexPath];
    return [NewNotificationsTableViewCell rowHeightForNotification:note andMaxWidth:CGRectGetWidth(tableView.bounds)];
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
    } else {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    if(note.isUnread) {
        note.unread = [NSNumber numberWithInt:0];
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];

        if(hasDetailsView) {
            [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
        
        [note markAsReadWithSuccess:nil failure:^(NSError *error){
            note.unread = [NSNumber numberWithInt:1];
        }];
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

- (NSString *)entityName {
    return @"Note";
}

- (NSDate *)lastSyncDate {
    return [[NSUserDefaults standardUserDefaults] objectForKey:NotificationsLastSyncDateKey];
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
    cell.note = [self.resultsController objectAtIndexPath:indexPath];
}

- (BOOL)userCanRefresh {
    return [WPAccount defaultWordPressComAccount] != nil;
}

- (void)syncItemsViaUserInteraction:(BOOL)userInteraction success:(void (^)())success failure:(void (^)(NSError *error))failure {
    if (userInteraction) {
        [self pruneOldNotes];
    }
    
    NSNumber *timestamp;
    NSArray *notes = [self.resultsController fetchedObjects];
    if (userInteraction == NO && [notes count] > 0) {
        Note *note = [notes objectAtIndex:0];
        timestamp = note.timestamp;
    } else {
        timestamp = nil;
    }
    
    [Note fetchNotificationsSince:timestamp success:^{
        [self updateSyncDate];
        if (success) {
            success();
        }
    } failure:failure];
}

- (BOOL)hasMoreContent {
    return YES;
}

- (BOOL)isSyncing
{
    return _retrievingNotifications;
}

- (void)syncItems
{
    // Check to see if there is a WordPress.com account before attempting to fetch notifications
    if ([WPAccount defaultWordPressComAccount]) {
        [super syncItems];
    }
}

- (void)loadMoreWithSuccess:(void (^)())success failure:(void (^)(NSError *))failure {
    Note *lastNote = [self.resultsController.fetchedObjects lastObject];
    if (lastNote == nil) {
        return;
    }
    
    _retrievingNotifications = YES;
    
    [Note fetchNotificationsBefore:lastNote.timestamp success:^{
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
