#import "ReaderPostsViewController.h"

#import <AFNetworking/AFNetworking.h>

#import "AccountService.h"
#import "BlogService.h"
#import "ContextManager.h"
#import "CustomHighlightButton.h"
#import "NSString+Helpers.h"
#import "NSString+XMLExtensions.h"
#import "ReaderBlockedTableViewCell.h"
#import "ReaderCommentsViewController.h"
#import "ReaderPost.h"
#import "ReaderPostDetailViewController.h"
#import "ReaderPostService.h"
#import "ReaderPostTableViewCell.h"
#import "ReaderSiteService.h"
#import "ReaderSubscriptionViewController.h"
#import "ReaderTopic.h"
#import "ReaderTopicService.h"
#import "RebloggingViewController.h"
#import "UIView+Subviews.h"
#import "WordPressAppDelegate.h"
#import "WPAccount.h"
#import "WPAnimatedBox.h"
#import "WPNoResultsView.h"
#import "WPTableImageSource.h"
#import "WPTabBarController.h"

#import "WPTableViewHandler.h"
#import "WordPress-Swift.h"


static CGFloat const RPVCHeaderHeightPhone = 10.0;
static CGFloat const RPVCBlockedCellHeight = 66.0;
static CGFloat const RPVCEstimatedRowHeightIPhone = 400.0;
static CGFloat const RPVCEstimatedRowHeightIPad = 600.0;
static NSInteger RPVCRefreshInterval = 300; // 5 minutes
static CGRect RPVCTableHeaderFrame = {0.0f, 0.0f, 0.0f, 40.0f};
static NSInteger const RPVCImageQuality = 65;

NSString * const BlockedCellIdentifier = @"BlockedCellIdentifier";
NSString * const FeaturedImageCellIdentifier = @"FeaturedImageCellIdentifier";
NSString * const NoFeaturedImageCellIdentifier = @"NoFeaturedImageCellIdentifier";
NSString * const RPVCDisplayedNativeFriendFinder = @"DisplayedNativeFriendFinder";

@interface ReaderPostsViewController ()<RebloggingViewControllerDelegate,
                                        UIActionSheetDelegate,
                                        WPContentSyncHelperDelegate,
                                        WPTableImageSourceDelegate,
                                        WPTableViewHandlerDelegate>


@property (nonatomic, assign) BOOL viewHasAppeared;
@property (nonatomic, strong) WPTableImageSource *featuredImageSource;
@property (nonatomic, strong) UIActivityIndicatorView *activityFooter;
@property (nonatomic, strong) WPAnimatedBox *animatedBox;
@property (nonatomic, readonly) ReaderTopic *currentTopic;
@property (nonatomic, strong) ReaderPostTableViewCell *cellForLayout;
@property (nonatomic, strong) NSNumber *siteIDToBlock;
@property (nonatomic, strong) NSNumber *postIDThatInitiatedBlock;
@property (nonatomic, strong) UIActionSheet *actionSheet;
@property (nonatomic, strong) WPNoResultsView *noResultsView;
@property (nonatomic, strong) WPTableViewHandler *tableViewHandler;
@property (nonatomic, strong) WPContentSyncHelper *syncHelper;
@property (nonatomic) BOOL shouldSkipRowAnimation;
@property (nonatomic) UIDeviceOrientation previousOrientation;
@property (nonatomic) BOOL hasWPComAccount;

@property (nonatomic, strong) NSManagedObjectContext *contextForSync;

@end


@implementation ReaderPostsViewController

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    return [[WPTabBarController sharedInstance] readerPostsViewController];
}


#pragma mark - Life Cycle methods

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        Class aClass = [ReaderPostsViewController class];
        self.restorationIdentifier = NSStringFromClass(aClass);
        self.restorationClass = aClass;

        _syncHelper = [[WPContentSyncHelper alloc] init];
        _syncHelper.delegate = self;

        // TODO: since the vc is not visible when accounts/topics change we could
        // handle this a different way and ditch the observers.
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeAccount:) name:WPAccountDefaultWordPressComAccountChangedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(readerTopicDidChange:) name:ReaderTopicDidChangeNotification object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self checkWPComAccountExists];
    [self configureRefreshControl];
    [self configureTableView];
    [self configureTableViewHandler];
    [self configureCellForLayout];
    [self configureFeaturedImageSource];
    [self configureInfiniteScroll];
    [self configureNavbar];

    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (self.previousOrientation != UIInterfaceOrientationUnknown) {
        if (UIInterfaceOrientationIsPortrait(self.previousOrientation) != UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
            [self.tableViewHandler refreshCachedRowHeightsForWidth:CGRectGetWidth(self.view.frame)];
            [self.tableView reloadData];
        }
    }

    [self updateTitle];

    [self configureNoResultsView];

    if (self.noResultsView && self.animatedBox) {
        [self.animatedBox prepareAnimation:NO];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    if (selectedIndexPath) {
        [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:YES];
    }

    if (!self.viewHasAppeared) {
        if (self.currentTopic) {
            [WPAnalytics track:WPAnalyticsStatReaderAccessed withProperties:[self tagPropertyForStats]];
        }
        self.viewHasAppeared = YES;
    }

    [self syncIfAppropriate];

    // Delay box animation after the view appears
    double delayInSeconds = 0.3;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (self.noResultsView && self.animatedBox) {
            [self.animatedBox animate];
        }
    });
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.previousOrientation = self.interfaceOrientation;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self configureNoResultsView];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // Remove the no results view or else the position will abruptly adjust after rotation
    // due to the table view sizing for image preloading
    [self.noResultsView removeFromSuperview];

    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // No need to update when we have a fixed width
    if ([UIDevice isPad]) {
        return;
    }

    // Refresh cached row heights based on the width for the new orientation.
    // Must happen before the table view calculates its content size / offset
    // for the new orientation.
    CGRect bounds = self.tableView.window.frame;
    CGFloat width = CGRectGetWidth(bounds);
    CGFloat height = CGRectGetHeight(bounds);
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
        width = MIN(width, height);
    } else {
        width = MAX(width, height);
    }

    [self.tableViewHandler refreshCachedRowHeightsForWidth:width];
}


#pragma mark - Configuration

- (void)checkWPComAccountExists
{
    self.hasWPComAccount = ([[[AccountService alloc] initWithManagedObjectContext:self.managedObjectContext] defaultWordPressComAccount] != nil);
}

- (void)configureRefreshControl
{
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
}

- (void)configureTableView
{
    [self.tableView registerClass:[ReaderBlockedTableViewCell class] forCellReuseIdentifier:BlockedCellIdentifier];
    [self.tableView registerClass:[ReaderPostTableViewCell class] forCellReuseIdentifier:NoFeaturedImageCellIdentifier];
    [self.tableView registerClass:[ReaderPostTableViewCell class] forCellReuseIdentifier:FeaturedImageCellIdentifier];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.accessibilityIdentifier = @"Reader Table";
    
    // Note: UIEdgeInsets are not always enforced. After logging in, the table might autoscroll up to the first row.
    if (UIDevice.isPad) {
        self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:RPVCTableHeaderFrame];
    }
}

- (void)configureTableViewHandler
{
    if (self.tableViewHandler) {
        self.tableViewHandler.delegate = nil;
    }

    self.tableViewHandler = [[WPTableViewHandler alloc] initWithTableView:self.tableView];
    self.tableViewHandler.cacheRowHeights = YES;
    self.tableViewHandler.delegate = self;
    self.tableViewHandler.updateRowAnimation = UITableViewRowAnimationNone;
}

- (void)configureCellForLayout
{
    NSString *CellIdentifier = @"CellForLayoutIdentifier";
    [self.tableView registerClass:[ReaderPostTableViewCell class] forCellReuseIdentifier:CellIdentifier];
    self.cellForLayout = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
}

- (void)configureFeaturedImageSource
{
    CGFloat maxWidth;
    if ([UIDevice isPad]) {
        maxWidth = WPTableViewFixedWidth;
    } else {
        maxWidth = MAX(CGRectGetWidth(self.tableView.bounds), CGRectGetHeight(self.tableView.bounds));
    }

    CGFloat maxHeight = maxWidth * WPContentViewMaxImageHeightPercentage;
    self.featuredImageSource = [[WPTableImageSource alloc] initWithMaxSize:CGSizeMake(maxWidth, maxHeight)];
    self.featuredImageSource.delegate = self;
    self.featuredImageSource.photonQuality = RPVCImageQuality;
}

- (void)configureInfiniteScroll
{
    if (self.syncHelper.hasMoreContent) {
        CGFloat width = CGRectGetWidth(self.tableView.bounds);
        UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, width, 50.0)];
        footerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        CGRect frame = self.activityFooter.frame;
        frame.origin.x = (width - CGRectGetWidth(frame))/2;
        self.activityFooter.frame = frame;
        [footerView addSubview:self.activityFooter];
        self.tableView.tableFooterView = footerView;

    } else {
        self.tableView.tableFooterView = nil;
    }
}

- (void)configureNavbar
{
    // Don't show 'Reader' in the next-view back button
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@" " style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem = backButton;

    // Topics button
    UIImage *image = [UIImage imageNamed:@"icon-reader-topics"];
    CustomHighlightButton *topicsButton = [CustomHighlightButton buttonWithType:UIButtonTypeCustom];
    topicsButton.tintColor = [WPStyleGuide navbarButtonTintColor];
    [topicsButton setImage:image forState:UIControlStateNormal];
    topicsButton.frame = CGRectMake(0.0, 0.0, image.size.width, image.size.height);
    [topicsButton addTarget:self action:@selector(topicsAction:) forControlEvents:UIControlEventTouchUpInside];

    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithCustomView:topicsButton];
    [button setAccessibilityLabel:NSLocalizedString(@"Topics", @"Accessibility label for the topics button. The user does not see this text but it can be spoken by a screen reader.")];
    self.navigationItem.rightBarButtonItem = button;

    [WPStyleGuide setRightBarButtonItemWithCorrectSpacing:button forNavigationItem:self.navigationItem];
}

- (void)configureNoResultsView
{
    if (!self.isViewLoaded) {
        return;
    }

    if (!self.noResultsView) {
        self.noResultsView = [[WPNoResultsView alloc] init];
    }

    if ([self.tableViewHandler.resultsController.fetchedObjects count] > 0) {
        [self.noResultsView removeFromSuperview];
        return;
    }

    // Refresh the NoResultsView Properties
    self.noResultsView.titleText        = self.noResultsTitleText;
    self.noResultsView.messageText      = self.noResultsMessageText;
    self.noResultsView.accessoryView    = self.noResultsAccessoryView;

    // Only add and animate no results view if it isn't already
    // in the table view
    if (![self.noResultsView isDescendantOfView:self.tableView]) {
        [self.tableView addSubviewWithFadeAnimation:self.noResultsView];
    } else {
        [self.noResultsView centerInSuperview];
    }

    [self.tableView sendSubviewToBack:self.noResultsView];
}

- (NSString *)noResultsTitleText
{
    if (self.syncHelper.isSyncing) {
        return NSLocalizedString(@"Fetching posts...", @"A brief prompt shown when the reader is empty, letting the user know the app is currently fetching new posts.");
    }

    NSRange range = [self.currentTopic.path rangeOfString:@"following"];
    if (range.location != NSNotFound) {
        return NSLocalizedString(@"You're not following any sites yet.", @"Message shown to user when the reader list is empty because they are not following any sites.");
    }

    range = [self.currentTopic.path rangeOfString:@"liked"];
    if (range.location != NSNotFound) {
        return NSLocalizedString(@"You have not liked any posts.", @"Message shown to user when the reader list is empty because they have not liked any posts.");
    }

    return NSLocalizedString(@"Sorry. No posts yet.", @"Generic message shown to the user when the reader list is empty. ");
}

- (NSString *)noResultsMessageText
{
    if (self.syncHelper.isSyncing) {
        return @"";
    }
    return NSLocalizedString(@"Tap the tag icon to browse posts from popular sites.", @"Message shown encouraging the user to browse posts from popular sites. ");
}

- (UIView *)noResultsAccessoryView
{
    if (!self.animatedBox) {
        self.animatedBox = [WPAnimatedBox new];
    }
    return self.animatedBox;
}


#pragma mark - Instance Methods and Accessors

- (UIActivityIndicatorView *)activityFooter
{
    if (_activityFooter) {
        return _activityFooter;
    }

    _activityFooter = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _activityFooter.hidesWhenStopped = YES;
    _activityFooter.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [_activityFooter stopAnimating];

    return _activityFooter;
}

- (ReaderTopic *)currentTopic
{
    return [self currentTopicInContext:self.managedObjectContext];
}

- (ReaderTopic *)currentTopicInContext:(NSManagedObjectContext *)context
{
    return [[[ReaderTopicService alloc] initWithManagedObjectContext:context] currentTopic];
}

- (BOOL)isCurrentTopicFreshlyPressed
{
    return [self.currentTopic.path rangeOfString:ReaderTopicFreshlyPressedPathCommponent].location != NSNotFound;
}

- (ReaderPost *)postFromCellSubview:(UIView *)subview
{
    ReaderPostTableViewCell *cell = [ReaderPostTableViewCell cellForSubview:subview];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    ReaderPost *post = (ReaderPost *)[self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    return post;
}

- (CGSize)tabBarSize
{
    CGSize tabBarSize = CGSizeZero;
    if ([self tabBarController]) {
        tabBarSize = [[[self tabBarController] tabBar] bounds].size;
    }

    return tabBarSize;
}

- (NSDictionary *)tagPropertyForStats
{
    return [NSDictionary dictionaryWithObjectsAndKeys:self.currentTopic.title, @"tag", nil];
}

- (void)setTitle:(NSString *)title
{
    [super setTitle:title];

    // Reset the tab bar title; this isn't a great solution, but works
    NSInteger tabIndex = [self.tabBarController.viewControllers indexOfObject:self.navigationController];
    UITabBarItem *tabItem = [[[self.tabBarController tabBar] items] objectAtIndex:tabIndex];
    tabItem.title = NSLocalizedString(@"Reader", @"Description of the Reader tab");
}

- (void)updateTitle
{
    if (self.currentTopic) {
        self.title = self.currentTopic.title;
    } else {
        self.title = NSLocalizedString(@"Reader", @"Default title for the reader before topics are loaded the first time.");
    }
}

- (void)openPost:(NSNumber *)postId onBlog:(NSNumber *)blogId
{
    ReaderPostDetailViewController *controller = [ReaderPostDetailViewController detailControllerWithPostID:postId siteID:blogId];
    [self.navigationController pushViewController:controller animated:YES];
}


#pragma mark - Image Methods

- (CGSize)sizeForFeaturedImage
{
    CGSize imageSize = CGSizeZero;
    imageSize.width = [UIDevice isPad] ? WPTableViewFixedWidth : CGRectGetWidth(self.tableView.bounds);
    imageSize.height = round(imageSize.width * WPContentViewMaxImageHeightPercentage);
    return imageSize;
}

- (void)preloadImagesForCellsAfterIndexPath:(NSIndexPath *)indexPath
{
    NSInteger numberToPreload = 2; // keep the number small else they compete and slow each other down.
    for (NSInteger i = 1; i <= numberToPreload; i++) {
        NSIndexPath *nextIndexPath = [NSIndexPath indexPathForRow:indexPath.row + i inSection:indexPath.section];
        if ([self.tableView numberOfRowsInSection:indexPath.section] > nextIndexPath.row) {
            ReaderPost *post = (ReaderPost *)[self.tableViewHandler.resultsController objectAtIndexPath:nextIndexPath];
            NSURL *imageURL = [post featuredImageURLForDisplay];
            if (!imageURL) {
                // No image to feature.
                continue;
            }

            UIImage *image = [self imageForURL:imageURL];
            if (image) {
                // already cached.
                continue;
            } else {
                [self.featuredImageSource fetchImageForURL:imageURL
                                                  withSize:[self sizeForFeaturedImage]
                                                 indexPath:nextIndexPath
                                                 isPrivate:post.isPrivate];
            }
        }
    }
}

- (UIImage *)imageForURL:(NSURL *)imageURL
{
    if (!imageURL) {
        return nil;
    }
    return [self.featuredImageSource imageForURL:imageURL withSize:[self sizeForFeaturedImage]];
}

- (void)setAvatarForPost:(ReaderPost *)post forCell:(ReaderPostTableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    if ([cell isEqual:self.cellForLayout]) {
        return;
    }

    CGSize imageSize = CGSizeMake(WPContentViewAuthorAvatarSize, WPContentViewAuthorAvatarSize);
    UIImage *image = [post cachedAvatarWithSize:imageSize];
    if (image) {
        [cell.postView setAvatarImage:image];
    } else {
        [post fetchAvatarWithSize:imageSize success:^(UIImage *image) {
            if (!image) {
                return;
            }
            if (cell == [self.tableView cellForRowAtIndexPath:indexPath]) {
                [cell.postView setAvatarImage:image];
            }
        }];
    }
}

- (void)setImageForPost:(ReaderPost *)post forCell:(ReaderPostTableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    if ([cell isEqual:self.cellForLayout]) {
        return;
    }

    NSURL *imageURL = [post featuredImageURLForDisplay];
    if ([[imageURL absoluteString] length] == 0) {
        return;
    }
    UIImage *image = [self imageForURL:imageURL];
    if (image) {
        [cell.postView setFeaturedImage:image];
    } else {
        [cell.postView setFeaturedImage:nil];
        [self.featuredImageSource fetchImageForURL:imageURL
                                          withSize:[self sizeForFeaturedImage]
                                         indexPath:indexPath
                                         isPrivate:post.isPrivate];
    }
}


#pragma mark - Blocking

- (void)blockSite
{
    if (!self.siteIDToBlock) {
        return;
    }

    self.tableViewHandler.updateRowAnimation = UITableViewRowAnimationFade;

    NSNumber *siteIDToBlock = self.siteIDToBlock;
    self.siteIDToBlock = nil;

    __weak __typeof(self) weakSelf = self;
    ReaderSiteService *service = [[ReaderSiteService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    [service flagSiteWithID:siteIDToBlock asBlocked:YES success:^{
        // Nothing to do.
    } failure:^(NSError *error) {
        self.tableViewHandler.updateRowAnimation = UITableViewRowAnimationNone;
        [weakSelf.tableView reloadData];
        weakSelf.postIDThatInitiatedBlock = nil;
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Blocking Site", @"Title of a prompt letting the user know there was an error trying to block a site from appearing in the reader.")
                                                            message:[error localizedDescription]
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK", @"Text for an alert's dismissal button.")
                                                  otherButtonTitles:nil, nil];
        [alertView show];
    }];
}

- (void)unblockSiteForPost:(ReaderPost *)post
{
    self.tableViewHandler.updateRowAnimation = UITableViewRowAnimationFade;
    __weak __typeof(self) weakSelf = self;
    ReaderSiteService *service = [[ReaderSiteService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    [service flagSiteWithID:post.siteID asBlocked:NO success:^{
        // Nothing to do.
        weakSelf.postIDThatInitiatedBlock = nil;
    } failure:^(NSError *error) {
        self.tableViewHandler.updateRowAnimation = UITableViewRowAnimationNone;
        [self.tableView reloadData];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Unblocking Site", @"Title of a prompt letting the user know there was an error trying to unblock a site from appearing in the reader.")
                                                            message:[error localizedDescription]
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK", @"Text for an alert's dismissal button.")
                                                  otherButtonTitles:nil, nil];
        [alertView show];
    }];
}

- (void)setPostIDThatInitiatedBlock:(NSNumber *)postIDThatInitiatedBlock
{
    // Comparing integer values is a valid check even if both values are nil, where an isEqual check would fail.
    if ([_postIDThatInitiatedBlock integerValue] == [postIDThatInitiatedBlock integerValue]) {
        return;
    }

    _postIDThatInitiatedBlock = postIDThatInitiatedBlock;
    [self updateAndPerformFetchRequest];
}


#pragma mark - Actions

- (void)topicsAction:(id)sender
{
    ReaderSubscriptionViewController *controller = [[ReaderSubscriptionViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
    navController.navigationBar.translucent = NO;
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)refresh
{
    [self syncItemsWithUserInteraction:YES];
}


#pragma mark - Notifications

- (void)readerTopicDidChange:(NSNotification *)notification
{
    [self updateTitle];

    [self.tableView setContentOffset:CGPointZero animated:NO];

    [self.tableViewHandler clearCachedRowHeights];
    [self updateAndPerformFetchRequest];
    [self.tableView reloadData];
    [self syncItemsWithUserInteraction:NO];

    [WPAnalytics track:WPAnalyticsStatReaderLoadedTag withProperties:[self tagPropertyForStats]];
    if ([self isCurrentTopicFreshlyPressed]) {
        [WPAnalytics track:WPAnalyticsStatReaderLoadedFreshlyPressed];
    }
}

- (void)didChangeAccount:(NSNotification *)notification
{
    [self checkWPComAccountExists];
    NSManagedObjectContext *context = [self managedObjectContext];
    [[[ReaderTopicService alloc] initWithManagedObjectContext:context] deleteAllTopics];
    [[[ReaderPostService alloc] initWithManagedObjectContext:context] deletePostsWithNoTopic];

    [self.tableViewHandler clearCachedRowHeights];
    [self updateAndPerformFetchRequest];
    [self.navigationController popToViewController:self animated:NO];

    if ([self isViewLoaded]) {
        [self refresh];
    }
}


#pragma mark - Sync methods

- (void)syncIfAppropriate
{
    // Do not start auto-sync if connection is down
    WordPressAppDelegate *appDelegate = [WordPressAppDelegate sharedWordPressApplicationDelegate];
    if (appDelegate.connectionAvailable == NO) {
        return;
    }

    NSDate *lastSynced = self.currentTopic.lastSynced;
    if (lastSynced == nil || ABS([lastSynced timeIntervalSinceNow]) > RPVCRefreshInterval) {
        [self syncItemsWithUserInteraction:NO];
    }
}

- (void)syncItemsWithUserInteraction:(BOOL)userInteraction
{
    DDLogMethod();
    [self configureNoResultsView];

    NSManagedObjectContext *context = [self managedObjectContext];
    AccountService *service = [[AccountService alloc] initWithManagedObjectContext:context];
    if ([service numberOfAccounts] == 0) {
        return;
    }

    // The synchelper only supports a single sync operation at a time. Since contextForSync is assigned
    // in the delegate callbacks, and cleared when the sync operation is cleared up (or after scrolling
    // finishes) there *should't* be an existing instance of the context when the synchelper's delegate
    // methods are called. However, check here just in case there is an unnexpected edgecase. 
    if (self.contextForSync) {
        return;
    }

    if (!self.currentTopic) {
        __weak __typeof(self) weakSelf = self;
        ReaderTopicService *topicService = [[ReaderTopicService alloc] initWithManagedObjectContext:context];
        [topicService fetchReaderMenuWithSuccess:^{
            [weakSelf updateAndPerformFetchRequest];
            [weakSelf updateTitle];
            [weakSelf.syncHelper syncContentWithUserInteraction:userInteraction];
        } failure:^(NSError *error) {
            DDLogError(@"Error refreshing topics: %@", error);
        }];
        return;
    }

    [self.syncHelper syncContentWithUserInteraction:userInteraction];
}

- (void)syncItemsWithSuccess:(void (^)(NSInteger, BOOL))success failure:(void (^)(NSError *))failure
{
    DDLogMethod();
    __weak __typeof(self) weakSelf = self;
    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
    self.contextForSync = context;
    ReaderPostService *service = [[ReaderPostService alloc] initWithManagedObjectContext:context];
    [context performBlock:^{
        ReaderTopic *topicInContext = [self currentTopicInContext:context];
        [service fetchPostsForTopic:topicInContext earlierThan:[NSDate date] skippingSave:YES success:^(NSInteger count, BOOL hasMore) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.postIDThatInitiatedBlock = nil;
                if (success) {
                    success(count, hasMore);
                }
            });
        } failure:^(NSError *error) {
            if (failure) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    failure(error);
                });
            }
        }];
    }];
}

- (void)backfillItemsWithSuccess:(void (^)(NSInteger, BOOL))success failure:(void (^)(NSError *))failure
{
    DDLogMethod();
    __weak __typeof(self) weakSelf = self;
    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
    self.contextForSync = context;
    ReaderPostService *service = [[ReaderPostService alloc] initWithManagedObjectContext:context];
    [context performBlock:^{
        ReaderTopic *topicInContext = [self currentTopicInContext:context];
        [service backfillPostsForTopic:topicInContext skippingSave:YES success:^(NSInteger count, BOOL hasMore) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.postIDThatInitiatedBlock = nil;
                if (success) {
                    success(count, hasMore);
                }
            });
        } failure:^(NSError *error) {
            if (failure) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    failure(error);
                });
            }
        }];
    }];
}

- (void)syncHelper:(WPContentSyncHelper *)syncHelper syncContentWithUserInteraction:(BOOL)userInteraction success:(void (^)(NSInteger, BOOL))success failure:(void (^)(NSError *))failure
{
    DDLogMethod();
    self.shouldSkipRowAnimation = NO;
    if (userInteraction) {
        [self configureNoResultsView];
        [self syncItemsWithSuccess:success failure:failure];
    } else {
        [self backfillItemsWithSuccess:success failure:failure];
    }
}

- (void)syncHelper:(WPContentSyncHelper *)syncHelper syncMoreWithSuccess:(void (^)(NSInteger, BOOL))success failure:(void (^)(NSError *))failure
{
    DDLogMethod();
    if ([self.tableViewHandler.resultsController.fetchedObjects count] == 0) {
        return;
    }

    if (self.currentTopic == nil) {
        if (failure) {
            failure(nil);
        }
        return;
    }

    [self.activityFooter startAnimating];

    ReaderPost *post = self.tableViewHandler.resultsController.fetchedObjects.lastObject;
    NSDate *earlierThan = post.sortDate;

    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
    ReaderPostService *service = [[ReaderPostService alloc] initWithManagedObjectContext:context];
    __weak __typeof(self) weakSelf = self;
    
    [context performBlock:^{
        ReaderTopic *topicInContext = [self currentTopicInContext:context];
        [service fetchPostsForTopic:topicInContext earlierThan:earlierThan success:^(NSInteger count, BOOL hasMore){
            if (success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    weakSelf.shouldSkipRowAnimation = YES;
                    success(count, hasMore);
                });
            }
        } failure:^(NSError *error) {
            if (failure) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    failure(error);
                });
            }
        }];
    }];
    
    [WPAnalytics track:WPAnalyticsStatReaderInfiniteScroll withProperties:[self tagPropertyForStats]];
}

- (void)syncContentEnded
{
    if (!self.contextForSync) {
        [self cleanupAfterRefresh];
        return;
    }
    [self saveContextForSync];
}

- (void)saveContextForSync
{
    if (self.syncHelper.isSyncing) {
        return;
    }

    if (self.tableViewHandler.isScrolling) {
        return;
    }

    self.tableViewHandler.shouldRefreshTableViewPreservingOffset = YES;
    [[ContextManager sharedInstance] saveContext:self.contextForSync];
    self.contextForSync = nil;

    [self cleanupAfterRefresh];
}

- (void)cleanupAfterRefresh
{
    [self.refreshControl endRefreshing];
    [self.activityFooter stopAnimating];

    [self.noResultsView removeFromSuperview];
    if ([[self.tableViewHandler.resultsController fetchedObjects] count] == 0) {
        // This is a special case.  Core data can be a bit slow about notifying
        // NSFetchedResultsController delegates about changes to the fetched results.
        // To compensate, call configureNoResultsView after a short delay.
        // It will be redisplayed if necessary.
        [self performSelector:@selector(configureNoResultsView) withObject:self afterDelay:0.1];
    }
}


#pragma mark - WPTableViewHelper Delegate Methods

- (void)tableViewHandlerWillRefreshTableViewPreservingOffset:(WPTableViewHandler *)tableViewHandler
{
    [UIView performWithoutAnimation:^{
        [self cleanupAfterRefresh];
    }];
}

- (void)tableViewHandlerDidRefreshTableViewPreservingOffset:(WPTableViewHandler *)tableViewHandler
{
    if ([self.tableView contentOffset].y < 0) {
        [self.tableView setContentOffset:CGPointZero animated:YES];
    }
}

- (void)tableViewDidChangeContent:(UITableView *)tableView
{
    // Index paths may have changed. We don't want callbacks for stale paths.
    if (self.actionSheet) {
        // Dismiss the action sheet when content changes since the post that was tapped may have scrolled out of view or been removed.
        [self.actionSheet dismissWithClickedButtonIndex:[self.actionSheet cancelButtonIndex] animated:YES];
    }
    [self.featuredImageSource invalidateIndexPaths];
    self.tableViewHandler.updateRowAnimation = UITableViewRowAnimationNone;
    [self configureNoResultsView];

    if (self.shouldSkipRowAnimation) {
        // short circuit any row animation when loading more.
        self.shouldSkipRowAnimation = NO;
        [self.tableView reloadData];
    }
}

- (NSPredicate *)predicateForFetchRequest
{
    NSPredicate *predicate;

    if (self.postIDThatInitiatedBlock) {
        predicate = [NSPredicate predicateWithFormat:@"topic = %@ AND (isSiteBlocked = NO OR postID = %@)", self.currentTopic, self.postIDThatInitiatedBlock];
    } else {
        predicate = [NSPredicate predicateWithFormat:@"topic = %@ AND isSiteBlocked = NO", self.currentTopic];
    }

    return predicate;
}

- (NSManagedObjectContext *)managedObjectContext
{
    return [[ContextManager sharedInstance] mainContext];
}

- (NSFetchRequest *)fetchRequest
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([ReaderPost class])];
    fetchRequest.predicate = [self predicateForFetchRequest];

    NSSortDescriptor *sortDescriptorDate = [NSSortDescriptor sortDescriptorWithKey:@"sortDate" ascending:NO];
    fetchRequest.sortDescriptors = @[sortDescriptorDate];

    return fetchRequest;
}

- (void)updateAndPerformFetchRequest
{
    NSAssert([NSThread isMainThread], @"ReaderPostsViewController Error: NSFetchedResultsController accessed in BG");
    
    NSError *error = nil;
    [self.tableViewHandler.resultsController.fetchRequest setPredicate:[self predicateForFetchRequest]];
    [self.tableViewHandler.resultsController performFetch:&error];
    if (error) {
        DDLogError(@"Error fetching posts after updating the fetch request predicate: %@", error);
    }
}

- (void)configureCell:(UITableViewCell *)aCell atIndexPath:(NSIndexPath *)indexPath
{
    if (!aCell) {
        return;
    }

    ReaderPost *post = (ReaderPost *)[self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    if (post.isSiteBlocked) {
        [self configureBlockedCell:(ReaderBlockedTableViewCell *)aCell atIndexPath:indexPath];
    } else {
        [self configurePostCell:(ReaderPostTableViewCell *)aCell atIndexPath:indexPath];
    }
}

- (void)configurePostCell:(ReaderPostTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    ReaderPost *post = (ReaderPost *)[self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    BOOL shouldShowAttributionMenu = ([self isCurrentTopicFreshlyPressed] || (self.currentTopic.type != ReaderTopicTypeList)) ? YES : NO;
    cell.postView.shouldShowAttributionMenu = self.hasWPComAccount && shouldShowAttributionMenu;
    cell.postView.canShowActionButtons = self.hasWPComAccount;
    cell.postView.shouldShowAttributionButton = self.hasWPComAccount;
    [cell configureCell:post];
    [self setImageForPost:post forCell:cell indexPath:indexPath];
    [self setAvatarForPost:post forCell:cell indexPath:indexPath];

    cell.postView.delegate = self;
}

- (void)configureBlockedCell:(ReaderBlockedTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    ReaderPost *post = (ReaderPost *)[self.tableViewHandler.resultsController objectAtIndexPath:indexPath];

    NSString *str = NSLocalizedString(@"The site %@ will no longer appear in your reader. Tap to undo.", @"Message expliaining that the specified site will no longer appear in the user's reader.  The '%@' characters are a placeholder for the title of the site.");
    NSString *formattedString = [NSString stringWithFormat:str, post.blogName];
    NSRange range = [formattedString rangeOfString:post.blogName];

    NSDictionary *labelAttributes = [WPStyleGuide subtitleAttributes];
    NSDictionary *boldLabelAttributes = [WPStyleGuide subtitleAttributesBold];

    NSMutableAttributedString *attributedStr = [[NSMutableAttributedString alloc]initWithString:formattedString attributes:labelAttributes];
    [attributedStr setAttributes:boldLabelAttributes range:range];

    [cell setLabelAttributedText:attributedStr];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return [[UIView alloc] initWithFrame:CGRectZero];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if ([UIDevice isPad]) {
        return [super tableView:tableView heightForHeaderInSection:section];
    }
    return RPVCHeaderHeightPhone;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ReaderPost *post = [self.tableViewHandler.resultsController.fetchedObjects objectAtIndex:indexPath.row];
    if (post.isSiteBlocked) {
        return RPVCBlockedCellHeight;
    }
    return [UIDevice isPad] ? RPVCEstimatedRowHeightIPad : RPVCEstimatedRowHeightIPhone;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat width = [UIDevice isPad] ? WPTableViewFixedWidth : CGRectGetWidth(self.tableView.bounds);
    return [self tableView:tableView heightForRowAtIndexPath:indexPath forWidth:width];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath forWidth:(CGFloat)width
{
    ReaderPost *post = [self.tableViewHandler.resultsController.fetchedObjects objectAtIndex:indexPath.row];
    if (post.isSiteBlocked) {
        return RPVCBlockedCellHeight;
    }

    [self configureCell:self.cellForLayout atIndexPath:indexPath];
    CGSize size = [self.cellForLayout sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
    CGFloat height = ceil(size.height);
    return height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    ReaderPost *post = (ReaderPost *)[self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    if ([post isSiteBlocked]) {
        cell = [tableView dequeueReusableCellWithIdentifier:BlockedCellIdentifier];
    } else if ([post featuredImageURLForDisplay]) {
        cell = [tableView dequeueReusableCellWithIdentifier:FeaturedImageCellIdentifier];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:NoFeaturedImageCellIdentifier];
    }

    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self preloadImagesForCellsAfterIndexPath:indexPath];

    // Are we approaching the end of the table?
    if ((indexPath.section + 1 == [self.tableViewHandler numberOfSectionsInTableView:tableView]) &&
        (indexPath.row + 4 >= [self.tableViewHandler tableView:tableView numberOfRowsInSection:indexPath.section])) {

        // Only 3 rows till the end of table
        if (self.syncHelper.hasMoreContent) {
            [self.syncHelper syncMoreContent];
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([UIDevice isPad]) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }

    ReaderPost *post = [self.tableViewHandler.resultsController.fetchedObjects objectAtIndex:indexPath.row];

    if (post.isSiteBlocked) {
        [self unblockSiteForPost:post];
        return;
    }

    UIViewController *detailController = [ReaderPostDetailViewController detailControllerWithPost:post];
    [self.navigationController pushViewController:detailController animated:YES];

    [WPAnalytics track:WPAnalyticsStatReaderOpenedArticle];
}


#pragma mark - ReaderPostContentView delegate methods

- (void)postView:(ReaderPostContentView *)postView didReceiveReblogAction:(id)sender
{
    // Pass the image forward
    ReaderPostTableViewCell *cell = [ReaderPostTableViewCell cellForSubview:sender];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    ReaderPost *post = (ReaderPost *)[self.tableViewHandler.resultsController objectAtIndexPath:indexPath];

    RebloggingViewController *controller = [[RebloggingViewController alloc] initWithPost:post];
    controller.delegate = self;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)postView:(ReaderPostContentView *)postView didReceiveLikeAction:(id)sender
{
    ReaderPost *post = [self postFromCellSubview:sender];
    BOOL wasLiked = post.isLiked;
    
    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
    ReaderPostService *service = [[ReaderPostService alloc] initWithManagedObjectContext:context];
    
    [context performBlock:^{
        ReaderPost *postInContext = (ReaderPost *)[context existingObjectWithID:post.objectID error:nil];
        if (!postInContext) {
            return;
        }
        
        [service toggleLikedForPost:postInContext success:^{
            if (wasLiked) {
                return;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [WPAnalytics track:WPAnalyticsStatReaderLikedArticle];
            });
        } failure:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                DDLogError(@"Error Liking Post : %@", [error localizedDescription]);
                [postView updateActionButtons];
            });
        }];
    }];

    [postView updateActionButtons];
}

- (void)contentView:(UIView *)contentView didReceiveAttributionLinkAction:(id)sender
{
    UIButton *followButton = (UIButton *)sender;

    ReaderPost *post = [self postFromCellSubview:followButton];

    if (!post.isFollowing) {
        [WPAnalytics track:WPAnalyticsStatReaderFollowedSite];
    }

    [followButton setSelected:!post.isFollowing]; // Set it optimistically

    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
    ReaderPostService *service = [[ReaderPostService alloc] initWithManagedObjectContext:context];
    
    [context performBlock:^{
        ReaderPost *postInContext = (ReaderPost *)[context existingObjectWithID:post.objectID error:nil];
        if (!postInContext) {
            return;
        }
        
        [service toggleFollowingForPost:postInContext success:nil failure:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                DDLogError(@"Error Following Blog : %@", [error localizedDescription]);
                [followButton setSelected:post.isFollowing];                
            });
        }];
    }];
}

- (void)contentView:(UIView *)contentView didReceiveAttributionMenuAction:(id)sender
{
    ReaderPost *post = [self postFromCellSubview:sender];
    self.siteIDToBlock = post.siteID;
    self.postIDThatInitiatedBlock = post.postID;

    NSString *cancel = NSLocalizedString(@"Cancel", @"The title of a cancel button.");
    NSString *blockSite = NSLocalizedString(@"Block This Site", @"The title of a button that triggers blocking a site from the user's reader.");

    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:cancel
                                               destructiveButtonTitle:blockSite
                                                    otherButtonTitles:nil, nil];
    if ([UIDevice isPad]) {
        UIView *view = (UIView *)sender;
        [actionSheet showFromRect:view.bounds inView:view animated:YES];
    } else {
        [actionSheet showFromTabBar:self.tabBarController.tabBar];
    }

    self.actionSheet = actionSheet;
}

- (void)postView:(ReaderPostContentView *)postView didReceiveCommentAction:(id)sender
{
    ReaderPost *post = [self postFromCellSubview:sender];
    ReaderCommentsViewController *controller = [ReaderCommentsViewController controllerWithPost:post];
    [self.navigationController pushViewController:controller animated:YES];
}


#pragma mark - RebloggingViewController Delegate Methods

- (void)postWasReblogged:(ReaderPost *)post
{
    NSIndexPath *indexPath = [self.tableViewHandler.resultsController indexPathForObject:post];
    if (!indexPath) {
        return;
    }
    ReaderPostTableViewCell *cell = (ReaderPostTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [cell configureCell:post];
    [self setAvatarForPost:post forCell:cell indexPath:indexPath];
}


#pragma mark - WPTableImageSourceDelegate

- (void)tableImageSource:(WPTableImageSource *)tableImageSource imageReady:(UIImage *)image forIndexPath:(NSIndexPath *)indexPath
{
    ReaderPostTableViewCell *cell = (ReaderPostTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];

    // Don't do anything if the cell is out of view or out of range
    // (this is a safety check in case the Reader doesn't properly kill image requests when changing topics)
    if (cell == nil) {
        return;
    }

    [cell.postView setFeaturedImage:image];
}


#pragma mark - ActionSheet Delegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        self.siteIDToBlock = nil;
        self.postIDThatInitiatedBlock = nil;
        return;
    }

    [self blockSite];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    self.actionSheet = nil;
    actionSheet.delegate = nil;
}


#pragma mark - UIScrollView Delegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if ([self.refreshControl isRefreshing]) {
        [self.refreshControl endRefreshing];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (decelerate) {
        return;
    }
    if (self.contextForSync) {
        [self saveContextForSync];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (self.contextForSync) {
        [self saveContextForSync];
    }
}

@end
