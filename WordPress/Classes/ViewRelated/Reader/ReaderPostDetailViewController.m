#import "ReaderPostDetailViewController.h"

#import "ContextManager.h"
#import "CustomHighlightButton.h"
#import "ReaderBrowseSiteViewController.h"
#import "ReaderCommentsViewController.h"
#import "ReaderPost.h"
#import "ReaderPostRichContentView.h"
#import "ReaderPostRichUnattributedContentView.h"
#import "ReaderPostService.h"
#import "RebloggingViewController.h"
#import "WPActivityDefaults.h"
#import "WPImageViewController.h"
#import "WPNoResultsView+AnimatedBox.h"
#import "WPTableImageSource.h"
#import "WPWebViewController.h"
#import "WordPress-Swift.h"
#import "BlogService.h"

static CGFloat const VerticalMargin = 40;
static NSInteger const ReaderPostDetailImageQuality = 65;

@interface ReaderPostDetailViewController ()<ReaderPostContentViewDelegate,
                                            RebloggingViewControllerDelegate,
                                            WPRichTextViewDelegate,
                                            WPTableImageSourceDelegate,
                                            UIPopoverControllerDelegate>

@property (nonatomic, strong, readwrite) ReaderPost *post;
@property (nonatomic, strong) UIPopoverController *popover;
@property (nonatomic, strong) ReaderPostRichContentView *postView;
@property (nonatomic, strong) UIBarButtonItem *shareButton;
@property (nonatomic, strong) WPTableImageSource *featuredImageSource;
@property (nonatomic, strong) UIScrollView *scrollView;

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
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];

    if (IS_IPHONE) {
        // Resize media in the post detail to match the width of the new orientation.
        // No need to refresh on iPad when using a fixed width.
        [self.postView refreshMediaLayout];
    }
}


#pragma mark - Configuration

- (Class)classForPostView
{
    if (self.readerViewStyle == ReaderViewStyleSitePreview) {
        return [ReaderPostRichUnattributedContentView class];
    }
    return [ReaderPostRichContentView class];
}

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
    CGFloat width = IS_IPAD ? WPTableViewFixedWidth : CGRectGetWidth(self.view.bounds);
    self.postView = [[[self classForPostView] alloc] initWithFrame:CGRectMake(0.0, 0.0, width, 1.0)]; // minimal frame so rich text will have initial layout.
    self.postView.translatesAutoresizingMaskIntoConstraints = NO;
    self.postView.delegate = self;
    self.postView.backgroundColor = [UIColor whiteColor];
    self.postView.shouldHideComments = self.shouldHideComments;

    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BOOL isLoggedIn = [[[AccountService alloc] initWithManagedObjectContext:context] defaultWordPressComAccount] != nil;
    self.postView.shouldEnableLoggedinFeatures = isLoggedIn;
    self.postView.shouldShowAttributionButton = isLoggedIn;
    
    [self setReblogButtonVisibilityOfPostView:self.postView];
    
    [self.scrollView addSubview:self.postView];
}

- (void)configureConstraints
{
    NSParameterAssert(self.postView);

    UIView *mainView = self.view;
    CGFloat verticalMargin = IS_IPAD ? VerticalMargin : 0;
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

    if (IS_IPAD) {
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[_postView(WPTableViewWidth)]"
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

- (void)setReblogButtonVisibilityOfPostView:(ReaderPostRichContentView *)postView
{
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    postView.shouldHideReblogButton = ![blogService hasVisibleWPComAccounts];
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

- (void)dismissPopover
{
    if (self.popover) {
        [self.popover dismissPopoverAnimated:YES];
        self.popover = nil;
    }
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
        self.featuredImageSource.photonQuality = ReaderPostDetailImageQuality;
    }
    
    CGFloat width = IS_IPAD ? WPTableViewFixedWidth : CGRectGetWidth(self.view.bounds);
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

- (void)contentViewDidReceiveAvatarAction:(UIView *)contentView
{
    ReaderBrowseSiteViewController *controller = [[ReaderBrowseSiteViewController alloc] initWithPost:self.post];
    [self.navigationController pushViewController:controller animated:YES];
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
    ReaderCommentsViewController *controller = [ReaderCommentsViewController controllerWithPost:self.post];
    [self.navigationController pushViewController:controller animated:YES];
}


# pragma mark - Rich Text Delegate Methods

- (void)richTextView:(WPRichTextView *)richTextView didReceiveLinkAction:(NSURL *)linkURL
{
    if (!linkURL.host) {
        // fix relative URLs 
        NSURL *postURL = [NSURL URLWithString:self.post.permaLink];
        linkURL = [NSURL URLWithString:[linkURL absoluteString] relativeToURL:postURL];
    }
    WPWebViewController *webViewController = [WPWebViewController webViewControllerWithURL:linkURL];
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
        WPWebViewController *webViewController = [WPWebViewController webViewControllerWithURL:imageControl.linkURL];
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
