#import <AFNetworking/AFNetworking.h>
#import "WPTableViewControllerSubclass.h"
#import "ReaderPostsViewController.h"
#import "ReaderPostTableViewCell.h"
#import "ReaderTopicsViewController.h"
#import "ReaderPostDetailViewController.h"
#import "ReaderPost.h"
#import "WordPressAppDelegate.h"
#import "NSString+XMLExtensions.h"
#import "WPFriendFinderViewController.h"
#import "WPAccount.h"
#import "WPTableImageSource.h"
#import "WPNoResultsView.h"
#import "NSString+Helpers.h"
#import "WPAnimatedBox.h"
#import "InlineComposeView.h"
#import "ReaderCommentPublisher.h"
#import "ContextManager.h"
#import "AccountService.h"
#import "RebloggingViewController.h"
#import "ReaderTopicService.h"
#import "ReaderPostService.h"

static CGFloat const RPVCHeaderHeightPhone = 10.0;
static CGFloat const RPVCExtraTableViewHeightPercentage = 2.0;
static CGFloat const RPVCEstimatedRowHeight = 400.0;

NSString * const RPVCDisplayedNativeFriendFinder = @"DisplayedNativeFriendFinder";

@interface ReaderPostsViewController ()<WPTableImageSourceDelegate, ReaderCommentPublisherDelegate, RebloggingViewControllerDelegate>

@property (nonatomic, assign) BOOL hasMoreContent;
@property (nonatomic, assign) BOOL loadingMore;
@property (nonatomic, assign) BOOL viewHasAppeared;
@property (nonatomic, strong) WPTableImageSource *featuredImageSource;
@property (nonatomic, assign) CGFloat keyboardOffset;
@property (nonatomic, assign) CGFloat lastOffset;
@property (nonatomic, strong) UIPopoverController *popover;
@property (nonatomic, strong) WPAnimatedBox *animatedBox;
@property (nonatomic, strong) UIGestureRecognizer *tapOffKeyboardGesture;

@property (nonatomic, strong) ReaderPostDetailViewController *detailController;
@property (nonatomic, strong) InlineComposeView *inlineComposeView;
@property (nonatomic, strong) ReaderCommentPublisher *commentPublisher;
@property (nonatomic, readonly) ReaderTopic *currentTopic;

@property (nonatomic, strong) ReaderPostTableViewCell *cellForLayout;
@property (nonatomic, strong) NSLayoutConstraint *cellForLayoutWidthConstraint;

@end

@implementation ReaderPostsViewController

#pragma mark - Life Cycle methods

- (void)dealloc
{
    self.featuredImageSource.delegate = nil;
    self.inlineComposeView.delegate = nil;
    self.inlineComposeView = nil;
    self.commentPublisher = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)init
{
	self = [super init];
	if (self) {
		self.hasMoreContent = YES;
		self.infiniteScrollEnabled = YES;
        self.incrementalLoadingSupported = YES;

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeAccount:) name:WPAccountDefaultWordPressComAccountChangedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(readerTopicDidChange:) name:ReaderTopicDidChangeNotification object:nil];
	}
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];

    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    [self configureCellForLayout];

    CGFloat maxWidth;
    if (IS_IPHONE) {
        maxWidth = MAX(CGRectGetWidth(self.tableView.bounds), CGRectGetHeight(self.tableView.bounds));
    } else {
        maxWidth = WPTableViewFixedWidth;
    }

    CGFloat maxHeight = maxWidth * WPContentViewMaxImageHeightPercentage;
    self.featuredImageSource = [[WPTableImageSource alloc] initWithMaxSize:CGSizeMake(maxWidth, maxHeight)];
    self.featuredImageSource.delegate = self;

    
	// Topics button
	UIBarButtonItem *button = nil;
    UIButton *topicsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [topicsButton setImage:[UIImage imageNamed:@"icon-reader-topics"] forState:UIControlStateNormal];
    [topicsButton setImage:[UIImage imageNamed:@"icon-reader-topics-active"] forState:UIControlStateHighlighted];

    CGSize imageSize = [UIImage imageNamed:@"icon-reader-topics"].size;
    topicsButton.frame = CGRectMake(0.0, 0.0, imageSize.width, imageSize.height);
    topicsButton.contentEdgeInsets = UIEdgeInsetsMake(0, 16, 0, -16);
    
    [topicsButton addTarget:self action:@selector(topicsAction:) forControlEvents:UIControlEventTouchUpInside];
    button = [[UIBarButtonItem alloc] initWithCustomView:topicsButton];
    [button setAccessibilityLabel:NSLocalizedString(@"Browse", @"")];
    self.navigationItem.rightBarButtonItem = button;

    self.tapOffKeyboardGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                         action:@selector(dismissKeyboard:)];

    self.inlineComposeView = [[InlineComposeView alloc] initWithFrame:CGRectZero];
    [self.inlineComposeView setButtonTitle:NSLocalizedString(@"Post", nil)];

    self.commentPublisher = [[ReaderCommentPublisher alloc]
                             initWithComposer:self.inlineComposeView
                             andPost:nil];

    self.commentPublisher.delegate = self;

    self.tableView.tableFooterView = self.inlineComposeView;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

    [self updateTitle];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardDidShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    if (self.noResultsView && self.animatedBox) {
        [self.animatedBox prepareAnimation:NO];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    if (selectedIndexPath) {
        [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:YES];
    }

    if (!self.viewHasAppeared) {
        if (self.currentTopic) {
            [WPAnalytics track:WPAnalyticsStatReaderAccessed withProperties:[self tagPropertyForStats]];
        }
        self.viewHasAppeared = YES;
    }

    [self resizeTableViewForImagePreloading];

    // Delay box animation after the view appears
    double delayInSeconds = 0.3;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (self.noResultsView && self.animatedBox) {
            [self.animatedBox animate];
        }
    });
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.inlineComposeView endEditing:YES];
    [super viewWillDisappear:animated];

	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // Remove the no results view or else the position will abruptly adjust after rotation
    // due to the table view sizing for image preloading
    [self.noResultsView removeFromSuperview];
    
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self resizeTableViewForImagePreloading];
    [self configureNoResultsView];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    CGFloat width;
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
        width = CGRectGetWidth(self.tableView.window.frame);
    } else {
        width = CGRectGetHeight(self.tableView.window.frame);
    }
    [self updateCellForLayoutWidthConstraint:width];
}


#pragma mark - Instance Methods

- (void)configureCellForLayout
{
    NSString *CellIdentifier = @"CellForLayoutIdentifier";
    [self.tableView registerClass:[ReaderPostTableViewCell class] forCellReuseIdentifier:CellIdentifier];
    self.cellForLayout = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
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

- (ReaderTopic *)currentTopic
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    return [[[ReaderTopicService alloc] initWithManagedObjectContext:context] currentTopic];
}

- (void)updateTitle
{
    if (self.currentTopic) {
        self.title = [self.currentTopic.title capitalizedString];
    } else {
        self.title = NSLocalizedString(@"Reader", @"Default title for the reader before topics are loaded the first time.");
    }
}

- (void)resizeTableViewForImagePreloading
{
    // Use a little trick to preload more images by making the table view longer
    CGRect rect = self.tableView.frame;
    CGFloat navigationHeight = self.navigationController.view.frame.size.height - self.navigationController.navigationBar.frame.size.height - self.navigationController.navigationBar.frame.origin.y;
    CGFloat extraHeight = navigationHeight * RPVCExtraTableViewHeightPercentage;
    rect.size.height = navigationHeight + extraHeight;
    self.tableView.frame = rect;
    
    // Move insets up to compensate
    UIEdgeInsets insets = self.tableView.contentInset;
    insets.bottom = extraHeight + [self tabBarSize].height;
    self.tableView.contentInset = insets;
    
    // Adjust the scroll insets as well
    UIEdgeInsets scrollInsets = self.tableView.scrollIndicatorInsets;
    scrollInsets.bottom = insets.bottom;
    self.tableView.scrollIndicatorInsets = scrollInsets;
    [self.tableView layoutIfNeeded];
}

- (void)setTitle:(NSString *)title
{
    [super setTitle:title];
    
    // Reset the tab bar title; this isn't a great solution, but works
    NSInteger tabIndex = [self.tabBarController.viewControllers indexOfObject:self.navigationController];
    UITabBarItem *tabItem = [[[self.tabBarController tabBar] items] objectAtIndex:tabIndex];
    tabItem.title = NSLocalizedString(@"Reader", @"Description of the Reader tab");
}

- (void)dismissPopover
{
    if (self.popover) {
        [self.popover dismissPopoverAnimated:YES];
        self.popover = nil;
    }
}

- (void)handleKeyboardDidShow:(NSNotification *)notification
{
    if (self.inlineComposeView.isDisplayed) {
        return;
    }

    UIView *view = self.view.superview;
	CGRect frame = view.frame;
	CGRect startFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
	CGRect endFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	
	// Figure out the difference between the bottom of this view, and the top of the keyboard.
	// This should account for any toolbars.
	CGPoint point = [view.window convertPoint:startFrame.origin toView:view];
	self.keyboardOffset = point.y - (frame.origin.y + frame.size.height);
	
	// if we're upside down, we need to adjust the origin.
	if (endFrame.origin.x == 0 && endFrame.origin.y == 0) {
		endFrame.origin.y = endFrame.origin.x += MIN(endFrame.size.height, endFrame.size.width);
	}
	
	point = [view.window convertPoint:endFrame.origin toView:view];
    CGSize tabBarSize = [self tabBarSize];
	frame.size.height = point.y + tabBarSize.height;
	
	[UIView animateWithDuration:0.3f delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
		view.frame = frame;
	} completion:^(BOOL finished) {
		// BUG: When dismissing a modal view, and the keyboard is showing again, the animation can get clobbered in some cases.
		// When this happens the view is set to the dimensions of its wrapper view, hiding content that should be visible
		// above the keyboard.
		// For now use a fallback animation.
		if (!CGRectEqualToRect(view.frame, frame)) {
			[UIView animateWithDuration:0.3 animations:^{
				view.frame = frame;
			}];
		}
	}];
}

- (void)handleKeyboardWillHide:(NSNotification *)notification
{
    if (self.inlineComposeView.isDisplayed) {
        return;
    }

    UIView *view = self.view.superview;
	CGRect frame = view.frame;
	CGRect keyFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	
	CGPoint point = [view.window convertPoint:keyFrame.origin toView:view];
	frame.size.height = point.y - (frame.origin.y + self.keyboardOffset);
	view.frame = frame;
}


#pragma mark - ReaderPostContentView delegate methods

- (void)postView:(ReaderPostContentView *)postView didReceiveReblogAction:(id)sender
{
    // Pass the image forward
    ReaderPostTableViewCell *cell = [ReaderPostTableViewCell cellForSubview:sender];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    ReaderPost *post = (ReaderPost *)[self.resultsController objectAtIndexPath:indexPath];

    CGSize imageSize = postView.featuredImageView.image.size;
    UIImage *image = [self.featuredImageSource imageForURL:post.featuredImageURL withSize:imageSize];
    UIImage *avatarImage = [post cachedAvatarWithSize:CGSizeMake(WPContentAttributionViewAvatarSize, WPContentAttributionViewAvatarSize)];

    RebloggingViewController *controller = [[RebloggingViewController alloc] initWithPost:post featuredImage:image avatarImage:avatarImage];
    controller.delegate = self;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)postView:(ReaderPostContentView *)postView didReceiveLikeAction:(id)sender
{
    ReaderPostTableViewCell *cell = [ReaderPostTableViewCell cellForSubview:sender];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    ReaderPost *post = (ReaderPost *)[self.resultsController objectAtIndexPath:indexPath];

    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
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

- (void)contentView:(UIView *)contentView didReceiveAttributionLinkAction:(id)sender
{
    UIButton *followButton = (UIButton *)sender;
    ReaderPostTableViewCell *cell = [ReaderPostTableViewCell cellForSubview:sender];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    ReaderPost *post = (ReaderPost *)[self.resultsController objectAtIndexPath:indexPath];
    
    if (![post isFollowable])
        return;
    
    if (!post.isFollowing) {
        [WPAnalytics track:WPAnalyticsStatReaderFollowedSite];
    }

    [followButton setSelected:!post.isFollowing]; // Set it optimistically
//	[cell setNeedsLayout];

    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
    ReaderPostService *service = [[ReaderPostService alloc] initWithManagedObjectContext:context];
    [service toggleFollowingForPost:post success:^{
        //noop
    } failure:^(NSError *error) {
		DDLogError(@"Error Following Blog : %@", [error localizedDescription]);
		[followButton setSelected:post.isFollowing];
//		[cell setNeedsLayout];
    }];
}

- (void)postView:(ReaderPostContentView *)postView didReceiveCommentAction:(id)sender
{
    [self.view addGestureRecognizer:self.tapOffKeyboardGesture];

    ReaderPostTableViewCell *cell = [ReaderPostTableViewCell cellForSubview:sender];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    ReaderPost *post = (ReaderPost *)[self.resultsController objectAtIndexPath:indexPath];

    if (self.commentPublisher.post == post) {
        [self.inlineComposeView toggleComposer];
        return;
    }

    self.commentPublisher.post = post;
    [self.inlineComposeView displayComposer];

    // scroll the item into view if possible
    [self.tableView scrollToRowAtIndexPath:indexPath
                          atScrollPosition:UITableViewScrollPositionTop
                                  animated:YES];
}


#pragma mark - RebloggingViewController Delegate Methods

- (void)postWasReblogged:(ReaderPost *)post
{
    NSIndexPath *indexPath = [self.resultsController indexPathForObject:post];
    if (!indexPath) {
        return;
    }
    ReaderPostTableViewCell *cell = (ReaderPostTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [cell configureCell:post];
    [self setAvatarForPost:post forCell:cell indexPath:indexPath];
}


#pragma mark - Actions

- (void)topicsAction:(id)sender
{
	ReaderTopicsViewController *controller = [[ReaderTopicsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    if (IS_IPAD) {
        if (self.popover && [self.popover isPopoverVisible]) {
            [self dismissPopover];
            return;
        }
        
        self.popover = [[UIPopoverController alloc] initWithContentViewController:controller];
        
        UIBarButtonItem *shareButton = self.navigationItem.rightBarButtonItem;
        [self.popover presentPopoverFromBarButtonItem:shareButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
        navController.navigationBar.translucent = NO;
        [self presentViewController:navController animated:YES completion:nil];
    }
}

- (void)dismissKeyboard:(id)sender
{
    for (UIGestureRecognizer *gesture in self.view.gestureRecognizers) {
        if ([gesture isEqual:self.tapOffKeyboardGesture]) {
            [self.view removeGestureRecognizer:gesture];
        }
    }
    
    [self.inlineComposeView toggleComposer];
}

#pragma mark - ReaderCommentPublisherDelegate Methods

- (void)commentPublisherDidPublishComment:(ReaderCommentPublisher *)publisher
{
    [WPAnalytics track:WPAnalyticsStatReaderCommentedOnArticle];
    publisher.post.dateCommentsSynced = nil;
    [self.inlineComposeView dismissComposer];
}

- (void)openPost:(NSUInteger *)postId onBlog:(NSUInteger)blogId
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    ReaderPostService *service = [[ReaderPostService alloc] initWithManagedObjectContext:context];
    [service deletePostsWithNoTopic];
    [service fetchPost:postId forSite:blogId success:^(ReaderPost *post) {
        ReaderPostDetailViewController *controller = [[ReaderPostDetailViewController alloc] initWithPost:post
                                                                                            featuredImage:nil
                                                                                              avatarImage:nil];

        [self.navigationController pushViewController:controller animated:YES];
    } failure:^(NSError *error) {
        DDLogError(@"%@, error fetching post for site", _cmd, error);
    }];
}

#pragma mark - WPTableViewSublass methods

- (NSString *)noResultsTitleText
{
    NSRange range = [self.currentTopic.path rangeOfString:@"following"];
    if (range.location != NSNotFound) {
        return NSLocalizedString(@"You're not following any sites yet.", @"");
    }

    range = [self.currentTopic.path rangeOfString:@"liked"];
    if (range.location != NSNotFound) {
        return NSLocalizedString(@"You have not liked any posts.", @"");
    }

    return NSLocalizedString(@"Sorry. No posts yet.", @"");
}


- (NSString *)noResultsMessageText
{
	return NSLocalizedString(@"Tap the tag icon to browse posts from popular sites.", nil);
}

- (UIView *)noResultsAccessoryView
{
    if (!self.animatedBox) {
        self.animatedBox = [WPAnimatedBox new];
    }
    return self.animatedBox;
}

- (NSString *)entityName
{
	return @"ReaderPost";
}

- (NSDate *)lastSyncDate
{
    return self.currentTopic.lastSynced;
}

- (NSFetchRequest *)fetchRequest
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[self entityName]];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"(topic == %@)", self.currentTopic];
    NSSortDescriptor *sortDescriptorDate = [NSSortDescriptor sortDescriptorWithKey:@"sortDate" ascending:NO];
    fetchRequest.sortDescriptors = @[sortDescriptorDate];
	fetchRequest.fetchBatchSize = 20;
	return fetchRequest;
}

- (NSString *)sectionNameKeyPath
{
	return nil;
}

- (Class)cellClass
{
    return [ReaderPostTableViewCell class];
}

- (void)configureCell:(UITableViewCell *)aCell atIndexPath:(NSIndexPath *)indexPath
{
	if (!aCell)
        return;

	ReaderPostTableViewCell *cell = (ReaderPostTableViewCell *)aCell;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	cell.accessoryType = UITableViewCellAccessoryNone;
	
	ReaderPost *post = (ReaderPost *)[self.resultsController objectAtIndexPath:indexPath];

	[cell configureCell:post];
    [self setImageForPost:post forCell:cell indexPath:indexPath];
    [self setAvatarForPost:post forCell:cell indexPath:indexPath];
    
    cell.postView.delegate = self;
    cell.postView.shouldShowActions = post.isWPCom;

}

- (UIImage *)imageForURL:(NSURL *)imageURL size:(CGSize)imageSize
{
    if (!imageURL)
        return nil;
    
    if (CGSizeEqualToSize(imageSize, CGSizeZero)) {
        imageSize.width = self.tableView.bounds.size.width;
        imageSize.height = round(imageSize.width * WPContentViewMaxImageHeightPercentage);
    }
    return [self.featuredImageSource imageForURL:imageURL withSize:imageSize];
}

- (void)setAvatarForPost:(ReaderPost *)post forCell:(ReaderPostTableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    CGSize imageSize = CGSizeMake(WPContentViewAuthorAvatarSize, WPContentViewAuthorAvatarSize);
    UIImage *image = [post cachedAvatarWithSize:imageSize];
    if (image) {
        [cell.postView setAvatarImage:image];
    } else {
        [post fetchAvatarWithSize:imageSize success:^(UIImage *image) {
            if (cell == [self.tableView cellForRowAtIndexPath:indexPath]) {
                [cell.postView setAvatarImage:image];
            }
        }];
    }
}

- (void)setImageForPost:(ReaderPost *)post forCell:(ReaderPostTableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    NSURL *imageURL = post.featuredImageURL;
    
    if (!imageURL) {
        return;
    }

    // We know the width, but not the height; let the image loader figure that out
    CGFloat imageWidth = self.tableView.frame.size.width;
    if (IS_IPAD) {
        imageWidth = WPTableViewFixedWidth;
    }
    CGSize imageSize = CGSizeMake(imageWidth, 0);
    UIImage *image = [self imageForURL:imageURL size:imageSize];
    
    if (image) {
        [cell.postView setFeaturedImage:image];
    } else {
        [self.featuredImageSource fetchImageForURL:imageURL withSize:imageSize indexPath:indexPath isPrivate:post.isPrivate];
    }
}

//- (BOOL)hasMoreContent
//{
//	return _hasMoreContent;
//}

- (void)syncItemsViaUserInteraction:(BOOL)userInteraction success:(void (^)())success failure:(void (^)(NSError *))failure
{
    DDLogMethod();

    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];

    if(!self.currentTopic) {
        ReaderTopicService *topicService = [[ReaderTopicService alloc] initWithManagedObjectContext:context];
        [topicService fetchReaderMenuWithSuccess:^{
            // Changing the topic means we need to also change the fetch request.
            [self resetResultsController];
            [self updateTitle];
            [self syncReaderItemsWithSuccess:success failure:failure];
        } failure:^(NSError *error) {
            failure(error);
        }];
        return;
    }

    if (userInteraction) {
        [self syncReaderItemsWithSuccess:success failure:failure];
    } else {
        [self backfillReaderItemsWithSuccess:success failure:failure];
    }
}

- (void)backfillReaderItemsWithSuccess:(void (^)())success failure:(void (^)(NSError *))failure
{
    DDLogMethod();

    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
    ReaderPostService *service = [[ReaderPostService alloc] initWithManagedObjectContext:context];
    [service backfillPostsForTopic:self.currentTopic success:^(BOOL hasMore) {
        if (success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                success();
            });
        }
    } failure:^(NSError *error) {
        if (failure) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(error);
            });
        }
    }];
}

- (void)syncReaderItemsWithSuccess:(void (^)())success failure:(void (^)(NSError *))failure
{
    DDLogMethod();

    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
    ReaderPostService *service = [[ReaderPostService alloc] initWithManagedObjectContext:context];
    [service fetchPostsForTopic:self.currentTopic earlierThan:[NSDate date] success:^(BOOL hasMore) {
        if (success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                success();
            });
        }
    } failure:^(NSError *error) {
        if(failure) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(error);
            });
        }
    }];
}

- (void)loadMoreWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure
{
    DDLogMethod();
	if ([self.resultsController.fetchedObjects count] == 0)
		return;
	
	if (self.loadingMore)
        return;
    
	self.loadingMore = YES;

	ReaderPost *post = self.resultsController.fetchedObjects.lastObject;
    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];

    ReaderPostService *service = [[ReaderPostService alloc] initWithManagedObjectContext:context];
    [service fetchPostsForTopic:self.currentTopic earlierThan:post.sortDate success:^(BOOL hasMore){
        if (success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                success();
            });
        }
        [self onSyncSuccess:hasMore];
    } failure:^(NSError *error) {
        if (failure) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(error);
            });
        }
    }];
    
    [WPAnalytics track:WPAnalyticsStatReaderInfiniteScroll withProperties:[self tagPropertyForStats]];
}

- (UITableViewRowAnimation)tableViewRowAnimation
{
	return UITableViewRowAnimationNone;
}

- (void)onSyncSuccess:(BOOL)hasMore
{
    DDLogMethod();
    self.loadingMore = NO;
    self.hasMoreContent = hasMore;
}


#pragma mark - TableView Methods

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return RPVCEstimatedRowHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self configureCell:self.cellForLayout atIndexPath:indexPath];
    [self.cellForLayout layoutSubviews];
    CGSize size = [self.cellForLayout.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    return ceil(size.height + 1);
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return [[UIView alloc] initWithFrame:CGRectZero];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (IS_IPHONE) {
        return RPVCHeaderHeightPhone;
    }
    return [super tableView:tableView heightForHeaderInSection:section];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (IS_IPAD) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }

    // Pass the image forward
	ReaderPost *post = [self.resultsController.fetchedObjects objectAtIndex:indexPath.row];
    ReaderPostTableViewCell *cell = (ReaderPostTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];

    CGSize imageSize = cell.postView.featuredImageView.image.size;
    UIImage *image = [_featuredImageSource imageForURL:post.featuredImageURL withSize:imageSize];
    UIImage *avatarImage = [cell.post cachedAvatarWithSize:CGSizeMake(32.0, 32.0)];
// TODO: the detail controller should just fetch the cached versions of these resources vs passing them around here. :P
	self.detailController = [[ReaderPostDetailViewController alloc] initWithPost:post featuredImage:image avatarImage:avatarImage];
    
    [self.navigationController pushViewController:self.detailController animated:YES];
    
    [WPAnalytics track:WPAnalyticsStatReaderOpenedArticle];
}


#pragma mark - NSFetchedResultsController overrides

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    // Do nothing (prevent superclass from adjusting table view)
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView reloadData];
    [self.noResultsView removeFromSuperview];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    // Do nothing (prevent superclass from adjusting table view)
}


#pragma mark - Notifications

- (void)readerTopicDidChange:(NSNotification *)notification
{
	if (IS_IPAD){
        [self dismissPopover];
	}

    [self updateTitle];

	self.loadingMore = NO;
	self.hasMoreContent = YES;
	[(WPNoResultsView *)self.noResultsView setTitleText:[self noResultsTitleText]];

	[self.tableView setContentOffset:CGPointMake(0, 0) animated:NO];
	[self resetResultsController];
	[self.tableView reloadData];
    [self syncItems];
	[self configureNoResultsView];

    [WPAnalytics track:WPAnalyticsStatReaderLoadedTag withProperties:[self tagPropertyForStats]];
    if ([self isCurrentTagFreshlyPressed]) {
        [WPAnalytics track:WPAnalyticsStatReaderLoadedFreshlyPressed];
    }
}

- (void)didChangeAccount:(NSNotification *)notification
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    [[[ReaderTopicService alloc] initWithManagedObjectContext:context] deleteAllTopics];
    [[[ReaderPostService alloc] initWithManagedObjectContext:context] deletePostsWithNoTopic];

    [self resetResultsController];
    [self.tableView reloadData];
    [self.navigationController popToViewController:self animated:NO];

    if ([self isViewLoaded]) {
        [self syncItems];
    }
}


#pragma mark - Utility

- (BOOL)isCurrentTagFreshlyPressed
{
    return [self.currentTopic.title rangeOfString:@"freshly-pressed"].location != NSNotFound;
}

- (NSDictionary *)tagPropertyForStats
{
    return @{@"tag": self.currentTopic.title};
}

- (CGSize)tabBarSize
{
    CGSize tabBarSize = CGSizeZero;
    if ([self tabBarController]) {
        tabBarSize = [[[self tabBarController] tabBar] bounds].size;
    }

    return tabBarSize;
}

#pragma mark - WPTableImageSourceDelegate

- (void)tableImageSource:(WPTableImageSource *)tableImageSource imageReady:(UIImage *)image forIndexPath:(NSIndexPath *)indexPath
{
    ReaderPostTableViewCell *cell = (ReaderPostTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    
    // Don't do anything if the cell is out of view or out of range
    // (this is a safety check in case the Reader doesn't properly kill image requests when changing topics)
    if (cell == nil) {
        return;
    }

    [cell.postView setFeaturedImage:image];
    
    // Failsafe: If the topic has changed, fetchedObject count might be zero
    if (self.resultsController.fetchedObjects.count == 0) {
        return;
    }
    
    // Update the detail view if it's open and applicable
    ReaderPost *post = [self.resultsController objectAtIndexPath:indexPath];
    
    if (post == self.detailController.post) {
        [self.detailController updateFeaturedImage:image];
    }
}

@end
