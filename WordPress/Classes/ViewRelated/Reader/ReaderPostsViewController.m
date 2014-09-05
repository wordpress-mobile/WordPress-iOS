#import <AFNetworking/AFNetworking.h>
#import "WPTableViewControllerSubclass.h"
#import "ReaderPostsViewController.h"
#import "ReaderPostTableViewCell.h"
#import "ReaderBlockedTableViewCell.h"
#import "ReaderSubscriptionViewController.h"
#import "ReaderPostDetailViewController.h"
#import "ReaderPost.h"
#import "ReaderTopic.h"
#import "WordPressAppDelegate.h"
#import "NSString+XMLExtensions.h"
#import "WPAccount.h"
#import "WPTableImageSource.h"
#import "WPNoResultsView.h"
#import "NSString+Helpers.h"
#import "WPAnimatedBox.h"
#import "InlineComposeView.h"
#import "ReaderCommentPublisher.h"
#import "ContextManager.h"
#import "AccountService.h"
#import "RebloggingViewController.h"
#import "ReaderTopicService.h"
#import "ReaderPostService.h"
#import "CustomHighlightButton.h"
#import "UIView+Subviews.h"
#import "BlogService.h"
#import "ReaderSiteService.h"

static CGFloat const RPVCHeaderHeightPhone = 10.0;
static CGFloat const RPVCBlockedCellHeight = 66.0;
static CGFloat const RPVCEstimatedRowHeightIPhone = 400.0;
static CGFloat const RPVCEstimatedRowHeightIPad = 600.0;

NSString * const BlockedCellIdentifier = @"BlockedCellIdentifier";
NSString * const FeaturedImageCellIdentifier = @"FeaturedImageCellIdentifier";
NSString * const NoFeaturedImageCellIdentifier = @"NoFeaturedImageCellIdentifier";
NSString * const RPVCDisplayedNativeFriendFinder = @"DisplayedNativeFriendFinder";

@interface ReaderPostsViewController ()<WPTableImageSourceDelegate, ReaderCommentPublisherDelegate, RebloggingViewControllerDelegate, UIActionSheetDelegate>

@property (nonatomic, assign) BOOL hasMoreContent;
@property (nonatomic, assign) BOOL loadingMore;
@property (nonatomic, assign) BOOL viewHasAppeared;
@property (nonatomic, strong) WPTableImageSource *featuredImageSource;
@property (nonatomic, assign) CGFloat keyboardOffset;
@property (nonatomic, assign) CGFloat lastOffset;
@property (nonatomic, strong) WPAnimatedBox *animatedBox;
@property (nonatomic, strong) UIGestureRecognizer *tapOffKeyboardGesture;
@property (nonatomic, strong) InlineComposeView *inlineComposeView;
@property (nonatomic, strong) ReaderCommentPublisher *commentPublisher;
@property (nonatomic, readonly) ReaderTopic *currentTopic;
@property (nonatomic, strong) ReaderPostTableViewCell *cellForLayout;
@property (nonatomic, strong) NSLayoutConstraint *cellForLayoutWidthConstraint;
@property (nonatomic) BOOL infiniteScrollEnabled;
@property (nonatomic, strong) NSMutableDictionary *cachedRowHeights;
@property (nonatomic, strong) NSNumber *siteIDToBlock;
@property (nonatomic, strong) NSNumber *postIDThatInitiatedBlock;
@property (nonatomic, strong) UIActionSheet *actionSheet;

@end

@implementation ReaderPostsViewController

#pragma mark - Life Cycle methods

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    return [[WordPressAppDelegate sharedWordPressApplicationDelegate] readerPostsViewController];
}

- (void)dealloc
{
    self.featuredImageSource.delegate = nil;
    self.inlineComposeView.delegate = nil;
    self.inlineComposeView = nil;
    self.commentPublisher = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _hasMoreContent = YES;
        _infiniteScrollEnabled = YES;

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeAccount:) name:WPAccountDefaultWordPressComAccountChangedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(readerTopicDidChange:) name:ReaderTopicDidChangeNotification object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.cachedRowHeights = [NSMutableDictionary dictionary];

    [self configureCellSeparatorStyle];

    self.incrementalLoadingSupported = YES;

    [self.tableView registerClass:[ReaderBlockedTableViewCell class] forCellReuseIdentifier:BlockedCellIdentifier];
    [self.tableView registerClass:[ReaderPostTableViewCell class] forCellReuseIdentifier:NoFeaturedImageCellIdentifier];
    [self.tableView registerClass:[ReaderPostTableViewCell class] forCellReuseIdentifier:FeaturedImageCellIdentifier];

    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;

    [self configureCellForLayout];

    CGFloat maxWidth;
    if (IS_IPHONE) {
        maxWidth = MAX(CGRectGetWidth(self.tableView.bounds), CGRectGetHeight(self.tableView.bounds));
    } else {
        maxWidth = WPTableViewFixedWidth;
    }

    CGFloat maxHeight = maxWidth * WPContentViewMaxImageHeightPercentage;
    self.featuredImageSource = [[WPTableImageSource alloc] initWithMaxSize:CGSizeMake(maxWidth, maxHeight)];
    self.featuredImageSource.delegate = self;

    // Topics button
    UIBarButtonItem *button = nil;
    CustomHighlightButton *topicsButton = [CustomHighlightButton buttonWithType:UIButtonTypeCustom];
    topicsButton.tintColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    [topicsButton setImage:[UIImage imageNamed:@"icon-reader-topics"] forState:UIControlStateNormal];

    CGSize imageSize = [UIImage imageNamed:@"icon-reader-topics"].size;
    topicsButton.frame = CGRectMake(0.0, 0.0, imageSize.width, imageSize.height);
    topicsButton.contentEdgeInsets = UIEdgeInsetsMake(0, 16, 0, -16);

    [topicsButton addTarget:self action:@selector(topicsAction:) forControlEvents:UIControlEventTouchUpInside];
    button = [[UIBarButtonItem alloc] initWithCustomView:topicsButton];
    [button setAccessibilityLabel:NSLocalizedString(@"Browse", @"")];
    self.navigationItem.rightBarButtonItem = button;

    // replace the back button of future child view controllers
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@" "
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:nil
                                                                  action:nil];

    self.navigationItem.backBarButtonItem = backButton;

    self.tapOffKeyboardGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                         action:@selector(dismissKeyboard:)];

    self.inlineComposeView = [[InlineComposeView alloc] initWithFrame:CGRectZero];
    [self.inlineComposeView setButtonTitle:NSLocalizedString(@"Post", nil)];
    self.commentPublisher = [[ReaderCommentPublisher alloc] initWithComposer:self.inlineComposeView];

    self.commentPublisher.delegate = self;

    self.tableView.tableFooterView = self.inlineComposeView;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self updateTitle];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardDidShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

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
    [self.inlineComposeView endEditing:YES];
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // Remove the no results view or else the position will abruptly adjust after rotation
    // due to the table view sizing for image preloading
    [self.noResultsView removeFromSuperview];

    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self configureNoResultsView];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    CGFloat width;
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
        width = CGRectGetWidth(self.tableView.window.frame);
    } else {
        width = CGRectGetHeight(self.tableView.window.frame);
    }
    [self updateCellForLayoutWidthConstraint:width];
    if (IS_IPHONE) {
        [self.cachedRowHeights removeAllObjects];
    }
}

#pragma mark - Instance Methods

- (void)configureCellSeparatorStyle
{
    // Setting the separator style will cause the table view to redraw all its cells.
    // We want to avoid this when we first load the tableview as there is a performance
    // cost.  As a work around, unset the delegate and datasource, and restore them
    // after setting the style.
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (void)configureCellForLayout
{
    NSString *CellIdentifier = @"CellForLayoutIdentifier";
    [self.tableView registerClass:[ReaderPostTableViewCell class] forCellReuseIdentifier:CellIdentifier];
    self.cellForLayout = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    [self updateCellForLayoutWidthConstraint:CGRectGetWidth(self.tableView.bounds)];
}

- (void)updateCellForLayoutWidthConstraint:(CGFloat)width
{
    UIView *contentView = self.cellForLayout.contentView;
    if (self.cellForLayoutWidthConstraint) {
        [contentView removeConstraint:self.cellForLayoutWidthConstraint];
    }
    NSDictionary *views = NSDictionaryOfVariableBindings(contentView);
    NSDictionary *metrics = @{@"width":@(width)};
    self.cellForLayoutWidthConstraint = [[NSLayoutConstraint constraintsWithVisualFormat:@"[contentView(width)]"
                                                                             options:0
                                                                             metrics:metrics
                                                                               views:views] firstObject];
    [contentView addConstraint:self.cellForLayoutWidthConstraint];
}

- (ReaderTopic *)currentTopic
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    return [[[ReaderTopicService alloc] initWithManagedObjectContext:context] currentTopic];
}

- (void)updateTitle
{
    if (self.currentTopic) {
        self.title = [self.currentTopic.title capitalizedString];
    } else {
        self.title = NSLocalizedString(@"Reader", @"Default title for the reader before topics are loaded the first time.");
    }
}

- (void)setTitle:(NSString *)title
{
    [super setTitle:title];

    // Reset the tab bar title; this isn't a great solution, but works
    NSInteger tabIndex = [self.tabBarController.viewControllers indexOfObject:self.navigationController];
    UITabBarItem *tabItem = [[[self.tabBarController tabBar] items] objectAtIndex:tabIndex];
    tabItem.title = NSLocalizedString(@"Reader", @"Description of the Reader tab");
}

- (void)handleKeyboardDidShow:(NSNotification *)notification
{
    if (self.inlineComposeView.isDisplayed) {
        return;
    }

    UIView *view = self.view.superview;
    CGRect frame = view.frame;
    CGRect startFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGRect endFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];

    // Figure out the difference between the bottom of this view, and the top of the keyboard.
    // This should account for any toolbars.
    CGPoint point = [view.window convertPoint:startFrame.origin toView:view];
    self.keyboardOffset = point.y - (frame.origin.y + frame.size.height);

    // if we're upside down, we need to adjust the origin.
    if (endFrame.origin.x == 0 && endFrame.origin.y == 0) {
        endFrame.origin.y = endFrame.origin.x += MIN(endFrame.size.height, endFrame.size.width);
    }

    point = [view.window convertPoint:endFrame.origin toView:view];
    CGSize tabBarSize = [self tabBarSize];
    frame.size.height = point.y + tabBarSize.height;

    [UIView animateWithDuration:0.3f delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        view.frame = frame;
    } completion:^(BOOL finished) {
        // BUG: When dismissing a modal view, and the keyboard is showing again, the animation can get clobbered in some cases.
        // When this happens the view is set to the dimensions of its wrapper view, hiding content that should be visible
        // above the keyboard.
        // For now use a fallback animation.
        if (!CGRectEqualToRect(view.frame, frame)) {
            [UIView animateWithDuration:0.3 animations:^{
                view.frame = frame;
            }];
        }
    }];
}

- (void)handleKeyboardWillHide:(NSNotification *)notification
{
    if (self.inlineComposeView.isDisplayed) {
        return;
    }

    UIView *view = self.view.superview;
    CGRect frame = view.frame;
    CGRect keyFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];

    CGPoint point = [view.window convertPoint:keyFrame.origin toView:view];
    frame.size.height = point.y - (frame.origin.y + self.keyboardOffset);
    view.frame = frame;
}

- (ReaderPost *)postFromCellSubview:(UIView *)subview
{
    ReaderPostTableViewCell *cell = [ReaderPostTableViewCell cellForSubview:subview];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    ReaderPost *post = (ReaderPost *)[self.resultsController objectAtIndexPath:indexPath];
    return post;
}

- (void)blockSite
{
    if (!self.siteIDToBlock) {
        return;
    }

    NSNumber *siteIDToBlock = self.siteIDToBlock;
    self.siteIDToBlock = nil;

    [self.cachedRowHeights removeAllObjects];
    NSManagedObjectContext *derivedContext = [[ContextManager sharedInstance] newDerivedContext];
    ReaderSiteService *service = [[ReaderSiteService alloc] initWithManagedObjectContext:derivedContext];
    [service flagSiteWithID:siteIDToBlock asBlocked:YES success:^{
        // Nothing to do.
    } failure:^(NSError *error) {
        self.postIDThatInitiatedBlock = nil;
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
    [self.cachedRowHeights removeAllObjects];
    NSManagedObjectContext *derivedContext = [[ContextManager sharedInstance] newDerivedContext];
    ReaderSiteService *service = [[ReaderSiteService alloc] initWithManagedObjectContext:derivedContext];
    [service flagSiteWithID:post.siteID asBlocked:NO success:^{
        // Nothing to do.
        self.postIDThatInitiatedBlock = nil;
    } failure:^(NSError *error) {
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

    [self.cachedRowHeights removeAllObjects];
    NSError *error;
    [self.resultsController.fetchRequest setPredicate:[self predicateForFetchRequest]];
    [self.resultsController performFetch:&error];
    if (error) {
        DDLogError(@"Error fetching posts after updating the fetch request predicate: %@", error);
    }
}


#pragma mark - ReaderPostContentView delegate methods

- (void)postView:(ReaderPostContentView *)postView didReceiveReblogAction:(id)sender
{
    // Pass the image forward
    ReaderPostTableViewCell *cell = [ReaderPostTableViewCell cellForSubview:sender];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    ReaderPost *post = (ReaderPost *)[self.resultsController objectAtIndexPath:indexPath];

    RebloggingViewController *controller = [[RebloggingViewController alloc] initWithPost:post];
    controller.delegate = self;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)postView:(ReaderPostContentView *)postView didReceiveLikeAction:(id)sender
{
    ReaderPostTableViewCell *cell = [ReaderPostTableViewCell cellForSubview:sender];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    ReaderPost *post = (ReaderPost *)[self.resultsController objectAtIndexPath:indexPath];

    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
    ReaderPostService *service = [[ReaderPostService alloc] initWithManagedObjectContext:context];
    [service toggleLikedForPost:post success:^{
        if (post.isLiked) {
            [WPAnalytics track:WPAnalyticsStatReaderLikedArticle];
        }
    } failure:^(NSError *error) {
        DDLogError(@"Error Liking Post : %@", [error localizedDescription]);
        [postView updateActionButtons];
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
    [service toggleFollowingForPost:post success:^{
        //noop
    } failure:^(NSError *error) {
        DDLogError(@"Error Following Blog : %@", [error localizedDescription]);
        [followButton setSelected:post.isFollowing];
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
    if (IS_IPHONE) {
        [actionSheet showFromTabBar:self.tabBarController.tabBar];
    } else {
        UIView *view = (UIView *)sender;
        [actionSheet showFromRect:view.bounds inView:view animated:YES];
    }

    self.actionSheet = actionSheet;
}

- (void)postView:(ReaderPostContentView *)postView didReceiveCommentAction:(id)sender
{
    [self.view addGestureRecognizer:self.tapOffKeyboardGesture];

    ReaderPostTableViewCell *cell = [ReaderPostTableViewCell cellForSubview:sender];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    ReaderPost *post = (ReaderPost *)[self.resultsController objectAtIndexPath:indexPath];

    if (self.commentPublisher.post == post) {
        [self.inlineComposeView toggleComposer];
        return;
    }

    self.commentPublisher.post = post;
    [self.inlineComposeView displayComposer];

    // scroll the item into view if possible
    [self.tableView scrollToRowAtIndexPath:indexPath
                          atScrollPosition:UITableViewScrollPositionTop
                                  animated:YES];
}

#pragma mark - RebloggingViewController Delegate Methods

- (void)postWasReblogged:(ReaderPost *)post
{
    NSIndexPath *indexPath = [self.resultsController indexPathForObject:post];
    if (!indexPath) {
        return;
    }
    ReaderPostTableViewCell *cell = (ReaderPostTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [cell configureCell:post];
    [self setAvatarForPost:post forCell:cell indexPath:indexPath];
}

#pragma mark - Actions

- (void)topicsAction:(id)sender
{
    ReaderSubscriptionViewController *controller = [[ReaderSubscriptionViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
    navController.navigationBar.translucent = NO;
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)dismissKeyboard:(id)sender
{
    for (UIGestureRecognizer *gesture in self.view.gestureRecognizers) {
        if ([gesture isEqual:self.tapOffKeyboardGesture]) {
            [self.view removeGestureRecognizer:gesture];
        }
    }

    [self.inlineComposeView toggleComposer];
}

#pragma mark - ReaderCommentPublisherDelegate Methods

- (void)commentPublisherDidPublishComment:(ReaderCommentPublisher *)publisher
{
    [WPAnalytics track:WPAnalyticsStatReaderCommentedOnArticle];
    publisher.post.dateCommentsSynced = nil;
    [self.inlineComposeView dismissComposer];
}

- (void)openPost:(NSNumber *)postId onBlog:(NSNumber *)blogId
{
    ReaderPostDetailViewController *controller = [ReaderPostDetailViewController detailControllerWithPostID:postId siteID:blogId];
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark - WPTableViewSublass methods

- (void)configureNoResultsView
{
    if (!self.isViewLoaded) {
        return;
    }

    [self.noResultsView removeFromSuperview];

    // Refresh the NoResultsView Properties
    self.noResultsView.titleText        = self.noResultsTitleText;
    self.noResultsView.messageText      = self.noResultsMessageText;
    self.noResultsView.accessoryView    = self.noResultsAccessoryView;
    self.noResultsView.buttonTitle      = self.noResultsButtonText;

    if (!self.resultsController || (self.resultsController.fetchedObjects.count > 0)) {
        return;
    }

    // only add and animate no results view if it isn't already
    // in the table view
    if (![self.noResultsView isDescendantOfView:self.tableView]) {
        [self.tableView addSubviewWithFadeAnimation:self.noResultsView];
    } else {
        [self.noResultsView centerInSuperview];
    }
}

- (NSString *)noResultsTitleText
{
    if (self.isSyncing) {
        return NSLocalizedString(@"Fetching posts...", @"A brief prompt shown when the reader is empty, letting the user know the app is currently fetching new posts.");
    }

    NSRange range = [self.currentTopic.path rangeOfString:@"following"];
    if (range.location != NSNotFound) {
        return NSLocalizedString(@"You're not following any sites yet.", @"");
    }

    range = [self.currentTopic.path rangeOfString:@"liked"];
    if (range.location != NSNotFound) {
        return NSLocalizedString(@"You have not liked any posts.", @"");
    }

    return NSLocalizedString(@"Sorry. No posts yet.", @"");
}

- (NSString *)noResultsMessageText
{
    if (self.isSyncing) {
        return @"";
    }
    return NSLocalizedString(@"Tap the tag icon to browse posts from popular sites.", nil);
}

- (UIView *)noResultsAccessoryView
{
    if (!self.animatedBox) {
        self.animatedBox = [WPAnimatedBox new];
    }
    return self.animatedBox;
}

- (NSString *)entityName
{
    return @"ReaderPost";
}

- (NSDate *)lastSyncDate
{
    return self.currentTopic.lastSynced;
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

- (NSFetchRequest *)fetchRequest
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[self entityName]];
    fetchRequest.predicate = [self predicateForFetchRequest];

    NSSortDescriptor *sortDescriptorDate = [NSSortDescriptor sortDescriptorWithKey:@"sortDate" ascending:NO];
    fetchRequest.sortDescriptors = @[sortDescriptorDate];
    fetchRequest.fetchBatchSize = 20;
    return fetchRequest;
}

- (NSString *)sectionNameKeyPath
{
    return nil;
}

- (Class)cellClass
{
    return [ReaderPostTableViewCell class];
}

- (void)configureCell:(UITableViewCell *)aCell atIndexPath:(NSIndexPath *)indexPath
{
    if (!aCell) {
        return;
    }

    ReaderPost *post = (ReaderPost *)[self.resultsController objectAtIndexPath:indexPath];
    if (post.isSiteBlocked) {
        [self configureBlockedCell:(ReaderBlockedTableViewCell *)aCell atIndexPath:indexPath];
    } else {
        [self configurePostCell:(ReaderPostTableViewCell *)aCell atIndexPath:indexPath];
    }
}

- (void)configurePostCell:(ReaderPostTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    ReaderPost *post = (ReaderPost *)[self.resultsController objectAtIndexPath:indexPath];
    BOOL shouldShowAttributionMenu = ([self isCurrentTopicFreshlyPressed] || (self.currentTopic.type != ReaderTopicTypeList)) ? YES : NO;
    cell.postView.shouldShowAttributionMenu = shouldShowAttributionMenu;
    [cell configureCell:post];
    [self setImageForPost:post forCell:cell indexPath:indexPath];
    [self setAvatarForPost:post forCell:cell indexPath:indexPath];

    cell.postView.delegate = self;
}

- (void)configureBlockedCell:(ReaderBlockedTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    ReaderPost *post = (ReaderPost *)[self.resultsController objectAtIndexPath:indexPath];

    NSString *str = NSLocalizedString(@"The site %@ will no longer appear in your reader. Tap to undo.", @"Message expliaining that the specified site will no longer appear in the user's reader.  The '%@' characters are a placeholder for the title of the site.");
    NSString *formattedString = [NSString stringWithFormat:str, post.blogName];
    NSRange range = [formattedString rangeOfString:post.blogName];

    NSDictionary *labelAttributes = [WPStyleGuide subtitleAttributes];
    NSDictionary *boldLabelAttributes = [WPStyleGuide subtitleAttributesBold];

    NSMutableAttributedString *attributedStr = [[NSMutableAttributedString alloc]initWithString:formattedString attributes:labelAttributes];
    [attributedStr setAttributes:boldLabelAttributes range:range];

    [cell setLabelAttributedText:attributedStr];
}


- (CGSize)sizeForFeaturedImage
{
    CGSize imageSize = CGSizeZero;
    imageSize.width = IS_IPAD ? WPTableViewFixedWidth : CGRectGetWidth(self.tableView.bounds);
    imageSize.height = round(imageSize.width * WPContentViewMaxImageHeightPercentage);
    return imageSize;
}

- (void)preloadImagesForCellsAfterIndexPath:(NSIndexPath *)indexPath
{
    NSInteger numberToPreload = 2; // keep the number small else they compete and slow each other down.
    for (NSInteger i = 1; i <= numberToPreload; i++) {
        NSIndexPath *nextIndexPath = [NSIndexPath indexPathForRow:indexPath.row + i inSection:indexPath.section];
        if ([self.tableView numberOfRowsInSection:indexPath.section] > nextIndexPath.row) {
            ReaderPost *post = (ReaderPost *)[self.resultsController objectAtIndexPath:nextIndexPath];
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
        [self.featuredImageSource fetchImageForURL:imageURL
                                          withSize:[self sizeForFeaturedImage]
                                         indexPath:indexPath
                                         isPrivate:post.isPrivate];
    }
}

- (void)syncItems
{
    AccountService *service = [[AccountService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    if ([service numberOfAccounts] > 0) {
        [super syncItems];
    } else {
        [self configureNoResultsView];
    }
}

- (void)syncItemsViaUserInteraction:(BOOL)userInteraction success:(void (^)())success failure:(void (^)(NSError *))failure
{
    DDLogMethod();
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];

    if (!self.currentTopic) {
        ReaderTopicService *topicService = [[ReaderTopicService alloc] initWithManagedObjectContext:context];
        [topicService fetchReaderMenuWithSuccess:^{
            // Changing the topic means we need to also change the fetch request.
            [self resetResultsController];
            [self updateTitle];
            [self syncReaderItemsWithSuccess:success failure:failure];
        } failure:^(NSError *error) {
            failure(error);
        }];
        return;
    }

    if (userInteraction) {
        [self syncReaderItemsWithSuccess:success failure:failure];
    } else {
        [self backfillReaderItemsWithSuccess:success failure:failure];
    }
}

- (void)backfillReaderItemsWithSuccess:(void (^)())success failure:(void (^)(NSError *))failure
{
    DDLogMethod();

    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
    ReaderPostService *service = [[ReaderPostService alloc] initWithManagedObjectContext:context];
    [service backfillPostsForTopic:self.currentTopic success:^(BOOL hasMore) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.postIDThatInitiatedBlock = nil;
            if (success) {
                success();
            }
        });
    } failure:^(NSError *error) {
        if (failure) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(error);
            });
        }
    }];
}

- (void)syncReaderItemsWithSuccess:(void (^)())success failure:(void (^)(NSError *))failure
{
    DDLogMethod();

    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
    ReaderPostService *service = [[ReaderPostService alloc] initWithManagedObjectContext:context];
    [service fetchPostsForTopic:self.currentTopic earlierThan:[NSDate date] success:^(BOOL hasMore) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.postIDThatInitiatedBlock = nil;
            if (success) {
                success();
            }
        });
    } failure:^(NSError *error) {
        if (failure) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(error);
            });
        }
    }];
}

- (void)loadMoreWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure
{
    DDLogMethod();
    if ([self.resultsController.fetchedObjects count] == 0) {
        return;
    }

    if (self.loadingMore) {
        return;
    }

    if (self.currentTopic == nil) {
        if (failure) {
            failure(nil);
        }
        return;
    }

    self.loadingMore = YES;

    ReaderPost *post = self.resultsController.fetchedObjects.lastObject;
    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];

    ReaderPostService *service = [[ReaderPostService alloc] initWithManagedObjectContext:context];
    [service fetchPostsForTopic:self.currentTopic earlierThan:post.sortDate success:^(BOOL hasMore){
        if (success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                success();
            });
        }
        [self onSyncSuccess:hasMore];
    } failure:^(NSError *error) {
        if (failure) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(error);
            });
        }
    }];

    [WPAnalytics track:WPAnalyticsStatReaderInfiniteScroll withProperties:[self tagPropertyForStats]];
}

- (UITableViewRowAnimation)tableViewRowAnimation
{
    return UITableViewRowAnimationNone;
}

- (void)onSyncSuccess:(BOOL)hasMore
{
    DDLogMethod();
    self.loadingMore = NO;
    self.hasMoreContent = hasMore;
}

#pragma mark - TableView Methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    ReaderPost *post = (ReaderPost *)[self.resultsController objectAtIndexPath:indexPath];
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

- (void)cacheHeight:(CGFloat)height forIndexPath:(NSIndexPath *)indexPath
{
    NSString *key = [NSString stringWithFormat:@"%i", indexPath.row];
    [self.cachedRowHeights setObject:@(height) forKey:key];
}

- (NSNumber *)cachedHeightForIndexPath:(NSIndexPath *)indexPath
{
    NSString *key = [NSString stringWithFormat:@"%i", indexPath.row];
    return [self.cachedRowHeights numberForKey:key];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSNumber *height = [self cachedHeightForIndexPath:indexPath];
    if (height) {
        return [height floatValue];
    }

    ReaderPost *post = [self.resultsController.fetchedObjects objectAtIndex:indexPath.row];
    if (post.isSiteBlocked) {
        return RPVCBlockedCellHeight;
    }
    return IS_IPAD ? RPVCEstimatedRowHeightIPad : RPVCEstimatedRowHeightIPhone;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSNumber *cachedHeight = [self cachedHeightForIndexPath:indexPath];
    if (cachedHeight) {
        return [cachedHeight floatValue];
    }

    ReaderPost *post = [self.resultsController.fetchedObjects objectAtIndex:indexPath.row];
    if (post.isSiteBlocked) {
        return RPVCBlockedCellHeight;
    }

    [self configureCell:self.cellForLayout atIndexPath:indexPath];
    CGFloat width = IS_IPAD ? WPTableViewFixedWidth : CGRectGetWidth(self.tableView.bounds);
    CGSize size = [self.cellForLayout sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
    CGFloat height = ceil(size.height) + 1;

    [self cacheHeight:height forIndexPath:indexPath];
    return height;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return [[UIView alloc] initWithFrame:CGRectZero];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (IS_IPHONE) {
        return RPVCHeaderHeightPhone;
    }
    return [super tableView:tableView heightForHeaderInSection:section];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (IS_IPAD) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }

	ReaderPost *post = [self.resultsController.fetchedObjects objectAtIndex:indexPath.row];

    if (post.isSiteBlocked) {
        [self unblockSiteForPost:post];
        return;
    }

    UIViewController *detailController = [ReaderPostDetailViewController detailControllerWithPost:post];
    [self.navigationController pushViewController:detailController animated:YES];

    [WPAnalytics track:WPAnalyticsStatReaderOpenedArticle];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
    // Preload here to avoid unnecessary preload calls when fetching cells for reasons other than for display.
    [self preloadImagesForCellsAfterIndexPath:indexPath];
}

#pragma mark - NSFetchedResultsController overrides

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    // Do nothing (prevent superclass from adjusting table view)
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    // Index paths may have changed. We don't want callbacks for stale paths.
    if (self.actionSheet) {
        // Dismiss the action sheet when content changes since the post that was tapped may have scrolled out of view or been removed.
        [self.actionSheet dismissWithClickedButtonIndex:[self.actionSheet cancelButtonIndex] animated:YES];
    }
    [self.featuredImageSource invalidateIndexPaths];
    [self.tableView reloadData];
    [self configureNoResultsView];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    if (type == NSFetchedResultsChangeInsert || type == NSFetchedResultsChangeDelete) {
        [self.cachedRowHeights removeAllObjects];
    }
    // Do not call super. (prevent superclass from adjusting table view)
}

#pragma mark - Notifications

- (void)readerTopicDidChange:(NSNotification *)notification
{
    [self updateTitle];

    self.loadingMore = NO;
    self.hasMoreContent = YES;

    [self.tableView setContentOffset:CGPointMake(0, 0) animated:NO];

    [self.cachedRowHeights removeAllObjects];
    [self resetResultsController];
    [self.tableView reloadData];
    [self syncItems];

    [WPAnalytics track:WPAnalyticsStatReaderLoadedTag withProperties:[self tagPropertyForStats]];
    if ([self isCurrentTopicFreshlyPressed]) {
        [WPAnalytics track:WPAnalyticsStatReaderLoadedFreshlyPressed];
    }
}

#pragma mark - WPAccount Notifications

- (void)didChangeAccount:(NSNotification *)notification
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    [[[ReaderTopicService alloc] initWithManagedObjectContext:context] deleteAllTopics];
    [[[ReaderPostService alloc] initWithManagedObjectContext:context] deletePostsWithNoTopic];

    [self resetResultsController];
    [self.tableView reloadData];
    [self.navigationController popToViewController:self animated:NO];

    if ([self isViewLoaded]) {
        [self syncItems];
    }
}

#pragma mark - Utility

- (BOOL)isCurrentTopicFreshlyPressed
{
    return [self.currentTopic.path rangeOfString:@"freshly-pressed"].location != NSNotFound;
}

- (NSDictionary *)tagPropertyForStats
{
    return @{@"tag": self.currentTopic.title};
}

- (CGSize)tabBarSize
{
    CGSize tabBarSize = CGSizeZero;
    if ([self tabBarController]) {
        tabBarSize = [[[self tabBarController] tabBar] bounds].size;
    }

    return tabBarSize;
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

@end
