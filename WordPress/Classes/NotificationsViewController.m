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
#import "NotificationSettingsViewController.h"

NSString * const NotificationsTableViewNoteCellIdentifier = @"NotificationsTableViewCell";
NSString * const NotificationsLastSyncDateKey = @"NotificationsLastSyncDate";

@interface NotificationsViewController ()

@property (nonatomic, strong) id authListener;
@property (nonatomic, strong) WordPressComApi *user;
@property (nonatomic, assign) BOOL isPushingViewController;

- (void)showNotificationsSettings;

@end


@implementation NotificationsViewController

@synthesize settingsButton;

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
    self.panelNavigationController.delegate = self;
    self.infiniteScrollEnabled = YES;
    // -[UITableView registerClass:forCellReuseIdentifier:] available in iOS 6.0 and later
    if ([self.tableView respondsToSelector:@selector(registerClass:forCellReuseIdentifier:)]) {
        [self.tableView registerClass:[NotificationsTableViewCell class] forCellReuseIdentifier:NotificationsTableViewNoteCellIdentifier];
    }
    
   /*
    if(IS_IPHONE) {
        if ([[UIButton class] respondsToSelector:@selector(appearance)]) {
            
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            [btn setImage:[UIImage imageNamed:@"settings.png"] forState:UIControlStateNormal];
            [btn setImage:[UIImage imageNamed:@"settings.png"] forState:UIControlStateHighlighted];
            
            UIImage *backgroundImage = [[UIImage imageNamed:@"navbar_button_bg"] stretchableImageWithLeftCapWidth:4 topCapHeight:0];
            [btn setBackgroundImage:backgroundImage forState:UIControlStateNormal];
            
            backgroundImage = [[UIImage imageNamed:@"navbar_button_bg_active"] stretchableImageWithLeftCapWidth:4 topCapHeight:0];
            [btn setBackgroundImage:backgroundImage forState:UIControlStateHighlighted];
            
            btn.frame = CGRectMake(0.0f, 0.0f, 44.0f, 30.0f);
            
            [btn addTarget:self action:@selector(showNotificationsSettings) forControlEvents:UIControlEventTouchUpInside];
            self.settingsButton = [[UIBarButtonItem alloc] initWithCustomView:btn];
        } else {
            self.settingsButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                                target:self
                                                                                action:@selector(showNotificationsSettings)];
        }
    } else {
        //iPad
        self.settingsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settings.png"]
                                                               style:UIBarButtonItemStylePlain
                                                              target:self
                                                              action:@selector(showNotificationsSettings)];
    }
    
    [self.settingsButton setAccessibilityLabel:NSLocalizedString(@"Settings", @"")];
    
    if ([self.settingsButton respondsToSelector:@selector(setTintColor:)]) {
        UIColor *color = [UIColor UIColorFromHex:0x464646];
        self.settingsButton.tintColor = color;
    }
    
    if (IS_IPHONE) {
       self.navigationItem.rightBarButtonItem = self.settingsButton;
    } else {
        self.toolbarItems = [NSArray arrayWithObjects: self.settingsButton , nil];
    }
    */
}

- (void)viewWillAppear:(BOOL)animated {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewWillAppear:animated];
    if (IS_IPAD)
        [self.panelNavigationController setToolbarHidden:NO forViewController:self animated:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _isPushingViewController = NO;
    // If table is at the top, simulate a pull to refresh
    BOOL simulatePullToRefresh = (self.tableView.contentOffset.y == 0);
    [self syncItemsWithUserInteraction:simulatePullToRefresh];
    [self refreshVisibleUnreadNotes];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (!_isPushingViewController)
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


- (void)showNotificationsSettings {
    
    NotificationSettingsViewController *notificationSettingsViewController = [[NotificationSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    
    if (IS_IPAD) {
        notificationSettingsViewController.showCloseButton = YES;
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:notificationSettingsViewController];
        
        nav.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
		nav.modalPresentationStyle = UIModalPresentationFormSheet;
      
        [self presentModalViewController:nav animated:YES];
    } else {
        [self.panelNavigationController pushViewController:notificationSettingsViewController fromViewController:self animated:YES];
    }
}

#pragma mark - Public methods

- (void)refreshFromPushNotification {
    if (IS_IPHONE)
        [self.panelNavigationController popToRootViewControllerAnimated:YES];
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
    [self syncItemsWithUserInteraction:NO];
    [self refreshVisibleUnreadNotes];
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

    if([note.isLoading intValue] == 1) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    
    BOOL hasDetailsView = [self noteHasDetailView:note];
    if (hasDetailsView) {
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

        if(hasDetailsView)
            [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        
        [self.user markNoteAsRead:note.noteID success:^(AFHTTPRequestOperation *operation, id responseObject) {
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            note.unread = [NSNumber numberWithInt:1];
        }];
    }
}

- (BOOL)noteHasDetailView:(Note *)note {
   
    if([note.isLoading intValue] == 1) {
        return NO;
    }
    
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
    
    if([cell.note.isLoading intValue] == 1) {
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc]
                                             initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        spinner.frame = CGRectMake(0, 0, 16, 16);
        cell.accessoryView = spinner;
        [spinner startAnimating];        
    } else {
        cell.accessoryView = nil;
        cell.accessoryType = [self noteHasDetailView:cell.note] ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;        
    }
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

#pragma mark - DetailViewDelegate

- (void)resetView {
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    if (selectedIndexPath) {
        [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:NO];
    }
}

@end
