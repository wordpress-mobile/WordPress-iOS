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
#import "WPComOAuthController.h"
#import "WordPressComApi.h"
#import "EGORefreshTableHeaderView.h"
#import "NotificationsTableViewCell.h"
#import "WPTableViewControllerSubclass.h"

NSString * const NotificationsTableViewNoteCellIdentifier = @"NotificationsTableViewCell";
NSString * const NotificationsLastSyncDateKey = @"NotificationsLastSyncDate";

@interface NotificationsViewController () <WPComOAuthDelegate>

@property (nonatomic, strong) id authListener;
@property (nonatomic, strong) WordPressComApi *user;

@end

@implementation NotificationsViewController

#pragma mark - View Lifecycle methods

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = NSLocalizedString(@"Notifications", @"Notifications View Controller title");
        self.user = [WordPressComApi sharedApi];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidLoad];

    self.infiniteScrollEnabled = YES;
    // -[UITableView registerClass:forCellReuseIdentifier:] available in iOS 6.0 and later
    if ([self.tableView respondsToSelector:@selector(registerClass:forCellReuseIdentifier:)]) {
        [self.tableView registerClass:[NotificationsTableViewCell class] forCellReuseIdentifier:NotificationsTableViewNoteCellIdentifier];
    }

    // If we don't have a valid auth token we need to intitiate Oauth, this listens for invalid tokens
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(displayOauthController:)
                                                 name:WordPressComApiNeedsAuthTokenNotification
                                               object:self.user];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // If table is at the top, simulate a pull to refresh
    BOOL simulatePullToRefresh = (self.tableView.contentOffset.y == 0);
    [self syncItemsWithUserInteraction:simulatePullToRefresh];
    [self refreshVisibleUnreadNotes];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self pruneOldNotes];
}

#pragma mark - Custom methods

- (void)refreshVisibleUnreadNotes {
    // figure out which notifications are visible
    NSArray *cells = [self.tableView visibleCells];
    NSMutableArray *notes = [NSMutableArray arrayWithCapacity:[cells count]];
    [cells enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        Note *note = [(NotificationsTableViewCell *)obj note];
        if ([note isUnread]) {
            [notes addObject:note];
        }
    }];

    [self.user refreshNotifications:notes success:^(AFHTTPRequestOperation *operation, id responseObject) {
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    }];
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
    [self syncItemsWithUserInteraction:NO];
    [self refreshVisibleUnreadNotes];
}

#pragma mark - OAuth controller delegate

- (void)displayOauthController:(NSNotification *)note {
    
    [WPComOAuthController presentWithClientId:[WordPressComApi WordPressAppId]
                                  redirectUrl:@"http://wordpress.com/"
                                 clientSecret:[WordPressComApi WordPressAppSecret]
                                       blogId:@"0"
                                        scope:@"global"
                                     delegate:self];
}

- (void)controller:(WPComOAuthController *)controller didAuthenticateWithToken:(NSString *)token blog:(NSString *)blogUrl scope:(NSString *)scope {
    // give the user the new auth token
    self.user.authToken = token;
    
}

- (void)controllerDidCancel:(WPComOAuthController *)controller {
    // let's not keep looping, they obviously didn't want to authorize for some reason
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // TODO: Show a message that they need to authorize to see the notifications
}

#pragma mark - UITableViewDelegate

/*
 * Comments are taller to show comment text
 * TODO: calculate the height of the comment text area by using sizeWithFont:forWidth:lineBreakMode:
 */
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    Note *note = [self.resultsController objectAtIndexPath:indexPath];
    return [note.type isEqualToString:@"comment"] ? 100.f : 63.f;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Note *note = [self.resultsController objectAtIndexPath:indexPath];
    if ([self noteHasDetailView:note]) {
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
        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        [self.user markNoteAsRead:note success:^(AFHTTPRequestOperation *operation, id responseObject) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"WordPressComUpdateNoteCount"
                                                                object:nil
                                                              userInfo:nil];
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
    fetchRequest.sortDescriptors = @[ dateSortDescriptor ];
    return fetchRequest;
}

- (UITableViewCell *)newCell {
    NotificationsTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:NotificationsTableViewNoteCellIdentifier];

    // In iOS 6.0 and later, -[UITableViewCell dequeueReusableCellWithIdentifier:] always returns a valid cell
    // since we registered the class
    //
    // The following initialisation is only needed for iOS 5
    if (cell == nil) {
        cell = [[NotificationsTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:NotificationsTableViewNoteCellIdentifier];
    }
    return cell;
}

- (void)configureCell:(NotificationsTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    cell.note = [self.resultsController objectAtIndexPath:indexPath];
    cell.accessoryType = [self noteHasDetailView:cell.note] ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
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

- (void)loadMoreWithSuccess:(void (^)())success failure:(void (^)(NSError *))failure {
    Note *lastNote = [self.resultsController.fetchedObjects lastObject];
    if (lastNote == nil) {
        return;
    }

    [self.user getNotificationsBefore:lastNote.timestamp success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success();
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

@end
