#import "ReaderCommentsViewController.h"

#import "CommentService.h"
#import "CoreDataStack.h"
#import "ReaderPost.h"
#import "ReaderPostService.h"
#import "UIView+Subviews.h"
#import "WPTableViewHandler.h"
#import "WordPress-Swift.h"
#import "WPAppAnalytics.h"

@class Comment;

// NOTE: We want the cells to have a rather large estimated height.  This avoids a peculiar
// crash in certain circumstances when the tableView lays out its visible cells,
// and those cells contain WPRichTextEmbeds. -- Aerych, 2016.11.30
static CGFloat const EstimatedCommentRowHeight = 300.0;
static NSString *CommentContentCellIdentifier = @"CommentContentTableViewCell";


@interface ReaderCommentsViewController () <NSFetchedResultsControllerDelegate,
                                            WPRichContentViewDelegate, // TODO: Remove once we switch to the `.web` rendering method.
                                            WPContentSyncHelperDelegate,
                                            ReaderCommentsFollowPresenterDelegate>

@property (nonatomic, strong, readwrite) ReaderPost *post;
@property (nonatomic, strong) NSNumber *postSiteID;
@property (nonatomic, strong) WPContentSyncHelper *syncHelper;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) WPTableViewHandler *tableViewHandler;
@property (nonatomic, strong) NoResultsViewController *noResultsViewController;
@property (nonatomic, strong) UIView *buttonComment;
@property (nonatomic, strong) NSLayoutConstraint *replyTextViewHeightConstraint;
@property (nonatomic, strong) NSCache *estimatedRowHeights;
@property (nonatomic) BOOL isLoggedIn;
@property (nonatomic) BOOL needsUpdateAttachmentsAfterScrolling;
@property (nonatomic) BOOL needsRefreshTableViewAfterScrolling;
@property (nonatomic, strong) NSError *fetchCommentsError;
@property (nonatomic) BOOL userInterfaceStyleChanged;
@property (nonatomic, strong) NSCache *cachedAttributedStrings;
@property (nonatomic, strong) FollowCommentsService *followCommentsService;
@property (nonatomic, strong) ReaderCommentsFollowPresenter *readerCommentsFollowPresenter;
@property (nonatomic, strong) UIBarButtonItem *followBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *subscriptionSettingsBarButtonItem;
@property (nonatomic, strong) ReaderCommentsHelper *helper;

/// A cached instance for the new comment header view.
@property (nonatomic, strong) UIView *cachedHeaderView;

/// Convenience computed variable that returns a separator inset that "hides" the separator by pushing it off the screen.
@property (nonatomic, assign) UIEdgeInsets hiddenSeparatorInsets;

@property (nonatomic, strong) NSIndexPath *highlightedIndexPath;

@property (nonatomic, strong) ReaderCommentsTableViewController *tableViewController;

@end


@implementation ReaderCommentsViewController

#pragma mark - Static Helpers

+ (instancetype)controllerWithPost:(ReaderPost *)post source:(ReaderCommentsSource)source
{
    ReaderCommentsViewController *controller = [[self alloc] init];
    controller.post = post;
    controller.source = source;
    return controller;
}

+ (instancetype)controllerWithPostID:(NSNumber *)postID siteID:(NSNumber *)siteID source:(ReaderCommentsSource)source
{
    ReaderCommentsViewController *controller = [[self alloc] init];
    [controller setupWithPostID:postID siteID:siteID];
    [controller trackCommentsOpenedWithPostID:postID siteID:siteID source:source];
    return controller;
}

#pragma mark - LifeCycle Methods

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.estimatedRowHeights = [[NSCache alloc] init];
    self.cachedAttributedStrings = [[NSCache alloc] init];

    self.tableViewController = [ReaderCommentsTableViewController new];
    [self configureTableViewController:self.tableViewController];

    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.commentModified = NO;
    self.helper = [ReaderCommentsHelper new];

    [self checkIfLoggedIn];

    [self configureNavbar];
    [self configureTableViewHandler];
    [self configureNoResultsView];
    [self configureCommentButton];
    [self configureViewConstraints];

    [self listenForClipboardChanges];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];

    [self refreshAndSync];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self dismissNotice];
    
    if (self.commentModified) {
        // Don't post the notification until the view is being dismissed to avoid purging cached comments prematurely.
        [self postCommentModifiedNotification];
    }

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    [self.tableViewController setBottomInset:self.buttonComment.frame.size.height];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];

    // Update cached attributed strings when toggling light/dark mode.
    self.userInterfaceStyleChanged = self.traitCollection.userInterfaceStyle != previousTraitCollection.userInterfaceStyle;
    [self refreshTableViewAndNoResultsView];
}

#pragma mark - Split View Support

/**
 We need to refresh media layout when the app's size changes due the the user adjusting
 the split view grip. Respond to the UIApplicationDidBecomeActiveNotification notification
 dispatched when the grip is changed and refresh media layout.
 */
- (void)handleApplicationDidBecomeActive:(NSNotification *)notification
{
    [self.view layoutIfNeeded];
}

#pragma mark - Tracking methods

- (void)trackCommentLikedOrUnliked:(Comment *) comment {
    ReaderPost *post = self.post;
    WPAnalyticsStat stat;
    if (comment.isLiked) {
        stat = WPAnalyticsStatReaderArticleCommentLiked;
    } else {
        stat = WPAnalyticsStatReaderArticleCommentUnliked;
    }

    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    properties[WPAppAnalyticsKeyPostID] = post.postID;
    properties[WPAppAnalyticsKeyBlogID] = post.siteID;
    [WPAnalytics trackReaderStat:stat properties:properties];
}

- (void)trackReplyTo:(BOOL)replyTarget {
    ReaderPost *post = self.post;
    NSDictionary *railcar = post.railcarDictionary;
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    properties[WPAppAnalyticsKeyBlogID] = post.siteID;
    properties[WPAppAnalyticsKeyPostID] = post.postID;
    properties[WPAppAnalyticsKeyIsJetpack] = @(post.isJetpack);
    properties[WPAppAnalyticsKeyReplyingTo] = replyTarget ? @"comment" : @"post";
    if (post.feedID && post.feedItemID) {
        properties[WPAppAnalyticsKeyFeedID] = post.feedID;
        properties[WPAppAnalyticsKeyFeedItemID] = post.feedItemID;
    }
    [WPAnalytics trackReaderStat:WPAnalyticsStatReaderArticleCommentedOn properties:properties];
    if (railcar) {
        [WPAppAnalytics trackTrainTracksInteraction:WPAnalyticsStatTrainTracksInteract withProperties:railcar];
    }
}

#pragma mark - Configuration

- (void)configureNavbar
{
    // Don't show 'Reader' in the next-view back button
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@" " style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem = backButton;

    self.title = NSLocalizedString(@"Comments", @"Title of the reader's comments screen");
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;

    [self refreshFollowButton];
}

- (void)configureTableViewHandler
{
    self.tableView = [UITableView new];
    self.tableViewHandler = [[WPTableViewHandler alloc] initWithTableView:self.tableView];
    self.tableViewHandler.updateRowAnimation = UITableViewRowAnimationNone;
    self.tableViewHandler.insertRowAnimation = UITableViewRowAnimationNone;
    self.tableViewHandler.moveRowAnimation = UITableViewRowAnimationNone;
    self.tableViewHandler.deleteRowAnimation = UITableViewRowAnimationNone;
    [self.tableViewHandler setListensForContentChanges:NO];
}

- (void)configureNoResultsView
{
    self.noResultsViewController = [NoResultsViewController controller];
}

- (void)configureCommentButton
{
    self.buttonComment = [self makeCommentButton];
}

#pragma mark - Autolayout Helpers

- (void)configureViewConstraints
{
    self.buttonComment.translatesAutoresizingMaskIntoConstraints = false;

    // TODO:
    // This LayoutConstraint is just a helper, meant to hide / display the ReplyTextView, as needed.
    // Whenever iOS 8 is set as the deployment target, let's always attach this one, and enable / disable it as needed!
    self.replyTextViewHeightConstraint = [NSLayoutConstraint constraintWithItem:self.buttonComment attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1 constant:0];
}

#pragma mark - Helpers

- (NSString *)noResultsTitleText
{
    // If we couldn't fetch the comments lets let the user know
    if (self.fetchCommentsError != nil) {
        return NSLocalizedString(@"There has been an unexpected error while loading the comments.", @"Message shown when comments for a post can not be loaded.");
    }
    // Let's just display the same message, for consistency's sake
    else if (self.isLoadingPost || self.syncHelper.isSyncing) {
        return NSLocalizedString(@"Fetching comments...", @"A brief prompt shown when the comment list is empty, letting the user know the app is currently fetching new comments.");
    } else {
        return NSLocalizedString(@"Be the first to leave a comment.", @"Message shown encouraging the user to leave a comment on a post in the reader.");
    }
}

- (UIView *)noResultsAccessoryView
{
    UIView *loadingAccessoryView = nil;
    if ((self.isLoadingPost || self.syncHelper.isSyncing) && self.fetchCommentsError == nil) {
        loadingAccessoryView = [NoResultsViewController loadingAccessoryView];
    }
    return loadingAccessoryView;
}

- (void)checkIfLoggedIn
{
    self.isLoggedIn = [AccountHelper isDotcomAvailable];
}

- (void)setHighlightedIndexPath:(NSIndexPath *)highlightedIndexPath
{
    if (_highlightedIndexPath) {
        CommentContentTableViewCell *previousCell = (CommentContentTableViewCell *)[self.tableView cellForRowAtIndexPath:_highlightedIndexPath];
        previousCell.isEmphasized = NO;
    }

    if (highlightedIndexPath) {
        CommentContentTableViewCell *cell = (CommentContentTableViewCell *)[self.tableView cellForRowAtIndexPath:highlightedIndexPath];
        cell.isEmphasized = YES;
    }

    _highlightedIndexPath = highlightedIndexPath;
}

- (UIView *)cachedHeaderView {
    if (!_cachedHeaderView) {
        _cachedHeaderView = [self configuredHeaderViewFor:self.tableView];
    }

    return _cachedHeaderView;
}

- (UIBarButtonItem *)followBarButtonItem
{
    if (!_followBarButtonItem) {
        _followBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Follow", @"Button title. Follow the comments on a post.")
                                                                style:UIBarButtonItemStylePlain
                                                               target:self
                                                               action:@selector(handleFollowConversationButtonTapped)];
    }

    return _followBarButtonItem;
}

- (UIBarButtonItem *)subscriptionSettingsBarButtonItem
{
    if (!_subscriptionSettingsBarButtonItem) {
        _subscriptionSettingsBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"bell"]
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(subscriptionSettingsButtonTapped)];
        _subscriptionSettingsBarButtonItem.accessibilityHint = NSLocalizedString(@"Open subscription settings for the post",
                                                                                 @"VoiceOver hint. Informs the user that the button allows the user to access "
                                                                                 + "post subscription settings.");
    }

    return _subscriptionSettingsBarButtonItem;
}

/// NOTE: In order for the inset to work across orientations, the tableView should use `UITableViewSeparatorInsetFromAutomaticInsets` to
/// base the separator insets on the cell layout margins instead of the edges.
///
/// With the default inset reference (i.e. `UITableViewSeparatorInsetFromCellEdges`), sometimes the cell configuration is called before the
/// orientation animation is completed – and this caused the computed separator insets to intermittently return the wrong table view size.
///
- (UIEdgeInsets)hiddenSeparatorInsets {
    CGFloat rightInset = CGRectGetWidth(self.tableView.frame);

    // Add an extra inset for landscape iPad (without a split view) where the separator does reach the trailing edge.
    // Otherwise, after orientation the inset may not be enough to hide the separator.
    if (self.view.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
        rightInset -= self.tableView.separatorInset.left;
    }

    // Note: no need to flip the insets manually for RTL layout. The system will automatically take care of this.
    return UIEdgeInsetsMake(0, -self.tableView.separatorInset.left, 0, rightInset);
}

/// Determines whether a separator should be drawn for the provided index path.
/// The method returns YES if the index path represent a comment that is placed before a top-level comment.
///
/// Example:
///
/// - comment 1
///     - comment 2
///         - comment 3      --> returns YES.
/// - comment 4
///     - comment 5
///         - comment 6
///             - comment 7
///         - comment 8      --> returns YES.
/// - comment 9
///
- (BOOL)shouldShowSeparatorForIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *nextIndexPath = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section];
    NSArray<id<NSFetchedResultsSectionInfo>> *sections = self.tableViewHandler.resultsController.sections;

    if (sections && sections[indexPath.section] && nextIndexPath.row < sections[indexPath.section].numberOfObjects) {
        Comment *nextComment = [self.tableViewHandler.resultsController objectAtIndexPath:nextIndexPath];
        return [nextComment isTopLevelComment];
    }

    return NO;
}

- (void)listenForClipboardChanges
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(clipboardChanged:)
                                                 name:UIPasteboardChangedNotification
                                               object:nil];
}

- (void)clipboardChanged:(NSNotification *)notification
{
    if (notification.userInfo == nil) {
        [WPAnalytics trackEvent:WPAnalyticsEventReaderCommentTextCopied];
    }
}

#pragma mark - Accessor methods

- (void)setPost:(ReaderPost *)post
{
    if (post == _post) {
        return;
    }

    _post = post;

    if (_post.isWPCom || _post.isJetpack) {
        self.syncHelper = [[WPContentSyncHelper alloc] init];
        self.syncHelper.delegate = self;
    }

    _followCommentsService = [FollowCommentsService createServiceWith:_post];
    _readerCommentsFollowPresenter = [[ReaderCommentsFollowPresenter alloc] initWithPost:_post delegate:self presentingViewController:self];
}

- (NSNumber *)siteID
{
    // If the post isn't loaded yet, maybe we're asynchronously retrieving it?
    return self.post.siteID ?: self.postSiteID;
}

- (BOOL)isLoadingPost
{
    return self.post == nil;
}

- (BOOL)canComment
{
    return self.post.commentsOpen && self.isLoggedIn;
}

- (BOOL)canFollowConversation
{
    return [self.followCommentsService canFollowConversation];
}

- (BOOL)shouldDisplayReplyTextView
{
    return self.canComment;
}

#pragma mark - View Refresh Helpers

- (void)refreshAndSync
{
    [self refreshFollowButton];
    [self refreshSubscriptionStatusIfNeeded];
    [self refreshReplyTextView];
    [self refreshInfiniteScroll];
    [self refreshTableViewAndNoResultsView];
    [self.syncHelper syncContent];
}

- (void)refreshFollowButton
{
    if (!self.canFollowConversation) {
        return;
    }

    self.navigationItem.rightBarButtonItem = self.post.isSubscribedComments ? self.subscriptionSettingsBarButtonItem : self.followBarButtonItem;
}

- (void)refreshSubscriptionStatusIfNeeded
{
    __weak __typeof(self) weakSelf = self;
    [self.followCommentsService fetchSubscriptionStatusWithSuccess:^(BOOL isSubscribed) {
        // update the ReaderPost button to keep it in-sync.
        weakSelf.post.isSubscribedComments = isSubscribed;
        [weakSelf refreshFollowButton];
        [ContextManager.sharedInstance saveContext:weakSelf.post.managedObjectContext];
    } failure:^(NSError *error) {
        DDLogError(@"Error fetching subscription status for post: %@", error);
    }];
}

- (void)refreshReplyTextView
{
    BOOL showsReplyTextView = self.shouldDisplayReplyTextView;
    self.buttonComment.hidden = !showsReplyTextView;
    
    if (showsReplyTextView) {
        [self.view removeConstraint:self.replyTextViewHeightConstraint];
    } else {
        [self.view addConstraint:self.replyTextViewHeightConstraint];
    }
}

- (void)refreshInfiniteScroll
{
    [self.tableViewController setLoadingFooterHidden:YES];
}

- (void)refreshNoResultsView
{
    [self.noResultsViewController removeFromView];

    BOOL isTableViewEmpty = (self.tableViewHandler.resultsController.fetchedObjects.count == 0);
    if (!isTableViewEmpty) {
        return;
    }

    NSString *image = nil;
    NSString *subtitle = nil;
    if (self.fetchCommentsError != nil) {
        image = @"wp-illustration-reader-empty";
        NSError *error = self.fetchCommentsError;
        if (error && [error.domain isEqualToString:WordPressComRestApiErrorDomain] && error.code == WordPressComRestApiErrorCodeAuthorizationRequired) {
            subtitle = NSLocalizedString(@"You don't have permission to view this private blog.",
                                          @"Error message that informs reader comments from a private blog cannot be fetched.");

        }
    }
    [self.noResultsViewController configureWithTitle:self.noResultsTitleText
                                     attributedTitle:nil
                                   noConnectionTitle:nil
                                         buttonTitle:nil
                                            subtitle:subtitle
                                noConnectionSubtitle:nil
                                  attributedSubtitle:nil
                     attributedSubtitleConfiguration:nil
                                               image:image
                                       subtitleImage:nil
                                       accessoryView:[self noResultsAccessoryView]];

    [self.noResultsViewController hideImageView:NO];
    [self addChildViewController:self.noResultsViewController];

    // when the table view is not yet properly initialized, use the view's frame instead to prevent wrong frame values.
    if (self.tableView.window == nil) {
        self.noResultsViewController.view.frame = self.view.frame;
    } else {
        self.noResultsViewController.view.frame = self.tableView.frame;
    }

    [self.view insertSubview:self.noResultsViewController.view belowSubview:self.buttonComment];
    [self.noResultsViewController didMoveToParentViewController:self];
}

- (void)refreshAfterCommentModeration
{
    [self.tableViewHandler refreshTableView];
    [self refreshNoResultsView];
}

- (void)updateTableViewForAttachments
{
    [self.tableView performBatchUpdates:nil completion:nil];
}

- (void)refreshTableViewAndNoResultsView:(BOOL)scrollToHighlightedComment {
    [self.tableViewHandler refreshTableView];
    [self refreshNoResultsView];
    [self.managedObjectContext performBlock:^{
        [self updateCachedContent];
    }];

    if (scrollToHighlightedComment) {
        [self navigateToCommentIDIfNeeded];
    }
}

- (void)refreshTableViewAndNoResultsView {
    [self refreshTableViewAndNoResultsView:YES];
}

- (void)updateCachedContent
{
    if (![Feature enabled:FeatureFlagReaderCommentsWebKit]) {
        NSArray *comments = self.tableViewHandler.resultsController.fetchedObjects;
        for(Comment *comment in comments) {
            [self cacheContentForComment:comment];
        }
    }
}


- (NSAttributedString *)cacheContentForComment:(Comment *)comment
{
    NSAttributedString *attrStr = [self.cachedAttributedStrings objectForKey:[NSNumber numberWithInt:comment.commentID]];
    if (!attrStr || self.userInterfaceStyleChanged == YES) {
        attrStr = [WPRichContentView formattedAttributedStringForString: comment.content];
        [self.cachedAttributedStrings setObject:attrStr forKey:[NSNumber numberWithInt:comment.commentID]];
    }
    return attrStr;
}

/// If we've been provided with a comment ID on initialization, then this
/// method locates that comment and scrolls the tableview to display it.
- (void)navigateToCommentIDIfNeeded
{
    if (self.navigateToCommentID == nil) {
        return;
    }
    double delayInSeconds = 0.5;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self scrollToCommentID];
    });
}

- (void)scrollToCommentID
{
    // Find the comment if it exists
    NSArray<Comment *> *comments = [self.tableViewHandler.resultsController fetchedObjects];
    NSArray<Comment *> *filteredComments = [comments filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"commentID == %@", self.navigateToCommentID]];
    Comment *comment = [filteredComments firstObject];

    if (!comment) {
        return;
    }

    // Force the table view to be laid out first before scrolling to indexPath.
    // This avoids a case where a cell instance could be orphaned and displayed randomly on top of the other cells.
    NSIndexPath *indexPath = [self.tableViewHandler.resultsController indexPathForObject:comment];
    [self.tableView layoutIfNeeded];

    // Ensure that the indexPath exists before scrolling to it.
    if (indexPath.section >=0
        && indexPath.row >=0
        && indexPath.section < self.tableView.numberOfSections
        && indexPath.row < [self.tableView numberOfRowsInSection:indexPath.section])
    {
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
        self.highlightedIndexPath = indexPath;
    }
}

#pragma mark - Actions

- (void)didTapReplyAtIndexPath:(NSIndexPath *)indexPath
{
    if (!indexPath || !self.canComment) {
        return;
    }
    Comment *comment = [self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    [self didTapReplyWithComment:comment];
}

- (void)didTapLikeForComment:(Comment *)comment atIndexPath:(NSIndexPath *)indexPath
{
    CommentService *commentService = [[CommentService alloc] initWithCoreDataStack:[ContextManager sharedInstance]];

    if (!comment.isLiked) {
        [[UINotificationFeedbackGenerator new] notificationOccurred:UINotificationFeedbackTypeSuccess];
    }

    __typeof(self) __weak weakSelf = self;
    [commentService toggleLikeStatusForComment:comment siteID:self.post.siteID success:^{
        [weakSelf trackCommentLikedOrUnliked:comment];
    } failure:^(NSError * __unused error) {
        // in case of failure, revert the cell's like state.
        [weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [[UINotificationFeedbackGenerator new] notificationOccurred:UINotificationFeedbackTypeError];
    }];
}

#pragma mark - Sync methods

- (void)syncHelper:(WPContentSyncHelper *)syncHelper syncContentWithUserInteraction:(BOOL)userInteraction success:(void (^)(BOOL))success failure:(void (^)(NSError *))failure
{
    self.fetchCommentsError = nil;

    CommentService *service = [[CommentService alloc] initWithCoreDataStack:[ContextManager sharedInstance]];
    [service syncHierarchicalCommentsForPost:self.post page:1 success:^(BOOL hasMore, NSNumber * __unused totalComments) {
        if (success) {
            success(hasMore);
        }
    } failure:failure];

    [self refreshNoResultsView];
}

- (void)syncHelper:(WPContentSyncHelper *)syncHelper syncMoreWithSuccess:(void (^)(BOOL))success failure:(void (^)(NSError *))failure
{
    self.fetchCommentsError = nil;
    [self.tableViewController setLoadingFooterHidden:NO];

    CommentService *service = [[CommentService alloc] initWithCoreDataStack:[ContextManager sharedInstance]];
    NSInteger page = [service numberOfHierarchicalPagesSyncedforPost:self.post] + 1;
    [service syncHierarchicalCommentsForPost:self.post page:page success:^(BOOL hasMore, NSNumber * __unused totalComments) {
        if (success) {
            success(hasMore);
        }
    } failure:failure];
}

- (void)syncContentEnded:(WPContentSyncHelper *)syncHelper
{
    [self.tableViewController setLoadingFooterHidden:YES];
    if ([self.tableViewHandler isScrolling]) {
        self.needsRefreshTableViewAfterScrolling = YES;
        return;
    }

    [self refreshTableViewAndNoResultsView];
}

- (void)syncContentFailed:(WPContentSyncHelper *)syncHelper
{
    self.fetchCommentsError = [NSError errorWithDomain:@"" code:0 userInfo:nil];
    [self.tableViewController setLoadingFooterHidden:YES];
    [self refreshTableViewAndNoResultsView];
}

#pragma mark - Async Loading Helpers

- (void)setupWithPostID:(NSNumber *)postID siteID:(NSNumber *)siteID
{
    ReaderPostService *service      = [[ReaderPostService alloc] initWithCoreDataStack:[ContextManager sharedInstance]];
    __weak __typeof(self) weakSelf  = self;
    
    self.postSiteID = siteID;
    
    [service fetchPost:postID.integerValue forSite:siteID.integerValue isFeed:NO success:^(ReaderPost *post) {

        [weakSelf setPost:post];
        [weakSelf refreshAndSync];
        
    } failure:^(NSError *error) {
        DDLogError(@"[RestAPI] %@", error);
        self.fetchCommentsError = error;
        [self.tableViewController setLoadingFooterHidden:YES];
        [self refreshTableViewAndNoResultsView];
    }];
}

#pragma mark - UITableView Delegate Methods

- (NSManagedObjectContext *)managedObjectContext
{
    return [[ContextManager sharedInstance] mainContext];
}

- (NSFetchRequest *)fetchRequest
{
    if (!self.post) {
        return nil;
    }

    // Moderated comments could still be cached, so filter out non-approved comments.
    NSString *approvedStatus = [Comment descriptionFor:CommentStatusTypeApproved];

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([Comment class])];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"post = %@ AND status = %@ AND visibleOnReader = %@", self.post, approvedStatus, @YES];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"hierarchy" ascending:YES];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];

    return fetchRequest;
}

- (void)configureCell:(UITableViewCell *)aCell atIndexPath:(NSIndexPath *)indexPath
{
    // When backgrounding, the app takes a snapshot, which triggers a layout pass,
    // which refreshes the cells, and for some reason triggers an assertion failure
    // in NSMutableAttributedString(data:,options:,documentAttributes:) when
    // the NSDocumentTypeDocumentAttribute option is NSHTMLTextDocumentType.
    // *** Assertion failure in void _prepareForCAFlush(UIApplication *__strong)(),
    // /BuildRoot/Library/Caches/com.apple.xbs/Sources/UIKit_Sim/UIKit-3600.6.21/UIApplication.m:2377
    // *** Terminating app due to uncaught exception 'NSInternalInconsistencyException',
    // reason: 'unexpected start state'
    // This seems like a framework bug, so to avoid it skip configuring cells
    // while the app is backgrounded.
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
        return;
    }

    Comment *comment = [self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    CommentContentTableViewCell *cell = (CommentContentTableViewCell *)aCell;
    [self configureContentCell:cell comment:comment indexPath:indexPath handler:self.tableViewHandler];

    if (self.highlightedIndexPath) {
        cell.isEmphasized = (indexPath == self.highlightedIndexPath);
    }

    // support for legacy content rendering method.
    cell.richContentDelegate = self;

    // show separator when the comment is the "last leaf" of its top-level comment.
    cell.separatorInset = [self shouldShowSeparatorForIndexPath:indexPath] ? UIEdgeInsetsZero : self.hiddenSeparatorInsets;

    // configure button actions.
    __weak __typeof(self) weakSelf = self;

    cell.accessoryButtonAction = ^(UIView * _Nonnull sourceView) {
        if (comment) {
            [weakSelf shareComment:comment sourceView:sourceView];
        }
    };

    cell.replyButtonAction = ^{
        [weakSelf didTapReplyAtIndexPath:indexPath];
    };

    cell.likeButtonAction = ^{
        [weakSelf didTapLikeForComment:comment atIndexPath:indexPath];
    };

    cell.contentLinkTapAction = ^(NSURL * _Nonnull url) {
        [weakSelf interactWithURL:url];
    };
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // NOTE: When using a `CommentContentTableViewCell` with `.web` rendering method, this method needs to return `UITableViewAutomaticDimension`.
    // Using cached estimated heights could get some cells to keep reloading their HTMLs indefinitely, causing the app to hang!

    NSNumber *cachedHeight = [self.estimatedRowHeights objectForKey:indexPath];
    if (cachedHeight.doubleValue) {
        return cachedHeight.doubleValue;
    }
    return EstimatedCommentRowHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewAutomaticDimension;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return self.cachedHeaderView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = CommentContentCellIdentifier;
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.estimatedRowHeights setObject:@(cell.frame.size.height) forKey:indexPath];

    // Are we approaching the end of the table?
    if ((indexPath.section + 1 == [self.tableViewHandler numberOfSectionsInTableView:tableView]) &&
        (indexPath.row + 4 >= [self.tableViewHandler tableView:tableView numberOfRowsInSection:indexPath.section])) {

        // Only 3 rows till the end of table
        if (self.syncHelper.hasMoreContent) {
            [self.syncHelper syncMoreContent];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0;
}

#pragma mark - UIScrollView Delegate Methods

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self.tableView deselectSelectedRowWithAnimation:YES];

    if (self.needsRefreshTableViewAfterScrolling) {
        self.needsRefreshTableViewAfterScrolling = NO;
        [self refreshTableViewAndNoResultsView];

        // If we reloaded the tableView we also updated cell heights
        // so there is no need to update for attachments.
        self.needsUpdateAttachmentsAfterScrolling = NO;
    }

    if (self.needsUpdateAttachmentsAfterScrolling) {
        self.needsUpdateAttachmentsAfterScrolling = NO;

        for (UITableViewCell *cell in [self.tableView visibleCells]) {
            if ([cell isKindOfClass:[CommentContentTableViewCell class]]) {
                [(CommentContentTableViewCell *)cell ensureRichContentTextViewLayout];
            }
        }
        [self updateTableViewForAttachments];
    }
}

#pragma mark - WPRichContentDelegate Methods

- (void)richContentView:(WPRichContentView *)richContentView didReceiveImageAction:(WPRichTextImage *)image
{
    [self showFullScreenImage:image from:richContentView];
}

- (void)interactWithURL:(NSURL *)URL
{
    [self presentWebViewControllerWith:URL];
}

- (BOOL)richContentViewShouldUpdateLayoutForAttachments:(WPRichContentView *)richContentView
{
    if (self.tableViewHandler.isScrolling) {
        self.needsUpdateAttachmentsAfterScrolling = YES;
        return NO;
    }

    return YES;
}

- (void)richContentViewDidUpdateLayoutForAttachments:(WPRichContentView *)richContentView
{
    [self updateTableViewForAttachments];
}

- (void)textViewDidChangeSelection:(UITextView *)textView
{
    if (!textView.selectedTextRange.isEmpty) {
        [WPAnalytics trackEvent:WPAnalyticsEventReaderCommentTextHighlighted];
    }
}

#pragma mark - ReaderCommentsFollowPresenterDelegate Methods

- (void)followConversationCompleteWithSuccess:(BOOL)success post:(ReaderPost *)post
{
    self.post = post;
    [self refreshFollowButton];
}

- (void)toggleNotificationCompleteWithSuccess:(BOOL)success post:(ReaderPost *)post
{
    self.post = post;
}

#pragma mark - Nav bar button helpers

- (void)handleFollowConversationButtonTapped
{
    [self.readerCommentsFollowPresenter handleFollowConversationButtonTapped];
}

- (void)subscriptionSettingsButtonTapped
{
    [self.readerCommentsFollowPresenter showNotificationSheetWithSourceBarButtonItem:self.navigationItem.rightBarButtonItem];
}

@end
