#import "ReaderCommentsViewController.h"

#import "Comment.h"
#import "CommentService.h"
#import "ContextManager.h"
#import "ReaderPost.h"
#import "ReaderPostService.h"
#import "ReaderPostHeaderView.h"
#import "UIView+Subviews.h"
#import "WPImageViewController.h"
#import "WPTableViewHandler.h"
#import "SuggestionsTableView.h"
#import "SuggestionService.h"
#import "WordPress-Swift.h"
#import "WPAppAnalytics.h"
#import <WordPressUI/WordPressUI.h>


// NOTE: We want the cells to have a rather large estimated height.  This avoids a peculiar
// crash in certain circumstances when the tableView lays out its visible cells,
// and those cells contain WPRichTextEmbeds. -- Aerych, 2016.11.30
static CGFloat const EstimatedCommentRowHeight = 300.0;
static NSInteger const MaxCommentDepth = 4.0;
static CGFloat const CommentIndentationWidth = 40.0;

static NSString *CommentCellIdentifier = @"CommentDepth0CellIdentifier";
static NSString *RestorablePostObjectIDURLKey = @"RestorablePostObjectIDURLKey";

@interface ReaderCommentsViewController () <NSFetchedResultsControllerDelegate,
                                            ReaderCommentCellDelegate,
                                            ReplyTextViewDelegate,
                                            UIViewControllerRestoration,
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
@property (nonatomic, strong) NSCache *cachedAttributedStrings;

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

    return [self controllerWithPost:restoredPost];
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

    [self refreshAndSync];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.keyboardManager startListeningToKeyboardNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleApplicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.tableView reloadData];
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

-(void)trackCommentsOpened {
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    properties[WPAppAnalyticsKeyPostID] = self.post.postID;
    properties[WPAppAnalyticsKeyBlogID] = self.post.siteID;
    [WPAppAnalytics track:WPAnalyticsStatReaderArticleCommentsOpened withProperties:properties];
}

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
    [WPAppAnalytics track: stat withProperties:properties];
}

-(void)trackReplyToComment {
    ReaderPost *post = self.post;
    NSDictionary *railcar = post.railcarDictionary;
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    properties[WPAppAnalyticsKeyBlogID] = post.siteID;
    properties[WPAppAnalyticsKeyPostID] = post.postID;
    properties[WPAppAnalyticsKeyIsJetpack] = @(post.isJetpack);
    if (post.feedID && post.feedItemID) {
        properties[WPAppAnalyticsKeyFeedID] = post.feedID;
        properties[WPAppAnalyticsKeyFeedItemID] = post.feedItemID;
    }
    [WPAppAnalytics track:WPAnalyticsStatReaderArticleCommentedOn withProperties:properties];
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
}

- (void)configurePostHeader
{
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
    headerView.translatesAutoresizingMaskIntoConstraints = NO;
    headerView.showsDisclosureIndicator = self.allowsPushingPostDetails;
    [headerView setSubtitle:NSLocalizedString(@"Comments on", @"Sentence fragment. The full phrase is 'Comments on' followed by the title of a post on a separate line.")];
    [headerWrapper addSubview:headerView];

    // Border
    CGSize borderSize = CGSizeMake(CGRectGetWidth(self.view.bounds), 1.0);
    UIImage *borderImage = [UIImage imageWithColor:[UIColor murielNeutral5] havingSize:borderSize];
    UIImageView *borderView = [[UIImageView alloc] initWithImage:borderImage];
    borderView.translatesAutoresizingMaskIntoConstraints = NO;
    borderView.contentMode = UIViewContentModeScaleAspectFill;
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

    UINib *commentNib = [UINib nibWithNibName:@"ReaderCommentCell" bundle:nil];
    [self.tableView registerNib:commentNib forCellReuseIdentifier:CommentCellIdentifier];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
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

    self.suggestionsTableView = [SuggestionsTableView new];
    self.suggestionsTableView.siteID = siteID;
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
    NSDictionary *views         = @{
        @"tableView"        : self.tableView,
        @"postHeader"       : self.postHeaderWrapper,
        @"mainView"         : self.view,
        @"suggestionsview"  : self.suggestionsTableView,
        @"replyTextView"    : self.replyTextView
    };

    // PostHeader Constraints
    [[self.postHeaderWrapper.leftAnchor constraintEqualToAnchor:self.tableView.leftAnchor] setActive:YES];
    [[self.postHeaderWrapper.rightAnchor constraintEqualToAnchor:self.tableView.rightAnchor] setActive:YES];

    // TableView Contraints
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[postHeader][tableView][replyTextView]"
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

#pragma mark - Accessor methods

- (void)setPost:(ReaderPost *)post
{
    if (post == _post) {
        return;
    }

    _post = post;
    [self trackCommentsOpened];
    if (_post.isWPCom || _post.isJetpack) {
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

    _activityFooter = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
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
    [self refreshTableViewAndNoResultsView];

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
        CGRect rect = self.activityFooter.frame;
        rect.origin.x = (width - rect.size.width) / 2.0;
        self.activityFooter.frame = rect;

        [footerView addSubview:self.activityFooter];
        self.tableView.tableFooterView = footerView;
        
    } else {
        self.tableView.tableFooterView = nil;
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
    [self.noResultsViewController.view setBackgroundColor:[UIColor clearColor]];
    [self addChildViewController:self.noResultsViewController];
    [self.view addSubviewWithFadeAnimation:self.noResultsViewController.view];
    self.noResultsViewController.view.frame = self.tableView.frame;
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
    NSAttributedString *attrStr = [self.cachedAttributedStrings objectForKey:comment.commentID];
    if (!attrStr) {
        attrStr = [WPRichContentView formattedAttributedStringForString: comment.content];
        [self.cachedAttributedStrings setObject:attrStr forKey:comment.commentID];
    }
    return attrStr;
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

    UINotificationFeedbackGenerator *generator = [UINotificationFeedbackGenerator new];
    [generator prepare];

    void (^successBlock)(void) = ^void() {
        [generator notificationOccurred:UINotificationFeedbackTypeSuccess];
        NSString *successMessage = NSLocalizedString(@"Reply Sent!", @"The app successfully sent a comment");
        [weakSelf displayNoticeWithTitle:successMessage message:nil];

        [weakSelf trackReplyToComment];
        [weakSelf.tableView deselectSelectedRowWithAnimation:YES];
        [weakSelf refreshReplyTextViewPlaceholder];

        [weakSelf refreshTableViewAndNoResultsView];
    };

    void (^failureBlock)(NSError *error) = ^void(NSError *error) {
        DDLogError(@"Error sending reply: %@", error);
        [generator notificationOccurred:UINotificationFeedbackTypeError];
        NSString *message = NSLocalizedString(@"There has been an unexpected error while sending your reply", "Reply Failure Message");
        [weakSelf displayNoticeWithTitle:message message:nil];

        [weakSelf refreshTableViewAndNoResultsView];
    };

    CommentService *service = [[CommentService alloc] initWithManagedObjectContext:self.managedObjectContext];

    if (self.indexPathForCommentRepliedTo) {
        Comment *comment = [self.tableViewHandler.resultsController objectAtIndexPath:self.indexPathForCommentRepliedTo];
        [service replyToHierarchicalCommentWithID:comment.commentID
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


#pragma mark - Sync methods

- (void)syncHelper:(WPContentSyncHelper *)syncHelper syncContentWithUserInteraction:(BOOL)userInteraction success:(void (^)(BOOL))success failure:(void (^)(NSError *))failure
{
    self.failedToFetchComments = NO;
    CommentService *service = [[CommentService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] newDerivedContext]];
    [service syncHierarchicalCommentsForPost:self.post page:1 success:^(NSInteger count, BOOL hasMore) {
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
    [service syncHierarchicalCommentsForPost:self.post page:page success:^(NSInteger count, BOOL hasMore) {
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
    ReaderCommentCell *cell = (ReaderCommentCell *)aCell;

    Comment *comment = [self.tableViewHandler.resultsController objectAtIndexPath:indexPath];

    cell.indentationWidth = CommentIndentationWidth;
    cell.indentationLevel = MIN([comment.depth integerValue], MaxCommentDepth);
    cell.delegate = self;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.enableLoggedInFeatures = [self isLoggedIn];
    cell.onTimeStampLongPress = ^(void) {
        NSURL *url = [NSURL URLWithString:comment.link];
        [UIAlertController presentAlertAndCopyCommentURLToClipboardWithUrl:url];
    };

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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ReaderCommentCell *cell = (ReaderCommentCell *)[self.tableView dequeueReusableCellWithIdentifier:CommentCellIdentifier];
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
    return 0;
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

        for (ReaderCommentCell *cell in [self.tableView visibleCells]) {
            [cell ensureTextViewLayout];
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

- (void)cell:(ReaderCommentCell *)cell didTapAuthor:(Comment *)comment
{
    NSURL *url = [comment authorURL];
    WebViewControllerConfiguration *configuration = [[WebViewControllerConfiguration alloc] initWithUrl:url];
    [configuration authenticateWithDefaultAccount];
    [configuration setAddsWPComReferrer:YES];
    UIViewController *webViewController = [WebViewControllerFactory controllerWithConfiguration:configuration];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:webViewController];
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)cell:(ReaderCommentCell *)cell didTapReply:(Comment *)comment
{
    // if a row is already selected don't allow selection of another
    if (self.replyTextView.isFirstResponder) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-result"
        [self.replyTextView resignFirstResponder];
#pragma clang diagnostic pop
        return;
    }

    if (!self.canComment) {
        return;
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-result"
    [self.replyTextView becomeFirstResponder];
#pragma clang diagnostic pop

    self.indexPathForCommentRepliedTo = [self.tableViewHandler.resultsController indexPathForObject:comment];
    [self.tableView selectRowAtIndexPath:self.indexPathForCommentRepliedTo animated:YES scrollPosition:UITableViewScrollPositionTop];
    [self refreshReplyTextViewPlaceholder];
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
    UIViewController *webViewController = [WebViewControllerFactory controllerWithConfiguration:configuration];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:webViewController];
    [self presentViewController:navController animated:YES completion:nil];
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
    [self.navigationController pushFullscreenViewController:controller animated:YES];
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
