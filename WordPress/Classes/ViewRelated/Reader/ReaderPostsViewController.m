#import "ReaderPostsViewController.h"

#import <AFNetworking/AFNetworking.h>

#import "AccountService.h"
#import "ContextManager.h"
#import "CustomHighlightButton.h"
#import "NSString+Helpers.h"
#import "NSString+XMLExtensions.h"
#import "ReaderBlockedTableViewCell.h"
#import "ReaderBrowseSiteViewController.h"
#import "ReaderCommentsViewController.h"
#import "ReaderPost.h"
#import "ReaderPostContentView.h"
#import "ReaderPostDetailViewController.h"
#import "ReaderPostService.h"
#import "ReaderPostTableViewCell.h"
#import "ReaderPostUnattributedTableViewCell.h"
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
#import "BlogService.h"

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
NSString * const ReaderDetailTypeKey = @"post-detail-type";
NSString * const ReaderDetailTypeNormal = @"normal";
NSString * const ReaderDetailTypePreviewSite = @"preview-site";

@interface ReaderPostsViewController ()<RebloggingViewControllerDelegate,
                                        UIActionSheetDelegate,
                                        WPContentSyncHelperDelegate,
                                        WPTableImageSourceDelegate,
                                        WPTableViewHandlerDelegate,
                                        ReaderPostContentViewDelegate>


@property (nonatomic, assign) BOOL viewHasAppeared;
@property (nonatomic, strong) WPTableImageSource *featuredImageSource;
@property (nonatomic, strong) UIActivityIndicatorView *activityFooter;
@property (nonatomic, strong) WPAnimatedBox *animatedBox;
@property (nonatomic, strong) ReaderPostTableViewCell *cellForLayout;
@property (nonatomic, strong) ReaderPost *postForMenuActionSheet;
@property (nonatomic, strong) NSMutableArray *postIDsForUndoBlockCells;
@property (nonatomic, strong) UIActionSheet *actionSheet;
@property (nonatomic, strong) WPNoResultsView *noResultsView;
@property (nonatomic, strong) WPTableViewHandler *tableViewHandler;
@property (nonatomic, strong) WPContentSyncHelper *syncHelper;
@property (nonatomic) BOOL shouldSkipRowAnimation;
@property (nonatomic) UIDeviceOrientation previousOrientation;
@property (nonatomic) BOOL hasWPComAccount;
@property (nonatomic) BOOL hasVisibleWPComAccount;

@property (nonatomic, strong) NSManagedObjectContext *contextForSync;

@end


@implementation ReaderPostsViewController

#pragma mark - Life Cycle methods

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.syncHelper.delegate = nil;
    self.tableViewHandler.delegate = nil;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        Class aClass = [self class];
        self.restorationIdentifier = NSStringFromClass(aClass);
        self.restorationClass = aClass;

        _syncHelper = [[WPContentSyncHelper alloc] init];
        _syncHelper.delegate = self;

        _postIDsForUndoBlockCells = [NSMutableArray array];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeAccount:) name:WPAccountDefaultWordPressComAccountChangedNotification object:nil];
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

    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if ([self shouldRefreshTableViewOnViewWillAppear]) {
        [self.tableView reloadData];
    }

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
        if (self.readerTopic) {
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


#pragma mark - Notifications

- (void)didChangeAccount:(NSNotification *)notification
{
    [self checkWPComAccountExists];
    [self.tableView reloadData];
}


#pragma mark - Configuration

- (BOOL)shouldRefreshTableViewOnViewWillAppear
{
    return ([self changedOrientation] || [self toggledVisibilityOfWPComAccount]);
}

- (BOOL)changedOrientation
{
    if (self.previousOrientation != UIInterfaceOrientationUnknown
        && UIInterfaceOrientationIsPortrait(self.previousOrientation) != UIInterfaceOrientationIsPortrait(self.interfaceOrientation))
    {
        [self.tableViewHandler refreshCachedRowHeightsForWidth:CGRectGetWidth(self.view.frame)];
        
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)toggledVisibilityOfWPComAccount
{
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    BOOL currentlyHasVisibleWPComAccount = [blogService hasVisibleWPComAccounts];
    
    if (self.hasVisibleWPComAccount != currentlyHasVisibleWPComAccount) {
        self.hasVisibleWPComAccount = currentlyHasVisibleWPComAccount;
        
        return YES;
    } else {
        return NO;
    }
}

- (void)checkWPComAccountExists
{
    self.hasWPComAccount = ([[[AccountService alloc] initWithManagedObjectContext:[self managedObjectContext]] defaultWordPressComAccount] != nil);
}

- (void)configureRefreshControl
{
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
}

- (Class)classForPostCell
{
    if (self.readerViewStyle == ReaderViewStyleSitePreview) {
        return [ReaderPostUnattributedTableViewCell class];
    }
    return [ReaderPostTableViewCell class];
}

- (void)configureTableView
{
    [self.tableView registerClass:[ReaderBlockedTableViewCell class] forCellReuseIdentifier:BlockedCellIdentifier];
    [self.tableView registerClass:[self classForPostCell] forCellReuseIdentifier:NoFeaturedImageCellIdentifier];
    [self.tableView registerClass:[self classForPostCell] forCellReuseIdentifier:FeaturedImageCellIdentifier];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.accessibilityIdentifier = @"Reader Table";
    
    // Note: UIEdgeInsets are not always enforced. After logging in, the table might autoscroll up to the first row.
    if (UIDevice.isPad && !self.skipIpadTopPadding) {
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
    [self.tableView registerClass:[self classForPostCell] forCellReuseIdentifier:CellIdentifier];
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

    NSRange range = [self.readerTopic.path rangeOfString:@"following"];
    if (range.location != NSNotFound) {
        return NSLocalizedString(@"You're not following any sites yet.", @"Message shown to user when the reader list is empty because they are not following any sites.");
    }

    range = [self.readerTopic.path rangeOfString:@"liked"];
    if (range.location != NSNotFound) {
        return NSLocalizedString(@"You have not liked any posts.", @"Message shown to user when the reader list is empty because they have not liked any posts.");
    }

    return NSLocalizedString(@"Sorry. No posts found.", @"Generic message shown to the user when the reader list is empty. ");
}

- (NSString *)noResultsMessageText
{
    if (self.syncHelper.isSyncing) {
        return @"";
    }
    if (self.readerViewStyle == ReaderViewStyleSitePreview) {
        return NSLocalizedString(@"We were unable to load any posts for this site.", @"Message shown when wwe were unable to load posts for a site being previewed in the reader. ");
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

- (ReaderTopic *)topicInContext:(NSManagedObjectContext *)context
{
    return [self topic:self.readerTopic inContext:context];
}

- (ReaderTopic *)topic:(ReaderTopic *)topic inContext:(NSManagedObjectContext *)context
{
    ReaderTopic *topicInContext = (ReaderTopic *)[context objectWithID:topic.objectID];
    return topicInContext;
}

- (void)setReaderTopic:(ReaderTopic *)readerTopic
{
    ReaderTopic *topic = readerTopic;
    if (!readerTopic) {
        topic = nil;

    } else {
        topic = [self topic:readerTopic inContext:[self managedObjectContext]];
    }

    if (topic == _readerTopic) {
        return;
    }

    _readerTopic = topic;
    [self readerTopicDidChange];
}

- (void)readerTopicDidChange
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

- (void)updateTitle
{
    if (self.readerTopic) {
        self.title = self.readerTopic.title;
    } else {
        self.title = NSLocalizedString(@"Reader", @"Description of the Reader tab");
    }
}

- (BOOL)isCurrentTopicFreshlyPressed
{
    return [self.readerTopic.path rangeOfString:ReaderTopicFreshlyPressedPathCommponent].location != NSNotFound;
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
    return [NSDictionary dictionaryWithObjectsAndKeys:self.readerTopic.title, @"tag", nil];
}

- (void)setTableHeaderView:(UIView *)view
{
    self.tableView.tableHeaderView = view;
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

- (void)blockSite:(ReaderPost *)post
{
    NSNumber *postID = post.postID;
    self.tableViewHandler.updateRowAnimation = UITableViewRowAnimationFade;
    [self addBlockedPostID:postID];

    __weak __typeof(self) weakSelf = self;
    ReaderSiteService *service = [[ReaderSiteService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    [service flagSiteWithID:post.siteID asBlocked:YES success:^{

    } failure:^(NSError *error) {
        weakSelf.tableViewHandler.updateRowAnimation = UITableViewRowAnimationNone;
        [weakSelf removeBlockedPostID:postID];
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
    NSNumber *postID = post.postID;
    self.tableViewHandler.updateRowAnimation = UITableViewRowAnimationFade;

    __weak __typeof(self) weakSelf = self;
    ReaderSiteService *service = [[ReaderSiteService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    [service flagSiteWithID:post.siteID asBlocked:NO success:^{
        [weakSelf removeBlockedPostID:postID];

    } failure:^(NSError *error) {
        weakSelf.tableViewHandler.updateRowAnimation = UITableViewRowAnimationNone;
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Unblocking Site", @"Title of a prompt letting the user know there was an error trying to unblock a site from appearing in the reader.")
                                                            message:[error localizedDescription]
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK", @"Text for an alert's dismissal button.")
                                                  otherButtonTitles:nil, nil];
        [alertView show];
    }];
}

- (void)addBlockedPostID:(NSNumber *)postID
{
    if ([self.postIDsForUndoBlockCells containsObject:postID]) {
        return;
    }

    [self.postIDsForUndoBlockCells addObject:postID];
    [self updateAndPerformFetchRequest];
}

- (void)removeBlockedPostID:(NSNumber *)postID
{
    if (![self.postIDsForUndoBlockCells containsObject:postID]) {
        return;
    }

    [self.postIDsForUndoBlockCells removeObject:postID];
    [self updateAndPerformFetchRequest];
}

- (void)removeAllBlockedPostIDs
{
    if ([self.postIDsForUndoBlockCells count] == 0) {
        return;
    }
    [self.postIDsForUndoBlockCells removeAllObjects];
    [self updateAndPerformFetchRequest];
}


#pragma mark - Actions

- (void)refresh
{
    [self syncItemsWithUserInteraction:YES];
}


#pragma mark - Sync methods

- (void)syncIfAppropriate
{
    // Do not start auto-sync if connection is down
    WordPressAppDelegate *appDelegate = [WordPressAppDelegate sharedInstance];
    if (appDelegate.connectionAvailable == NO) {
        return;
    }

    NSDate *lastSynced = self.readerTopic.lastSynced;
    if (lastSynced == nil || ABS([lastSynced timeIntervalSinceNow]) > RPVCRefreshInterval) {
        [self syncItemsWithUserInteraction:NO];
    }
}

- (void)syncItemsWithUserInteraction:(BOOL)userInteraction
{
    DDLogMethod();
    [self configureNoResultsView];

    if (!self.readerTopic) {
        return;
    }

    // Weird we should ever have a topic without an account but check for it just in case
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

    [self.syncHelper syncContentWithUserInteraction:userInteraction];
}

- (void)syncItemsWithSuccess:(void (^)(BOOL))success failure:(void (^)(NSError *))failure
{
    DDLogMethod();
    __weak __typeof(self) weakSelf = self;
    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
    self.contextForSync = context;
    ReaderPostService *service = [[ReaderPostService alloc] initWithManagedObjectContext:context];
    [context performBlock:^{
        ReaderTopic *topicInContext = [self topicInContext:context];
        [service fetchPostsForTopic:topicInContext earlierThan:[NSDate date] skippingSave:YES success:^(NSInteger count, BOOL hasMore) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf removeAllBlockedPostIDs];
                if (success) {
                    success(hasMore);
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

- (void)backfillItemsWithSuccess:(void (^)(BOOL))success failure:(void (^)(NSError *))failure
{
    DDLogMethod();
    __weak __typeof(self) weakSelf = self;
    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
    self.contextForSync = context;
    ReaderPostService *service = [[ReaderPostService alloc] initWithManagedObjectContext:context];
    [context performBlock:^{
        ReaderTopic *topicInContext = [self topicInContext:context];
        [service backfillPostsForTopic:topicInContext skippingSave:YES success:^(NSInteger count, BOOL hasMore) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf removeAllBlockedPostIDs];
                if (success) {
                    success(hasMore);
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

- (void)syncHelper:(WPContentSyncHelper *)syncHelper syncContentWithUserInteraction:(BOOL)userInteraction success:(void (^)(BOOL))success failure:(void (^)(NSError *))failure
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

- (void)syncHelper:(WPContentSyncHelper *)syncHelper syncMoreWithSuccess:(void (^)(BOOL))success failure:(void (^)(NSError *))failure
{
    DDLogMethod();
    if ([self.tableViewHandler.resultsController.fetchedObjects count] == 0) {
        return;
    }

    if (self.readerTopic == nil) {
        if (failure) {
            failure(nil);
        }
        return;
    }

    [self.activityFooter startAnimating];

    ReaderPost *post = self.tableViewHandler.resultsController.fetchedObjects.lastObject;
    NSDate *earlierThan = post.sortDate;

    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    ReaderPostService *service = [[ReaderPostService alloc] initWithManagedObjectContext:context];
    __weak __typeof(self) weakSelf = self;
    
    [context performBlock:^{
        ReaderTopic *topicInContext = [self topicInContext:context];
        [service fetchPostsForTopic:topicInContext earlierThan:earlierThan success:^(NSInteger count, BOOL hasMore){
            if (success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    weakSelf.shouldSkipRowAnimation = YES;
                    success(hasMore);
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

    if ([self.postIDsForUndoBlockCells count]) {
        predicate = [NSPredicate predicateWithFormat:@"topic = %@ AND (isSiteBlocked = NO OR postID IN %@)", self.readerTopic, self.postIDsForUndoBlockCells];
    } else {
        predicate = [NSPredicate predicateWithFormat:@"topic = %@ AND isSiteBlocked = NO", self.readerTopic];
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
    BOOL shouldShowAttributionMenu = ([self isCurrentTopicFreshlyPressed] || (self.readerTopic.type != ReaderTopicTypeList)) ? YES : NO;
    cell.postView.shouldShowAttributionMenu = self.hasWPComAccount && shouldShowAttributionMenu;
    cell.postView.shouldEnableLoggedinFeatures = self.hasWPComAccount;
    cell.postView.shouldShowAttributionButton = self.hasWPComAccount;
    cell.postView.shouldHideReblogButton = !self.hasVisibleWPComAccount;
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
    ReaderPost *post = [self.tableViewHandler.resultsController.fetchedObjects objectAtIndex:indexPath.row];
    if ([UIDevice isPad] || post.isSiteBlocked) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }

    if (post.isSiteBlocked) {
        [self unblockSiteForPost:post];
        return;
    }

    ReaderPostDetailViewController *detailController = [ReaderPostDetailViewController detailControllerWithPost:post];
    detailController.readerViewStyle = self.readerViewStyle;
    [self.navigationController pushViewController:detailController animated:YES];

    NSString *detailType = (self.readerViewStyle == ReaderViewStyleNormal) ? ReaderDetailTypeNormal : ReaderDetailTypePreviewSite;
    [WPAnalytics track:WPAnalyticsStatReaderOpenedArticle withProperties:@{ReaderDetailTypeKey:detailType}];
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

- (void)contentViewDidReceiveAvatarAction:(UIView *)contentView
{
    ReaderPost *post = [self postFromCellSubview:contentView];
    ReaderBrowseSiteViewController *controller = [[ReaderBrowseSiteViewController alloc] initWithPost:post];
    [self.navigationController pushViewController:controller animated:YES];
    [WPAnalytics track:WPAnalyticsStatReaderPreviewedSite];
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
    self.postForMenuActionSheet = post;

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
    ReaderPost *post = self.postForMenuActionSheet;
    self.postForMenuActionSheet = nil;
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }

    [self blockSite:post];
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
