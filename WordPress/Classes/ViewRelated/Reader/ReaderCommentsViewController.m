#import "ReaderCommentsViewController.h"

#import <WordPressShared/UIImage+Util.h>
#import <DTCoreText/DTCoreText.h>

#import "Comment.h"
#import "CommentContentView.h"
#import "CommentService.h"
#import "ContextManager.h"
#import "CustomHighlightButton.h"
#import "ReaderCommentCell.h"
#import "ReaderPost.h"
#import "ReaderPostService.h"
#import "ReaderPostHeaderView.h"
#import "UIView+Subviews.h"
#import "WPAvatarSource.h"
#import "WPNoResultsView.h"
#import "WPImageViewController.h"
#import "WPRichTextView.h"
#import "WPTableViewHandler.h"
#import "WPWebViewController.h"
#import "SuggestionsTableView.h"
#import "SuggestionService.h"
#import "WordPress-Swift.h"
#import "WPAppAnalytics.h"



// Note:
// Due to a UITableView bug on iOS 8, let's keep the estimated height to the bare minimum.
// If the estimated is bigger than needed, UITableView might actually use that size, and shrink using an undesired animation.

static CGFloat const EstimatedCommentRowHeight = 100.0;
static CGFloat const CommentAvatarSize = 32.0;
static CGFloat const PostHeaderHeight = 54.0;

static NSString *CommentCellIdentifier = @"CommentDepth0CellIdentifier";
static NSString *CommentLayoutCellIdentifier = @"CommentLayoutCellIdentifier";


@interface ReaderCommentsViewController () <NSFetchedResultsControllerDelegate,
                                            CommentContentViewDelegate,
                                            ReplyTextViewDelegate,
                                            WPContentSyncHelperDelegate,
                                            WPTableViewHandlerDelegate,
                                            SuggestionsTableViewDelegate>

@property (nonatomic, strong, readwrite) ReaderPost *post;
@property (nonatomic, strong) NSNumber *postSiteID;
@property (nonatomic, strong) UIGestureRecognizer *tapOffKeyboardGesture;
@property (nonatomic, strong) UIActivityIndicatorView *activityFooter;
@property (nonatomic, strong) WPContentSyncHelper *syncHelper;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) WPTableViewHandler *tableViewHandler;
@property (nonatomic, strong) ReaderCommentCell *cellForLayout;
@property (nonatomic, strong) NSLayoutConstraint *cellForLayoutWidthConstraint;
@property (nonatomic, strong) WPNoResultsView *noResultsView;
@property (nonatomic, strong) ReplyTextView *replyTextView;
@property (nonatomic, strong) SuggestionsTableView *suggestionsTableView;
@property (nonatomic, strong) UIView *postHeaderWrapper;
@property (nonatomic, strong) ReaderPostHeaderView *postHeaderView;
@property (nonatomic, strong) NSMutableDictionary *mediaCellCache;
@property (nonatomic, strong) NSIndexPath *indexPathForCommentRepliedTo;
@property (nonatomic, assign) CGSize previousViewGeometry;
@property (nonatomic, strong) NSLayoutConstraint *replyTextViewHeightConstraint;
@property (nonatomic, strong) NSLayoutConstraint *replyTextViewBottomConstraint;
@property (nonatomic) BOOL isLoggedIn;

@end


@implementation ReaderCommentsViewController

#pragma mark - Static Helpers

+ (instancetype)controllerWithPost:(ReaderPost *)post
{
    ReaderCommentsViewController *controller = [[self alloc] init];
    controller.post = post;
    return controller;
}

+ (instancetype)controllerWithPostID:(NSNumber *)postID siteID:(NSNumber *)siteID
{
    ReaderCommentsViewController *controller = [[self alloc] init];
    [controller setupWithPostID:postID siteID:siteID];
    return controller;
}


#pragma mark - LifeCycle Methods

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.previousViewGeometry = self.view.frame.size;

    self.mediaCellCache = [NSMutableDictionary dictionary];
    [self checkIfLoggedIn];

    [self configureNavbar];
    [self configurePostHeader];
    [self configureTableView];
    [self configureTableViewHandler];
    [self configureCellForLayout];
    [self configureNoResultsView];
    [self configureReplyTextView];
    [self configureSuggestionsTableView];
    [self configureKeyboardGestureRecognizer];
    [self configureViewConstraints];
    
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    
    [self refreshAndSync];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (!CGSizeEqualToSize(self.previousViewGeometry, CGSizeZero)) {
        if (! CGSizeEqualToSize(self.previousViewGeometry, self.view.frame.size)) {
            // Refresh cached row heights based on the new width
            [self.tableViewHandler refreshCachedRowHeightsForWidth:CGRectGetWidth(self.view.frame)];
            [self.tableView reloadData];
        }
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleApplicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self preventPendingMediaLayoutInCells:NO];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    self.previousViewGeometry = self.view.frame.size;

    [self.replyTextView resignFirstResponder];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    // Remove the no results view or else the position will abruptly adjust after rotation
    // due to the table view sizing for image preloading
    [self refreshNoResultsView];

    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    // Avoid refreshing cells when there is no need.
    if (![UIDevice isPad] && WPTableViewFixedWidth > CGRectGetWidth(self.tableView.frame)) {
        // Refresh cached row heights based on the new width
        [self updateCellsAndRefreshMediaForWidth:size.width];
    }

    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
        // Make sure a selected comment is visible after rotating, and that the replyTextView is still the first responder.
        if (selectedIndexPath) {
            [self.replyTextView becomeFirstResponder];
            [self.tableView selectRowAtIndexPath:selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
        
        [self refreshNoResultsView];
    }];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];

    [self.view layoutIfNeeded];

    CGFloat width = CGRectGetWidth(self.view.frame);
    [self updateCellsAndRefreshMediaForWidth:width];
    [self.tableView reloadRowsAtIndexPaths:[self.tableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationNone];
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

    CGFloat width = CGRectGetWidth(self.view.frame);
    [self updateCellsAndRefreshMediaForWidth:width];
    [self.tableView reloadRowsAtIndexPaths:[self.tableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationNone];
}


#pragma mark - Configuration

- (void)configureNavbar
{
    // Don't show 'Reader' in the next-view back button
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@" " style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem = backButton;

    self.title = NSLocalizedString(@"Comments", @"Title of the reader's comments screen");
}

- (void)configurePostHeader
{
    __typeof(self) __weak weakSelf = self;
    
    // Wrapper view
    UIView *headerWrapper = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.bounds), PostHeaderHeight)];
    headerWrapper.translatesAutoresizingMaskIntoConstraints = NO;
    headerWrapper.backgroundColor = [UIColor whiteColor];
    headerWrapper.clipsToBounds = YES;

    // Post header view
    ReaderPostHeaderView *headerView = [[ReaderPostHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.bounds), PostHeaderViewAvatarSize)];
    headerView.onClick = ^{
        [weakSelf handleHeaderTapped];
    };
    headerView.translatesAutoresizingMaskIntoConstraints = NO;
    headerView.backgroundColor = [UIColor whiteColor];
    headerView.showsDisclosureIndicator = self.allowsPushingPostDetails;
    [headerView setSubtitle:NSLocalizedString(@"Comments on", @"Sentence fragment. The full phrase is 'Comments on' followed by the title of a post on a separate line.")];
    [headerWrapper addSubview:headerView];

    // Border
    CGSize borderSize = CGSizeMake(CGRectGetWidth(self.view.bounds), 1.0);
    UIImage *borderImage = [UIImage imageWithColor:[WPStyleGuide readGrey] havingSize:borderSize];
    UIImageView *borderView = [[UIImageView alloc] initWithImage:borderImage];
    borderView.translatesAutoresizingMaskIntoConstraints = NO;
    borderView.contentMode = UIViewContentModeScaleAspectFill;
    [headerWrapper addSubview:borderView];

    // Layout
    NSDictionary *views = NSDictionaryOfVariableBindings(headerView, borderView);
    NSDictionary *metrics = @{@"margin":@12};
    [headerWrapper addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(margin)-[headerView]-(margin)-|"
                                                                          options:0
                                                                          metrics:metrics
                                                                            views:views]];
    [headerWrapper addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(margin)-[headerView]-(>=1)-[borderView(1)]|"
                                                                          options:0
                                                                          metrics:metrics
                                                                            views:views]];
    [headerWrapper addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[borderView]|"
                                                                          options:0
                                                                          metrics:metrics
                                                                            views:views]];

    self.postHeaderView = headerView;
    self.postHeaderWrapper = headerWrapper;
    [self.view addSubview:self.postHeaderWrapper];
}

- (void)configureTableView
{
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.tableView];

    [self.tableView registerClass:[ReaderCommentCell class] forCellReuseIdentifier:CommentCellIdentifier];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
}

- (void)configureTableViewHandler
{
    self.tableViewHandler = [[WPTableViewHandler alloc] initWithTableView:self.tableView];
    self.tableViewHandler.updateRowAnimation = UITableViewRowAnimationNone;
    self.tableViewHandler.cacheRowHeights = YES;
    self.tableViewHandler.delegate = self;
}

- (void)configureCellForLayout
{
    [self.tableView registerClass:[ReaderCommentCell class] forCellReuseIdentifier:CommentLayoutCellIdentifier];
    self.cellForLayout = [self.tableView dequeueReusableCellWithIdentifier:CommentLayoutCellIdentifier];
    [self updateCellForLayoutWidthConstraint:CGRectGetWidth(self.tableView.bounds)];
}

- (void)configureNoResultsView
{
    self.noResultsView = [[WPNoResultsView alloc] init];
    self.noResultsView.hidden = YES;
    self.noResultsView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.noResultsView];
}

- (void)configureReplyTextView
{
    __typeof(self) __weak weakSelf = self;

    ReplyTextView *replyTextView = [[ReplyTextView alloc] initWithWidth:CGRectGetWidth(self.view.frame)];
    replyTextView.replyText = [NSLocalizedString(@"Reply", @"") uppercaseString];
    replyTextView.onReply = ^(NSString *content) {
        [weakSelf sendReplyWithNewContent:content];
    };
    replyTextView.delegate = self;
    self.replyTextView = replyTextView;
    
    [self refreshReplyTextViewPlaceholder];

    [self.view addSubview:self.replyTextView];
    [self.view bringSubviewToFront:self.replyTextView];
}

- (void)configureSuggestionsTableView
{
    NSNumber *siteID = self.siteID;
    NSParameterAssert(siteID);
    
    self.suggestionsTableView = [[SuggestionsTableView alloc] initWithSiteID:siteID];
    self.suggestionsTableView.suggestionsDelegate = self;
    [self.suggestionsTableView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:self.suggestionsTableView];
}

- (void)configureKeyboardGestureRecognizer
{
    self.tapOffKeyboardGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapRecognized:)];
    self.tapOffKeyboardGesture.enabled = NO;
    [self.view addGestureRecognizer:self.tapOffKeyboardGesture];
}


#pragma mark - Autolayout Helpers

- (void)configureViewConstraints
{
    NSDictionary *views         = @{
        @"tableView"        : self.tableView,
        @"postHeader"       : self.postHeaderWrapper,
        @"mainView"         : self.view,
        @"suggestionsview"  : self.suggestionsTableView,
        @"replyTextView"    : self.replyTextView
    };
    
    NSDictionary *metrics = @{
        @"WPTableViewWidth" : @(WPTableViewFixedWidth),
        @"headerHeight"     : @(PostHeaderHeight)
    };
    
    // PostHeader Constraints
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.postHeaderWrapper
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1.0
                                                           constant:0.0]];

    if ([UIDevice isPad]) {
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(>=0)-[postHeader(WPTableViewWidth@900)]-(>=0)-|"
                                                                          options:0
                                                                          metrics:metrics
                                                                            views:views]];
    } else {
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[postHeader(==mainView)]"
                                                                          options:0
                                                                          metrics:metrics
                                                                            views:views]];
    }
    
    // TableView Contraints
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[postHeader(headerHeight)][tableView][replyTextView]"
                                                                      options:0
                                                                      metrics:metrics
                                                                        views:views]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[tableView]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:views]];

    // ReplyTextView Constraints
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.replyTextView
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1.0
                                                           constant:0.0]];

    self.replyTextViewBottomConstraint = [NSLayoutConstraint constraintWithItem:self.view
                                                                      attribute:NSLayoutAttributeBottom
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.replyTextView
                                                                      attribute:NSLayoutAttributeBottom
                                                                     multiplier:1.0
                                                                       constant:0.0];
    self.replyTextViewBottomConstraint.priority = UILayoutPriorityDefaultHigh;

    [self.view addConstraint:self.replyTextViewBottomConstraint];
    
    if ([UIDevice isPad]) {
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(>=0)-[replyTextView(WPTableViewWidth@900)]-(>=0)-|"
                                                                          options:0
                                                                          metrics:metrics
                                                                            views:views]];
    } else {
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[replyTextView(==mainView)]"
                                                                          options:0
                                                                          metrics:metrics
                                                                            views:views]];
    }
    
    // Suggestions Constraints
    // Pin the suggestions view left and right edges to the reply view edges
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.suggestionsTableView
                                                          attribute:NSLayoutAttributeLeft
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.replyTextView
                                                          attribute:NSLayoutAttributeLeft
                                                         multiplier:1.0
                                                           constant:0.0]];

    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.suggestionsTableView
                                                          attribute:NSLayoutAttributeRight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.replyTextView
                                                          attribute:NSLayoutAttributeRight
                                                         multiplier:1.0
                                                           constant:0.0]];

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[suggestionsview][replyTextView]"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:views]];
    
    // TODO:
    // This LayoutConstraint is just a helper, meant to hide / display the ReplyTextView, as needed.
    // Whenever iOS 8 is set as the deployment target, let's always attach this one, and enable / disable it as needed!
    self.replyTextViewHeightConstraint = [NSLayoutConstraint constraintWithItem:self.replyTextView
                                                                      attribute:NSLayoutAttributeHeight
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:nil
                                                                      attribute:nil
                                                                     multiplier:1
                                                                       constant:0];
}


#pragma mark - Helpers

- (NSString *)noResultsTitleText
{
    // Let's just display the same message, for consistency's sake
    if (self.isLoadingPost || self.syncHelper.isSyncing) {
        return NSLocalizedString(@"Fetching comments...", @"A brief prompt shown when the comment list is empty, letting the user know the app is currently fetching new comments.");
    }
    
    return NSLocalizedString(@"Be the first to leave a commment.", @"Message shown encouraging the user to leave a comment on a post in the reader.");
}

// Call when changing orientation, or when split view size changes.
- (void)updateCellsAndRefreshMediaForWidth:(CGFloat)width
{
    [self updateCellForLayoutWidthConstraint:width];
    [self updateCachedMediaCellLayoutForWidth:width];

    // Resize cells in the media cell cache
    // No need to refresh on iPad when using a fixed width.
    for (NSString *key in [self.mediaCellCache allKeys]) {
        ReaderCommentCell *cell = [self.mediaCellCache objectForKey:key];
        NSIndexPath *indexPath = [self indexPathForCommentWithID:[key numericValue]];

        [cell refreshMediaLayout];
        [self.tableViewHandler invalidateCachedRowHeightAtIndexPath:indexPath];
    }

    [self.tableViewHandler refreshCachedRowHeightsForWidth:width];
}

- (void)updateCellForLayoutWidthConstraint:(CGFloat)width
{
    if (self.cellForLayoutWidthConstraint) {
        self.cellForLayoutWidthConstraint.constant = width;
        return;
    }

    UIView *contentView = self.cellForLayout.contentView;
    self.cellForLayoutWidthConstraint = [NSLayoutConstraint constraintWithItem:contentView
                                                                     attribute:NSLayoutAttributeWidth
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:nil
                                                                     attribute:nil
                                                                    multiplier:1
                                                                      constant:width];
    [contentView addConstraint:self.cellForLayoutWidthConstraint];
}

- (void)setAvatarForComment:(Comment *)comment forCell:(ReaderCommentCell *)cell indexPath:(NSIndexPath *)indexPath
{
    WPAvatarSource *source = [WPAvatarSource sharedSource];

    NSString *hash;
    CGSize size = CGSizeMake(CommentAvatarSize, CommentAvatarSize);
    NSURL *url = [comment avatarURLForDisplay];
    WPAvatarSourceType type = [source parseURL:url forAvatarHash:&hash];

    if (!hash) {
        [cell setAvatarImage:[UIImage imageNamed:@"gravatar"]];
        return;
    }

    UIImage *image = [source cachedImageForAvatarHash:hash ofType:type withSize:size];
    if (image) {
        [cell setAvatarImage:image];
        return;
    }

    [cell setAvatarImage:[UIImage imageNamed:@"gravatar"]];
    [source fetchImageForAvatarHash:hash ofType:type withSize:size success:^(UIImage *image) {
        if (cell == [self.tableView cellForRowAtIndexPath:indexPath]) {
            [cell setAvatarImage:image];
        }
    }];
}

- (void)checkIfLoggedIn
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    self.isLoggedIn = [[[AccountService alloc] initWithManagedObjectContext:context] defaultWordPressComAccount] != nil;
}

#pragma mark - Accessor methods

- (void)setPost:(ReaderPost *)post
{
    if (post == _post) {
        return;
    }

    _post = post;

    if (_post.isWPCom) {
        self.syncHelper = [[WPContentSyncHelper alloc] init];
        self.syncHelper.delegate = self;
    }
}

- (NSNumber *)siteID
{
    // If the post isn't loaded yet, maybe we're asynchronously retrieving it?
    return self.post.siteID ?: self.postSiteID;
}

- (UIActivityIndicatorView *)activityFooter
{
    if (_activityFooter) {
        return _activityFooter;
    }

    CGRect rect = CGRectMake(145.0f, 10.0f, 30.0f, 30.0f);
    _activityFooter = [[UIActivityIndicatorView alloc] initWithFrame:rect];
    _activityFooter.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    _activityFooter.hidesWhenStopped = YES;
    _activityFooter.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [_activityFooter stopAnimating];

    return _activityFooter;
}

- (BOOL)isLoadingPost
{
    return self.post == nil;
}

- (BOOL)canComment
{
    return self.post.commentsOpen && self.isLoggedIn;
}

- (BOOL)shouldDisplayReplyTextView
{
    return self.canComment;
}

- (BOOL)shouldDisplaySuggestionsTableView
{
    return self.shouldDisplayReplyTextView && [[SuggestionService sharedInstance] shouldShowSuggestionsForSiteID:self.post.siteID];
}


#pragma mark - View Refresh Helpers

- (void)refreshAndSync
{
    [self refreshPostHeaderView];
    [self refreshReplyTextView];
    [self refreshSuggestionsTableView];
    [self refreshInfiniteScroll];
    [self refreshNoResultsView];

    [self.tableView reloadData];
    [self.syncHelper syncContent];
}

- (void)refreshPostHeaderView
{
    NSParameterAssert(self.postHeaderView);
    NSParameterAssert(self.postHeaderWrapper);
    
    self.postHeaderWrapper.hidden = self.isLoadingPost;
    if (self.isLoadingPost) {
        return;
    }
    
    [self.postHeaderView setTitle:self.post.titleForDisplay];
    
    CGSize imageSize = CGSizeMake(PostHeaderViewAvatarSize, PostHeaderViewAvatarSize);
    UIImage *image = [self.post cachedAvatarWithSize:imageSize];
    if (image) {
        [self.postHeaderView setAvatarImage:image];
    } else {
        [self.post fetchAvatarWithSize:imageSize success:^(UIImage *image) {
            [self.postHeaderView setAvatarImage:image];
        }];
    }
}

- (void)refreshReplyTextView
{
    BOOL showsReplyTextView = self.shouldDisplayReplyTextView;
    self.replyTextView.hidden = !showsReplyTextView;
    
    if (showsReplyTextView) {
        [self.view removeConstraint:self.replyTextViewHeightConstraint];
    } else {
        [self.view addConstraint:self.replyTextViewHeightConstraint];
    }
}

- (void)refreshSuggestionsTableView
{
    self.suggestionsTableView.enabled = self.shouldDisplaySuggestionsTableView;
}

- (void)refreshReplyTextViewPlaceholder
{
    if (self.tableView.indexPathForSelectedRow) {
        self.replyTextView.placeholder = NSLocalizedString(@"Reply to comment…", @"Placeholder text for replying to a comment");
    } else {
        self.replyTextView.placeholder = NSLocalizedString(@"Reply to post…", @"Placeholder text for replying to a post");
    }
}

- (void)refreshInfiniteScroll
{
    if (self.syncHelper.hasMoreContent) {
        CGFloat width = CGRectGetWidth(self.tableView.bounds);
        UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, width, 50.0f)];
        footerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [footerView addSubview:self.activityFooter];
        self.tableView.tableFooterView = footerView;
        
    } else {
        self.tableView.tableFooterView = nil;
        self.activityFooter = nil;
    }
}


- (void)refreshNoResultsView
{
    BOOL isTableViewEmpty = (self.tableViewHandler.resultsController.fetchedObjects.count == 0);
    BOOL shouldPerformAnimation = self.noResultsView.hidden;
    
    self.noResultsView.hidden = !isTableViewEmpty;
    
    if (!isTableViewEmpty) {
        return;
    }
    
    // Refresh the NoResultsView Properties
    self.noResultsView.titleText = self.noResultsTitleText;
    [self.noResultsView centerInSuperview];
    
    if (shouldPerformAnimation) {
        [self.noResultsView fadeInWithAnimation];
    }
}


#pragma mark - Notification handlers

- (void)handleKeyboardWillShow:(NSNotification *)notification
{
    NSDictionary* userInfo = notification.userInfo;

    // Convert the rect to view coordinates: enforce the current orientation!
    CGRect kbRect = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    kbRect = [self.view convertRect:kbRect fromView:nil];

    // Bottom Inset: Consider the tab bar!
    CGRect viewFrame = self.view.frame;
    CGFloat bottomInset = CGRectGetHeight(kbRect) - (CGRectGetMaxY(kbRect) - CGRectGetHeight(viewFrame));

    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:[userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    [UIView setAnimationCurve:[userInfo[UIKeyboardAnimationCurveUserInfoKey] intValue]];

    self.replyTextViewBottomConstraint.constant = bottomInset;
    [self.view layoutIfNeeded];

    [UIView commitAnimations];
}

- (void)handleKeyboardWillHide:(NSNotification *)notification
{
    //deselect the selected comment if there is one
    NSArray *selection = [self.tableView indexPathsForSelectedRows];
    if ([selection count] > 0) {
        [self.tableView deselectRowAtIndexPath:[selection objectAtIndex:0] animated:YES];
    }

    NSDictionary* userInfo = notification.userInfo;

    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:[userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    [UIView setAnimationCurve:[userInfo[UIKeyboardAnimationCurveUserInfoKey] intValue]];

    self.replyTextViewBottomConstraint.constant = 0;
    [self.view layoutIfNeeded];

    [UIView commitAnimations];
}


#pragma mark - Actions

- (void)tapRecognized:(id)sender
{
    self.tapOffKeyboardGesture.enabled = NO;
    self.indexPathForCommentRepliedTo = nil;
    [self.tableView deselectSelectedRowWithAnimation:YES];
    [self.replyTextView resignFirstResponder];
    [self refreshReplyTextViewPlaceholder];
}

- (void)sendReplyWithNewContent:(NSString *)content
{
    __typeof(self) __weak weakSelf = self;
    ReaderPost *post = self.post;
    void (^successBlock)() = ^void() {
        NSMutableDictionary *properties = [NSMutableDictionary dictionary];
        properties[WPAppAnalyticsKeyBlogID] = post.siteID;
        properties[WPAppAnalyticsKeyPostID] = post.postID;
        properties[WPAppAnalyticsKeyIsJetpack] = @(post.isJetpack);
        if (post.feedID && post.feedItemID) {
            properties[WPAppAnalyticsKeyFeedID] = post.feedID;
            properties[WPAppAnalyticsKeyFeedItemID] = post.feedItemID;
        }
        [WPAppAnalytics track:WPAnalyticsStatReaderArticleCommentedOn withProperties:properties];

        [weakSelf.tableView deselectSelectedRowWithAnimation:YES];
        [weakSelf refreshReplyTextViewPlaceholder];
    };

    void (^failureBlock)(NSError *error) = ^void(NSError *error) {
        DDLogError(@"Error sending reply: %@", error);

        NSString *alertMessage = NSLocalizedString(@"There has been an unexpected error while sending your reply", nil);
        NSString *alertCancel = NSLocalizedString(@"Cancel", @"Verb. A button label. Tapping the button dismisses a prompt.");
        NSString *alertTryAgain = NSLocalizedString(@"Try Again", @"A button label. Tapping the re-tries an action that previously failed.");
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                                 message:alertMessage
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        [alertController addCancelActionWithTitle:alertCancel handler:nil];
        [alertController addActionWithTitle:alertTryAgain style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [weakSelf sendReplyWithNewContent:content];
        }];
        [alertController presentFromRootViewController];
    };

    CommentService *service = [[CommentService alloc] initWithManagedObjectContext:self.managedObjectContext];

    if (self.indexPathForCommentRepliedTo) {
        Comment *comment = [self.tableViewHandler.resultsController objectAtIndexPath:self.indexPathForCommentRepliedTo];
        [service replyToHierarchicalCommentWithID:comment.commentID
                                           postID:self.post.postID
                                           siteID:self.post.siteID
                                          content:content
                                          success:successBlock
                                          failure:failureBlock];
    } else {
        [service replyToPostWithID:self.post.postID
                            siteID:self.post.siteID
                           content:content
                           success:successBlock
                           failure:failureBlock];
    }
    self.indexPathForCommentRepliedTo = nil;
}


#pragma mark - Comment Media Cell Methods

- (void)updateCachedMediaCellLayoutForWidth:(CGFloat)width
{
    for (ReaderCommentCell *cell in [self.mediaCellCache allValues]) {
        CGRect frame = cell.frame;
        frame.size.width = width;
        cell.frame = frame;
        [cell layoutIfNeeded];
    }
}

- (NSIndexPath *)indexPathForCommentWithID:(NSNumber *)commentID
{
    NSSet *comments = [self.post.comments filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"commentID = %@", commentID]];
    Comment *comment = [comments anyObject];
    return [self.tableViewHandler.resultsController indexPathForObject:comment];
}

/**
 Do not use dequeued cells for comments with media attachments. We want to avoid
 unnecessary loading/redrawing of the media cell's content which we can't guarentee
 if we use dequeued cells.
 */
- (ReaderCommentCell *)storedCellForIndexPath:(NSIndexPath *)indexPath
{
    Comment *comment = (Comment *)[self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    ReaderCommentCell *cell = [self.mediaCellCache objectForKey:[comment.commentID stringValue]];
    if (!cell) {
        cell = [[ReaderCommentCell alloc] initWithFrame:self.cellForLayout.bounds];
        [cell preventPendingMediaLayout:YES];
        cell.delegate = self;
        [self.mediaCellCache setObject:cell forKey:[comment.commentID stringValue]];
    }
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (NSInteger)numAttachmentsForCommentAtIndexPath:(NSIndexPath *)indexPath
{
    Comment *comment = (Comment *)[self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    NSData *data = [[comment contentForDisplay] dataUsingEncoding:NSUTF8StringEncoding];
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithHTMLData:data
                                                                                options:nil
                                                                     documentAttributes:nil];
    NSInteger numAttachments = [[attributedString textAttachmentsWithPredicate:nil class:nil] count];

    return numAttachments;
}

- (void)preventPendingMediaLayoutInCells:(BOOL)prevent
{
    for (ReaderCommentCell *cell in [self.mediaCellCache allValues]) {
        [cell preventPendingMediaLayout:prevent];
    }
}


#pragma mark - Sync methods

- (void)syncHelper:(WPContentSyncHelper *)syncHelper syncContentWithUserInteraction:(BOOL)userInteraction success:(void (^)(BOOL))success failure:(void (^)(NSError *))failure
{
    CommentService *service = [[CommentService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    [service syncHierarchicalCommentsForPost:self.post page:1 success:^(NSInteger count, BOOL hasMore) {
        if (success) {
            success(hasMore);
        }
    } failure:failure];
    [self refreshNoResultsView];
}

- (void)syncHelper:(WPContentSyncHelper *)syncHelper syncMoreWithSuccess:(void (^)(BOOL))success failure:(void (^)(NSError *))failure
{
    [self.activityFooter startAnimating];

    CommentService *service = [[CommentService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    NSInteger page = [service numberOfHierarchicalPagesSyncedforPost:self.post] + 1;
    [service syncHierarchicalCommentsForPost:self.post page:page success:^(NSInteger count, BOOL hasMore) {
        if (success) {
            success(hasMore);
        }
    } failure:failure];
}

- (void)syncContentEnded
{
    [self.activityFooter stopAnimating];
    [self refreshNoResultsView];
}


#pragma mark - Async Loading Helpers

- (void)setupWithPostID:(NSNumber *)postID siteID:(NSNumber *)siteID
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    ReaderPostService *service      = [[ReaderPostService alloc] initWithManagedObjectContext:context];
    __weak __typeof(self) weakSelf  = self;
    
    self.postSiteID = siteID;
    
    [service fetchPost:postID.integerValue forSite:siteID.integerValue success:^(ReaderPost *post) {

        [weakSelf setPost:post];
        [weakSelf refreshAndSync];
        
    } failure:^(NSError *error) {
        DDLogError(@"[RestAPI] %@", error);
    }];
}


#pragma mark - UITableView Delegate Methods

- (NSManagedObjectContext *)managedObjectContext
{
    return [[ContextManager sharedInstance] mainContext];
}

- (NSString *)entityName
{
    return NSStringFromClass([Comment class]);
}

- (NSFetchRequest *)fetchRequest
{
    if (!self.post) {
        return nil;
    }

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:[self entityName]];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"post = %@", self.post];

    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"hierarchy" ascending:YES];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];

    return fetchRequest;
}

- (void)configureCell:(UITableViewCell *)aCell atIndexPath:(NSIndexPath *)indexPath
{
    ReaderCommentCell *cell = (ReaderCommentCell *)aCell;
    cell.shouldEnableLoggedinFeatures = self.isLoggedIn;
    cell.shouldShowReply = self.canComment;

    Comment *comment = [self.tableViewHandler.resultsController objectAtIndexPath:indexPath];

    if (comment.depth > 0 && indexPath.row > 0) {
        NSIndexPath *previousPath = [NSIndexPath indexPathForRow:indexPath.row - 1 inSection:indexPath.section];
        Comment *previousComment = [self.tableViewHandler.resultsController objectAtIndexPath:previousPath];
        if (previousComment.depth < comment.depth) {
            cell.isFirstNestedComment = YES;
        }
    }

    NSInteger rowsInSection = [self.tableViewHandler tableView:self.tableView numberOfRowsInSection:indexPath.section];
    if (indexPath.row < rowsInSection - 1) {
        NSIndexPath *nextPath = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section];
        Comment *nextComment = [self.tableViewHandler.resultsController objectAtIndexPath:nextPath];
        if ([nextComment.depth integerValue] == 0) {
            cell.needsExtraPadding = YES;
        }
    }

    if (indexPath.row == 0) {
        cell.hidesBorder = YES;
    }

    [cell configureCell:comment];

    if ([cell isEqual:self.cellForLayout]) {
        return;
    }

    [self setAvatarForComment:comment forCell:cell indexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return EstimatedCommentRowHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat width = [UIDevice isPad] ? MIN(WPTableViewFixedWidth, CGRectGetWidth(self.view.bounds)) : CGRectGetWidth(self.tableView.bounds);
    return [self tableView:tableView heightForRowAtIndexPath:indexPath forWidth:width];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath forWidth:(CGFloat)width
{
    CGSize size;
    CGSize sizeToFit = CGSizeMake(width, CGFLOAT_MAX);

    if ([self numAttachmentsForCommentAtIndexPath:indexPath] > 0) {
        size = [[self storedCellForIndexPath:indexPath] sizeThatFits:sizeToFit];
    } else {
        [self configureCell:self.cellForLayout atIndexPath:indexPath];
        size = [self.cellForLayout sizeThatFits:sizeToFit];
    }

    CGFloat height = ceil(size.height);
    return height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger numAttachments = [self numAttachmentsForCommentAtIndexPath:indexPath];
    if (numAttachments > 0) {
        return [self storedCellForIndexPath:indexPath];
    }
    ReaderCommentCell *cell = (ReaderCommentCell *)[self.tableView dequeueReusableCellWithIdentifier:CommentCellIdentifier];
    cell.delegate = self;
    cell.accessoryType = UITableViewCellAccessoryNone;

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
    // Are we approaching the end of the table?
    if ((indexPath.section + 1 == [self.tableViewHandler numberOfSectionsInTableView:tableView]) &&
        (indexPath.row + 4 >= [self.tableViewHandler tableView:tableView numberOfRowsInSection:indexPath.section])) {

        // Only 3 rows till the end of table
        if (self.syncHelper.hasMoreContent) {
            [self.syncHelper syncMoreContent];
        }
    }
}

- (void)tableViewDidChangeContent:(UITableView *)tableView
{
    [self refreshNoResultsView];
}


#pragma mark - UIScrollView Delegate Methods

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self preventPendingMediaLayoutInCells:YES];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self preventPendingMediaLayoutInCells:NO];

    NSArray *selectedRows = [self.tableView indexPathsForSelectedRows];
    [self.tableView deselectRowAtIndexPath:[selectedRows objectAtIndex:0] animated:YES];
    [self.replyTextView resignFirstResponder];
    [self refreshReplyTextViewPlaceholder];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (decelerate) {
        return;
    }
    [self preventPendingMediaLayoutInCells:NO];
}


#pragma mark - SuggestionsTableViewDelegate

- (void)suggestionsTableView:(SuggestionsTableView *)suggestionsTableView didSelectSuggestion:(NSString *)suggestion forSearchText:(NSString *)text
{
    [self.replyTextView replaceTextAtCaret:text withText:suggestion];
    [suggestionsTableView showSuggestionsForWord:@""];
    self.tapOffKeyboardGesture.enabled = YES;
}


#pragma mark - CommentContentView Delegate methods

- (void)commentView:(CommentContentView *)commentView updatedAttachmentViewsForProvider:(id<WPContentViewProvider>)contentProvider
{
    Comment *comment = (Comment *)contentProvider;
    NSIndexPath *indexPath = [self.tableViewHandler.resultsController indexPathForObject:comment];
    if (!indexPath) {
        return;
    }

    [self.tableViewHandler invalidateCachedRowHeightAtIndexPath:indexPath];

    // HACK:
    // For some reason, a single call to reloadRowsAtIndexPath can result in an
    // invalid row height. Calling twice seems to prevent any layout errors at
    // the expense of an extra layout pass.
    // Wrapping the calls in a performWithoutAnimation block ensures the are no
    // strange transitions from the old height to the new.
    // BOTH calls to reloadRowsAtIndexPaths:withRowAnimation are needed to avoid
    // visual oddity.
    [UIView performWithoutAnimation:^{
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }];
}

- (void)commentCell:(UITableViewCell *)cell linkTapped:(NSURL *)url
{
    WPWebViewController *webViewController = [WPWebViewController authenticatedWebViewController:url];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:webViewController];
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)handleReplyTapped:(id<WPContentViewProvider>)contentProvider
{
    // if a row is already selected don't allow selection of another
    if (self.replyTextView.isFirstResponder) {
        [self.replyTextView resignFirstResponder];
        return;
    }

    if (!self.canComment) {
        return;
    }

    [self.replyTextView becomeFirstResponder];

    Comment *comment = (Comment *)contentProvider;
    self.indexPathForCommentRepliedTo = [self.tableViewHandler.resultsController indexPathForObject:comment];
    [self.tableView selectRowAtIndexPath:self.indexPathForCommentRepliedTo animated:YES scrollPosition:UITableViewScrollPositionTop];
    [self refreshReplyTextViewPlaceholder];
}

- (void)toggleLikeStatus:(id<WPContentViewProvider>)contentProvider
{
    Comment *comment = (Comment *)contentProvider;
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    CommentService *commentService = [[CommentService alloc] initWithManagedObjectContext:context];

    [commentService toggleLikeStatusForComment:comment siteID:self.post.siteID success:nil failure:nil];
}

- (void)richTextView:(WPRichTextView *)richTextView didReceiveLinkAction:(NSURL *)linkURL
{
    if (linkURL.path && !linkURL.host) {
        NSURL *url = [NSURL URLWithString:self.post.blogURL];
        linkURL = [NSURL URLWithString:linkURL.path relativeToURL:url];
    }

    WPWebViewController *webViewController = [WPWebViewController authenticatedWebViewController:linkURL];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:webViewController];
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)richTextView:(WPRichTextView *)richTextView didReceiveImageLinkAction:(WPRichTextImage *)imageControl
{
    UIViewController *controller = nil;
    BOOL isSupportedNatively = [WPImageViewController isUrlSupported:imageControl.linkURL];
    
    if (isSupportedNatively) {
        controller = [[WPImageViewController alloc] initWithImage:imageControl.imageView.image andURL:imageControl.linkURL];
    } else if (imageControl.linkURL) {
        WPWebViewController *webViewController = [WPWebViewController authenticatedWebViewController:imageControl.linkURL];
        controller = [[UINavigationController alloc] initWithRootViewController:webViewController];
    } else {
        controller = [[WPImageViewController alloc] initWithImage:imageControl.imageView.image];
    }
    
    if ([controller isKindOfClass:[WPImageViewController class]]) {
        controller.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        controller.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    
    [self presentViewController:controller animated:YES completion:nil];
}


#pragma mark - PostHeaderView helpers

- (void)handleHeaderTapped
{
    if (!self.allowsPushingPostDetails) {
        return;
    }
    
    // Note: Let's manually hide the comments button, in order to prevent recursion in the flow
    ReaderDetailViewController *controller = [ReaderDetailViewController controllerWithPost:self.post];
    controller.shouldHideComments = YES;
    [self.navigationController pushViewController:controller animated:YES];
}


#pragma mark - UITextViewDelegate methods

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    self.tapOffKeyboardGesture.enabled = YES;
    return YES;
}

- (void)textView:(UITextView *)textView didTypeWord:(NSString *)word
{
    // Disable the gestures recognizer when showing suggestions
    BOOL showsSuggestions = [self.suggestionsTableView showSuggestionsForWord:word];
    self.tapOffKeyboardGesture.enabled = !showsSuggestions;
}

@end
