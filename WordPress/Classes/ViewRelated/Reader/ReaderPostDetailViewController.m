#import "ReaderPostDetailViewController.h"

#import <WordPress-Swift.h>
#import <MediaPlayer/MediaPlayer.h>
#import "Comment.h"
#import "CommentService.h"
#import "ContextManager.h"
#import "CustomHighlightButton.h"
#import "InlineComposeView.h"
#import "ReaderCommentPublisher.h"
#import "ReaderCommentCell.h"
#import "ReaderPost.h"
#import "ReaderPostRichContentView.h"
#import "ReaderPostService.h"
#import "RebloggingViewController.h"
#import "WPActivityDefaults.h"
#import "WPAvatarSource.h"
#import "WPImageViewController.h"
#import "WPNoResultsView+AnimatedBox.h"
#import "WPRichTextVideoControl.h"
#import "WPRichTextImageControl.h"
#import "WPTableImageSource.h"
#import "WPTableViewHandler.h"
#import "WPWebVideoViewController.h"
#import "WPWebViewController.h"

static CGFloat const SectionHeaderHeight = 25.0f;
static CGFloat const TableViewTopMargin = 40;
static CGFloat const EstimatedCommentRowHeight = 150.0;
static CGFloat const CommentAvatarSize = 32.0;

static NSString *CommentDepth0CellIdentifier = @"CommentDepth0CellIdentifier";
static NSString *CommentDepth1CellIdentifier = @"CommentDepth1CellIdentifier";
static NSString *CommentDepth2CellIdentifier = @"CommentDepth2CellIdentifier";
static NSString *CommentDepth3CellIdentifier = @"CommentDepth3CellIdentifier";
static NSString *CommentDepth4CellIdentifier = @"CommentDepth4CellIdentifier";
static NSString *CommentLayoutCellIdentifier = @"CommentLayoutCellIdentifier";

@interface ReaderPostDetailViewController ()<
                                            ReaderCommentPublisherDelegate,
                                            ReaderCommentCellDelegate,
                                            ReaderPostContentViewDelegate,
                                            RebloggingViewControllerDelegate,
                                            WPContentSyncHelperDelegate,
                                            WPRichTextViewDelegate,
                                            WPTableImageSourceDelegate,
                                            WPTableViewHandlerDelegate,
                                            NSFetchedResultsControllerDelegate,
                                            UIPopoverControllerDelegate >

@property (nonatomic, strong, readwrite) ReaderPost *post;
@property (nonatomic, strong) UIPopoverController *popover;
@property (nonatomic, strong) UIGestureRecognizer *tapOffKeyboardGesture;
@property (nonatomic, strong) ReaderPostRichContentView *postView;
@property (nonatomic, strong) UIActivityIndicatorView *activityFooter;
@property (nonatomic, strong) UIBarButtonItem *shareButton;
@property (nonatomic, strong) InlineComposeView *inlineComposeView;
@property (nonatomic, strong) ReaderCommentPublisher *commentPublisher;
@property (nonatomic, strong) WPTableImageSource *featuredImageSource;
@property (nonatomic, strong) WPContentSyncHelper *syncHelper;
@property (nonatomic, strong) WPTableViewHandler *tableViewHandler;

@property (nonatomic, strong) ReaderCommentCell *cellForLayout;
@property (nonatomic, strong) NSLayoutConstraint *cellForLayoutWidthConstraint;

@end


@implementation ReaderPostDetailViewController

#pragma mark - Static Helpers

+ (instancetype)detailControllerWithPost:(ReaderPost *)post
{
    ReaderPostDetailViewController *detailsViewController = [[self alloc] init];
    detailsViewController.post = post;
    return detailsViewController;
}

+ (instancetype)detailControllerWithPostID:(NSNumber *)postID siteID:(NSNumber *)siteID
{
    ReaderPostDetailViewController *detailsViewController = [[self alloc] init];
    [detailsViewController setupWithPostID:postID siteID:siteID];
    return detailsViewController;
}


#pragma mark - LifeCycle Methods

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tapOffKeyboardGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard:)];

    if (self.tableViewHandler) {
        self.tableViewHandler.delegate = nil;
    }
    self.tableViewHandler = [[WPTableViewHandler alloc] initWithTableView:self.tableView];
    self.tableViewHandler.cacheRowHeights = YES;
    self.tableViewHandler.delegate = self;

    [self configureCellForLayout];
    [self configureInfiniteScroll];
    [self configureTableView];
    [self configureNavbar];
    [self configureCommentPublisher];

    [self configurePostView];
    [self configureTableHeaderView];
    
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    [self refreshAndSync];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // The first time the activity view controller is loaded, there is a bit of
    // processing that happens under the hood. This can cause a stutter
    // if the user taps the share button while scrolling. A work around is to
    // prime the activity controller when there is no animation occuring.
    // The performance hit only happens once so its fine to discard the controller
    // after it loads its view.
    [[self activityViewControllerForSharing] view];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [self.inlineComposeView dismissComposer];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];

    if (IS_IPHONE) {
        // Resize media in the post detail to match the width of the new orientation.
        // No need to refresh on iPad when using a fixed width.
        [self.postView refreshMediaLayout];
        [self refreshHeightForTableHeaderView];

        // DTCoreText can be cranky about refreshing its rendered text when its
        // frame changes, even when setting its relayoutMask. Setting setNeedsLayout
        // on the cell prior to reloading seems to force the cell's
        // DTAttributedTextContentView to behave.
        for (UITableViewCell *cell in [self.tableView visibleCells]) {
            [cell setNeedsLayout];
        }
        [self.tableView reloadRowsAtIndexPaths:[self.tableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationAutomatic];
    }

    // Make sure a selected comment is visible after rotating.
    if ([self.tableView indexPathForSelectedRow] && self.inlineComposeView.isDisplayed) {
        [self.tableView scrollToNearestSelectedRowAtScrollPosition:UITableViewScrollPositionNone animated:NO];
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];

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
    [self updateCellForLayoutWidthConstraint:width];

    if (IS_IPHONE) {
        [self.tableViewHandler refreshCachedRowHeightsForWidth:width];
    }
}


#pragma mark - Configuration

- (void)configureCellForLayout
{
    [self.tableView registerClass:[ReaderCommentCell class] forCellReuseIdentifier:CommentLayoutCellIdentifier];
    self.cellForLayout = [self.tableView dequeueReusableCellWithIdentifier:CommentLayoutCellIdentifier];
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

- (void)configureInfiniteScroll
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

- (void)setAvatarForComment:(Comment *)comment forCell:(ReaderCommentCell *)cell indexPath:(NSIndexPath *)indexPath
{
    WPAvatarSource *source = [WPAvatarSource sharedSource];

    NSString *hash;
    CGSize size = CGSizeMake(CommentAvatarSize, CommentAvatarSize);
    NSURL *url = [comment avatarURLForDisplay];
    WPAvatarSourceType type = [source parseURL:url forAvatarHash:&hash];

    UIImage *image = [source cachedImageForAvatarHash:hash ofType:type withSize:size];
    if (image) {
        [cell setAvatarImage:image];
        return;
    }

    [cell setAvatarImage:[UIImage imageNamed:@"default-identicon"]];
    if (hash) {
        [source fetchImageForAvatarHash:hash ofType:type withSize:size success:^(UIImage *image) {
            if (cell == [self.tableView cellForRowAtIndexPath:indexPath]) {
                [cell setAvatarImage:image];
            }
        }];
    }
}

- (void)configureTableView
{
    [self.tableView registerClass:[ReaderCommentCell class] forCellReuseIdentifier:CommentDepth0CellIdentifier];
    [self.tableView registerClass:[ReaderCommentCell class] forCellReuseIdentifier:CommentDepth1CellIdentifier];
    [self.tableView registerClass:[ReaderCommentCell class] forCellReuseIdentifier:CommentDepth2CellIdentifier];
    [self.tableView registerClass:[ReaderCommentCell class] forCellReuseIdentifier:CommentDepth3CellIdentifier];
    [self.tableView registerClass:[ReaderCommentCell class] forCellReuseIdentifier:CommentDepth4CellIdentifier];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
}

- (void)configureNavbar
{
    // Don't show 'Reader' in the next-view back button
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@" " style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem = backButton;
    [WPStyleGuide setRightBarButtonItemWithCorrectSpacing:self.shareButton forNavigationItem:self.navigationItem];
}

- (void)configureCommentPublisher
{
    self.inlineComposeView = [[InlineComposeView alloc] initWithFrame:CGRectZero];
    [self.inlineComposeView setButtonTitle:NSLocalizedString(@"Post", nil)];
    [self.view addSubview:self.inlineComposeView];

    // Comment composer responds to the inline compose view to publish comments
    self.commentPublisher = [[ReaderCommentPublisher alloc] initWithComposer:self.inlineComposeView];
    self.commentPublisher.delegate = self;
}

- (void)configurePostView
{
    CGFloat width = IS_IPAD ? WPTableViewFixedWidth : CGRectGetWidth(self.tableView.bounds);
    self.postView = [[ReaderPostRichContentView alloc] initWithFrame:CGRectMake(0.0, 0.0, width, 1.0)]; // minimal frame so rich text will have initial layout.
    self.postView.translatesAutoresizingMaskIntoConstraints = NO;
    self.postView.delegate = self;
    self.postView.backgroundColor = [UIColor whiteColor];
}

- (void)configureTableHeaderView
{
    NSParameterAssert(self.postView);
    NSParameterAssert(self.tableView);

    UIView *tableHeaderView = [[UIView alloc] init];
    [tableHeaderView addSubview:self.postView];

    CGFloat marginTop = IS_IPAD ? TableViewTopMargin : 0;
    NSDictionary *views = NSDictionaryOfVariableBindings(_postView);
    NSDictionary *metrics = @{@"WPTableViewWidth": @(WPTableViewFixedWidth), @"marginTop": @(marginTop)};
    if (IS_IPAD) {
        [tableHeaderView addConstraint:[NSLayoutConstraint constraintWithItem:self.postView
                                                                    attribute:NSLayoutAttributeCenterX
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:tableHeaderView
                                                                    attribute:NSLayoutAttributeCenterX
                                                                   multiplier:1.0
                                                                     constant:0.0]];
        [tableHeaderView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[_postView(WPTableViewWidth)]"
                                                                                options:0
                                                                                metrics:metrics
                                                                                  views:views]];
    } else {
        [tableHeaderView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_postView]|"
                                                                                options:0
                                                                                metrics:nil
                                                                                  views:views]];
    }
    // Don't anchor the post view to the bottom of its superview allows for (visually) smoother rotation.
    [tableHeaderView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(marginTop)-[_postView]"
                                                                            options:0
                                                                            metrics:metrics
                                                                              views:views]];
    self.tableView.tableHeaderView = tableHeaderView;
    [self refreshHeightForTableHeaderView];
}

- (UIActivityViewController *)activityViewControllerForSharing
{
    NSString *title = self.post.postTitle;
    NSString *summary = self.post.summary;
    NSString *tags = self.post.tags;

    NSMutableArray *activityItems = [NSMutableArray array];
    NSMutableDictionary *postDictionary = [NSMutableDictionary dictionary];

    if (title) {
        postDictionary[@"title"] = title;
    }
    if (summary) {
        postDictionary[@"summary"] = summary;
    }
    if (tags) {
        postDictionary[@"tags"] = tags;
    }
    [activityItems addObject:postDictionary];
    NSURL *permaLink = [NSURL URLWithString:self.post.permaLink];
    if (permaLink) {
        [activityItems addObject:permaLink];
    }
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:[WPActivityDefaults defaultActivities]];
    if (title) {
        [activityViewController setValue:title forKey:@"subject"];
    }
    activityViewController.completionHandler = ^(NSString *activityType, BOOL completed) {
        if (!completed) {
            return;
        }
        [WPActivityDefaults trackActivityType:activityType];
    };
    return activityViewController;
}

- (void)setupWithPostID:(NSNumber *)postID siteID:(NSNumber *)siteID
{

    [WPNoResultsView displayAnimatedBoxWithTitle:NSLocalizedString(@"Loading Post...", @"Text displayed while loading a post.")
                                         message:nil
                                            view:self.view];

    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    ReaderPostService *service      = [[ReaderPostService alloc] initWithManagedObjectContext:context];
    __weak __typeof(self) weakSelf  = self;

    [service deletePostsWithNoTopic];
    [service fetchPost:postID.integerValue forSite:siteID.integerValue success:^(ReaderPost *post) {

        weakSelf.post = post;
        [weakSelf refreshAndSync];

        [WPNoResultsView removeFromView:weakSelf.view];

    } failure:^(NSError *error) {
        DDLogError(@"[RestAPI] %@", error);

        [WPNoResultsView displayAnimatedBoxWithTitle:NSLocalizedString(@"Error Loading Post", @"Text displayed when load post fails.")
                                             message:nil
                                                view:weakSelf.view];

    }];
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

    if([self isViewLoaded]) {
        [self configureInfiniteScroll];
    }
}

- (UIBarButtonItem *)shareButton
{
    if (_shareButton) {
        return _shareButton;
    }

    // Top Navigation bar and Sharing
    UIImage *image = [UIImage imageNamed:@"icon-posts-share"];
    CustomHighlightButton *button = [[CustomHighlightButton alloc] initWithFrame:CGRectMake(0.0, 0.0, image.size.width, image.size.height)];
    [button setImage:image forState:UIControlStateNormal];
    [button addTarget:self action:@selector(handleShareButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    _shareButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    _shareButton.accessibilityLabel = NSLocalizedString(@"Share", @"Spoken accessibility label");

    return _shareButton;
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

- (BOOL)isLoaded
{
    return (self.post != nil);
}

- (BOOL)canComment
{
    return self.post.commentsOpen;
}

- (void)dismissPopover
{
    if (self.popover) {
        [self.popover dismissPopoverAnimated:YES];
        self.popover = nil;
    }
}


#pragma mark - View Refresh Helpers

- (void)refreshAndSync
{
    self.title = self.post.postTitle ?: NSLocalizedString(@"Reader", @"Placeholder title for ReaderPostDetails.");

    [self refreshPostView];
    [self refreshHeightForTableHeaderView];

    // Refresh incase the post needed to be fetched.
    [self.tableView reloadData];

    // Enable Share action only when the post is fully loaded
    self.shareButton.enabled = self.isLoaded;

    [self.syncHelper syncContent];
}

- (void)refreshPostView
{
    NSParameterAssert(self.postView);

    self.postView.hidden = !self.isLoaded;
    
    if (!self.isLoaded) {
        return;
    }
    
    [self.postView configurePost:self.post];
    
    CGSize imageSize = CGSizeMake(WPContentViewAuthorAvatarSize, WPContentViewAuthorAvatarSize);
    UIImage *image = [self.post cachedAvatarWithSize:imageSize];
    if (image) {
        [self.postView setAvatarImage:image];
    } else {
        [self.post fetchAvatarWithSize:imageSize success:^(UIImage *image) {
            [self.postView setAvatarImage:image];
        }];
    }
    
    // Only show featured image if one exists and its not already in the post content.
    NSURL *featuredImageURL = [self.post featuredImageURLForDisplay];
    if (featuredImageURL) {
        // If ReaderPostView has a featured image, show it unless you're showing full detail & featured image is in the post already
        if ([self.post contentIncludesFeaturedImage]) {
            self.postView.alwaysHidesFeaturedImage = YES;
        } else {
            [self fetchFeaturedImage];
        }
    }
}

- (void)fetchFeaturedImage
{
    if (!self.featuredImageSource) {
        CGFloat maxWidth = IS_IPAD ? WPTableViewFixedWidth : MAX(CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds));;
        CGFloat maxHeight = maxWidth * WPContentViewMaxImageHeightPercentage;
        self.featuredImageSource = [[WPTableImageSource alloc] initWithMaxSize:CGSizeMake(maxWidth, maxHeight)];
        self.featuredImageSource.delegate = self;
    }
    
    CGFloat width = IS_IPAD ? WPTableViewFixedWidth : CGRectGetWidth(self.tableView.bounds);
    CGFloat height = round(width * WPContentViewMaxImageHeightPercentage);
    CGSize size = CGSizeMake(width, height);
    
    NSURL *imageURL = [self.post featuredImageURLForDisplay];
    UIImage *image = [self.featuredImageSource imageForURL:imageURL withSize:size];
    if(image) {
        [self.postView setFeaturedImage:image];
    } else {
        [self.featuredImageSource fetchImageForURL:imageURL
                                          withSize:size
                                         indexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                         isPrivate:self.post.isPrivate];
    }
}

- (void)refreshHeightForTableHeaderView
{
    CGFloat marginTop = IS_IPAD ? TableViewTopMargin : 0;
    CGFloat width = IS_IPAD ? WPTableViewFixedWidth : CGRectGetWidth(self.tableView.bounds);
    CGSize size = [self.postView sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
    CGFloat height = size.height + marginTop;
    UIView *tableHeaderView = self.tableView.tableHeaderView;
    tableHeaderView.frame = CGRectMake(0.0, 0.0, CGRectGetWidth(self.tableView.bounds), height);
    self.tableView.tableHeaderView = tableHeaderView;
}


#pragma mark - Notification handlers

- (void)handleKeyboardWillHide:(NSNotification *)notification
{
    //deselect the selected comment if there is one
    NSArray *selection = [self.tableView indexPathsForSelectedRows];
    if ([selection count] > 0) {
        [self.tableView deselectRowAtIndexPath:[selection objectAtIndex:0] animated:YES];
    }
}

- (void)moviePlaybackDidFinish:(NSNotification *)notification
{
    // Obtain the reason why the movie playback finished
    NSNumber *finishReason = [[notification userInfo] objectForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey];

    // Dismiss the view controller ONLY when the reason is not "playback ended"
    if ([finishReason intValue] != MPMovieFinishReasonPlaybackEnded) {
        MPMoviePlayerController *moviePlayer = [notification object];

        // Remove this class from the observers
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:MPMoviePlayerPlaybackDidFinishNotification
                                                      object:moviePlayer];

        // Dismiss the view controller
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}


#pragma mark - Actions

- (void)handleShareButtonTapped:(id)sender
{
    UIActivityViewController *activityViewController = [self activityViewControllerForSharing];
    if (IS_IPAD) {
        if (self.popover) {
            [self dismissPopover];
            return;
        }
        self.popover = [[UIPopoverController alloc] initWithContentViewController:activityViewController];
        self.popover.delegate = self;
        [self.popover presentPopoverFromBarButtonItem:self.shareButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        [self presentViewController:activityViewController animated:YES completion:nil];
    }
}

- (void)dismissKeyboard:(id)sender
{
    if ([self.view.gestureRecognizers containsObject:self.tapOffKeyboardGesture]) {
        [self.view removeGestureRecognizer:self.tapOffKeyboardGesture];
    }

    [self.inlineComposeView dismissComposer];
}


#pragma mark - ReaderPostView delegate methods

- (void)contentView:(UIView *)contentView didReceiveFeaturedImageAction:(id)sender
{
    UITapGestureRecognizer *gesture = (UITapGestureRecognizer *)sender;
    UIImageView *imageView = (UIImageView *)gesture.view;
    WPImageViewController *controller = [[WPImageViewController alloc] initWithImage:imageView.image];

    controller.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    controller.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)contentView:(UIView *)contentView didReceiveAttributionLinkAction:(id)sender
{
    UIButton *followButton = (UIButton *)sender;
    ReaderPost *post = self.post;

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

- (void)postView:(ReaderPostContentView *)postView didReceiveReblogAction:(id)sender
{
    RebloggingViewController *controller = [[RebloggingViewController alloc] initWithPost:self.post];
    controller.delegate = self;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)postView:(ReaderPostContentView *)postView didReceiveLikeAction:(id)sender
{
    ReaderPost *post = self.post;
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
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

- (void)postView:(ReaderPostContentView *)postView didReceiveCommentAction:(id)sender
{
    [self.view addGestureRecognizer:self.tapOffKeyboardGesture];

    self.commentPublisher.post = self.post;
    self.commentPublisher.comment = nil;
    [self.inlineComposeView toggleComposer];
}


# pragma mark - Rich Text Delegate Methods

- (void)richTextView:(WPRichTextView *)richTextView didReceiveLinkAction:(NSURL *)linkURL
{
    WPWebViewController *controller = [[WPWebViewController alloc] init];
    [controller setUrl:linkURL];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)richTextView:(WPRichTextView *)richTextView didReceiveImageLinkAction:(WPRichTextImageControl *)imageControl
{
    UIViewController *controller;

    if (imageControl.linkURL) {
        NSString *url = [imageControl.linkURL absoluteString];

        BOOL matched = NO;
        NSArray *types = @[@".png", @".jpg", @".gif", @".jpeg"];
        for (NSString *type in types) {
            if (NSNotFound != [url rangeOfString:type].location) {
                matched = YES;
                break;
            }
        }

        if (matched) {
            controller = [[WPImageViewController alloc] initWithImage:imageControl.imageView.image andURL:imageControl.linkURL];
        } else {
            controller = [[WPWebViewController alloc] init];
            [(WPWebViewController *)controller setUrl:imageControl.linkURL];
        }
    } else {
        controller = [[WPImageViewController alloc] initWithImage:imageControl.imageView.image];
    }

    if ([controller isKindOfClass:[WPImageViewController class]]) {
        controller.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        controller.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:controller animated:YES completion:nil];
    } else {
        [self.navigationController pushViewController:controller animated:YES];
    }
}

- (void)richTextView:(WPRichTextView *)richTextView didReceiveVideoLinkAction:(WPRichTextVideoControl *)videoControl
{
    if (!videoControl.isHTMLContent) {
        MPMoviePlayerViewController *controller = [[MPMoviePlayerViewController alloc] initWithContentURL:videoControl.contentURL];

        // Remove the movie player view controller from the "playback did finish" notification observers
        [[NSNotificationCenter defaultCenter] removeObserver:controller
                                                        name:MPMoviePlayerPlaybackDidFinishNotification
                                                      object:controller.moviePlayer];

        // Register this class as an observer instead
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(moviePlaybackDidFinish:)
                                                     name:MPMoviePlayerPlaybackDidFinishNotification
                                                   object:controller.moviePlayer];

        controller.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        controller.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:controller animated:YES completion:nil];

    } else {
        // Should either be an iframe, or an object embed. In either case a src attribute should have been parsed for the contentURL.
        // Assume this is content we can show and try to load it.
        UIViewController *controller = [[WPWebVideoViewController alloc] initWithURL:videoControl.contentURL];
        controller.title = (videoControl.title != nil) ? videoControl.title : @"Video";
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
        navController.navigationBar.translucent = NO;
        navController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        navController.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:navController animated:YES completion:nil];
    }
}

- (void)richTextViewDidLoadMediaBatch:(WPRichTextView *)richTextView
{
    [self.postView layoutIfNeeded];
    [self refreshHeightForTableHeaderView];
}


#pragma mark - Sync methods

- (void)syncHelper:(WPContentSyncHelper *)syncHelper syncContentWithUserInteraction:(BOOL)userInteraction success:(void (^)(NSInteger))success failure:(void (^)(NSError *))failure
{
    CommentService *service = [[CommentService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    [service syncHierarchicalCommentsForPost:self.post page:1 success:success failure:failure];
}

- (void)syncHelper:(WPContentSyncHelper *)syncHelper syncMoreWithSuccess:(void (^)(NSInteger))success failure:(void (^)(NSError *))failure
{
    [self.activityFooter startAnimating];

    CommentService *service = [[CommentService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    NSInteger page = [service numberOfHierarchicalPagesSyncedforPost:self.post] + 1;
    [service syncHierarchicalCommentsForPost:self.post page:page success:success failure:failure];
}

- (void)syncContentEnded
{
    [self.activityFooter stopAnimating];
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
    Comment *comment = [self.tableViewHandler.resultsController objectAtIndexPath:indexPath];

    if (comment.depth > 0 && indexPath.row > 0) {
        NSIndexPath *previousPath = [NSIndexPath indexPathForRow:indexPath.row - 1 inSection:indexPath.section];
        Comment *previousComment = [self.tableViewHandler.resultsController objectAtIndexPath:previousPath];
        if (previousComment.depth < comment.depth) {
            cell.isFirstNestedComment = YES;
        }
    }

    if (indexPath.row < [self.tableView numberOfRowsInSection:indexPath.section] - 1) {
        NSIndexPath *nextPath = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section];
        Comment *nextComment = [self.tableViewHandler.resultsController objectAtIndexPath:nextPath];
        if ([nextComment.depth integerValue] == 0) {
            cell.needsExtraPadding = YES;
        }
    }

    [cell configureCell:comment];

    if ([cell isEqual:self.cellForLayout]) {
        return;
    }
    
    [self setAvatarForComment:comment forCell:cell indexPath:indexPath];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return [[UIView alloc] initWithFrame:CGRectZero];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return SectionHeaderHeight;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return EstimatedCommentRowHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat width = IS_IPAD ? WPTableViewFixedWidth : CGRectGetWidth(self.tableView.bounds);
    return [self tableView:tableView heightForRowAtIndexPath:indexPath forWidth:width];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath forWidth:(CGFloat)width
{
    [self configureCell:self.cellForLayout atIndexPath:indexPath];
    CGSize size = [self.cellForLayout sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
    CGFloat height = ceil(size.height);
    return height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Comment *comment = (Comment *)[self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    NSInteger depth = [comment.depth integerValue];

    NSString *cellIdentifier;

    switch (depth) {
        case 0:
            cellIdentifier = CommentDepth0CellIdentifier;
            break;
        case 1:
            cellIdentifier = CommentDepth1CellIdentifier;
            break;
        case 2:
            cellIdentifier = CommentDepth2CellIdentifier;
            break;
        case 3:
            cellIdentifier = CommentDepth3CellIdentifier;
            break;
        default:
            cellIdentifier = CommentDepth4CellIdentifier;
    }

    ReaderCommentCell *cell = (ReaderCommentCell *)[self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
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


#pragma mark - UIScrollView Delegate Methods

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    NSArray *selectedRows = [self.tableView indexPathsForSelectedRows];
    [self.tableView deselectRowAtIndexPath:[selectedRows objectAtIndex:0] animated:YES];

    if (self.inlineComposeView.isDisplayed) {
        [self.inlineComposeView dismissComposer];
    }
}


#pragma mark - ReaderCommentPublisherDelegate methods

- (void)commentPublisherDidPublishComment:(ReaderCommentPublisher *)composer
{
    [WPAnalytics track:WPAnalyticsStatReaderCommentedOnArticle];
    [self.inlineComposeView dismissComposer];

// TODO: figure out which page of comments this falls under and sync that page.

}


#pragma mark - ReaderCommentCell Delegate methods

- (void)commentCell:(UITableViewCell *)cell linkTapped:(NSURL *)url
{
    WPWebViewController *controller = [[WPWebViewController alloc] init];
    [controller setUrl:url];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)commentCell:(UITableViewCell *)cell replyToComment:(Comment *)comment
{
    // if a row is already selected don't allow selection of another
    if (self.inlineComposeView.isDisplayed) {
        [self.inlineComposeView toggleComposer];
        return;
    }

    self.commentPublisher.post = self.post;
    self.commentPublisher.comment = comment;

    if ([self canComment]) {
        [self.view addGestureRecognizer:self.tapOffKeyboardGesture];

        [self.inlineComposeView displayComposer];
    }

    [self.tableView selectRowAtIndexPath:[self.tableView indexPathForCell:cell] animated:YES scrollPosition:UITableViewScrollPositionTop];
}


#pragma mark - WPTableImageSource Delegate

- (void)tableImageSource:(WPTableImageSource *)tableImageSource imageReady:(UIImage *)image forIndexPath:(NSIndexPath *)indexPath
{
    [self.postView setFeaturedImage:image];
}


#pragma mark - RebloggingViewController Delegate Methods

- (void)postWasReblogged:(ReaderPost *)post
{
    [self.postView updateActionButtons];
}


#pragma mark - UIPopover Delegate Methods

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.popover = nil;
}

@end
