#import "ReaderPostDetailViewController.h"

#import "ContextManager.h"
#import "CustomHighlightButton.h"
#import "ReaderCommentsViewController.h"
#import "ReaderPost.h"
#import "ReaderPostRichContentView.h"
#import "ReaderPostService.h"
#import "RebloggingViewController.h"
#import "WPActivityDefaults.h"
#import "WPImageViewController.h"
#import "WPNoResultsView+AnimatedBox.h"
#import "WPTableImageSource.h"
#import "WPWebViewController.h"
#import "WordPress-Swift.h"

static CGFloat const TableViewTopMargin = 40;

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
    [self configurePostView];
    [self configureTableHeaderView];
    
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

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

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];

    if (IS_IPHONE) {
        // Resize media in the post detail to match the width of the new orientation.
        // No need to refresh on iPad when using a fixed width.
        [self.postView refreshMediaLayout];
        [self refreshHeightForTableHeaderView];
    }
}


#pragma mark - Configuration

- (void)configureNavbar
{
    // Don't show 'Reader' in the next-view back button
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@" " style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem = backButton;
    [WPStyleGuide setRightBarButtonItemWithCorrectSpacing:self.shareButton forNavigationItem:self.navigationItem];
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

- (void)refreshAndSync
{
    self.title = self.post.postTitle ?: NSLocalizedString(@"Reader", @"Placeholder title for ReaderPostDetails.");

    [self refreshPostView];
    [self refreshHeightForTableHeaderView];

    // Refresh incase the post needed to be fetched.
    [self.tableView reloadData];

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
    WPWebViewController *controller = [[WPWebViewController alloc] init];
    [controller setUrl:linkURL];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)richTextView:(WPRichTextView *)richTextView didReceiveImageLinkAction:(WPRichTextImage *)imageControl
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

- (void)richTextViewDidLoadMediaBatch:(WPRichTextView *)richTextView
{
    [self.postView layoutIfNeeded];
    [self refreshHeightForTableHeaderView];
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
