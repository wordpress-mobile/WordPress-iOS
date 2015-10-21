#import "ReaderPostDetailViewController.h"

#import "BlogService.h"
#import "ContextManager.h"
#import "CustomHighlightButton.h"
#import "ReachabilityUtils.h"
#import "ReaderCommentsViewController.h"
#import "ReaderPost.h"
#import "ReaderPostRichContentView.h"
#import "ReaderPostRichUnattributedContentView.h"
#import "ReaderPostService.h"
#import "SourcePostAttribution.h"
#import "WPActivityDefaults.h"
#import "WPImageViewController.h"
#import "WPNoResultsView+AnimatedBox.h"
#import "WPTableImageSource.h"
#import "WPWebViewController.h"
#import "WordPressAppDelegate.h"
#import "WordPress-Swift.h"
#import "WPUserAgent.h"

static CGFloat const VerticalMargin = 40;
static NSInteger const ReaderPostDetailImageQuality = 65;
NSString * const ReaderPostLikeCountKeyPath = @"likeCount";
NSString * const ReaderDetailTypeKey = @"post_detail_type";
NSString * const ReaderDetailTypeNormal = @"normal";
NSString * const ReaderDetailTypePreviewSite = @"preview_site";
NSString * const ReaderDetailOfflineKey = @"offline_view";
NSString * const ReaderPixelStatReferrer = @"https://wordpress.com/";

@interface ReaderPostDetailViewController ()<ReaderPostContentViewDelegate,
                                            WPRichTextViewDelegate,
                                            WPTableImageSourceDelegate>

@property (nonatomic, strong, readwrite) ReaderPost *post;
@property (nonatomic, strong) ReaderPostRichContentView *postView;
@property (nonatomic, strong) UIBarButtonItem *shareButton;
@property (nonatomic, strong) WPTableImageSource *featuredImageSource;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic) BOOL didBumpStats;
@property (nonatomic) BOOL didBumpPageViews;

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
    [self.post removeObserver:self forKeyPath:ReaderPostLikeCountKeyPath];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self configureNavbar];
    [self configureScrollView];
    [self configurePostView];
    [self configureConstraints];

    [WPStyleGuide configureColorsForView:self.view andTableView:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self bumpStats];
    [self refresh];
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
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleApplicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self.postView refreshMediaLayout];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];

    [self.view layoutIfNeeded];
    [self.postView refreshMediaLayout];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if (object == self.post && [keyPath isEqualToString:ReaderPostLikeCountKeyPath]) {
        // Note: The intent here is to update the action buttons, specifically the
        // like button, *after* both likeCount and isLiked has changed. The order
        // of the properties is important.
        [self.postView updateActionButtons];
    }
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
    [self.postView refreshMediaLayout];
}


#pragma mark - Configuration

- (void)configureNavbar
{
    // Don't show 'Reader' in the next-view back button
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@" " style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem = backButton;
    [WPStyleGuide setRightBarButtonItemWithCorrectSpacing:self.shareButton forNavigationItem:self.navigationItem];
}

- (void)configureScrollView
{
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;

    [self.view addSubview:self.scrollView];
}

- (void)configurePostView
{
    CGFloat width = [UIDevice isPad] ? MIN(WPTableViewFixedWidth, CGRectGetWidth(self.view.bounds)) : CGRectGetWidth(self.view.bounds);
    self.postView = [[ReaderPostRichContentView alloc] initWithFrame:CGRectMake(0.0, 0.0, width, 1.0)]; // minimal frame so rich text will have initial layout.
    self.postView.translatesAutoresizingMaskIntoConstraints = NO;
    self.postView.delegate = self;
    self.postView.backgroundColor = [UIColor whiteColor];
    self.postView.shouldHideComments = self.shouldHideComments;

    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BOOL isLoggedIn = [[[AccountService alloc] initWithManagedObjectContext:context] defaultWordPressComAccount] != nil;
    self.postView.shouldEnableLoggedinFeatures = isLoggedIn;
    self.postView.shouldShowAttributionButton = isLoggedIn;
    
    [self.scrollView addSubview:self.postView];
}

- (void)configureConstraints
{
    NSParameterAssert(self.postView);

    UIView *mainView = self.view;
    CGFloat verticalMargin = [UIDevice isPad] ? VerticalMargin : 0;
    NSDictionary *views = NSDictionaryOfVariableBindings(_scrollView, _postView, mainView);
    NSDictionary *metrics = @{@"WPTableViewWidth": @(WPTableViewFixedWidth), @"verticalMargin": @(verticalMargin)};

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_scrollView]|"
                                                                      options:0
                                                                      metrics:metrics
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_scrollView]|"
                                                                      options:0
                                                                      metrics:metrics
                                                                        views:views]];

    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.postView
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1.0
                                                           constant:0.0]];

    if ([UIDevice isPad]) {
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(>=0)-[_postView(WPTableViewWidth@900)]-(>=0)-|"
                                                                                options:0
                                                                                metrics:metrics
                                                                                  views:views]];
    } else {
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[_postView(==mainView)]"
                                                                                options:0
                                                                                metrics:metrics
                                                                                  views:views]];
    }

    [self.scrollView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(verticalMargin)-[_postView]-(verticalMargin)-|"
                                                                            options:0
                                                                            metrics:metrics
                                                                              views:views]];
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
    activityViewController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
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
        [weakSelf refresh];

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

    if (!post) {
        [_post removeObserver:self forKeyPath:ReaderPostLikeCountKeyPath];
        _post = nil;
        return;
    }

    _post = post;
    [_post addObserver:self forKeyPath:ReaderPostLikeCountKeyPath options:0 context:nil];
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

- (BOOL)isLoaded
{
    return (self.post != nil);
}

- (BOOL)canComment
{
    return self.post.commentsOpen;
}


#pragma mark - View Refresh Helpers

- (void)refresh
{
    self.title = self.post.postTitle ?: NSLocalizedString(@"Post", @"Placeholder title for ReaderPostDetails.");

    [self refreshPostView];

    // Enable Share action only when the post is fully loaded
    self.shareButton.enabled = self.isLoaded;
}

- (void)refreshPostView
{
    NSParameterAssert(self.postView);

    self.postView.hidden = !self.isLoaded;

    if (!self.isLoaded) {
        return;
    }

    // We have a post. Bump its page views.
    [self bumpPageViewsForPost:self.post.postID site:self.post.siteID siteURL:self.post.blogURL];

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
        CGFloat maxWidth = MAX(CGRectGetWidth(self.postView.bounds), CGRectGetHeight(self.postView.bounds));
        CGFloat maxHeight = maxWidth * WPContentViewMaxImageHeightPercentage;
        self.featuredImageSource = [[WPTableImageSource alloc] initWithMaxSize:CGSizeMake(maxWidth, maxHeight)];
        self.featuredImageSource.delegate = self;
        self.featuredImageSource.photonQuality = ReaderPostDetailImageQuality;
    }
    
    CGFloat width = CGRectGetWidth(self.postView.bounds);
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


#pragma mark - Analytics

- (void)bumpStats
{
    if (self.didBumpStats) {
        return;
    }
    self.didBumpStats = YES;
    NSString *isOfflineView = [ReachabilityUtils isInternetReachable] ? @"no" : @"yes";
    NSString *detailType = (self.post.topic.type == ReaderSiteTopic.TopicType) ? ReaderDetailTypePreviewSite : ReaderDetailTypeNormal;
    NSDictionary *properties = @{
                                 ReaderDetailTypeKey:detailType,
                                 ReaderDetailOfflineKey:isOfflineView
                                 };
    [WPAnalytics track:WPAnalyticsStatReaderArticleOpened withProperties:properties];
}

- (void)bumpPageViewsForPost:(NSNumber *)postID site:(NSNumber *)siteID siteURL:(NSString *)siteURL
{
    if (self.didBumpPageViews) {
        return;
    }
    self.didBumpPageViews = YES;

    // If the user is an admin on the post's site do not bump the page view unless
    // the the post is private.
    if (!self.post.isPrivate && [self isUserAdminOnSiteWithID:self.post.siteID]) {
        return;
    }

    NSURL *site = [NSURL URLWithString:siteURL];
    if (![site host]) {
        return;
    }
    NSString *pixel = @"https://pixel.wp.com/g.gif";
    NSArray *params = @[
                        @"v=wpcom",
                        @"reader=1",
                        [NSString stringWithFormat:@"ref=%@", ReaderPixelStatReferrer],
                        [NSString stringWithFormat:@"host=%@",[site host]],
                        [NSString stringWithFormat:@"blog=%@",siteID],
                        [NSString stringWithFormat:@"post=%@",postID],
                        [NSString stringWithFormat:@"t=%d", arc4random()]
                        ];

    NSString *path = [NSString stringWithFormat:@"%@?%@", pixel, [params componentsJoinedByString:@"&"]];
    NSString *userAgent = [[WordPressAppDelegate sharedInstance].userAgent currentUserAgent];

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:path]];
    [request setValue:userAgent forHTTPHeaderField:@"User-Agent"];
    [request setValue:ReaderPixelStatReferrer forHTTPHeaderField:@"Referer"];

    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request];
    [task resume];
}

- (BOOL)isUserAdminOnSiteWithID:(NSNumber *)siteID
{
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    Blog *blog = [blogService blogByBlogId:siteID];
    return blog.isAdmin;
}


#pragma mark - Actions

- (void)handleShareButtonTapped:(id)sender
{
    UIActivityViewController *activityViewController = [self activityViewControllerForSharing];
    if (![UIDevice isPad]) {
        [self presentViewController:activityViewController animated:YES completion:nil];
        return;
    }

    activityViewController.modalPresentationStyle = UIModalPresentationPopover;
    [self presentViewController:activityViewController animated:YES completion:nil];
    UIPopoverPresentationController *presentationController = activityViewController.popoverPresentationController;
    presentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    presentationController.sourceView = self.shareButton.customView;
    presentationController.sourceRect = self.shareButton.customView.bounds;
    
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

- (void)contentViewDidReceiveAvatarAction:(UIView *)contentView
{
    NSNumber *siteID = self.post.siteID;
    ReaderStreamViewController *controller = [ReaderStreamViewController controllerWithSiteID:siteID isFeed:self.post.isExternal];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)postView:(ReaderPostContentView *)postView didReceiveLikeAction:(id)sender
{
    ReaderPost *post = self.post;
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    ReaderPostService *service = [[ReaderPostService alloc] initWithManagedObjectContext:context];
    [service toggleLikedForPost:post success:nil failure:^(NSError *error) {
        DDLogError(@"Error (un)liking post : %@", [error localizedDescription]);
    }];
}

- (void)postView:(ReaderPostContentView *)postView didReceiveCommentAction:(id)sender
{
    ReaderCommentsViewController *controller = [ReaderCommentsViewController controllerWithPost:self.post];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)postView:(ReaderPostContentView *)postView didTapDiscoverAttribution:(id)sender
{
    if (!self.post.sourceAttribution) {
        return;
    }
    if (self.post.sourceAttribution.blogID) {
        ReaderStreamViewController *controller = [ReaderStreamViewController controllerWithSiteID:self.post.sourceAttribution.blogID isFeed:NO];
        [self.navigationController pushViewController:controller animated:YES];
        return;
    }

    NSString *path;
    if ([self.post.sourceAttribution.attributionType isEqualToString:SourcePostAttributionTypePost]) {
        path = self.post.sourceAttribution.permalink;
    } else {
        path = self.post.sourceAttribution.blogURL;
    }
    NSURL *linkURL = [NSURL URLWithString:path];
    [self presentWebViewControllerWithLink:linkURL];
}

- (void)presentWebViewControllerWithLink:(NSURL *)linkURL
{
    WPWebViewController *webViewController = [WPWebViewController authenticatedWebViewController:linkURL];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:webViewController];
    [self presentViewController:navController animated:YES completion:nil];
}

# pragma mark - Rich Text Delegate Methods

- (void)richTextView:(WPRichTextView *)richTextView didReceiveLinkAction:(NSURL *)linkURL
{
    if (!linkURL.host) {
        // fix relative URLs 
        NSURL *postURL = [NSURL URLWithString:self.post.permaLink];
        linkURL = [NSURL URLWithString:[linkURL absoluteString] relativeToURL:postURL];
    }
    [self presentWebViewControllerWithLink:linkURL];
}

- (void)richTextView:(WPRichTextView *)richTextView didReceiveImageLinkAction:(WPRichTextImage *)imageControl
{
    WPImageViewController *controller = nil;
    BOOL isSupportedNatively = [WPImageViewController isUrlSupported:imageControl.linkURL];
    
    if (isSupportedNatively) {
        controller = [[WPImageViewController alloc] initWithImage:imageControl.imageView.image andURL:imageControl.linkURL];
    } else if (imageControl.linkURL) {
        [self presentWebViewControllerWithLink:imageControl.linkURL];
        return;
    } else {
        controller = [[WPImageViewController alloc] initWithImage:imageControl.imageView.image];
    }

    controller.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    controller.modalPresentationStyle = UIModalPresentationFullScreen;
    
    [self presentViewController:controller animated:YES completion:nil];
}


#pragma mark - WPTableImageSource Delegate

- (void)tableImageSource:(WPTableImageSource *)tableImageSource imageReady:(UIImage *)image forIndexPath:(NSIndexPath *)indexPath
{
    [self.postView setFeaturedImage:image];
}

@end
