#import "ReaderPostDetailViewController.h"
#import "ReaderPostsViewController.h"

#import <MediaPlayer/MediaPlayer.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "WPActivityDefaults.h"
#import "WordPressAppDelegate.h"
#import "ReaderComment.h"
#import "ReaderCommentTableViewCell.h"
#import "IOS7CorrectedTextView.h"
#import "WPImageViewController.h"
#import "WPWebVideoViewController.h"
#import "WPWebViewController.h"
#import "ContextManager.h"
#import "InlineComposeView.h"
#import "ReaderCommentPublisher.h"
#import "RebloggingViewController.h"
#import "WPAvatarSource.h"
#import "ReaderPostService.h"
#import "ReaderPost.h"
#import "WPRichTextVideoControl.h"
#import "WPRichTextImageControl.h"
#import "ReaderCommentTableViewCell.h"
#import "ReaderPostRichContentView.h"
#import "CustomHighlightButton.h"
#import "WPTableImageSource.h"
#import "WPNoResultsView+AnimatedBox.h"

static NSInteger const ReaderCommentsToSync = 100;
static NSTimeInterval const ReaderPostDetailViewControllerRefreshTimeout = 300; // 5 minutes
static CGFloat const SectionHeaderHeight = 25.0f;

@interface ReaderPostDetailViewController ()<UIActionSheetDelegate,
                                            MFMailComposeViewControllerDelegate,
                                            UIPopoverControllerDelegate,
                                            ReaderCommentPublisherDelegate,
                                            RebloggingViewControllerDelegate,
                                            ReaderPostContentViewDelegate,
                                            WPRichTextViewDelegate,
                                            ReaderCommentTableViewCellDelegate,
                                            WPTableImageSourceDelegate,
                                            NSFetchedResultsControllerDelegate>

@property (nonatomic, strong, readwrite) ReaderPost *post;
@property (nonatomic, strong) UIPopoverController *popover;
@property (nonatomic, strong) UIGestureRecognizer *tapOffKeyboardGesture;
@property (nonatomic, strong) ReaderPostRichContentView *postView;
@property (nonatomic) BOOL infiniteScrollEnabled;
@property (nonatomic, strong) UIActivityIndicatorView *activityFooter;
@property (nonatomic, strong) UIBarButtonItem *commentButton;
@property (nonatomic, strong) UIBarButtonItem *likeButton;
@property (nonatomic, strong) UIBarButtonItem *reblogButton;
@property (nonatomic, strong) UIBarButtonItem *shareButton;
@property (nonatomic, strong) NSMutableArray *comments;
@property (nonatomic, strong) NSFetchedResultsController *resultsController;
@property (nonatomic) BOOL hasMoreContent;
@property (nonatomic) BOOL loadingMore;
@property (nonatomic) CGPoint savedScrollOffset;
@property (nonatomic) CGFloat keyboardOffset;
@property (nonatomic) BOOL isSyncing;
@property (nonatomic, strong) InlineComposeView *inlineComposeView;
@property (nonatomic, strong) ReaderCommentPublisher *commentPublisher;
@property (nonatomic, strong) WPTableImageSource *featuredImageSource;

@end

@implementation ReaderPostDetailViewController

#pragma mark - Static Helpers

+ (instancetype)detailControllerWithPost:(ReaderPost *)post
{
    ReaderPostDetailViewController *detailsViewController = [self new];
    detailsViewController.post = post;
    return detailsViewController;
}

+ (instancetype)detailControllerWithPostID:(NSNumber *)postID siteID:(NSNumber *)siteID
{
    ReaderPostDetailViewController *detailsViewController = [self new];
    [detailsViewController setupWithPostID:postID siteID:siteID];
    return detailsViewController;
}


#pragma mark - LifeCycle Methods

- (void)dealloc
{
    self.resultsController.delegate = nil;
    self.tableView.delegate = nil;
    self.postView.delegate = nil;
    self.commentPublisher.delegate = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _comments = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.infiniteScrollEnabled) {
        [self enableInfiniteScrolling];
    }
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    [self.tableView registerClass:[WPTableViewCell class] forCellReuseIdentifier:@"PostCell"];

    // Don't show 'Reader' in the next-view back button
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem = backButton;
    
    UIToolbar *toolbar = self.navigationController.toolbar;
    toolbar.barTintColor = [WPStyleGuide littleEddieGrey];
    toolbar.tintColor = [UIColor whiteColor];
    toolbar.translucent = NO;
    
    self.tapOffKeyboardGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard:)];
    
    self.inlineComposeView = [[InlineComposeView alloc] initWithFrame:CGRectZero];
    [self.inlineComposeView setButtonTitle:NSLocalizedString(@"Post", nil)];
    [self.view addSubview:self.inlineComposeView];
    
    // Comment composer responds to the inline compose view to publish comments
    self.commentPublisher = [[ReaderCommentPublisher alloc] initWithComposer:self.inlineComposeView];
    self.commentPublisher.delegate = self;
    
    [self configurePostView];
    [self configureTableHeaderView];
    
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    [WPStyleGuide setRightBarButtonItemWithCorrectSpacing:self.shareButton forNavigationItem:self.navigationItem];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    CGSize contentSize = self.tableView.contentSize;
    if (contentSize.height > self.savedScrollOffset.y) {
        [self.tableView scrollRectToVisible:CGRectMake(self.savedScrollOffset.x, self.savedScrollOffset.y, 0.0f, 0.0f) animated:NO];
    } else {
        [self.tableView scrollRectToVisible:CGRectMake(0.0f, contentSize.height, 0.0f, 0.0f) animated:NO];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    [self reloadData];
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
	
    if (IS_IPHONE) {
        self.savedScrollOffset = self.tableView.contentOffset;
    }

    [self.inlineComposeView dismissComposer];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
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
    }

    // Make sure a selected comment is visible after rotating.
    if ([self.tableView indexPathForSelectedRow] != nil && self.inlineComposeView.isDisplayed) {
        [self.tableView scrollToNearestSelectedRowAtScrollPosition:UITableViewScrollPositionNone animated:NO];
    }
}


#pragma mark - Actions

- (void)dismissKeyboard:(id)sender
{
    for (UIGestureRecognizer *gesture in self.view.gestureRecognizers) {
        if ([gesture isEqual:self.tapOffKeyboardGesture]) {
            [self.view removeGestureRecognizer:gesture];
        }
    }
    
    [self.inlineComposeView dismissComposer];
}


#pragma mark - View getters/builders

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

    CGFloat marginTop = IS_IPAD ? WPTableViewTopMargin : 0;
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


#pragma mark View Refresh Helpers

- (void)reloadData
{
    self.title = self.post.postTitle ?: NSLocalizedString(@"Reader", @"Placeholder title for ReaderPostDetails.");
    
    [self prepareComments];
    
    [self refreshPostView];
    [self refreshHeightForTableHeaderView];
    [self refreshCommentsIfNeeded];
    [self refreshShareButton];
}

- (void)refreshPostView
{
    NSParameterAssert(self.postView);
    
    BOOL isLoaded = self.isLoaded;
    self.postView.hidden = !isLoaded;
    
    if (!isLoaded) {
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
        NSString *content = [self.post contentForDisplay];
        if ([content rangeOfString:[featuredImageURL absoluteString]].length > 0) {
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
    CGFloat marginTop = IS_IPAD ? WPTableViewTopMargin : 0;
    CGFloat width = IS_IPAD ? WPTableViewFixedWidth : CGRectGetWidth(self.tableView.bounds);
    CGSize size = [self.postView sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
    CGFloat height = size.height + marginTop;
    UIView *tableHeaderView = self.tableView.tableHeaderView;
    tableHeaderView.frame = CGRectMake(0.0, 0.0, CGRectGetWidth(self.tableView.bounds), height);
    self.tableView.tableHeaderView = tableHeaderView;
}

- (void)refreshCommentsIfNeeded
{
    // Hit the backend, if needed
    BOOL isConnected    = [[WordPressAppDelegate sharedWordPressApplicationDelegate] connectionAvailable];
    NSDate *lastSynced  = self.lastSyncDate;
    BOOL isRefreshTime  = (lastSynced == nil || ABS([lastSynced timeIntervalSinceNow] > ReaderPostDetailViewControllerRefreshTimeout));
    
    if (isConnected && self.post.isWPCom && isRefreshTime) {
        [self syncWithUserInteraction:NO];
    }
}

- (void)refreshShareButton
{
    // Enable Share action only when the post is fully loaded
    self.shareButton.enabled = self.isLoaded;
}


#pragma mark Lazy Loading Helpers

- (void)setupWithPostID:(NSNumber *)postID siteID:(NSNumber *)siteID
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    ReaderPostService *service      = [[ReaderPostService alloc] initWithManagedObjectContext:context];
    __weak __typeof(self) weakSelf  = self;
    
    [WPNoResultsView displayAnimatedBoxWithTitle:NSLocalizedString(@"Loading Post...", @"Text displayed while loading a post.")
                                         message:nil
                                            view:self.view];
    
    [service deletePostsWithNoTopic];
    [service fetchPost:postID.integerValue forSite:siteID.integerValue success:^(ReaderPost *post) {
        
        [[ContextManager sharedInstance] saveContext:context];
        
        weakSelf.post = post;
        [weakSelf reloadData];

        [WPNoResultsView removeFromView:weakSelf.view];
        
    } failure:^(NSError *error) {
        DDLogError(@"[RestAPI] %@", error);

        [WPNoResultsView displayAnimatedBoxWithTitle:NSLocalizedString(@"Error Loading Post", @"Text displayed when load post fails.")
                                             message:nil
                                                view:weakSelf.view];
        
    }];
}

- (BOOL)isLoaded
{
    return (self.post != nil);
}


#pragma mark - Comments

- (BOOL)canComment
{
    return self.post.commentsOpen;
}

- (void)prepareComments
{
    self.resultsController = nil;
    [self.comments removeAllObjects];

    __block void(__unsafe_unretained ^flattenComments)(NSArray *) = ^void (NSArray *comments) {
        // Ensure the array is correctly sorted. 
        comments = [comments sortedArrayUsingComparator: ^(id obj1, id obj2) {
            ReaderComment *a = obj1;
            ReaderComment *b = obj2;
            if ([[a dateCreated] timeIntervalSince1970] > [[b dateCreated] timeIntervalSince1970]) {
                return (NSComparisonResult)NSOrderedDescending;
            }
            if ([[a dateCreated] timeIntervalSince1970] < [[b dateCreated] timeIntervalSince1970]) {
                return (NSComparisonResult)NSOrderedAscending;
            }
            return (NSComparisonResult)NSOrderedSame;
        }];

        for (ReaderComment *comment in comments) {
            [self.comments addObject:comment];
            if ([comment.childComments count] > 0) {
                flattenComments([comment.childComments allObjects]);
            }
        }
    };

    flattenComments(self.resultsController.fetchedObjects);

    // Cache attributed strings.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, NULL), ^{
        for (ReaderComment *comment in self.comments) {
            comment.attributedContent = [ReaderCommentTableViewCell convertHTMLToAttributedString:comment.content withOptions:nil];
        }
        __weak ReaderPostDetailViewController *weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.tableView reloadData];
        });
	});
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

- (BOOL)isReplying
{
    return ([self.tableView indexPathForSelectedRow] != nil) ? YES : NO;
}

- (CGSize)tabBarSize
{
    CGSize tabBarSize = CGSizeZero;
    if ([self tabBarController]) {
        tabBarSize = [[[self tabBarController] tabBar] bounds].size;
    }
    
    return tabBarSize;
}

- (void)dismissPopover
{
    if (self.popover) {
        [self.popover dismissPopoverAnimated:YES];
        self.popover = nil;
    }
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.popover = nil;
}

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

    if (![post isFollowable]) {
        return;
    }

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


#pragma mark - RebloggingViewController Delegate Methods

- (void)postWasReblogged:(ReaderPost *)post
{
    [self.postView updateActionButtons];
}


#pragma mark - Sync methods

- (NSDate *)lastSyncDate
{
    return self.post.dateCommentsSynced;
}

- (void)syncWithUserInteraction:(BOOL)userInteraction
{
    if ([self.post.postID integerValue] == 0 ) { // Weird that this should ever happen.
        self.post.dateCommentsSynced = [NSDate date];
        return;
    }
    self.isSyncing = YES;
    NSDictionary *params = @{@"number":[NSNumber numberWithInteger:ReaderCommentsToSync]};

    [ReaderPost getCommentsForPost:[self.post.postID integerValue]
                          fromSite:[self.post.siteID stringValue]
                    withParameters:params
                           success:^(AFHTTPRequestOperation *operation, id responseObject) {
                               [self onSyncSuccess:operation response:responseObject];
                           } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                           }];
}

- (void)loadMoreWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure
{
    if ([self.resultsController.fetchedObjects count] == 0) {
        return;
    }
	
    if (self.loadingMore) {
        return;
    }

    self.loadingMore = YES;
    self.isSyncing = YES;
    NSUInteger numberToSync = [self.comments count] + ReaderCommentsToSync;
    NSDictionary *params = @{@"number":[NSNumber numberWithInteger:numberToSync]};

    [ReaderPost getCommentsForPost:[self.post.postID integerValue]
                          fromSite:[self.post.siteID stringValue]
                    withParameters:params
                           success:^(AFHTTPRequestOperation *operation, id responseObject) {
                               [self onSyncSuccess:operation response:responseObject];
                           } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                           }];
}

- (void)onSyncSuccess:(AFHTTPRequestOperation *)operation response:(id)responseObject
{
    self.post.dateCommentsSynced = [NSDate date];
    self.loadingMore = NO;
    self.isSyncing = NO;
    NSDictionary *resp = (NSDictionary *)responseObject;
    NSArray *commentsArr = [resp arrayForKey:@"comments"];

    if (!commentsArr) {
        self.hasMoreContent = NO;
        return;
    }

    if ([commentsArr count] < ([self.comments count] + ReaderCommentsToSync)) {
        self.hasMoreContent = NO;
    }

    [ReaderComment syncAndThreadComments:commentsArr
                                 forPost:self.post
                             withContext:[[ContextManager sharedInstance] mainContext]];

    [self prepareComments];
}


#pragma mark - Infinite Scrolling

- (void)setInfiniteScrollEnabled:(BOOL)infiniteScrollEnabled
{
    if (infiniteScrollEnabled == self.infiniteScrollEnabled) {
        return;
    }
	
    self.infiniteScrollEnabled = infiniteScrollEnabled;
    if (self.isViewLoaded) {
        if (self.infiniteScrollEnabled) {
            [self enableInfiniteScrolling];
        } else {
            [self disableInfiniteScrolling];
        }
    }
}

- (void)enableInfiniteScrolling
{
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 50.0f)];
    footerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [footerView addSubview:self.activityFooter];
    self.tableView.tableFooterView = footerView;
}

- (void)disableInfiniteScrolling
{
    self.tableView.tableFooterView = nil;
    self.activityFooter = nil;
}


#pragma mark - UITableView Delegate Methods

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return [[UIView alloc] initWithFrame:CGRectZero];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return SectionHeaderHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat width = IS_IPAD ? WPTableViewFixedWidth : CGRectGetWidth(self.tableView.bounds);

    if ([self.comments count] == 0) {
        return 0.0f;
    }

    ReaderComment *comment = [self.comments objectAtIndex:indexPath.row];
    return [ReaderCommentTableViewCell heightForComment:comment
                                                  width:width
                                             tableStyle:tableView.style
                                          accessoryType:UITableViewCellAccessoryNone];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.comments count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = @"ReaderCommentCell";
    ReaderCommentTableViewCell *cell = (ReaderCommentTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[ReaderCommentTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.delegate = self;
    }
    cell.accessoryType = UITableViewCellAccessoryNone;

    ReaderComment *comment = [self.comments objectAtIndex:indexPath.row];
    [cell configureCell:comment];
    [self setAvatarForComment:comment forCell:cell indexPath:indexPath];

    return cell;
}

- (void)setAvatarForComment:(ReaderComment *)comment forCell:(ReaderCommentTableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    WPAvatarSource *source = [WPAvatarSource sharedSource];

    NSString *hash;
    CGSize size = CGSizeMake(32.0, 32.0);
    NSURL *url = [comment avatarURLForDisplay];
    WPAvatarSourceType type = [source parseURL:url forAvatarHash:&hash];

    UIImage *image = [source cachedImageForAvatarHash:hash ofType:type withSize:size];
    if (image) {
        [cell setAvatar:image];
        return;
    }

    [cell setAvatar:[UIImage imageNamed:@"default-identicon"]];
    if (hash) {
        [source fetchImageForAvatarHash:hash ofType:type withSize:size success:^(UIImage *image) {
            if (cell == [self.tableView cellForRowAtIndexPath:indexPath]) {
                [cell setAvatar:image];
            }
        }];
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ReaderComment *comment = [self.comments objectAtIndex:indexPath.row];

    // if a row is already selected don't allow selection of another
    if (self.inlineComposeView.isDisplayed) {
        if (comment == self.commentPublisher.comment) {
            [self.inlineComposeView toggleComposer];
        }
        return nil;
    }

    self.commentPublisher.post = self.post;
    self.commentPublisher.comment = comment;
    
    if ([self canComment]) {
        [self.view addGestureRecognizer:self.tapOffKeyboardGesture];
        
        [self.inlineComposeView displayComposer];
    }

    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (![self canComment]) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
        return;
    }

    [self.tableView scrollToNearestSelectedRowAtScrollPosition:UITableViewRowAnimationTop animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    // if we selected the already active comment allow highlight
    // so we can toggle the inline composer
    ReaderComment *comment = [self.comments objectAtIndex:indexPath.row];
    if (comment == self.commentPublisher.comment) {
        return YES;
    }

    return !self.inlineComposeView.isDisplayed;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (IS_IPAD) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    // Are we approaching the end of the table?
    if ((indexPath.section + 1 == [self numberOfSectionsInTableView:tableView]) &&
        (indexPath.row + 4 >= [self tableView:tableView numberOfRowsInSection:indexPath.section]) &&
        [self tableView:tableView numberOfRowsInSection:indexPath.section] > 10) {

        // Only 3 rows till the end of table
        if (!self.isSyncing && self.hasMoreContent) {
            [self.activityFooter startAnimating];
            [self loadMoreWithSuccess:^{
                [self.activityFooter stopAnimating];
            } failure:^(NSError *error) {
                [self.activityFooter stopAnimating];
            }];
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
    [self syncWithUserInteraction:NO];
}

#pragma mark - ReaderCommentTableViewCellDelegate methods

- (void)readerCommentTableViewCell:(ReaderCommentTableViewCell *)cell didTapURL:(NSURL *)url
{
    WPWebViewController *controller = [[WPWebViewController alloc] init];
    [controller setUrl:url];
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)resultsController
{
    if (_resultsController != nil) {
        return _resultsController;
    }
	
    NSString *entityName = @"ReaderComment";
    NSManagedObjectContext *moc = [[ContextManager sharedInstance] mainContext];

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"ReaderComment" inManagedObjectContext:moc]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(post = %@) && (parentID = 0)", self.post];
    [fetchRequest setPredicate:predicate];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"dateCreated" ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    _resultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                             managedObjectContext:moc
                                                               sectionNameKeyPath:nil
                                                                        cacheName:nil];
    
    _resultsController.delegate = self;
	
    NSError *error = nil;
    if (![_resultsController performFetch:&error]) {
        DDLogError(@"%@ couldn't fetch %@: %@", self, entityName, [error localizedDescription]);
        _resultsController = nil;
    }
    
    return _resultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    // noop
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView reloadData];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    // noop
}


#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

//Returns true if the ToAddress field was found any of the sub views and made first responder
//passing in @"MFComposeSubjectView"     as the value for field makes the subject become first responder
//passing in @"MFComposeTextContentView" as the value for field makes the body become first responder
//passing in @"RecipientTextField"       as the value for field makes the to address field become first responder
- (BOOL)setMFMailFieldAsFirstResponder:(UIView*)view mfMailField:(NSString*)field
{
    for (UIView *subview in view.subviews) {
        NSString *className = [NSString stringWithFormat:@"%@", [subview class]];
        if ([className isEqualToString:field]) {
            //Found the sub view we need to set as first responder
            [subview becomeFirstResponder];
            return YES;
        }
        
        if ([subview.subviews count] > 0) {
            if ([self setMFMailFieldAsFirstResponder:subview mfMailField:field]){
                //Field was found and made first responder in a subview
                return YES;
            }
        }
    }
    
    //field not found in this view.
    return NO;
}


#pragma mark - WPTableImageSource Delegate

- (void)tableImageSource:(WPTableImageSource *)tableImageSource imageReady:(UIImage *)image forIndexPath:(NSIndexPath *)indexPath
{
    [self.postView setFeaturedImage:image];
}

@end
