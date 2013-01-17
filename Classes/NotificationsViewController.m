//
//  NotificationsViewController.m
//  WordPress
//
//  Created by Beau Collins on 11/05/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "NotificationsViewController.h"
#import "WPComOAuthController.h"
#import "WordPressComApi.h"
#import "EGORefreshTableHeaderView.h"
#import "NotificationsTableViewCell.h"

NSString *const NotificationsTableViewNoteCellIdentifier = @"NotificationsTableViewCell";

@interface NotificationsViewController () <WPComOAuthDelegate, EGORefreshTableHeaderDelegate>

@property (nonatomic, strong) id authListener;
@property (nonatomic, strong) WordPressComApi *user;
@property (nonatomic, strong) EGORefreshTableHeaderView *refreshHeaderView;
@property (nonatomic, strong) NSMutableArray *notes;
@property (readwrite, nonatomic, strong) NSDate *lastRefreshDate;
@property (readwrite, getter = isRefreshing) BOOL refreshing;

@end

@implementation NotificationsViewController

+ (void)registerTableViewCells:(UITableView *)tableView {
    [tableView registerClass:[NotificationsTableViewCell class] forCellReuseIdentifier:NotificationsTableViewNoteCellIdentifier];
}


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
    self.title = nil;
    self.user = nil;
}

- (void)viewDidLoad
{
    [[self class] registerTableViewCells:self.tableView];
    
    CGRect refreshFrame = self.tableView.bounds;
    refreshFrame.origin.y = -refreshFrame.size.height;
    self.refreshHeaderView = [[EGORefreshTableHeaderView alloc] initWithFrame:refreshFrame];
    self.refreshHeaderView.delegate = self;
    NSLog(@"Refresh header view delegate: %@", self.refreshHeaderView.delegate);
    [self.tableView addSubview:self.refreshHeaderView];
    self.tableView.delegate = self; // UIScrollView methods
    
    // If we don't have a valid auth token we need to intitiate Oauth, this listens for invalid tokens
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(displayOauthController:)
                                                 name:WordPressComApiNeedsAuthTokenNotification
                                               object:self.user];
    [super viewDidLoad];
    
    [self refreshNotifications];
}

- (void)displayOauthController:(NSNotification *)note {
    
    [WPComOAuthController presentWithClientId:[WordPressComApi WordPressAppId]
                                  redirectUrl:@"wpios://oauth/connect"
                                 clientSecret:[WordPressComApi WordPressAppSecret]
                                     delegate:self];
}

- (void)controller:(WPComOAuthController *)controller didAuthenticateWithToken:(NSString *)token blog:(NSString *)blogUrl {
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
 * Ask the user to check for new notifications
 * TODO: handle failure
 */
- (void)refreshNotifications {
    if (self.isRefreshing) {
        return;
    }
    [self notificationsWillRefresh];
    self.refreshing = YES;
    [self.user checkNotificationsSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        self.lastRefreshDate = [NSDate new];
        NSArray *noteData = (NSArray *)[responseObject objectForKey:@"notes"];
        NSMutableArray *newNotes = [[NSMutableArray alloc] initWithCapacity:[noteData count]];
        [noteData enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            Note *note = [[Note alloc] initWithNoteData:(NSDictionary*)obj];
            [newNotes addObject:note];
        }];
        self.notes = newNotes;
        self.refreshing = NO;
        [self notificationsDidFinishRefreshingWithError:nil];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        self.refreshing = NO;
        [self notificationsDidFinishRefreshingWithError:error];
    }];
}

/*
 * For loading of additional notifications
 */
- (void)loadNotificationsAfterNote:(id)note {
    [self.user getNotificationsBefore:[note objectForKey:@"timestamp"] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
    }];
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    [self.refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    [self.refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
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
    [self refreshNotifications];
}

#pragma mark - UITableViewDataSource

/*
 * Number of rows is equal to number of notes
 */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.notes count];
}

/*
 * Dequeue a cell and have it render the note
 */
-  (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NotificationsTableViewCell *cell = (NotificationsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:NotificationsTableViewNoteCellIdentifier];
    cell.note = [self.notes objectAtIndex:indexPath.row];
    return cell;
}

#pragma mark - UITableViewDelegate

/*
 * Comments are taller to show comment text
 * TODO: calculate the height of the comment text area by using sizeWithFont:forWidth:lineBreakMode:
 */
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    Note *note = [self.notes objectAtIndex:indexPath.row];
    return [note.type isEqualToString:@"comment"] ? 110.f : 63.f;
    
}





@end
