#import "ReaderCommentsViewController.h"

#import "CommentService.h"
#import "CoreDataStack.h"
#import "ReaderPost.h"
#import "ReaderPostService.h"
#import "UIView+Subviews.h"
#import "WPImageViewController.h"
#import "WPTableViewHandler.h"
#import "SuggestionsTableView.h"
#import "WordPress-Swift.h"
#import "WPAppAnalytics.h"

@class Comment;

// NOTE: We want the cells to have a rather large estimated height.  This avoids a peculiar
// crash in certain circumstances when the tableView lays out its visible cells,
// and those cells contain WPRichTextEmbeds. -- Aerych, 2016.11.30
static CGFloat const EstimatedCommentRowHeight = 300.0;
static NSString *RestorablePostObjectIDURLKey = @"RestorablePostObjectIDURLKey";
static NSString *CommentContentCellIdentifier = @"CommentContentTableViewCell";


@interface ReaderCommentsViewController () <NSFetchedResultsControllerDelegate,
                                            WPRichContentViewDelegate, // TODO: Remove once we switch to the `.web` rendering method.
                                            ReplyTextViewDelegate,
                                            UIViewControllerRestoration,
                                            WPContentSyncHelperDelegate,
                                            WPTableViewHandlerDelegate,
                                            SuggestionsTableViewDelegate,
                                            ReaderCommentsFollowPresenterDelegate>

@property (nonatomic, strong, readwrite) ReaderPost *post;
@property (nonatomic, strong) NSNumber *postSiteID;
@property (nonatomic, strong) UIGestureRecognizer *tapOffKeyboardGesture;
@property (nonatomic, strong) UIActivityIndicatorView *activityFooter;
@property (nonatomic, strong) WPContentSyncHelper *syncHelper;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) WPTableViewHandler *tableViewHandler;
@property (nonatomic, strong) NoResultsViewController *noResultsViewController;
@property (nonatomic, strong) ReplyTextView *replyTextView;
@property (nonatomic, strong) KeyboardDismissHelper *keyboardManager;
@property (nonatomic, strong) SuggestionsTableView *suggestionsTableView;
@property (nonatomic, strong) NSIndexPath *indexPathForCommentRepliedTo;
@property (nonatomic, strong) NSLayoutConstraint *replyTextViewHeightConstraint;
@property (nonatomic, strong) NSLayoutConstraint *replyTextViewBottomConstraint;
@property (nonatomic, strong) NSCache *estimatedRowHeights;
@property (nonatomic) BOOL isLoggedIn;
@property (nonatomic) BOOL needsUpdateAttachmentsAfterScrolling;
@property (nonatomic) BOOL needsRefreshTableViewAfterScrolling;
@property (nonatomic, strong) NSError *fetchCommentsError;
@property (nonatomic) BOOL deviceIsRotating;
@property (nonatomic) BOOL userInterfaceStyleChanged;
@property (nonatomic, strong) NSCache *cachedAttributedStrings;
@property (nonatomic, strong) FollowCommentsService *followCommentsService;
@property (nonatomic, strong) ReaderCommentsFollowPresenter *readerCommentsFollowPresenter;
@property (nonatomic, strong) UIBarButtonItem *followBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *subscriptionSettingsBarButtonItem;

/// A cached instance for the new comment header view.
@property (nonatomic, strong) UIView *cachedHeaderView;

/// Convenience computed variable that returns a separator inset that "hides" the separator by pushing it off the screen.
@property (nonatomic, assign) UIEdgeInsets hiddenSeparatorInsets;

@property (nonatomic, strong) NSIndexPath *highlightedIndexPath;

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


#pragma mark - State Restoration

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    NSString *path = [coder decodeObjectForKey:RestorablePostObjectIDURLKey];
    if (!path) {
        return nil;
    }

    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    NSManagedObjectID *objectID = [context.persistentStoreCoordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:path]];
    if (!objectID) {
        return nil;
    }

    NSError *error = nil;
    ReaderPost *restoredPost = (ReaderPost *)[context existingObjectWithID:objectID error:&error];
    if (error || !restoredPost) {
        return nil;
    }

    return [self controllerWithPost:restoredPost source:ReaderCommentsSourcePostDetails];
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [coder encodeObject:[[self.post.objectID URIRepresentation] absoluteString] forKey:RestorablePostObjectIDURLKey];
    [super encodeRestorableStateWithCoder:coder];
}


#pragma mark - LifeCycle Methods

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.restorationIdentifier = NSStringFromClass([self class]);
        self.restorationClass = [self class];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor murielBasicBackground];
    self.commentModified = NO;

    [self checkIfLoggedIn];

    [self configureNavbar];
    [self configureTableView];
    [self configureTableViewHandler];
    [self configureNoResultsView];
    [self configureReplyTextView];
    [self configureSuggestionsTableView];
    [self configureKeyboardGestureRecognizer];
    [self configureViewConstraints];
    [self configureKeyboardManager];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.keyboardManager startListeningToKeyboardNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleApplicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];

    [self refreshAndSync];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.tableView reloadData];

    if (self.promptToAddComment) {
        [self.replyTextView becomeFirstResponder];

        // Reset the value to prevent prompting again if the user leaves and comes back
        self.promptToAddComment = NO;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self dismissNotice];
    
    if (self.commentModified) {
        // Don't post the notification until the view is being dismissed to avoid purging cached comments prematurely.
        [self postCommentModifiedNotification];
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-result"
    [self.replyTextView resignFirstResponder];
#pragma clang diagnostic pop
    [self.keyboardManager stopListeningToKeyboardNotifications];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    self.deviceIsRotating = true;

    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull __unused context) {
        self.deviceIsRotating = false;
        NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
        // Make sure a selected comment is visible after rotating, and that the replyTextView is still the first responder.
        if (selectedIndexPath) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-result"
            [self.replyTextView becomeFirstResponder];
#pragma clang diagnostic pop
            [self.tableView selectRowAtIndexPath:selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
    }];
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

-(void)trackCommentLikedOrUnliked:(Comment *) comment {
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

-(void)trackReplyTo:(BOOL)replyTarget {
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

- (void)configureTableView
{
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.cellLayoutMarginsFollowReadableWidth = YES;
    self.tableView.preservesSuperviewLayoutMargins = YES;
    self.tableView.backgroundColor = [UIColor murielBasicBackground];
    [self.view addSubview:self.tableView];

    // register the content cell
    UINib *nib = [UINib nibWithNibName:[CommentContentTableViewCell classNameWithoutNamespaces] bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:CommentContentCellIdentifier];

    // configure table view separator
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.separatorInsetReference = UITableViewSeparatorInsetFromAutomaticInsets;

    // hide cell separator for the last row
    self.tableView.tableFooterView = [self tableFooterViewForHiddenSeparators];

    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;

    self.estimatedRowHeights = [[NSCache alloc] init];
    self.cachedAttributedStrings = [[NSCache alloc] init];
}

- (void)configureTableViewHandler
{
    self.tableViewHandler = [[WPTableViewHandler alloc] initWithTableView:self.tableView];
    self.tableViewHandler.updateRowAnimation = UITableViewRowAnimationNone;
    self.tableViewHandler.insertRowAnimation = UITableViewRowAnimationNone;
    self.tableViewHandler.moveRowAnimation = UITableViewRowAnimationNone;
    self.tableViewHandler.deleteRowAnimation = UITableViewRowAnimationNone;
    self.tableViewHandler.delegate = self;
    [self.tableViewHandler setListensForContentChanges:NO];
}

- (void)configureNoResultsView
{
    self.noResultsViewController = [NoResultsViewController controller];
}

- (void)configureReplyTextView
{
    __typeof(self) __weak weakSelf = self;

    ReplyTextView *replyTextView = [[ReplyTextView alloc] initWithWidth:CGRectGetWidth(self.view.frame)];
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

    self.suggestionsTableView = [[SuggestionsTableView alloc] initWithSiteID:siteID suggestionType:SuggestionTypeMention delegate:self];
    [self.suggestionsTableView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:self.suggestionsTableView];
}

- (void)configureKeyboardGestureRecognizer
{
    self.tapOffKeyboardGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapRecognized:)];
    self.tapOffKeyboardGesture.enabled = NO;
    [self.view addGestureRecognizer:self.tapOffKeyboardGesture];
}

- (void)configureKeyboardManager
{
    // The variable introduced because we cannot reuse the same constraint for the keyboard manager and the reply text view.
    self.replyTextViewBottomConstraint = [self.view.keyboardLayoutGuide.topAnchor constraintEqualToAnchor:self.replyTextView.bottomAnchor];
    self.keyboardManager = [[KeyboardDismissHelper alloc] initWithParentView:self.view
                                                                  scrollView:self.tableView
                                                          dismissableControl:self.replyTextView
                                                      bottomLayoutConstraint:self.replyTextViewBottomConstraint];

    __weak UITableView *weakTableView = self.tableView;
    __weak ReaderCommentsViewController *weakSelf = self;
    self.keyboardManager.onWillHide = ^{
        [weakTableView deselectSelectedRowWithAnimation:YES];
        [weakSelf refreshNoResultsView];
    };
    self.keyboardManager.onWillShow = ^{
        [weakSelf refreshNoResultsView];
    };
}

#pragma mark - Autolayout Helpers

- (void)configureViewConstraints
{
    NSMutableDictionary *views = [[NSMutableDictionary alloc] initWithDictionary:@{
        @"tableView"        : self.tableView,
        @"mainView"         : self.view,
        @"suggestionsview"  : self.suggestionsTableView,
        @"replyTextView"    : self.replyTextView
    }];

    NSString *verticalVisualFormatString = @"V:|[tableView][replyTextView]";

    // TableView Contraints
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:verticalVisualFormatString
                                                                      options:0
                                                                      metrics:nil
                                                                        views:views]];

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[tableView]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:views]];

    [NSLayoutConstraint activateConstraints:@[
        [self.replyTextView.leadingAnchor constraintEqualToAnchor:self.replyTextView.leadingAnchor],
        [self.replyTextView.trailingAnchor constraintEqualToAnchor:self.replyTextView.trailingAnchor],
        [self.view.keyboardLayoutGuide.topAnchor constraintEqualToAnchor:self.replyTextView.bottomAnchor]
    ]];

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
                                                                      attribute:0
                                                                     multiplier:1
                                                                       constant:0];
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

- (UIView *)tableFooterViewForHiddenSeparators
{
    return [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 0)];
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

- (void)setIndexPathForCommentRepliedTo:(NSIndexPath *)indexPathForCommentRepliedTo
{
    // un-highlight the cell if a highlighted Reply button is tapped.
    if (_indexPathForCommentRepliedTo && indexPathForCommentRepliedTo && _indexPathForCommentRepliedTo == indexPathForCommentRepliedTo) {
        [self tapRecognized:nil];
        return;
    }

    if (_indexPathForCommentRepliedTo) {
        CommentContentTableViewCell *previousCell = (CommentContentTableViewCell *)[self.tableView cellForRowAtIndexPath:_indexPathForCommentRepliedTo];
        previousCell.isReplyHighlighted = NO;
    }

    if (indexPathForCommentRepliedTo) {
        CommentContentTableViewCell *cell = (CommentContentTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPathForCommentRepliedTo];
        cell.isReplyHighlighted = YES;
    }

    self.highlightedIndexPath = indexPathForCommentRepliedTo;
    _indexPathForCommentRepliedTo = indexPathForCommentRepliedTo;
    
    [self refreshProminentSuggestions];
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

- (UIActivityIndicatorView *)activityFooter
{
    if (_activityFooter) {
        return _activityFooter;
    }

    _activityFooter = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    _activityFooter.activityIndicatorViewStyle = UIActivityIndicatorViewStyleMedium;
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

- (BOOL)canFollowConversation
{
    return [self.followCommentsService canFollowConversation];
}

- (BOOL)shouldDisplayReplyTextView
{
    return self.canComment;
}

- (BOOL)shouldDisplaySuggestionsTableView
{
    return self.shouldDisplayReplyTextView && [self shouldShowSuggestionsFor:self.post.siteID];
}

#pragma mark - View Refresh Helpers

- (void)refreshAndSync
{
    [self refreshFollowButton];
    [self refreshSubscriptionStatusIfNeeded];
    [self refreshReplyTextView];
    [self refreshSuggestionsTableView];
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
        [ContextManager.sharedInstance saveContext:weakSelf.post.managedObjectContext];
    } failure:^(NSError *error) {
        DDLogError(@"Error fetching subscription status for post: %@", error);
    }];
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
    [self refreshProminentSuggestions];
}

- (void)refreshProminentSuggestions
{
    NSIndexPath *commentIndexPath = self.indexPathForCommentRepliedTo;
    WPAccount *defaultAccount = [WPAccount lookupDefaultWordPressComAccountInContext:self.managedObjectContext];
    NSNumber *defaultAccountId = defaultAccount ? defaultAccount.userID : nil;
    NSNumber *postAuthorId = self.post ? self.post.authorID : nil;
    Comment *comment = commentIndexPath ? [self.tableViewHandler.resultsController objectAtIndexPath:commentIndexPath] : nil;
    NSNumber *commentAuthorId = comment ? [NSNumber numberWithInt:comment.authorID] : nil;
    self.suggestionsTableView.prominentSuggestionsIds = [SuggestionsTableView prominentSuggestionsFromPostAuthorId:postAuthorId
                                                                                                 commentAuthorId:commentAuthorId
                                                                                                  defaultAccountId:defaultAccountId];
}

- (void)refreshReplyTextViewPlaceholder
{
    if (self.tableView.indexPathForSelectedRow) {
        Comment *comment = [self.tableViewHandler.resultsController objectAtIndexPath:self.indexPathForCommentRepliedTo];
        NSString *placeholderFormat = NSLocalizedString(@"Reply to %1$@", @"Placeholder text for replying to a comment. %1$@ is a placeholder for the comment author's name.");
        self.replyTextView.placeholder = [NSString stringWithFormat:placeholderFormat, [comment authorForDisplay]];
    } else {
        self.replyTextView.accessibilityIdentifier = @"reply-to-post-text-field";
        self.replyTextView.placeholder = NSLocalizedString(@"Reply to post", @"Placeholder text for replying to a post");
    }
}

- (void)refreshInfiniteScroll
{
    if (self.syncHelper.hasMoreContent) {
        CGFloat width = CGRectGetWidth(self.tableView.bounds);
        UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, width, 50.0f)];
        footerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        CGRect rect = self.activityFooter.frame;
        rect.origin.x = (width - rect.size.width) / 2.0;
        self.activityFooter.frame = rect;

        [footerView addSubview:self.activityFooter];
        self.tableView.tableFooterView = footerView;
        
    } else {
        self.tableView.tableFooterView = [self tableFooterViewForHiddenSeparators];
        self.activityFooter = nil;
    }
}

- (void)refreshNoResultsView
{
    // During rotation, the keyboard hides and shows.
    // To prevent view flashing, do nothing until rotation is finished.
    if (self.deviceIsRotating) {
        return;
    }

    [self.noResultsViewController removeFromView];

    BOOL isTableViewEmpty = (self.tableViewHandler.resultsController.fetchedObjects.count == 0);
    if (!isTableViewEmpty) {
        return;
    }

    // Because the replyTextView grows, limit what is displayed with the keyboard visible:
    // iPhone landscape: show nothing.
    // iPhone portrait: hide the image.
    // iPad landscape: hide the image.
    
    BOOL isLandscape = UIDevice.currentDevice.orientation != UIDeviceOrientationPortrait;
    BOOL hideImageView = false;
    if (self.keyboardManager.isKeyboardVisible) {

        if (WPDeviceIdentification.isiPhone && isLandscape) {
            return;
        }
        
        hideImageView = (WPDeviceIdentification.isiPhone && !isLandscape) || (WPDeviceIdentification.isiPad && isLandscape);
    }
    NSString *image = nil;
    NSString *subtitle = nil;
    if (self.fetchCommentsError != nil) {
        image = @"wp-illustration-reader-empty";
        NSError *error = self.fetchCommentsError;
        if (error && [error.domain isEqualToString:WordPressComRestApiErrorDomain] && error.code == WordPressComRestApiErrorCodeAuthorizationRequired) {
            subtitle = NSLocalizedString(@"You have no access to the private blog.",
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

    [self.noResultsViewController hideImageView:hideImageView];
    [self addChildViewController:self.noResultsViewController];

    // when the table view is not yet properly initialized, use the view's frame instead to prevent wrong frame values.
    if (self.tableView.window == nil) {
        self.noResultsViewController.view.frame = self.view.frame;
    } else {
        self.noResultsViewController.view.frame = self.tableView.frame;
    }

    [self.view insertSubview:self.noResultsViewController.view belowSubview:self.replyTextView];
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


- (void)refreshTableViewAndNoResultsView
{
    [self.tableViewHandler refreshTableView];
    [self refreshNoResultsView];
    [self.managedObjectContext performBlock:^{
        [self updateCachedContent];
    }];

    [self navigateToCommentIDIfNeeded];
}

- (void)updateCachedContent
{
    NSArray *comments = self.tableViewHandler.resultsController.fetchedObjects;
    for(Comment *comment in comments) {
        [self cacheContentForComment:comment];
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
    if (self.navigateToCommentID != nil) {
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

        // Reset the commentID so we don't do this again.
        self.navigateToCommentID = nil;
    }
}

#pragma mark - Actions

- (void)tapRecognized:(id)sender
{
    self.tapOffKeyboardGesture.enabled = NO;
    self.indexPathForCommentRepliedTo = nil;
    [self.tableView deselectSelectedRowWithAnimation:YES];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-result"
    [self.replyTextView resignFirstResponder];
#pragma clang diagnostic pop
    [self refreshReplyTextViewPlaceholder];
}

- (void)sendReplyWithNewContent:(NSString *)content
{
    __typeof(self) __weak weakSelf = self;

    BOOL replyToComment = self.indexPathForCommentRepliedTo != nil;
    UINotificationFeedbackGenerator *generator = [UINotificationFeedbackGenerator new];
    [generator prepare];

    void (^successBlock)(void) = ^void() {
        [generator notificationOccurred:UINotificationFeedbackTypeSuccess];
        NSString *successMessage = NSLocalizedString(@"Reply Sent!", @"The app successfully sent a comment");
        [weakSelf displayNoticeWithTitle:successMessage message:nil];

        [weakSelf trackReplyTo:replyToComment];
        [weakSelf.tableView deselectSelectedRowWithAnimation:YES];
        [weakSelf refreshReplyTextViewPlaceholder];

        // Dispatch is used here to address an issue in iOS 15 where some cells could disappear from the screen after `reloadData`.
        // This seems to be affecting the Simulator environment only since I couldn't reproduce it on the device, but I'm fixing it just in case.
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf refreshTableViewAndNoResultsView];
        });
    };

    void (^failureBlock)(NSError *error) = ^void(NSError *error) {
        DDLogError(@"Error sending reply: %@", error);
        [generator notificationOccurred:UINotificationFeedbackTypeError];
        NSString *message = NSLocalizedString(@"There has been an unexpected error while sending your reply", "Reply Failure Message");
        [weakSelf displayNoticeWithTitle:message message:nil];

        [weakSelf refreshTableViewAndNoResultsView];
    };

    CommentService *service = [[CommentService alloc] initWithCoreDataStack:[ContextManager sharedInstance]];

    if (replyToComment) {
        Comment *comment = [self.tableViewHandler.resultsController objectAtIndexPath:self.indexPathForCommentRepliedTo];
        [service replyToHierarchicalCommentWithID:[NSNumber numberWithInt:comment.commentID]
                                             post:self.post
                                          content:content
                                          success:successBlock
                                          failure:failureBlock];
    } else {
        [service replyToPost:self.post
                     content:content
                     success:successBlock
                     failure:failureBlock];
    }
    self.indexPathForCommentRepliedTo = nil;
}

- (void)didTapReplyAtIndexPath:(NSIndexPath *)indexPath
{
    if (!indexPath || !self.canComment) {
        return;
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-result"
    [self.replyTextView becomeFirstResponder];
#pragma clang diagnostic pop

    self.indexPathForCommentRepliedTo = indexPath;
    [self.tableView selectRowAtIndexPath:self.indexPathForCommentRepliedTo animated:YES scrollPosition:UITableViewScrollPositionTop];
    [self refreshReplyTextViewPlaceholder];
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
    [self.activityFooter startAnimating];

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
    [self.activityFooter stopAnimating];
    if ([self.tableViewHandler isScrolling]) {
        self.needsRefreshTableViewAfterScrolling = YES;
        return;
    }

    [self refreshTableViewAndNoResultsView];
}

- (void)syncContentFailed:(WPContentSyncHelper *)syncHelper
{
    self.fetchCommentsError = [NSError errorWithDomain:@"" code:0 userInfo:nil];
    [self.activityFooter stopAnimating];
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
        [self.activityFooter stopAnimating];
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
    [self configureContentCell:cell comment:comment attributedText:[self cacheContentForComment:comment] indexPath:indexPath handler:self.tableViewHandler];

    if (self.highlightedIndexPath) {
        cell.isEmphasized = (indexPath == self.highlightedIndexPath);
    }

    if (self.indexPathForCommentRepliedTo) {
        cell.isReplyHighlighted = (indexPath == self.indexPathForCommentRepliedTo);
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

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.keyboardManager scrollViewWillBeginDragging:scrollView];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self refreshReplyTextViewPlaceholder];

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

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.keyboardManager scrollViewDidScroll:scrollView];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    [self.keyboardManager scrollViewWillEndDragging:scrollView withVelocity:velocity];
}


#pragma mark - SuggestionsTableViewDelegate

- (void)suggestionsTableView:(SuggestionsTableView *)suggestionsTableView didSelectSuggestion:(NSString *)suggestion forSearchText:(NSString *)text
{
    [self.replyTextView replaceTextAtCaret:text withText:suggestion];
    [suggestionsTableView showSuggestionsForWord:@""];
    self.tapOffKeyboardGesture.enabled = YES;
}


- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction
{
    return NO;
}

#pragma mark - WPRichContentDelegate Methods

- (void)richContentView:(WPRichContentView *)richContentView didReceiveImageAction:(WPRichTextImage *)image
{
    UIViewController *controller = nil;
    BOOL isSupportedNatively = [WPImageViewController isUrlSupported:image.linkURL];

    if (image.imageView.animatedGifData) {
        controller = [[WPImageViewController alloc] initWithGifData:image.imageView.animatedGifData];
    } else if (isSupportedNatively) {
        controller = [[WPImageViewController alloc] initWithImage:image.imageView.image andURL:image.linkURL];
    } else if (image.linkURL) {
        [self presentWebViewControllerWithURL:image.linkURL];
        return;
    } else if (image.imageView.image) {
        controller = [[WPImageViewController alloc] initWithImage:image.imageView.image];
    }

    if (controller) {
        controller.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        controller.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:controller animated:YES completion:nil];
    }
}

- (void)interactWithURL:(NSURL *)URL
{
    [self presentWebViewControllerWithURL:URL];
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

- (void)presentWebViewControllerWithURL:(NSURL *)URL
{
    NSURL *linkURL = URL;
    NSURLComponents *components = [NSURLComponents componentsWithString:[URL absoluteString]];
    if (!components.host) {
        linkURL = [components URLRelativeToURL:[NSURL URLWithString:self.post.blogURL]];
    }

    WebViewControllerConfiguration *configuration = [[WebViewControllerConfiguration alloc] initWithUrl:linkURL];
    [configuration authenticateWithDefaultAccount];
    [configuration setAddsWPComReferrer:YES];
    UIViewController *webViewController = [WebViewControllerFactory controllerWithConfiguration:configuration source:@"reader_comments"];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:webViewController];
    [self presentViewController:navController animated:YES completion:nil];
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

- (void)replyTextView:(ReplyTextView *)replyTextView willEnterFullScreen:(FullScreenCommentReplyViewController *)controller
{
    NSString *searchText = [self.suggestionsTableView viewModel].searchText;
    [self.suggestionsTableView hideSuggestions];
    [controller enableSuggestionsWith:self.siteID prominentSuggestionsIds:self.suggestionsTableView.prominentSuggestionsIds
                        searchText:searchText];
}

- (void)replyTextView:(ReplyTextView *)replyTextView didExitFullScreen:(NSString *)lastSearchText
{
    if ([lastSearchText length] != 0) {
        [self.suggestionsTableView showSuggestionsForWord:lastSearchText];
    }
}

@end
