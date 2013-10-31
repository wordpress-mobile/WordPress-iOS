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

NSString * const NotificationsTableViewNoteCellIdentifier = @"NotificationsTableViewCell";
NSString * const NotificationsLastSyncDateKey = @"NotificationsLastSyncDate";

@interface NotificationsViewController () {
    BOOL _retrievingNotifications;
    BOOL _viewHasAppeared;
}

@property (nonatomic, strong) id authListener;
@property (nonatomic, strong) WordPressComApi *user;
@property (nonatomic, assign) BOOL isPushingViewController;

@end


@implementation NotificationsViewController

- (id)init {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"Notifications", @"Notifications View Controller title");
        self.user = [WordPressComApi sharedApi];
    }
    return self;
}

- (NSString *)noResultsText
{
    return NSLocalizedString(@"No notifications yet", @"Displayed when the user pulls up the notifications view and they have no items");
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    WPFLogMethod();
    [super viewDidLoad];
    
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    
    self.panelNavigationController.delegate = self;
    self.infiniteScrollEnabled = YES;
    [self.tableView registerClass:[NewNotificationsTableViewCell class] forCellReuseIdentifier:NotificationsTableViewNoteCellIdentifier];
}

- (void)viewWillAppear:(BOOL)animated {
    WPFLogMethod();
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if (!_viewHasAppeared) {
        _viewHasAppeared = YES;
        [WPMobileStats incrementProperty:StatsPropertyNotificationsOpened forEvent:StatsEventAppClosed];
    }
    
    _isPushingViewController = NO;
    // If table is at the top, simulate a pull to refresh
    BOOL simulatePullToRefresh = (self.tableView.contentOffset.y == 0);
    [self syncItemsWithUserInteraction:simulatePullToRefresh];
    [self refreshUnreadNotes];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (!_isPushingViewController)
        [self pruneOldNotes];
}

- (UIColor *)backgroundColorForRefreshHeaderView
{
    return [WPStyleGuide itsEverywhereGrey];
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
        [self.user updateNoteLastSeenTime:note.timestamp success:nil failure:nil];
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
        [self.panelNavigationController popToRootViewControllerAnimated:YES];
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
    if (![self isSyncing]) {
        [self syncItemsWithUserInteraction:NO];
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
            NotificationsCommentDetailViewController *detailViewController = [[NotificationsCommentDetailViewController alloc] initWithNibName:@"NotificationsCommentDetailViewController" bundle:nil];
            detailViewController.note = note;
            detailViewController.user = self.user;
            [self.panelNavigationController pushViewController:detailViewController fromViewController:self animated:YES];
        } else {
            NotificationsFollowDetailViewController *detailViewController = [[NotificationsFollowDetailViewController alloc] initWithNibName:@"NotificationsFollowDetailViewController" bundle:nil];
            detailViewController.note = note;
            [self.panelNavigationController pushViewController:detailViewController fromViewController:self animated:YES];
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
        
        [self.user markNoteAsRead:note.noteID success:^(AFHTTPRequestOperation *operation, id responseObject) {
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            note.unread = [NSNumber numberWithInt:1];
        }];
    }
}

- (BOOL)noteHasDetailView:(Note *)note {
    
    if ([note isComment])
        return YES;
    
    NSDictionary *noteBody = [[note getNoteData] objectForKey:@"body"];
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

- (UITableViewCell *)newCell {
    NewNotificationsTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:NotificationsTableViewNoteCellIdentifier];

    if (cell == nil) {
        cell = [[NewNotificationsTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:NotificationsTableViewNoteCellIdentifier];
    }
    
    return cell;
}

- (void)configureCell:(NewNotificationsTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    cell.note = [self.resultsController objectAtIndexPath:indexPath];
}

- (void)syncItemsWithUserInteraction:(BOOL)userInteraction success:(void (^)())success failure:(void (^)(NSError *error))failure {
    if (userInteraction) {
        [self pruneOldNotes];
    }
    NSNumber *timestamp;
    NSArray *notes = [self.resultsController fetchedObjects];
    if ([notes count] > 0) {
        Note *note = [notes objectAtIndex:0];
        timestamp = note.timestamp;
    } else {
        timestamp = nil;
    }
    [self.user getNotificationsSince:timestamp success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self updateSyncDate];
        if (success) {
            success();
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (BOOL)hasMoreContent {
    return YES;
}

- (BOOL)isSyncing
{
    return _retrievingNotifications;
}

- (void)loadMoreWithSuccess:(void (^)())success failure:(void (^)(NSError *))failure {
    Note *lastNote = [self.resultsController.fetchedObjects lastObject];
    if (lastNote == nil) {
        return;
    }
    
    _retrievingNotifications = YES;
    
    [self.user getNotificationsBefore:lastNote.timestamp success:^(AFHTTPRequestOperation *operation, id responseObject) {
        _retrievingNotifications = NO;
                
        if (success) {
            success();
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
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
