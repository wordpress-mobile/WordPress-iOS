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

NSString *const NotificationsTableViewNoteCellIdentifier = @"NotificationsTableViewCell";

@interface NotificationsViewController () <WPComOAuthDelegate, EGORefreshTableHeaderDelegate, NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) id authListener;
@property (nonatomic, strong) WordPressComApi *user;
@property (nonatomic, strong) EGORefreshTableHeaderView *refreshHeaderView;
@property (nonatomic, strong) NSMutableArray *notes;
@property (readwrite, nonatomic, strong) NSDate *lastRefreshDate;
@property (readwrite, getter = isRefreshing) BOOL refreshing;
@property (readwrite, getter = isLoading) BOOL loading;
@property (nonatomic, strong) NSFetchedResultsController *notesFetchedResultsController;

@end

@implementation NotificationsViewController


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

    // -[UITableView registerClass:forCellReuseIdentifier:] available in iOS 6.0 and later
    if ([self.tableView respondsToSelector:@selector(registerClass:forCellReuseIdentifier:)]) {
        [self.tableView registerClass:[NotificationsTableViewCell class] forCellReuseIdentifier:NotificationsTableViewNoteCellIdentifier];
    }
    
    CGRect refreshFrame = self.tableView.bounds;
    refreshFrame.origin.y = -refreshFrame.size.height;
    self.refreshHeaderView = [[EGORefreshTableHeaderView alloc] initWithFrame:refreshFrame];
    self.refreshHeaderView.delegate = self;

    [self.tableView addSubview:self.refreshHeaderView];
    self.tableView.delegate = self; // UIScrollView methods
    self.tableView.backgroundColor = TABLE_VIEW_BACKGROUND_COLOR;
    
    // If we don't have a valid auth token we need to intitiate Oauth, this listens for invalid tokens
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(displayOauthController:)
                                                 name:WordPressComApiNeedsAuthTokenNotification
                                               object:self.user];
    
    if (activityFooter == nil) {
        CGRect rect = CGRectMake(145.0, 10.0, 30.0, 30.0);
        activityFooter = [[UIActivityIndicatorView alloc] initWithFrame:rect];
        activityFooter.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        activityFooter.hidesWhenStopped = YES;
        activityFooter.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [activityFooter stopAnimating];
    }
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 50.0)];
    footerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [footerView addSubview:activityFooter];
    self.tableView.tableFooterView = footerView;
    
    [self reloadNotes];
}

- (void)viewDidAppear:(BOOL)animated {
    [self refreshNotifications];
    [self refreshVisibleUnreadNotes];
}

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


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Notification loading

/*
 * Load notes from local coredata store
 */
- (void)reloadNotes {
    self.notesFetchedResultsController = nil;
    NSError *error;
    if(![self.notesFetchedResultsController performFetch:&error]){
        NSLog(@"Failed fetch request: %@", error);
    }
    [self.tableView reloadData];
}

/*
 * Ask the user to check for new notifications
 * TODO: handle failure
 */
- (void)refreshNotifications {
    if (self.isRefreshing) {
        return;
    }
    
    [self notificationsWillRefresh];
    self.refreshing = YES;
    Note *note;
    NSNumber *timestamp;
    if ([self.notesFetchedResultsController.fetchedObjects count] > 0) {
        note = [self.notesFetchedResultsController.fetchedObjects objectAtIndex:0];
        timestamp = note.timestamp;
    } else {
        timestamp = nil;
    }
    [self.user getNotificationsSince:timestamp success:^(AFHTTPRequestOperation *operation, id responseObject) {
        self.lastRefreshDate = [NSDate new];
        self.refreshing = NO;
        [self notificationsDidFinishRefreshingWithError:nil];
        [self reloadNotes];
        [self updateLastSeenTime];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        self.refreshing = NO;
        [self notificationsDidFinishRefreshingWithError:error];
    }];
}

/*
 * For loading of additional notifications
 */
- (void)loadNotificationsAfterNote:(Note *)note {
    if (note == nil) {
        return;
    }
    self.loading = YES;
    [self.user getNotificationsBefore:note.timestamp success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [activityFooter stopAnimating];
        self.loading = NO;
        [self reloadNotes];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [activityFooter stopAnimating];
        self.loading = NO;
    }];
}

- (void)loadNotificationsAfterLastNote {
    [self loadNotificationsAfterNote:[self.notesFetchedResultsController.fetchedObjects lastObject]];
}

- (void)refreshVisibleUnreadNotes {
    
    // figure out which notifications are
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

- (void)updateLastSeenTime {
    // get the most recent note
    NSArray *notes = self.notesFetchedResultsController.fetchedObjects;
    if ([notes count] > 0) {
        Note *note = [notes objectAtIndex:0];
        [self.user updateNoteLastSeenTime:note.timestamp success:nil failure:nil];
    }
    
}

- (void)refreshFromPushNotification {
    [self refreshNotifications];
    [self refreshVisibleUnreadNotes];
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    [self.refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    [self.refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
    if (decelerate == NO) {
        [self refreshVisibleUnreadNotes];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self refreshVisibleUnreadNotes];
}

- (void)notificationsDidFinishRefreshingWithError:(NSError *)error {
    [self.refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
    [self.tableView reloadData];
}

/*
 * TODO: If refresh not initiated by Pull-To-Refresh then simulate it
 */
- (void)notificationsWillRefresh {
}

#pragma mark - EGORefreshTableHeaderDelegate

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView *)view {
    return self.isRefreshing;
}

- (NSDate *)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView *)view {
    return self.lastRefreshDate;
}

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView *)view {
    //delete all notes
    NSManagedObjectContext *context = [[WordPressAppDelegate sharedWordPressApplicationDelegate] managedObjectContext];
    NSFetchRequest *allNotes = [[NSFetchRequest alloc] init];
    [allNotes setEntity:[NSEntityDescription entityForName:@"Note" inManagedObjectContext:context]];
    [allNotes setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    
    NSError *error = nil;
    NSArray *notes = [context executeFetchRequest:allNotes error:&error];
    for (NSManagedObject *note in notes) {
        [context deleteObject:note];
    }
    [self reloadNotes];
    [self refreshNotifications];
}

#pragma mark - UITableViewDataSource

/*
 * Number of rows is equal to number of notes
 */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.notesFetchedResultsController.fetchedObjects count];
}

/*
 * Dequeue a cell and have it render the note
 */
-  (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *cellIdentifier = @"NotificationCell";
    NotificationsTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    // In iOS 6.0 and later, -[UITableViewCell dequeueReusableCellWithIdentifier:] always returns a valid cell
    // since we registered the class
    //
    // The following initialisation is only needed for iOS 5
    if (cell == nil) {
        cell = [[NotificationsTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }

    cell.note = [self.notesFetchedResultsController.fetchedObjects objectAtIndex:indexPath.row];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // Are we approaching the end of the table?
    if ((indexPath.section + 1 == [self numberOfSectionsInTableView:tableView]) && (indexPath.row + 4 >= [self tableView:tableView numberOfRowsInSection:indexPath.section]) && [self tableView:tableView numberOfRowsInSection:indexPath.section] > 9) {
        // Only 3 rows till the end of table
        if (!self.loading) {
            [activityFooter startAnimating];
            [self loadNotificationsAfterLastNote];
        }
    }
}


/*
 * Comments are taller to show comment text
 * TODO: calculate the height of the comment text area by using sizeWithFont:forWidth:lineBreakMode:
 */
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    Note *note = [self.notesFetchedResultsController.fetchedObjects objectAtIndex:indexPath.row];
    return [note.type isEqualToString:@"comment"] ? 100.f : 63.f;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Note *note = [self.notesFetchedResultsController.fetchedObjects objectAtIndex:indexPath.row];
    if ([self noteHasDetailView:note]) {
        if ([note isComment]) {
            NotificationsCommentDetailViewController *detailViewController = [[NotificationsCommentDetailViewController alloc] initWithNibName:@"NotificationsCommentDetailViewController" bundle:nil];
            detailViewController.note = note;
            detailViewController.user = self.user;
            NSLog(@"Pushing comment");
            [self.panelNavigationController pushViewController:detailViewController animated:YES];
        } else {
            NotificationsFollowDetailViewController *detailViewController = [[NotificationsFollowDetailViewController alloc] initWithNibName:@"NotificationsFollowDetailViewController" bundle:nil];
            detailViewController.note = note;
            [self.panelNavigationController pushViewController:detailViewController animated:YES];
        }
    } else {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    if(note.isUnread) {
        note.unread = [NSNumber numberWithInt:0];
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

#pragma mark - NSFetchedResultsController

- (NSFetchedResultsController *)notesFetchedResultsController {
    if (_notesFetchedResultsController == nil) {
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Note"];
        NSSortDescriptor *dateSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO];
        fetchRequest.sortDescriptors = @[ dateSortDescriptor ];
        NSManagedObjectContext *context = [[WordPressAppDelegate sharedWordPressApplicationDelegate] managedObjectContext];
        self.notesFetchedResultsController = [[NSFetchedResultsController alloc]
                                              initWithFetchRequest:fetchRequest
                                              managedObjectContext:context
                                              sectionNameKeyPath:nil
                                              cacheName:nil];
        
        self.notesFetchedResultsController.delegate = self;
    }
    return _notesFetchedResultsController;
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    
    if (type == NSFetchedResultsChangeUpdate) {
        NotificationsTableViewCell *cell = (NotificationsTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        cell.note = anObject;
    }

}




@end
