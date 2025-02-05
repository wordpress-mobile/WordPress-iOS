#import "ReaderCommentsViewController.h"

#import "CommentService.h"
#import "CoreDataStack.h"
#import "ReaderPost.h"
#import "ReaderPostService.h"
#import "UIView+Subviews.h"
#import "WordPress-Swift.h"
#import "WPAppAnalytics.h"

@class Comment;

@interface ReaderCommentsViewController () <NSFetchedResultsControllerDelegate,
                                            WPRichContentViewDelegate, // TODO: Remove once we switch to the `.web` rendering method.
                                            WPContentSyncHelperDelegate,
                                            ReaderCommentsFollowPresenterDelegate>

@property (nonatomic, strong, readwrite) ReaderPost *post;
@property (nonatomic, strong) NSNumber *postSiteID;
@property (nonatomic, strong) WPContentSyncHelper *syncHelper;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NoResultsViewController *noResultsViewController;
@property (nonatomic, strong) UIView *buttonAddComment;
@property (nonatomic, strong) NSLayoutConstraint *replyTextViewHeightConstraint;
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

    self.cachedAttributedStrings = [[NSCache alloc] init];

    self.tableViewController = [[ReaderCommentsTableViewController alloc] initWithPost:self.post];
    self.tableViewController.containerViewController = self;
    [self configureTableViewController:self.tableViewController];

    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.commentModified = NO;
    self.helper = [ReaderCommentsHelper new];

    [self checkIfLoggedIn];

    [self configureNavbar];
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

    [self.tableViewController setBottomInset:self.buttonAddComment.frame.size.height];
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

- (void)configureNoResultsView
{
    self.noResultsViewController = [NoResultsViewController controller];
}

- (void)configureCommentButton
{
    self.buttonAddComment = [self makeCommentButton];
}

#pragma mark - Autolayout Helpers

- (void)configureViewConstraints
{
    self.buttonAddComment.translatesAutoresizingMaskIntoConstraints = false;

    // TODO:
    // This LayoutConstraint is just a helper, meant to hide / display the ReplyTextView, as needed.
    // Whenever iOS 8 is set as the deployment target, let's always attach this one, and enable / disable it as needed!
    self.replyTextViewHeightConstraint = [NSLayoutConstraint constraintWithItem:self.buttonAddComment attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1 constant:0];
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
    self.buttonAddComment.hidden = !showsReplyTextView;
    
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

    // TODO: (kean) reimplement
//    BOOL isTableViewEmpty = (self.tableViewHandler.resultsController.fetchedObjects.count == 0);
//    if (!isTableViewEmpty) {
//        return;
//    }

    return ;

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

    [self.view insertSubview:self.noResultsViewController.view belowSubview:self.buttonAddComment];
    [self.noResultsViewController didMoveToParentViewController:self];
}

- (void)refreshAfterCommentModeration
{
    [self.tableViewController.tableView reloadData];
    [self refreshNoResultsView];
}

- (void)updateTableViewForAttachments
{
    [self.tableView performBatchUpdates:nil completion:nil];
}

- (void)refreshTableViewAndNoResultsView:(BOOL)scrollToHighlightedComment {
    // TODO: remove
    [self.tableViewController.tableView reloadData];
    [self refreshNoResultsView];

    if (scrollToHighlightedComment) {
        [self navigateToCommentIDIfNeeded];
    }
}

- (void)refreshTableViewAndNoResultsView {
    [self refreshTableViewAndNoResultsView:YES];
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
        [self.tableViewController scrollToCommentWithID:self.navigateToCommentID];
    });
}

- (void)highlightCommentAtIndexPath:(NSIndexPath *)indexPath {
    self.highlightedIndexPath = indexPath;
}

#pragma mark - Actions

- (void)didTapReplyAtIndexPath:(NSIndexPath *)indexPath
{
    if (!indexPath || !self.canComment) {
        return;
    }
    Comment *comment = [self.tableViewController commentAt:indexPath];
    if (comment) {
        [self didTapReplyWithComment:comment];
    }
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
    ReaderPostService *service = [[ReaderPostService alloc] initWithCoreDataStack:[ContextManager sharedInstance]];
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

- (void)configureCell:(CommentContentTableViewCell *)cell comment:(Comment *)comment indexPath:(NSIndexPath *)indexPath
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

    [self configureContentCell:cell comment:comment indexPath:indexPath tableView:self.tableViewController.tableView];

    if (self.highlightedIndexPath) {
        cell.isEmphasized = (indexPath == self.highlightedIndexPath);
    }

    // support for legacy content rendering method.
    cell.richContentDelegate = self;

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

- (void)loadMore
{
    if (self.syncHelper.hasMoreContent) {
        [self.syncHelper syncMoreContent];
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
