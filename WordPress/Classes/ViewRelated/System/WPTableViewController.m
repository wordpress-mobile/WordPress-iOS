#import "WPTableViewController.h"
#import "WPTableViewControllerSubclass.h"
#import "EditSiteViewController.h"
#import "WPWebViewController.h"
#import "WPNoResultsView.h"
#import "SupportViewController.h"
#import "ContextManager.h"
#import "UIView+Subviews.h"

NSTimeInterval const WPTableViewControllerRefreshTimeout = 300; // 5 minutes
CGFloat const WPTableViewTopMargin = 40;
CGFloat const CellHeight = 44.0;
static CGFloat const SectionHeaderHeight = 25.0;
NSString *const WPBlogRestorationKey = @"WPBlogRestorationKey";
NSString *const DefaultCellIdentifier = @"DefaultCellIdentifier";

@interface WPTableViewController ()

@property (nonatomic, strong) NSFetchedResultsController *resultsController;
@property (nonatomic) BOOL infiniteScrollEnabled;
@property (nonatomic, strong, readonly) UIView *swipeView;
@property (nonatomic, strong) UITableViewCell *swipeCell;
@property (nonatomic, strong) WPNoResultsView *noResultsView;
@property (nonatomic, strong) EditSiteViewController *editSiteViewController;
@property (nonatomic, strong) NSIndexPath *indexPathSelectedBeforeUpdates;
@property (nonatomic, strong) NSIndexPath *indexPathSelectedAfterUpdates;
@property (nonatomic, assign) UISwipeGestureRecognizerDirection swipeDirection;
@property (nonatomic, strong) UIActivityIndicatorView *activityFooter;
@property (nonatomic, assign) BOOL animatingRemovalOfModerationSwipeView;
@property (nonatomic, assign) BOOL didPromptForCredentials;
@property (nonatomic, assign, setter = setSyncing:) BOOL isSyncing;
@property (nonatomic, assign) BOOL isLoadingMore;
@property (nonatomic, assign) BOOL didTriggerRefresh;
@property (nonatomic, assign) CGPoint savedScrollOffset;
@property (nonatomic, strong) UIActivityIndicatorView *noResultsActivityIndicator;

@end

@implementation WPTableViewController

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    NSString *blogID = [coder decodeObjectForKey:WPBlogRestorationKey];
    if (!blogID) {
        return nil;
    }

    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    NSManagedObjectID *objectID = [context.persistentStoreCoordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:blogID]];
    if (!objectID) {
        return nil;
    }

    NSError *error = nil;
    Blog *restoredBlog = (Blog *)[context existingObjectWithID:objectID error:&error];
    if (error || !restoredBlog) {
        return nil;
    }

    WPTableViewController *viewController = [[self alloc] initWithStyle:UITableViewStyleGrouped];
    viewController.blog = restoredBlog;

    return viewController;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:UITableViewStyleGrouped];

    if (self) {
        self.restorationIdentifier = NSStringFromClass([self class]);
        self.restorationClass = [self class];
    }

    return self;
}

- (void)dealloc
{
    _resultsController.delegate = nil;
    _editSiteViewController.delegate = nil;

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [coder encodeObject:[[self.blog.objectID URIRepresentation] absoluteString] forKey:WPBlogRestorationKey];
    [super encodeRestorableStateWithCoder:coder];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;

    self.tableView.allowsSelectionDuringEditing = YES;
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    [self.tableView registerClass:[self cellClass] forCellReuseIdentifier:DefaultCellIdentifier];

    if (IS_IPHONE) {
        // Account for 1 pixel header height
        UIEdgeInsets tableInset = [self.tableView contentInset];
        tableInset.top = -1;
        self.tableView.contentInset = tableInset;
    }

    if (self.infiniteScrollEnabled) {
        [self enableInfiniteScrolling];
    }

    [self configureNoResultsView];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(automaticallyRefreshIfAppropriate) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    CGSize contentSize = self.tableView.contentSize;
    if (contentSize.height > _savedScrollOffset.y) {
        [self.tableView scrollRectToVisible:CGRectMake(_savedScrollOffset.x, _savedScrollOffset.y, 0.0, 0.0) animated:NO];
    } else {
        [self.tableView scrollRectToVisible:CGRectMake(0.0, contentSize.height, 0.0, 0.0) animated:NO];
    }
    if ([self.tableView indexPathForSelectedRow]) {
        [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    }
    [self configureNoResultsView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self automaticallyRefreshIfAppropriate];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (IS_IPHONE) {
        _savedScrollOffset = self.tableView.contentOffset;
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
}

#pragma mark - No Results View

- (NSString *)noResultsTitleText
{
    NSString *ttl = NSLocalizedString(@"No %@ yet", @"A string format. The '%@' will be replaced by the relevant type of object, posts, pages or comments.");
    ttl = [NSString stringWithFormat:ttl, [self.title lowercaseString]];
    return ttl;
}

- (NSString *)noResultsMessageText
{
    return nil;
}

- (UIView *)noResultsAccessoryView
{
    return nil;
}

- (NSString *)noResultsButtonText
{
    return nil;
}

#pragma mark - Property accessors

- (void)setBlog:(Blog *)blog
{
    if (_blog == blog) {
        return;
    }

    _blog = blog;

    self.resultsController = nil;
    [self.tableView reloadData];
    WordPressAppDelegate *appDelegate = [WordPressAppDelegate sharedInstance];
    if (!(appDelegate.connectionAvailable == YES && [self.resultsController.fetchedObjects count] == 0 && ![self isSyncing])) {
        [self configureNoResultsView];
    }
}

- (void)setInfiniteScrollEnabled:(BOOL)infiniteScrollEnabled
{
    if (infiniteScrollEnabled == _infiniteScrollEnabled) {
        return;
    }

    _infiniteScrollEnabled = infiniteScrollEnabled;
    if (self.isViewLoaded) {
        if (_infiniteScrollEnabled) {
            [self enableInfiniteScrolling];
        } else {
            [self disableInfiniteScrolling];
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.resultsController sections] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.resultsController sections] objectAtIndex:section];
    return [sectionInfo name];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = nil;
    sectionInfo = [[self.resultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:DefaultCellIdentifier];

    if (self.tableView.isEditing) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}

- (void)tableView:(UITableView *)tableView
        willDisplayCell:(UITableViewCell *)cell
        forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Are we approaching the end of the table?
    if ((indexPath.section + 1 == [self numberOfSectionsInTableView:tableView]) && (indexPath.row + 4 >= [self tableView:tableView numberOfRowsInSection:indexPath.section]) && [self tableView:tableView numberOfRowsInSection:indexPath.section] > 10) {
        // Only 3 rows till the end of table

        if ([self hasMoreContent] && !_isLoadingMore) {
            if (![self isSyncing] || self.incrementalLoadingSupported) {
                [_activityFooter startAnimating];
                _isLoadingMore = YES;
                [self loadMoreWithSuccess:^{
                    _isLoadingMore = NO;
                    [_activityFooter stopAnimating];
                } failure:^(NSError *error) {
                    _isLoadingMore = NO;
                    [_activityFooter stopAnimating];
                }];
            }
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return CellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    // Don't show section headers if there are no named sections, or if this is the first (and has no name)
    NSString *sectionTitle = [self tableView:tableView titleForHeaderInSection:section];
    BOOL firstTitleAndNoName = section == 0 && [sectionTitle length] == 0;
    if ([[self.resultsController sections] count] <= 1 || firstTitleAndNoName) {
        return IS_IPHONE ? 1 : WPTableViewTopMargin;
    }

    return SectionHeaderHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    // remove footer height for all but last section
    return section == [[self.resultsController sections] count] - 1 ? UITableViewAutomaticDimension : 1.0;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

#pragma mark - Fetched results controller

- (UITableViewRowAnimation)tableViewRowAnimation
{
    return UITableViewRowAnimationFade;
}

- (NSFetchedResultsController *)resultsController
{
    if (_resultsController != nil) {
        return _resultsController;
    }

    NSManagedObjectContext *moc = [self managedObjectContext];
    _resultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:[self fetchRequest]
                                                             managedObjectContext:moc
                                                               sectionNameKeyPath:[self sectionNameKeyPath]
                                                                        cacheName:nil];
    _resultsController.delegate = self;

    NSError *error = nil;
    if (![_resultsController performFetch:&error]) {
        DDLogError(@"%@ couldn't fetch %@: %@", self, [self entityName], [error localizedDescription]);
        _resultsController = nil;
    }

    return _resultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    _indexPathSelectedBeforeUpdates = [self.tableView indexPathForSelectedRow];
    [self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
    if (_indexPathSelectedAfterUpdates) {
        [self.tableView selectRowAtIndexPath:_indexPathSelectedAfterUpdates animated:NO scrollPosition:UITableViewScrollPositionNone];

        _indexPathSelectedBeforeUpdates = nil;
        _indexPathSelectedAfterUpdates = nil;
    }

    [self configureNoResultsView];
    [self didChangeContent];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    if (NSFetchedResultsChangeUpdate == type && newIndexPath && ![newIndexPath isEqual:indexPath]) {
        // Seriously, Apple?
        // http://developer.apple.com/library/ios/#releasenotes/iPhone/NSFetchedResultsChangeMoveReportedAsNSFetchedResultsChangeUpdate/_index.html
        type = NSFetchedResultsChangeMove;
    }
    if (newIndexPath == nil) {
        // It seems in some cases newIndexPath can be nil for updates
        newIndexPath = indexPath;
    }
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            {
                [self invalidateRowHeightsBelowIndexPath:newIndexPath];
                [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:[self tableViewRowAnimation]];
            }
            break;
        case NSFetchedResultsChangeDelete:
            {
                [self invalidateRowHeightsBelowIndexPath:indexPath];
                [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:[self tableViewRowAnimation]];
                if ([_indexPathSelectedBeforeUpdates isEqual:indexPath]) {
                    [self.navigationController popToViewController:self animated:YES];
                }
            }
            break;
        case NSFetchedResultsChangeUpdate:
            {
                [self invalidateRowHeightAtIndexPath:indexPath];
                [self configureCell:[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:newIndexPath];
            }
            break;
        case NSFetchedResultsChangeMove:
            {
                NSIndexPath *lowerIndexPath = indexPath;
                if ([indexPath compare:newIndexPath] == NSOrderedDescending) {
                    lowerIndexPath = newIndexPath;
                }
                [self invalidateRowHeightsBelowIndexPath:lowerIndexPath];
                
                [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:[self tableViewRowAnimation]];
                [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:[self tableViewRowAnimation]];
                if ([_indexPathSelectedBeforeUpdates isEqual:indexPath] && _indexPathSelectedAfterUpdates == nil) {
                    _indexPathSelectedAfterUpdates = newIndexPath;
                }
            }
            break;
        default:
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller
        didChangeSection:(id )sectionInfo
        atIndex:(NSUInteger)sectionIndex
        forChangeType:(NSFetchedResultsChangeType)type
{
    if (type == NSFetchedResultsChangeInsert) {
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:[self tableViewRowAnimation]];
    } else if (type == NSFetchedResultsChangeDelete) {
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:[self tableViewRowAnimation]];
    }
}

#pragma mark - UIRefreshControl Methods

- (void)refresh
{
    if (![self userCanRefresh]) {
        [self.refreshControl endRefreshing];
        return;
    }

    _didTriggerRefresh = YES;
    [self syncItemsViaUserInteraction];
}

- (BOOL)userCanRefresh
{
    return YES;
}

#pragma mark - UIScrollViewDelegate Methods

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    _isScrolling = YES;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    _isScrolling = NO;
}

- (void)sendUserToXMLOptionsFromAlert:(UIAlertView *)alertView
{
    NSString *path = nil;
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"http\\S+writing.php" options:NSRegularExpressionCaseInsensitive error:&error];
    NSString *msg = [alertView message];
    NSRange rng = [regex rangeOfFirstMatchInString:msg options:0 range:NSMakeRange(0, [msg length])];

    if (rng.location == NSNotFound) {
        path = [self.blog adminUrlWithPath:@"/wp-admin/options-writing.php"];
    } else {
        path = [msg substringWithRange:rng];
    }

    NSURL *targetURL = [NSURL URLWithString:path];
    WPWebViewController *webViewController = [WPWebViewController webViewControllerWithURL:targetURL];
    webViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStylePlain target:self action:@selector(dismissModal:)];
    webViewController.authToken = self.blog.authToken;
    webViewController.username = self.blog.username;
    webViewController.password = self.blog.password;
    webViewController.wpLoginURL = [NSURL URLWithString:self.blog.loginUrl];
    webViewController.shouldScrollToBottom = YES;
    
    // Probably should be modal.
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:webViewController];
    navController.navigationBar.translucent = NO;
    if (IS_IPAD) {
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
        navController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    }
    [self.navigationController presentViewController:navController animated:YES completion:nil];
}

#pragma mark - SettingsViewControllerDelegate

- (void)controllerDidDismiss:(UIViewController *)controller cancelled:(BOOL)cancelled
{
    if (self.editSiteViewController == controller) {
        _didPromptForCredentials = cancelled;
        self.editSiteViewController = nil;
    }
}

#pragma mark - Private Methods

- (void)automaticallyRefreshIfAppropriate
{
    // Only automatically refresh if the view is loaded and visible on the screen
    if (self.isViewLoaded == NO || self.view.window == nil) {
        DDLogVerbose(@"View is not visible and will not check for auto refresh.");
        return;
    }

    // Do not start auto-sync if connection is down
    WordPressAppDelegate *appDelegate = [WordPressAppDelegate sharedInstance];
    if (appDelegate.connectionAvailable == NO) {
        return;
    }

    // Don't try to refresh if we just canceled editing credentials
    if (_didPromptForCredentials) {
        return;
    }

    if ([self userCanRefresh] == NO) {
        return;
    }

    NSDate *lastSynced = [self lastSyncDate];
    if (lastSynced == nil || ABS([lastSynced timeIntervalSinceNow]) > WPTableViewControllerRefreshTimeout) {
        // Update in the background
        [self syncItems];
    }
}

- (void)configureNoResultsView
{
    if (!self.isViewLoaded) {
        return;
    }
    [self.noResultsActivityIndicator stopAnimating];
    [self.noResultsActivityIndicator removeFromSuperview];

    if (self.resultsController.fetchedObjects.count) {
        [self.noResultsView removeFromSuperview];
        return;
    }

    if (self.isSyncing) {
        // Show activity indicator view when syncing is occuring and the fetched results controller has no objects
        [self.noResultsActivityIndicator startAnimating];
        self.noResultsActivityIndicator.center = [self.tableView convertPoint:self.tableView.center fromView:self.tableView.superview];
        [self.tableView addSubview:self.noResultsActivityIndicator];

    } else {
        // Refresh the NoResultsView Properties
        self.noResultsView.titleText        = self.noResultsTitleText;
        self.noResultsView.messageText      = self.noResultsMessageText;
        self.noResultsView.accessoryView    = self.noResultsAccessoryView;
        self.noResultsView.buttonTitle      = self.noResultsButtonText;

        // Show no results view if the fetched results controller has no objects and syncing is not happening.
        if (![self.noResultsView isDescendantOfView:self.tableView]) {
            [self.tableView addSubviewWithFadeAnimation:self.noResultsView];
        } else {
            [self.noResultsView centerInSuperview];
        }
    }
}

- (WPNoResultsView *)noResultsView
{
    if (!_noResultsView) {
        _noResultsView = [WPNoResultsView new];
        _noResultsView.delegate = self;
    }

    return _noResultsView;
}

- (UIActivityIndicatorView *)noResultsActivityIndicator
{
    if (!_noResultsActivityIndicator) {
        _noResultsActivityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _noResultsActivityIndicator.hidesWhenStopped = YES;
        _noResultsActivityIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        _noResultsActivityIndicator.center = [self.tableView convertPoint:self.tableView.center fromView:self.tableView.superview];
    }

    return _noResultsActivityIndicator;
}

- (void)hideRefreshHeader
{
    [self.refreshControl endRefreshing];
    _didTriggerRefresh = NO;
}

- (void)dismissModal:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)syncItems
{
    [self syncItemsViaUserInteraction:NO];
}

- (void)syncItemsViaUserInteraction
{
    [self syncItemsViaUserInteraction:YES];
}

- (void)syncItemsViaUserInteraction:(BOOL)userInteraction
{
    if ([self isSyncing]) {
        if (self.didTriggerRefresh) {
            [self hideRefreshHeader];
        }
        return;
    }

    [self setSyncing:YES];
    [self syncItemsViaUserInteraction:userInteraction success:^{
        [self hideRefreshHeader];
        [self setSyncing:NO];
        [self configureNoResultsView];
    } failure:^(NSError *error) {
        [self hideRefreshHeader];
        [self setSyncing:NO];
        [self configureNoResultsView];
        if (self.blog) {
            if ([error.domain isEqualToString:WPXMLRPCClientErrorDomain]) {
                NSInteger statusCode = error.code;
                if (statusCode == 405) {
                    // Prompt to enable XML-RPC using the default message provided from the WordPress site.
                    [WPError showAlertWithTitle:NSLocalizedString(@"Couldn't sync", @"") message:[error localizedDescription]
                              withSupportButton:YES okPressedBlock:^(UIAlertView *alertView){
                                  [self sendUserToXMLOptionsFromAlert:alertView];
                    }];

                } else if (error.code == 403 && self.editSiteViewController == nil) {
                    [self promptForPassword];
                } else if (error.code == 425 && self.editSiteViewController == nil) {
                    [self promptForPasswordWithMessage:[error localizedDescription]];
                } else if (userInteraction) {
                    [WPError showNetworkingAlertWithError:error title:NSLocalizedString(@"Couldn't sync", @"")];
                }
            } else {
                [WPError showNetworkingAlertWithError:error];
            }
        } else {
            if (error) {
                [WPError showNetworkingAlertWithError:error];
            }
        }
    }];
}

- (void)promptForPassword
{
    [self promptForPasswordWithMessage:nil];
}

- (void)promptForPasswordWithMessage:(NSString *)message
{
    if (message == nil) {
        message = NSLocalizedString(@"The username or password stored in the app may be out of date. Please re-enter your password in the settings and try again.", @"");
    }
    [WPError showAlertWithTitle:NSLocalizedString(@"Couldn't Connect", @"") message:message];

    // bad login/pass combination
    self.editSiteViewController = [[EditSiteViewController alloc] initWithBlog:self.blog];
    self.editSiteViewController.isCancellable = YES;
    self.editSiteViewController.delegate = self;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.editSiteViewController];
    navController.navigationBar.translucent = NO;

    if (IS_IPAD) {
        navController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
    }

    [self.navigationController presentViewController:navController animated:YES completion:nil];
}

#pragma mark - Infinite scrolling

- (void)enableInfiniteScrolling
{
    if (_activityFooter == nil) {
        CGRect rect = CGRectMake(145.0, 10.0, 30.0, 30.0);
        _activityFooter = [[UIActivityIndicatorView alloc] initWithFrame:rect];
        _activityFooter.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        _activityFooter.hidesWhenStopped = YES;
        _activityFooter.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [_activityFooter stopAnimating];
    }
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 50.0)];
    footerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [footerView addSubview:_activityFooter];
    self.tableView.tableFooterView = footerView;
}

- (void)disableInfiniteScrolling
{
    self.tableView.tableFooterView = nil;
    _activityFooter = nil;
}

#pragma mark - Subclass methods

- (BOOL)userCanCreateEntity
{
    return NO;
}

- (NSManagedObjectContext *)managedObjectContext
{
    return [[ContextManager sharedInstance] mainContext];
}

#define AssertNoBlogSubclassMethod() NSAssert(self.blog, @"You must override %@ in a subclass if there is no blog", NSStringFromSelector(_cmd))

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wreturn-type"

- (NSString *)entityName
{
    AssertSubclassMethod();
}

- (NSDate *)lastSyncDate
{
    AssertSubclassMethod();
}

- (NSFetchRequest *)fetchRequest
{
    AssertNoBlogSubclassMethod();
}

#pragma clang diagnostic pop

- (NSString *)sectionNameKeyPath
{
    return nil;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    AssertSubclassMethod();
}

- (void)syncItemsViaUserInteraction:(BOOL)userInteraction
                            success:(void (^)())success
                            failure:(void (^)(NSError *))failure
{
    AssertSubclassMethod();
}

- (void)invalidateRowHeightsBelowIndexPath:(NSIndexPath *)indexPath
{
    // Optional: Override if needed
}

- (void)invalidateRowHeightAtIndexPath:(NSIndexPath *)indexPath
{
    // Optional: Override if needed
}

- (void)didChangeContent
{
    // Optional: Override if needed
}

- (BOOL)isSyncing
{
    return _isSyncing;
}

- (Class)cellClass
{
    return [UITableViewCell class];
}

- (BOOL)hasMoreContent
{
    return NO;
}

- (void)loadMoreWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure
{
    AssertSubclassMethod();
}

- (void)resetResultsController
{
    _resultsController.delegate = nil;
    _resultsController = nil;
}

@end
