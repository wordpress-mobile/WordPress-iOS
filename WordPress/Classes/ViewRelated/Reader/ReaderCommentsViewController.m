#import "ReaderCommentsViewController.h"

#import "CommentService.h"
#import "ContextManager.h"
#import "ReaderPost.h"
#import "ReaderPostService.h"
#import "ReaderPostHeaderView.h"
#import "UIView+Subviews.h"
#import "WPImageViewController.h"
#import "WPTableViewHandler.h"
#import "SuggestionsTableView.h"
#import "WordPress-Swift.h"
#import "WPAppAnalytics.h"
#import <WordPressUI/WordPressUI.h>

@class Comment;

// NOTE: We want the cells to have a rather large estimated height.  This avoids a peculiar
// crash in certain circumstances when the tableView lays out its visible cells,
// and those cells contain WPRichTextEmbeds. -- Aerych, 2016.11.30
static CGFloat const EstimatedCommentRowHeight = 300.0;
static NSInteger const MaxCommentDepth = 4.0;
static CGFloat const CommentIndentationWidth = 40.0;

static NSString *CommentCellIdentifier = @"CommentDepth0CellIdentifier";
static NSString *RestorablePostObjectIDURLKey = @"RestorablePostObjectIDURLKey";
static NSString *CommentContentCellIdentifier = @"CommentContentTableViewCell";


@interface ReaderCommentsViewController () <NSFetchedResultsControllerDelegate,
                                            ReaderCommentCellDelegate,
                                            ReplyTextViewDelegate,
                                            UIViewControllerRestoration,
                                            WPContentSyncHelperDelegate,
                                            WPTableViewHandlerDelegate,
                                            SuggestionsTableViewDelegate,
                                            ReaderCommentsNotificationSheetDelegate>

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
@property (nonatomic, strong) UIView *postHeaderWrapper;
@property (nonatomic, strong) ReaderPostHeaderView *postHeaderView;
@property (nonatomic, strong) NSIndexPath *indexPathForCommentRepliedTo;
@property (nonatomic, strong) NSLayoutConstraint *replyTextViewHeightConstraint;
@property (nonatomic, strong) NSLayoutConstraint *replyTextViewBottomConstraint;
@property (nonatomic, strong) NSCache *estimatedRowHeights;
@property (nonatomic) BOOL isLoggedIn;
@property (nonatomic) BOOL needsUpdateAttachmentsAfterScrolling;
@property (nonatomic) BOOL needsRefreshTableViewAfterScrolling;
@property (nonatomic) BOOL failedToFetchComments;
@property (nonatomic) BOOL deviceIsRotating;
@property (nonatomic) BOOL userInterfaceStyleChanged;
@property (nonatomic, strong) NSCache *cachedAttributedStrings;
@property (nonatomic, strong) FollowCommentsService *followCommentsService;

@property (nonatomic, strong) UIBarButtonItem *followBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *subscriptionSettingsBarButtonItem;

/// A cached instance for the new comment header view.
@property (nonatomic, strong) UIView *cachedHeaderView;

/// Caches the post subscription state. Used to revert subscription state when the update request fails.
@property (nonatomic, assign) BOOL subscribedToPost;

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

    [self checkIfLoggedIn];

    [self configureNavbar];
    [self configurePostHeader];
    [self configureTableView];
    [self configureTableViewHandler];
    [self configureNoResultsView];
    [self configureReplyTextView];
    [self configureSuggestionsTableView];
    [self configureKeyboardGestureRecognizer];
    [self configureViewConstraints];
    [self configureKeyboardManager];

    if (![self newCommentThreadEnabled]) {
        [self refreshAndSync];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.keyboardManager startListeningToKeyboardNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleApplicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];

    if ([self newCommentThreadEnabled]) {
        [self refreshAndSync];
    }
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

    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
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

- (void)configurePostHeader
{
    // Don't show the current post header view when the newCommentThread flag is enabled.
    // the new header will displayed as a table section header.
    if ([self newCommentThreadEnabled]) {
        return;
    }

    __typeof(self) __weak weakSelf = self;
    
    // Wrapper view
    UIView *headerWrapper = [UIView new];
    headerWrapper.translatesAutoresizingMaskIntoConstraints = NO;
    headerWrapper.preservesSuperviewLayoutMargins = YES;
    headerWrapper.backgroundColor = [UIColor whiteColor];
    headerWrapper.clipsToBounds = YES;

    // Post header view
    ReaderPostHeaderView *headerView = [[ReaderPostHeaderView alloc] init];
    headerView.onClick = ^{
        [weakSelf handleHeaderTapped];
    };
    headerView.onFollowConversationClick = ^{
        [weakSelf handleFollowConversationButtonTapped];
    };
    headerView.translatesAutoresizingMaskIntoConstraints = NO;
    headerView.showsDisclosureIndicator = self.allowsPushingPostDetails;
    [headerView setSubtitle:NSLocalizedString(@"Comments on", @"Sentence fragment. The full phrase is 'Comments on' followed by the title of a post on a separate line.")];
    [headerWrapper addSubview:headerView];

    // Border
    CGRect borderRect = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 1.0);
    UIView *borderView = [[UIView alloc] initWithFrame:borderRect];
    borderView.backgroundColor = [UIColor murielNeutral5];
    borderView.translatesAutoresizingMaskIntoConstraints = NO;
    [headerWrapper addSubview:borderView];

    // Layout
    NSDictionary *views = NSDictionaryOfVariableBindings(headerView, borderView);
    [headerWrapper addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[headerView]|"
                                                                          options:0
                                                                          metrics:nil
                                                                            views:views]];
    [headerWrapper addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[headerView][borderView(1@1000)]|"
                                                                          options:0
                                                                          metrics:nil
                                                                            views:views]];
    [headerWrapper addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[borderView]|"
                                                                          options:0
                                                                          metrics:nil
                                                                            views:views]];

    self.postHeaderView = headerView;
    self.postHeaderWrapper = headerWrapper;
    [self.view addSubview:self.postHeaderWrapper];
}

- (void)configureTableView
{
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.cellLayoutMarginsFollowReadableWidth = YES;
    self.tableView.preservesSuperviewLayoutMargins = YES;
    self.tableView.backgroundColor = [UIColor murielBasicBackground];
    [self.view addSubview:self.tableView];

    if ([self newCommentThreadEnabled]) {
        // register the content cell
        UINib *nib = [UINib nibWithNibName:[CommentContentTableViewCell classNameWithoutNamespaces] bundle:nil];
        [self.tableView registerNib:nib forCellReuseIdentifier:CommentContentCellIdentifier];

        // configure table view separator
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        self.tableView.separatorInsetReference = UITableViewSeparatorInsetFromAutomaticInsets;

        // hide cell separator for the last row
        self.tableView.tableFooterView = [self tableFooterViewForHiddenSeparators];

    } else {
        UINib *commentNib = [UINib nibWithNibName:@"ReaderCommentCell" bundle:nil];
        [self.tableView registerNib:commentNib forCellReuseIdentifier:CommentCellIdentifier];

        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }

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

    if (![self newCommentThreadEnabled]) {
        [views setObject:self.postHeaderWrapper forKey:@"postHeader"];
        verticalVisualFormatString = @"V:|[postHeader][tableView][replyTextView]";

        // PostHeader Constraints
        [[self.postHeaderWrapper.leftAnchor constraintEqualToAnchor:self.tableView.leftAnchor] setActive:YES];
        [[self.postHeaderWrapper.rightAnchor constraintEqualToAnchor:self.tableView.rightAnchor] setActive:YES];
    }

    // TableView Contraints
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:verticalVisualFormatString
                                                                      options:0
                                                                      metrics:nil
                                                                        views:views]];

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[tableView]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:views]];

    // ReplyTextView Constraints
    [[self.replyTextView.leftAnchor constraintEqualToAnchor:self.tableView.leftAnchor] setActive:YES];
    [[self.replyTextView.rightAnchor constraintEqualToAnchor:self.tableView.rightAnchor] setActive:YES];

    self.replyTextViewBottomConstraint = [NSLayoutConstraint constraintWithItem:self.view
                                                                      attribute:NSLayoutAttributeBottom
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.replyTextView
                                                                      attribute:NSLayoutAttributeBottom
                                                                     multiplier:1.0
                                                                       constant:0.0];
    self.replyTextViewBottomConstraint.priority = UILayoutPriorityDefaultHigh;

    [self.view addConstraint:self.replyTextViewBottomConstraint];

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
    // Let's just display the same message, for consistency's sake
    if (self.isLoadingPost || self.syncHelper.isSyncing) {
        return NSLocalizedString(@"Fetching comments...", @"A brief prompt shown when the comment list is empty, letting the user know the app is currently fetching new comments.");
    }
    // If we couldn't fetch the comments lets let the user know
    if (self.failedToFetchComments) {
        return NSLocalizedString(@"There has been an unexpected error while loading the comments.", @"Message shown when comments for a post can not be loaded.");
    }
    return NSLocalizedString(@"Be the first to leave a comment.", @"Message shown encouraging the user to leave a comment on a post in the reader.");
}

- (UIView *)noResultsAccessoryView
{
    UIView *loadingAccessoryView = nil;
    if (self.isLoadingPost || self.syncHelper.isSyncing) {
        loadingAccessoryView = [NoResultsViewController loadingAccessoryView];
    }
    return loadingAccessoryView;
}

- (void)checkIfLoggedIn
{
    self.isLoggedIn = [AccountHelper isDotcomAvailable];
}

- (BOOL)followViaNotificationsEnabled
{
    return [Feature enabled:FeatureFlagFollowConversationViaNotifications];
}

- (BOOL)newCommentThreadEnabled
{
    return [Feature enabled:FeatureFlagNewCommentThread];
}

- (UIView *)tableFooterViewForHiddenSeparators
{
    return [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 0)];
}

- (void)setHighlightedIndexPath:(NSIndexPath *)highlightedIndexPath
{
    if (![self newCommentThreadEnabled]) {
        _highlightedIndexPath = highlightedIndexPath;
        return;
    }

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
    if (![self newCommentThreadEnabled]) {
        _indexPathForCommentRepliedTo = indexPathForCommentRepliedTo;
        return;
    }

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
}

- (UIView *)cachedHeaderView {
    if (!_cachedHeaderView && [self newCommentThreadEnabled]) {
        _cachedHeaderView = [self configuredHeaderViewFor:self.tableView];
    }

    return _cachedHeaderView;
}

// NOTE: remove this when the `followConversationViaNotifications` flag is removed.
- (void)setSubscribedToPost:(BOOL)subscribedToPost {
    if (self.postHeaderView) {
        self.postHeaderView.isSubscribedToPost = subscribedToPost;
    }

    _subscribedToPost = subscribedToPost;
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
    [self refreshPostHeaderView];
    [self refreshSubscriptionStatusIfNeeded];
    [self refreshReplyTextView];
    [self refreshSuggestionsTableView];
    [self refreshInfiniteScroll];
    [self refreshTableViewAndNoResultsView];

    [self.syncHelper syncContent];
}

- (void)refreshPostHeaderView
{
    if ([self newCommentThreadEnabled]) {
        return;
    }

    NSParameterAssert(self.postHeaderView);
    NSParameterAssert(self.postHeaderWrapper);
    
    self.postHeaderWrapper.hidden = self.isLoadingPost;
    if (self.isLoadingPost) {
        return;
    }
    
    [self.postHeaderView setTitle:self.post.titleForDisplay];

    CGFloat scale = [[UIScreen mainScreen] scale];
    CGSize imageSize = CGSizeMake(PostHeaderViewAvatarSize * scale, PostHeaderViewAvatarSize * scale);
    UIImage *image = [self.post cachedAvatarWithSize:imageSize];
    if (image) {
        [self.postHeaderView setAvatarImage:image];
    } else {
        [self.post fetchAvatarWithSize:imageSize success:^(UIImage *image) {
            [self.postHeaderView setAvatarImage:image];
        }];
    }

    // when the "follow via notifications" flag is enabled, the Follow button is moved into the navigation bar as a UIButtonBarItem.
    self.postHeaderView.showsFollowConversationButton = self.canFollowConversation && ![self followViaNotificationsEnabled];
}

- (void)refreshFollowButton
{
    if (!self.canFollowConversation || ![self followViaNotificationsEnabled]) {
        return;
    }

    self.navigationItem.rightBarButtonItem = self.post.isSubscribedComments ? self.subscriptionSettingsBarButtonItem : self.followBarButtonItem;
}

// NOTE: Remove this method once "follow via notifications" feature flag can be removed.
// Subscription status is now available through ReaderPost's `isSubscribedComments` Boolean property.
- (void)refreshSubscriptionStatusIfNeeded
{
    __weak __typeof(self) weakSelf = self;
    [self.followCommentsService fetchSubscriptionStatusWithSuccess:^(BOOL isSubscribed) {
        weakSelf.subscribedToPost = isSubscribed;

        if ([self followViaNotificationsEnabled]) {
            // update the ReaderPost button to keep it in-sync.
            self.post.isSubscribedComments = isSubscribed;
            [ContextManager.sharedInstance saveContext:self.post.managedObjectContext];
        }

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
}

- (void)refreshReplyTextViewPlaceholder
{
    if (self.tableView.indexPathForSelectedRow) {
        Comment *comment = [self.tableViewHandler.resultsController objectAtIndexPath:self.indexPathForCommentRepliedTo];
        NSString *placeholderFormat = NSLocalizedString(@"Reply to %1$@", @"Placeholder text for replying to a comment. %1$@ is a placeholder for the comment author's name.");
        self.replyTextView.placeholder = [NSString stringWithFormat:placeholderFormat, [comment authorForDisplay]];
    } else {
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
        self.tableView.tableFooterView = [self newCommentThreadEnabled] ? [self tableFooterViewForHiddenSeparators] : nil;
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
    [self.noResultsViewController configureWithTitle:self.noResultsTitleText
                                     attributedTitle:nil
                                   noConnectionTitle:nil
                                         buttonTitle:nil
                                            subtitle:nil
                                noConnectionSubtitle:nil
                                  attributedSubtitle:nil
                     attributedSubtitleConfiguration:nil
                                               image:nil
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

    [self.view insertSubview:self.noResultsViewController.view belowSubview:self.suggestionsTableView];
    [self.noResultsViewController didMoveToParentViewController:self];
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

        NSIndexPath *indexPath = [self.tableViewHandler.resultsController indexPathForObject:comment];

        if ([self newCommentThreadEnabled]) {
            // Force the table view to be laid out first before scrolling to indexPath.
            // This avoids a case where a cell instance could be orphaned and displayed randomly on top of the other cells.
            [self.tableView layoutIfNeeded];
            [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
        } else {
            // Dispatch to ensure the tableview has reloaded before we scroll
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
                // Yes, calling this twice is horrible.
                // Our row heights are dynamically calculated, and the first time we perform a scroll it
                // seems that we may end up in slightly the wrong position.
                // If we then immediately scroll again, everything has been laid out, and we should end up
                // at the correct row. @frosty 2021-05-06
                [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES ];
            });
        }

        self.highlightedIndexPath = indexPath;

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

    CommentService *service = [[CommentService alloc] initWithManagedObjectContext:self.managedObjectContext];

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

- (void)subscriptionSettingsButtonTapped
{
    [self showNotificationSheetWithNotificationsEnabled:self.post.receivesCommentNotifications
                                               delegate:self
                                    sourceBarButtonItem:self.navigationItem.rightBarButtonItem];
}

- (void)didTapReplyAtIndexPath:(NSIndexPath *)indexPath
{
    // in the new comment thread, we want to allow tapping the Reply button again to un-highlight the row.
    if (![self newCommentThreadEnabled] && self.replyTextView.isFirstResponder) {
        // if a row is already selected don't allow selection of another
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-result"
        [self.replyTextView resignFirstResponder];
#pragma clang diagnostic pop
        return;
    }

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
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    CommentService *commentService = [[CommentService alloc] initWithManagedObjectContext:context];

    if (!comment.isLiked) {
        [[UINotificationFeedbackGenerator new] notificationOccurred:UINotificationFeedbackTypeSuccess];
    }

    __typeof(self) __weak weakSelf = self;
    [commentService toggleLikeStatusForComment:comment siteID:self.post.siteID success:^{
        [weakSelf trackCommentLikedOrUnliked:comment];
    } failure:^(NSError *error) {
        // in case of failure, revert the cell's like state.
        [weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
}

#pragma mark - Sync methods

- (void)syncHelper:(WPContentSyncHelper *)syncHelper syncContentWithUserInteraction:(BOOL)userInteraction success:(void (^)(BOOL))success failure:(void (^)(NSError *))failure
{
    self.failedToFetchComments = NO;
    CommentService *service = [[CommentService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] newDerivedContext]];
    [service syncHierarchicalCommentsForPost:self.post page:1 success:^(BOOL hasMore, NSNumber *totalComments) {
        if (success) {
            success(hasMore);
        }
    } failure:failure];
    [self refreshNoResultsView];
}

- (void)syncHelper:(WPContentSyncHelper *)syncHelper syncMoreWithSuccess:(void (^)(BOOL))success failure:(void (^)(NSError *))failure
{
    self.failedToFetchComments = NO;
    [self.activityFooter startAnimating];

    CommentService *service = [[CommentService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] newDerivedContext]];
    NSInteger page = [service numberOfHierarchicalPagesSyncedforPost:self.post] + 1;
    [service syncHierarchicalCommentsForPost:self.post page:page success:^(BOOL hasMore, NSNumber *totalComments) {
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
    self.failedToFetchComments = YES;
    [self.activityFooter stopAnimating];
    [self refreshTableViewAndNoResultsView];
}

#pragma mark - Async Loading Helpers

- (void)setupWithPostID:(NSNumber *)postID siteID:(NSNumber *)siteID
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    ReaderPostService *service      = [[ReaderPostService alloc] initWithManagedObjectContext:context];
    __weak __typeof(self) weakSelf  = self;
    
    self.postSiteID = siteID;
    
    [service fetchPost:postID.integerValue forSite:siteID.integerValue isFeed:NO success:^(ReaderPost *post) {

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

- (NSFetchRequest *)fetchRequest
{
    if (!self.post) {
        return nil;
    }

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([Comment class])];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"post = %@", self.post];

    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"hierarchy" ascending:YES];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];

    return fetchRequest;
}

- (void)configureCell:(UITableViewCell *)aCell atIndexPath:(NSIndexPath *)indexPath
{
    Comment *comment = [self.tableViewHandler.resultsController objectAtIndexPath:indexPath];

    if ([self newCommentThreadEnabled]) {
        CommentContentTableViewCell *cell = (CommentContentTableViewCell *)aCell;
        [self configureContentCell:cell comment:comment indexPath:indexPath handler:self.tableViewHandler];

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
            if (comment && [self isModerationMenuEnabledFor:comment]) {
                // NOTE: Remove when minimum version is bumped to iOS 14.
                [self showMenuSheetFor:comment indexPath:indexPath handler:weakSelf.tableViewHandler sourceView:sourceView];
            } else {
                [self shareComment:comment sourceView:sourceView];
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

        return;
    }

    ReaderCommentCell *cell = (ReaderCommentCell *)aCell;
    cell.indentationWidth = CommentIndentationWidth;
    cell.indentationLevel = MIN(comment.depth, MaxCommentDepth);
    cell.delegate = self;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.enableLoggedInFeatures = [self isLoggedIn];

    NSURL *commentURL = [comment commentURL];
    if (commentURL) {
        cell.onTimeStampLongPress = ^(void) {
            [UIAlertController presentAlertAndCopyCommentURLToClipboardWithUrl:commentURL];
        };
    }

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

    NSAttributedString *attrStr = [self cacheContentForComment:comment];
    [cell configureCellWithComment:comment attributedString:attrStr];
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
    NSString *cellIdentifier = [self newCommentThreadEnabled] ? CommentContentCellIdentifier : CommentCellIdentifier;
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
    // Override WPTableViewHandler's default of UITableViewAutomaticDimension,
    // which results in 30pt tall headers on iOS 11
    return [self newCommentThreadEnabled] ? UITableViewAutomaticDimension : 0;
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
            if ([cell isKindOfClass:[ReaderCommentCell class]]) {
                [(ReaderCommentCell *)cell ensureTextViewLayout];
            } else if ([cell isKindOfClass:[CommentContentTableViewCell class]]) {
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


#pragma mark - ReaderCommentCell Delegate Methods

// TODO: Remove ReaderCommentCell methods once the `newCommentThread` flag is removed.

- (void)cell:(ReaderCommentCell *)cell didTapAuthor:(Comment *)comment
{
    NSURL *url = [comment authorURL];
    WebViewControllerConfiguration *configuration = [[WebViewControllerConfiguration alloc] initWithUrl:url];
    [configuration authenticateWithDefaultAccount];
    [configuration setAddsWPComReferrer:YES];
    UIViewController *webViewController = [WebViewControllerFactory controllerWithConfiguration:configuration source:@"reader_comments_author"];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:webViewController];
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)cell:(ReaderCommentCell *)cell didTapReply:(Comment *)comment
{
    [self didTapReplyAtIndexPath:[self.tableViewHandler.resultsController indexPathForObject:comment]];
}

- (void)cell:(ReaderCommentCell *)cell didTapLike:(Comment *)comment
{

    if (![WordPressAppDelegate shared].connectionAvailable) {
        NSString *title = NSLocalizedString(@"No Connection", @"Title of error prompt when no internet connection is available.");
        NSString *message = NSLocalizedString(@"The Internet connection appears to be offline.", @"Message of error prompt shown when a user tries to perform an action without an internet connection.");
        [WPError showAlertWithTitle:title message:message];
        return;
    }

    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    CommentService *commentService = [[CommentService alloc] initWithManagedObjectContext:context];

    if (!comment.isLiked) {
        [[UINotificationFeedbackGenerator new] notificationOccurred:UINotificationFeedbackTypeSuccess];
    }

    __typeof(self) __weak weakSelf = self;
    [commentService toggleLikeStatusForComment:comment siteID:self.post.siteID success:^{
        [weakSelf trackCommentLikedOrUnliked:comment];

        [weakSelf.tableView reloadData];
    } failure:^(NSError *error) {

        [weakSelf.tableView reloadData];
    }];

    [self.tableView reloadData];
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction
{
    return NO;
}

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

- (void)interactWithURL:(NSURL *) URL {
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


#pragma mark - ReaderCommentsNotificationSheet Delegate Methods

- (void)didToggleNotificationSwitch:(BOOL)isOn completion:(void (^)(BOOL))completion
{
    [self handleNotificationsButtonTappedWithUndo:NO completion:completion];
}

- (void)didTapUnfollowConversation
{
    [self handleFollowConversationButtonTapped];
}

#pragma mark - PostHeaderView helpers

- (void)handleFollowConversationButtonTapped
{
    __typeof(self) __weak weakSelf = self;

    UINotificationFeedbackGenerator *generator = [UINotificationFeedbackGenerator new];
    [generator prepare];

    // Keep previous subscription status in case of failure
    BOOL oldIsSubscribed = self.subscribedToPost;
    BOOL newIsSubscribed = !oldIsSubscribed;

    // Optimistically toggle subscription status
    self.subscribedToPost = newIsSubscribed;

    // Define success block
    void (^successBlock)(BOOL taskSucceeded) = ^void(BOOL taskSucceeded) {
        if (taskSucceeded == NO) {
            NSString *title = newIsSubscribed
                ? NSLocalizedString(@"Unable to follow conversation", @"The app failed to subscribe to the comments for the post")
                : NSLocalizedString(@"Failed to unfollow conversation", @"The app failed to unsubscribe from the comments for the post");

            dispatch_async(dispatch_get_main_queue(), ^{
                [generator notificationOccurred:UINotificationFeedbackTypeSuccess];
                [weakSelf displayNoticeWithTitle:title message:nil];

                // The task failed, fall back to the old subscription status
                self.subscribedToPost = oldIsSubscribed;
            });
        } else {
            NSString *title = newIsSubscribed
                ? NSLocalizedString(@"Successfully followed conversation", @"The app successfully subscribed to the comments for the post")
                : NSLocalizedString(@"Successfully unfollowed conversation", @"The app successfully unsubscribed from the comments for the post");

            dispatch_async(dispatch_get_main_queue(), ^{
                // update ReaderPost when the subscription process has succeeded.
                weakSelf.post.isSubscribedComments = newIsSubscribed;
                [ContextManager.sharedInstance saveContext:weakSelf.post.managedObjectContext];

                [generator notificationOccurred:UINotificationFeedbackTypeSuccess];

                if ([self followViaNotificationsEnabled]) {
                    [weakSelf refreshFollowButton];

                    // only show the new notice with undo option when the user intends to subscribe.
                    if (newIsSubscribed) {
                        [weakSelf displayActionableNoticeWithTitle:NSLocalizedString(@"Following this conversation",
                                                                                     @"The app successfully subscribed to the comments for the post")
                                                           message:NSLocalizedString(@"Enable in-app notifications?",
                                                                                     @"Hint for the action button that enables notification for new comments")
                                                       actionTitle:NSLocalizedString(@"Enable",
                                                                                     @"Button title to enable notifications for new comments")
                                                     actionHandler:^(BOOL accepted) {
                            [weakSelf handleNotificationsButtonTappedWithUndo:YES completion:nil];
                        }];
                        return;
                    }
                }

                [weakSelf displayNoticeWithTitle:title message:nil];
            });
        }
    };

    // Define failure block
    void (^failureBlock)(NSError *error) = ^void(NSError *error) {
        DDLogError(@"Error toggling subscription status: %@", error);

        NSString *title = newIsSubscribed
            ? NSLocalizedString(@"Could not subscribe to comments", "The app failed to subscribe to the comments for the post")
            : NSLocalizedString(@"Could not unsubscribe from comments", "The app failed to unsubscribe from the comments for the post");

        dispatch_async(dispatch_get_main_queue(), ^{
            [generator notificationOccurred:UINotificationFeedbackTypeError];
            [weakSelf displayNoticeWithTitle:title message:nil];

            // If the request fails, fall back to the old subscription status
            weakSelf.subscribedToPost = oldIsSubscribed;
        });
    };

    // Call the service to toggle the subscription status
    [self.followCommentsService toggleSubscribed:oldIsSubscribed
                                         success:successBlock
                                         failure:failureBlock];
}

/// Toggles the state of comment subscription notifications. When enabled, the user will receive in-app notifications for new comments.
///
/// @param canUndo Boolean. When true, this provides a way for the user to revert their actions.
- (void)handleNotificationsButtonTappedWithUndo:(BOOL)canUndo completion:(void (^ _Nullable)(BOOL))completion
{
    BOOL desiredState = !self.post.receivesCommentNotifications;
    PostSubscriptionAction action = desiredState ? PostSubscriptionActionEnableNotification : PostSubscriptionActionDisableNotification;

    __weak __typeof(self) weakSelf = self;
    NSString* (^noticeTitle)(BOOL) = ^NSString* (BOOL success) {
        return [weakSelf noticeTitleForAction:action success:success];
    };

    [self.followCommentsService toggleNotificationSettings:desiredState success:^{
        if (completion) {
            completion(YES);
        }

        if (!canUndo) {
            [weakSelf displayNoticeWithTitle:noticeTitle(YES) message:nil];
            return;
        }

        // show the undo notice with action button.
        NSString *undoActionTitle = NSLocalizedString(@"Undo", @"Button title. Reverts the previous notification operation");
        [weakSelf displayActionableNoticeWithTitle:noticeTitle(YES) message:nil actionTitle:undoActionTitle actionHandler:^(BOOL accepted) {
            [weakSelf handleNotificationsButtonTappedWithUndo:NO completion:nil];
        }];

    } failure:^(NSError * _Nullable error) {
        [weakSelf displayNoticeWithTitle:noticeTitle(NO) message:nil];
        if (completion) {
            completion(NO);
        }
    }];
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
    [self.suggestionsTableView hideSuggestions];
    
    [controller enableSuggestionsWith:self.siteID];
}
@end
