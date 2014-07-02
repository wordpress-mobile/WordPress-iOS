#import "NotificationsViewController.h"

#import <Simperium/Simperium.h>
#import "WordPressAppDelegate.h"
#import "ContextManager.h"
#import "Constants.h"

#import "WPTableViewControllerSubclass.h"
#import "WPWebViewController.h"
#import "Notification.h"
#import "Notification+UI.h"
#import "Meta.h"

#import "NotificationSettingsViewController.h"
#import "NoteTableViewCell.h"
#import "NotificationsManager.h"
#import "NotificationDetailsViewController.h"

#import "WPAccount.h"
#import "AccountService.h"

#import "ReaderPost.h"
#import "ReaderPostService.h"
#import "ReaderPostDetailViewController.h"

#import "Comment.h"
#import "BlogService.h"
#import "CommentViewController.h"



#pragma mark ====================================================================================
#pragma mark Private Properties
#pragma mark ====================================================================================

@interface NotificationsViewController ()

@property (nonatomic, assign) dispatch_once_t trackedViewDisplay;

typedef void (^LoadPostCompletionBlock)(BOOL success, ReaderPost *post);
- (void)loadPostWithId:(NSNumber *)postID fromSite:(NSNumber *)siteID completion:(LoadPostCompletionBlock)completion;

typedef void (^LoadCommentCompletionBlock)(BOOL success, Comment *comment);
- (void)loadCommentWithId:(NSNumber *)commentId fromSite:(NSNumber *)siteID completion:(LoadCommentCompletionBlock)completion;

@end


#pragma mark ====================================================================================
#pragma mark NotificationsViewController
#pragma mark ====================================================================================

@implementation NotificationsViewController

- (void)dealloc
{
    NSString *keyPath = NSStringFromSelector(@selector(applicationIconBadgeNumber));
    [[UIApplication sharedApplication] removeObserver:self forKeyPath:keyPath];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.title = NSLocalizedString(@"Notifications", @"Notifications View Controller title");
        
        // Watch for application badge number changes
        NSString *keyPath = NSStringFromSelector(@selector(applicationIconBadgeNumber));
        [[UIApplication sharedApplication] addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew context:nil];
    }
    
    return self;
}


#pragma mark - UIViewController Methods

- (void)viewDidLoad
{
    DDLogMethod();
    [super viewDidLoad];
    
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    
    self.infiniteScrollEnabled  = NO;
	self.refreshControl         = nil;
    
    [self updateTabBarBadgeNumber];
}

- (void)viewWillAppear:(BOOL)animated
{
    DDLogMethod();
    [super viewWillAppear:animated];
    
    [self showManageButtonIfNeeded];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    dispatch_once(&_trackedViewDisplay, ^{
        [WPAnalytics track:WPAnalyticsStatNotificationsAccessed];
    });
    
    [self updateLastSeenTime];
    [self resetApplicationBadge];
}


#pragma mark - NSObject(NSKeyValueObserving) methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(applicationIconBadgeNumber))]) {
        [self updateTabBarBadgeNumber];
    }
}


#pragma mark - Helper methods

- (void)resetApplicationBadge
{
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}

- (void)updateTabBarBadgeNumber
{
    NSInteger count         = [[UIApplication sharedApplication] applicationIconBadgeNumber];
    NSString *countString   = (count) ? [NSString stringWithFormat:@"%d", count] : nil;
    
    self.navigationController.tabBarItem.badgeValue = countString;
}

- (void)updateLastSeenTime
{
    Notification *note      = [self.resultsController.fetchedObjects firstObject];
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

- (void)showManageButtonIfNeeded
{
    UINavigationItem *navigationItem = self.navigationItem;
    if (![NotificationsManager deviceRegisteredForPushNotifications] || navigationItem.rightBarButtonItem) {
        return;
    }
    
    navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Manage", @"")
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

#pragma mark - REST Helpers

- (void)loadPostWithId:(NSNumber *)postID fromSite:(NSNumber *)siteID completion:(LoadPostCompletionBlock)completion
{
    ContextManager *contextManager  = [ContextManager sharedInstance];
    NSManagedObjectContext *context = [contextManager mainContext];
    ReaderPostService *service      = [[ReaderPostService alloc] initWithManagedObjectContext:context];
    
    [service fetchPost:postID.integerValue forSite:siteID.integerValue success:^(ReaderPost *post) {
        completion(YES, post);
    } failure:^(NSError *error) {
        DDLogError(@"[RestAPI] %@", error);
        completion(NO, nil);
    }];
}

//#warning TODO: Implement Me Properly Please!!

- (void)loadCommentWithId:(NSNumber *)commentId fromSite:(NSNumber *)siteID completion:(LoadCommentCompletionBlock)completion
{
    completion(false, nil);
    
//    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
//    
//    BlogService *blogService        = [[BlogService alloc] initWithManagedObjectContext:context];
//    Blog *blog                      = [blogService blogByBlogId:siteID];
//    
//    [blogService syncCommentsForBlog:blog success:^{
//        [context refreshObject:blog mergeChanges:NO];
//        NSSet *results = [blog.comments filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"commentID == %@", commentId]];
//        completion(results.count, [results anyObject]);
//    } failure:^(NSError *error) {
//        completion(false, nil);
//    }];

    
    //    NSString *commentPath = [NSString stringWithFormat:@"sites/%@/comments/%@", siteID, commentId];
    //    [blog.restApi GET:commentPath parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
    //
    //        NSDictionary *comment = responseObject;
    //
    //        [Comment mergeNewComments:@[comment] forBlog:blog];
    //        NSLog(@"Here: %@", responseObject);
    //
    //    } failure:^(AFHTTPRequestOperation *operation, NSError *error){
    //        DDLogVerbose(@"[Rest API] ! %@", [error localizedDescription]);
    //    }];
}


#pragma mark - UITableViewDelegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NoteTableViewCell *cell = (NoteTableViewCell *)[tableView dequeueReusableCellWithIdentifier:[NoteTableViewCell reuseIdentifier]];
    NSAssert([cell isKindOfClass:[NoteTableViewCell class]], nil);
    
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Notification *note = [self.resultsController objectAtIndexPath:indexPath];
    return [NoteTableViewCell calculateHeightForNote:note];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Notification *note = [self.resultsController objectAtIndexPath:indexPath];
    if (!note) {
        return;
    }
    
    // Mark as Read, if needed
    if(!note.read.boolValue) {
        note.read = @(1);
        [[ContextManager sharedInstance] saveContext:note.managedObjectContext];
        
        NoteTableViewCell *cell = (NoteTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
        cell.read = true;
    }
    
    // Tracker!
    [WPAnalytics track:WPAnalyticsStatNotificationsOpenedNotificationDetails];
    
    // At last, push the details
    if (note.isMatcher) {
        [self loadPostWithId:note.metaPostID fromSite:note.metaSiteID completion:^(BOOL success, ReaderPost *post) {
            if (success) {
                [self performSegueWithIdentifier:NSStringFromClass([ReaderPostDetailViewController class]) sender:post];
            } else {
                [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            }
        }];
        
    } else if (note.isComment) {
        [self loadCommentWithId:note.metaCommentID fromSite:note.metaSiteID completion:^(BOOL success, Comment *comment) {
            if (success) {
                [self performSegueWithIdentifier:NSStringFromClass([CommentViewController class]) sender:comment];
            } else {
                [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            }
        }];
        
    } else {
        [self performSegueWithIdentifier:NSStringFromClass([NotificationDetailsViewController class]) sender:note];
    }
}


#pragma mark - Storyboard Helpers

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *detailsSegueID    = NSStringFromClass([NotificationDetailsViewController class]);
    NSString *commentSegueID    = NSStringFromClass([CommentViewController class]);
    NSString *readerSegueID     = NSStringFromClass([ReaderPostDetailViewController class]);
    
    if([segue.identifier isEqualToString:detailsSegueID]) {
        NotificationDetailsViewController *detailsViewController = segue.destinationViewController;
        detailsViewController.note  = sender;

    } else if ([segue.identifier isEqualToString:commentSegueID]) {
        CommentViewController *commentsViewController = segue.destinationViewController;
        commentsViewController.comment = sender;
    
    } else if([segue.identifier isEqualToString:readerSegueID]) {
        ReaderPostDetailViewController *readerViewController = segue.destinationViewController;
        readerViewController.post = sender;
    }
}


#pragma mark - WPTableViewController subclass methods

- (NSString *)entityName
{
    return NSStringFromClass([Notification class]);
}

- (NSDate *)lastSyncDate
{
    return [NSDate date];
}

- (NSFetchRequest *)fetchRequest
{
    NSString *sortKey               = NSStringFromSelector(@selector(timestamp));
    NSFetchRequest *fetchRequest    = [NSFetchRequest fetchRequestWithEntityName:[self entityName]];
    fetchRequest.sortDescriptors    = @[ [NSSortDescriptor sortDescriptorWithKey:sortKey ascending:NO] ];
    
    return fetchRequest;
}

- (Class)cellClass
{
    return [NoteTableViewCell class];
}

- (void)configureCell:(NoteTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Notification *note      = [self.resultsController objectAtIndexPath:indexPath];
    cell.attributedSubject  = note.subjectBlock.attributedSubject;
    cell.read               = [note.read boolValue];
    cell.iconURL            = note.iconURL;
    cell.timestamp          = note.timestampAsDate;
    cell.noticon            = note.noticon;
}

- (void)syncItems
{
	// No-Op. Handled by Simperium!
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
