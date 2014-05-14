#import <AFNetworking/AFNetworking.h>
#import <DTCoreText/DTCoreText.h>
#import "DTCoreTextFontDescriptor.h"
#import "WPTableViewControllerSubclass.h"
#import "ReaderPostsViewController.h"
#import "ReaderPostTableViewCell.h"
#import "ReaderTopicsViewController.h"
#import "ReaderPostDetailViewController.h"
#import "ReaderPost.h"
#import "WordPressAppDelegate.h"
#import "NSString+XMLExtensions.h"
#import "ReaderReblogFormView.h"
#import "WPFriendFinderViewController.h"
#import "WPAccount.h"
#import "WPTableImageSource.h"
#import "WPNoResultsView.h"
#import "NSString+Helpers.h"
#import "IOS7CorrectedTextView.h"
#import "WPAnimatedBox.h"
#import "InlineComposeView.h"
#import "ReaderCommentPublisher.h"
#import "ContextManager.h"
#import "AccountService.h"
#import "ReaderTopicService.h"
#import "ReaderPostService.h"

static CGFloat const RPVCHeaderHeightPhone = 10.f;
static CGFloat const RPVCMaxImageHeightPercentage = 0.58f;
static CGFloat const RPVCExtraTableViewHeightPercentage = 2.0f;

NSString * const RPVCDisplayedNativeFriendFinder = @"DisplayedNativeFriendFinder";

@interface ReaderPostsViewController ()<ReaderTextFormDelegate, WPTableImageSourceDelegate, ReaderCommentPublisherDelegate> {
	BOOL _hasMoreContent;
	BOOL _loadingMore;
    BOOL _viewHasAppeared;
    WPTableImageSource *_featuredImageSource;
	CGFloat keyboardOffset;
    CGFloat _lastOffset;
    UIPopoverController *_popover;
    WPAnimatedBox *_animatedBox;
    UIGestureRecognizer *_tapOffKeyboardGesture;
}

@property (nonatomic, strong) ReaderReblogFormView *readerReblogFormView;
@property (nonatomic, strong) ReaderPostDetailViewController *detailController;
@property (nonatomic, strong) UINavigationBar *navBar;
@property (nonatomic) BOOL isShowingReblogForm;
@property (nonatomic, strong) InlineComposeView *inlineComposeView;
@property (nonatomic, strong) ReaderCommentPublisher *commentPublisher;
@property (nonatomic, strong) ReaderTopic *currentTopic;

@end

@implementation ReaderPostsViewController

+ (void)initialize {
	// DTCoreText will cache font descriptors on a background thread. However, because the font cache
	// updated synchronously, the detail view controller ends up waiting for the fonts to load anyway
	// (at least for the first time). We'll have DTCoreText prime its font cache here so things are ready
	// for the detail view, and avoid a perceived lag. 
	[DTCoreTextFontDescriptor fontDescriptorWithFontAttributes:nil];
}


#pragma mark - Life Cycle methods

- (void)dealloc {
    _featuredImageSource.delegate = nil;
	self.readerReblogFormView = nil;
    self.inlineComposeView.delegate = nil;
    self.inlineComposeView = nil;
    self.commentPublisher = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)init {
	self = [super init];
	if (self) {
		// This is a convenient place to check for the user's blogs and primary blog for reblogging.
		_hasMoreContent = YES;
		self.infiniteScrollEnabled = YES;
        self.incrementalLoadingSupported = YES;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(readerTopicDidChange:) name:ReaderTopicDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchBlogsAndPrimaryBlog) name:WPAccountDefaultWordPressComAccountChangedNotification object:nil];

        NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
        self.currentTopic = [[[ReaderTopicService alloc] initWithManagedObjectContext:context] currentTopic];
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];

    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;

    [self fetchBlogsAndPrimaryBlog];

    CGFloat maxWidth;
    if (IS_IPHONE) {
        maxWidth = MAX(self.tableView.bounds.size.width, self.tableView.bounds.size.height);
    } else {
        maxWidth = WPTableViewFixedWidth;
    }

    CGFloat maxHeight = maxWidth * RPVCMaxImageHeightPercentage;
    _featuredImageSource = [[WPTableImageSource alloc] initWithMaxSize:CGSizeMake(maxWidth, maxHeight)];
    _featuredImageSource.delegate = self;
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
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
    
	CGRect frame = CGRectMake(0.0f, self.view.bounds.size.height, self.view.bounds.size.width, [ReaderReblogFormView desiredHeight]);
	self.readerReblogFormView = [[ReaderReblogFormView alloc] initWithFrame:frame];
	_readerReblogFormView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
	_readerReblogFormView.navigationItem = self.navigationItem;
	_readerReblogFormView.delegate = self;
	
    _tapOffKeyboardGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                     action:@selector(dismissKeyboard:)];
    
	if (_isShowingReblogForm) {
		[self showReblogForm];
	}

    // Sync content as soon as login or creation occurs
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeAccount:) name:WPAccountDefaultWordPressComAccountChangedNotification object:nil];

    self.inlineComposeView = [[InlineComposeView alloc] initWithFrame:CGRectZero];
    [self.inlineComposeView setButtonTitle:NSLocalizedString(@"Post", nil)];

    self.commentPublisher = [[ReaderCommentPublisher alloc]
                             initWithComposer:self.inlineComposeView
                             andPost:nil];

    self.commentPublisher.delegate = self;

    self.tableView.tableFooterView = self.inlineComposeView;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

    [self updateTitle];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardDidShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    if (self.noResultsView && _animatedBox) {
        [_animatedBox prepareAnimation:NO];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    if (selectedIndexPath) {
        [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:YES];
    }

    if (!_viewHasAppeared) {
        if (self.currentTopic) {
            [WPAnalytics track:WPAnalyticsStatReaderAccessed withProperties:[self tagPropertyForStats]];
        }
        _viewHasAppeared = YES;
    }

    [self resizeTableViewForImagePreloading];

    // Delay box animation after the view appears
    double delayInSeconds = 0.3;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (self.noResultsView && _animatedBox) {
            [_animatedBox animate];
        }
    });
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.inlineComposeView endEditing:YES];
    [super viewWillDisappear:animated];

	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    // Remove the no results view or else the position will abruptly adjust after rotation
    // due to the table view sizing for image preloading
    [self.noResultsView removeFromSuperview];
    
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self resizeTableViewForImagePreloading];
    [self configureNoResultsView];
}

#pragma mark - Instance Methods

- (void)updateTitle {
    if (self.currentTopic) {
        self.title = [self.currentTopic.title capitalizedString];
    } else {
        self.title = NSLocalizedString(@"Reader", @"Default title for the reader before topics are loaded the first time.");
    }
}

- (void)resizeTableViewForImagePreloading {
    
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

- (void)setTitle:(NSString *)title {
    [super setTitle:title];
    
    // Reset the tab bar title; this isn't a great solution, but works
    NSInteger tabIndex = [self.tabBarController.viewControllers indexOfObject:self.navigationController];
    UITabBarItem *tabItem = [[[self.tabBarController tabBar] items] objectAtIndex:tabIndex];
    tabItem.title = NSLocalizedString(@"Reader", @"Description of the Reader tab");
}

- (void)dismissPopover {
    if (_popover) {
        [_popover dismissPopoverAnimated:YES];
        _popover = nil;
    }
}

- (void)handleKeyboardDidShow:(NSNotification *)notification {
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
	keyboardOffset = point.y - (frame.origin.y + frame.size.height);
	
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

- (void)handleKeyboardWillHide:(NSNotification *)notification {

    if (self.inlineComposeView.isDisplayed) {
        return;
    }

    UIView *view = self.view.superview;
	CGRect frame = view.frame;
	CGRect keyFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	
	CGPoint point = [view.window convertPoint:keyFrame.origin toView:view];
	frame.size.height = point.y - (frame.origin.y + keyboardOffset);
	view.frame = frame;
}

- (void)showReblogForm {
	if (_readerReblogFormView.superview != nil)
		return;
	
	NSIndexPath *path = [self.tableView indexPathForSelectedRow];
	_readerReblogFormView.post = (ReaderPost *)[self.resultsController objectAtIndexPath:path];
	
	CGFloat reblogHeight = [ReaderReblogFormView desiredHeight];
	CGRect tableFrame = self.tableView.frame;
    CGRect superviewFrame = self.view.superview.frame;
    
    // The table's frame is artifically tall due to resizeTableViewForImagePreloading, so effectively undo that
	tableFrame.size.height = superviewFrame.size.height - tableFrame.origin.y - reblogHeight - [self tabBarSize].height;
	self.tableView.frame = tableFrame;
	
	CGFloat y = tableFrame.origin.y + tableFrame.size.height;
	_readerReblogFormView.frame = CGRectMake(0.0f, y, self.view.bounds.size.width, reblogHeight);
	[self.view.superview addSubview:_readerReblogFormView];
	self.isShowingReblogForm = YES;
	[_readerReblogFormView.textView becomeFirstResponder];
}

- (void)hideReblogForm {
	if (_readerReblogFormView.superview == nil)
		return;
	
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:NO];
	
	CGRect tableFrame = self.tableView.frame;
	tableFrame.size.height = self.tableView.frame.size.height + _readerReblogFormView.frame.size.height;
	
	self.tableView.frame = tableFrame;
    [self resizeTableViewForImagePreloading];
	[_readerReblogFormView removeFromSuperview];
	self.isShowingReblogForm = NO;
	[self.view endEditing:YES];
}


#pragma mark - ReaderPostView delegate methods

- (void)postView:(ReaderPostView *)postView didReceiveReblogAction:(id)sender {
    NSIndexPath *selectedPath = [self.tableView indexPathForSelectedRow];
	UITableViewCell *cell = [ReaderPostTableViewCell cellForSubview:sender];
	NSIndexPath *path = [self.tableView indexPathForCell:cell];
	
	// if not showing form, show the form.
	if (!selectedPath) {
		[self.tableView selectRowAtIndexPath:path animated:NO scrollPosition:UITableViewScrollPositionNone];
		[self showReblogForm];
		return;
	}
	
	// if showing form && same cell as before, dismiss the form.
	if ([selectedPath compare:path] == NSOrderedSame) {
		[self hideReblogForm];
	} else {
		[self.tableView selectRowAtIndexPath:path animated:NO scrollPosition:UITableViewScrollPositionNone];
	}
}

- (void)postView:(ReaderPostView *)postView didReceiveLikeAction:(id)sender {
    ReaderPost *post = postView.post;

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

- (void)contentView:(ReaderPostView *)postView didReceiveFollowAction:(id)sender {
    UIButton *followButton = (UIButton *)sender;
    ReaderPostTableViewCell *cell = [ReaderPostTableViewCell cellForSubview:sender];
    ReaderPost *post = postView.post;
    
    if (![post isFollowable])
        return;
    
    if (!post.isFollowing) {
        [WPAnalytics track:WPAnalyticsStatReaderFollowedSite];
    }

    [followButton setSelected:!post.isFollowing]; // Set it optimistically
	[cell setNeedsLayout];

    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
    ReaderPostService *service = [[ReaderPostService alloc] initWithManagedObjectContext:context];
    [service toggleFollowingForPost:post success:^{
        //noop
    } failure:^(NSError *error) {
		DDLogError(@"Error Following Blog : %@", [error localizedDescription]);
		[followButton setSelected:post.isFollowing];
		[cell setNeedsLayout];
    }];
}

- (void)postView:(ReaderPostView *)postView didReceiveCommentAction:(id)sender {
    [self.view addGestureRecognizer:_tapOffKeyboardGesture];
    
    if (self.commentPublisher.post == postView.post) {
        [self.inlineComposeView toggleComposer];
        return;
    }

    self.commentPublisher.post = postView.post;
    [self.inlineComposeView displayComposer];

    // scroll the item into view if possible
    NSIndexPath *indexPath = [self.resultsController indexPathForObject:postView.post];

    [self.tableView scrollToRowAtIndexPath:indexPath
                          atScrollPosition:UITableViewScrollPositionTop
                                  animated:YES];

}


#pragma mark - Actions

- (void)topicsAction:(id)sender {
	ReaderTopicsViewController *controller = [[ReaderTopicsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    if (IS_IPAD) {
        if (_popover) {
            [self dismissPopover];
            return;
        }
        
        _popover = [[UIPopoverController alloc] initWithContentViewController:controller];
        
        UIBarButtonItem *shareButton = self.navigationItem.rightBarButtonItem;
        [_popover presentPopoverFromBarButtonItem:shareButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
        navController.navigationBar.translucent = NO;
        [self presentViewController:navController animated:YES completion:nil];
    }
}

- (void)dismissKeyboard:(id)sender {
    for (UIGestureRecognizer *gesture in self.view.gestureRecognizers) {
        if ([gesture isEqual:_tapOffKeyboardGesture]) {
            [self.view removeGestureRecognizer:gesture];
        }
    }
    
    [self.inlineComposeView toggleComposer];
}

#pragma mark - ReaderCommentPublisherDelegate Methods

- (void)commentPublisherDidPublishComment:(ReaderCommentPublisher *)publisher {
    [WPAnalytics track:WPAnalyticsStatReaderCommentedOnArticle];
    publisher.post.dateCommentsSynced = nil;
    [self.inlineComposeView dismissComposer];
}

- (void)openPost:(NSUInteger *)postId onBlog:(NSUInteger)blogId {

    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    ReaderPostService *service = [[ReaderPostService alloc] initWithManagedObjectContext:context];
    [service fetchPost:postId forSite:blogId success:^(ReaderPost *post) {
        ReaderPostDetailViewController *controller = [[ReaderPostDetailViewController alloc] initWithPost:post
                                                                                            featuredImage:nil
                                                                                              avatarImage:nil];

        [self.navigationController pushViewController:controller animated:YES];
    } failure:^(NSError *error) {
        // noop
    }];
}

#pragma mark - ReaderTextForm Delegate Methods

- (void)readerTextFormDidSend:(ReaderTextFormView *)readerTextForm {
	[self hideReblogForm];
}


- (void)readerTextFormDidCancel:(ReaderTextFormView *)readerTextForm {
	[self hideReblogForm];
}


#pragma mark - UIScrollView Delegate Methods

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [super scrollViewDidEndDecelerating:scrollView];

	NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
	if (!selectedIndexPath)
		return;

	__block BOOL found = NO;
	[[self.tableView indexPathsForVisibleRows] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		NSIndexPath *objPath = (NSIndexPath *)obj;
		if ([objPath compare:selectedIndexPath] == NSOrderedSame) {
			found = YES;
		}
		*stop = YES;
	}];
	
	if (found)
        return;
	
	[self hideReblogForm];
}


#pragma mark - WPTableViewSublass methods

- (NSString *)noResultsTitleText {
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


- (NSString *)noResultsMessageText {
	return NSLocalizedString(@"Tap the tag icon to browse posts from popular sites.", nil);
}

- (UIView *)noResultsAccessoryView {
    if (!_animatedBox) {
        _animatedBox = [WPAnimatedBox new];
    }
    return _animatedBox;
}

- (NSString *)entityName {
	return @"ReaderPost";
}

- (NSDate *)lastSyncDate {
    return self.currentTopic.lastSynced;
}

- (NSFetchRequest *)fetchRequest {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[self entityName]];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"(topic == %@)", self.currentTopic];
    NSSortDescriptor *sortDescriptorDate = [NSSortDescriptor sortDescriptorWithKey:@"sortDate" ascending:NO];
    fetchRequest.sortDescriptors = @[sortDescriptorDate];
	fetchRequest.fetchBatchSize = 20;
	return fetchRequest;
}

- (NSString *)sectionNameKeyPath {
	return nil;
}

- (Class)cellClass {
    return [ReaderPostTableViewCell class];
}

- (void)configureCell:(UITableViewCell *)aCell atIndexPath:(NSIndexPath *)indexPath {
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

}

- (UIImage *)imageForURL:(NSURL *)imageURL size:(CGSize)imageSize {
    if (!imageURL)
        return nil;
    
    if (CGSizeEqualToSize(imageSize, CGSizeZero)) {
        imageSize.width = self.tableView.bounds.size.width;
        imageSize.height = round(imageSize.width * RPVCMaxImageHeightPercentage);
    }
    return [_featuredImageSource imageForURL:imageURL withSize:imageSize];
}

- (void)setAvatarForPost:(ReaderPost *)post forCell:(ReaderPostTableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    CGSize imageSize = cell.postView.avatarImageView.bounds.size;
    UIImage *image = [post cachedAvatarWithSize:imageSize];
    if (image) {
        [cell.postView setAvatar:image];
    } else {
        [post fetchAvatarWithSize:imageSize success:^(UIImage *image) {
            if (cell == [self.tableView cellForRowAtIndexPath:indexPath]) {
                [cell.postView setAvatar:image];
            }
        }];
    }
}

- (void)setImageForPost:(ReaderPost *)post forCell:(ReaderPostTableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    NSURL *imageURL = post.featuredImageURL;
    
    if (!imageURL)
        return;
    
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
        [_featuredImageSource fetchImageForURL:imageURL withSize:imageSize indexPath:indexPath isPrivate:post.isPrivate];
    }
}

- (BOOL)hasMoreContent {
	return _hasMoreContent;
}

- (void)syncItemsViaUserInteraction:(BOOL)userInteraction success:(void (^)())success failure:(void (^)(NSError *))failure {
    DDLogMethod();

    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];

    if(!self.currentTopic) {
        ReaderTopicService *topicService = [[ReaderTopicService alloc] initWithManagedObjectContext:context];
        [topicService fetchReaderMenuWithSuccess:^{
            self.currentTopic = [[[ReaderTopicService alloc] initWithManagedObjectContext:context] currentTopic];
            // Changing the topic means we need to also change the fetch request.
            [self resetResultsController];
            [self updateTitle];
            [self syncReaderItemsWithSuccess:success failure:failure];
        } failure:^(NSError *error) {
            failure(error);
        }];
        return;
    }

    [self syncReaderItemsWithSuccess:success failure:failure];
}

- (void)syncReaderItemsWithSuccess:(void (^)())success failure:(void (^)(NSError *))failure {
    DDLogMethod();

    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
    ReaderPostService *service = [[ReaderPostService alloc] initWithManagedObjectContext:context];
    [service fetchPostsForTopic:self.currentTopic earlierThan:[NSDate date] keepExisting:_loadingMore success:^(NSUInteger count) {
        if (success) {
            success();
        }
    } failure:^(NSError *error) {
        if(failure) {
            failure(error);
        }
    }];
}

- (void)loadMoreWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    DDLogMethod();
	if ([self.resultsController.fetchedObjects count] == 0)
		return;
	
	if (_loadingMore)
        return;
    
	_loadingMore = YES;

	ReaderPost *post = self.resultsController.fetchedObjects.lastObject;
    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];

    ReaderPostService *service = [[ReaderPostService alloc] initWithManagedObjectContext:context];
    [service fetchPostsForTopic:self.currentTopic earlierThan:post.sortDate keepExisting:YES success:^(NSUInteger count){
        if (success) {
            success();
        }
        [self onSyncSuccess:count];
    } failure:^(NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
    
    [WPAnalytics track:WPAnalyticsStatReaderInfiniteScroll withProperties:[self tagPropertyForStats]];
}

- (UITableViewRowAnimation)tableViewRowAnimation {
	return UITableViewRowAnimationNone;
}

- (void)onSyncSuccess:(NSUInteger)count {
    DDLogMethod();
    _loadingMore = NO;
    if (count == 0) {
        _hasMoreContent = NO;
    }
}


#pragma mark -
#pragma mark TableView Methods

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
     return [ReaderPostTableViewCell cellHeightForPost:[self.resultsController objectAtIndexPath:indexPath] withWidth:self.tableView.bounds.size.width];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [ReaderPostTableViewCell cellHeightForPost:[self.resultsController objectAtIndexPath:indexPath] withWidth:self.tableView.bounds.size.width];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [[UIView alloc] initWithFrame:CGRectZero];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (IS_IPHONE)
        return RPVCHeaderHeightPhone;
    
    return [super tableView:tableView heightForHeaderInSection:section];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (_readerReblogFormView.superview != nil) {
		[self hideReblogForm];
		return nil;
	}
	
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	if ([cell isSelected]) {
		_readerReblogFormView.post = nil;
		[tableView deselectRowAtIndexPath:indexPath animated:NO];
		[self hideReblogForm];
		return nil;
	}
	
	return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (IS_IPAD) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }

    // Pass the image forward
	ReaderPost *post = [self.resultsController.fetchedObjects objectAtIndex:indexPath.row];
    ReaderPostTableViewCell *cell = (ReaderPostTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    CGSize imageSize = cell.postView.cellImageView.image.size;
    UIImage *image = [_featuredImageSource imageForURL:post.featuredImageURL withSize:imageSize];
    UIImage *avatarImage = cell.postView.avatarImageView.image;

	self.detailController = [[ReaderPostDetailViewController alloc] initWithPost:post featuredImage:image avatarImage:avatarImage];
    
    [self.navigationController pushViewController:self.detailController animated:YES];
    
    [WPAnalytics track:WPAnalyticsStatReaderOpenedArticle];
}


#pragma mark - NSFetchedResultsController overrides

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    // Do nothing (prevent superclass from adjusting table view)
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView reloadData];
    [self.noResultsView removeFromSuperview];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    // Do nothing (prevent superclass from adjusting table view)
}


#pragma mark - Notifications

- (void)readerTopicDidChange:(NSNotification *)notification {
	if (IS_IPAD){
        [self dismissPopover];
	}

    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    self.currentTopic = [[[ReaderTopicService alloc] initWithManagedObjectContext:context] currentTopic];
    [self updateTitle];

	_loadingMore = NO;
	_hasMoreContent = YES;
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

- (void)didChangeAccount:(NSNotification *)notification {
    self.currentTopic = nil;
    [self resetResultsController];
    [self.tableView reloadData];
    [self.navigationController popToViewController:self animated:NO];

    if ([self isViewLoaded]) {
        [self syncItems];
    }
}


#pragma mark - Utility

- (BOOL)isCurrentTagFreshlyPressed {
    return [self.currentTopic.title rangeOfString:@"freshly-pressed"].location != NSNotFound;
}

- (NSDictionary *)tagPropertyForStats {
    return @{@"tag": self.currentTopic.title};
}

- (void)fetchBlogsAndPrimaryBlog {
	NSURL *xmlrpc;
    NSString *username, *password, *authToken;
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

    if (!defaultAccount) {
        return;
    }
	
	xmlrpc = [NSURL URLWithString:@"https://wordpress.com/xmlrpc.php"];
	username = defaultAccount.username;
	password = defaultAccount.password;
    authToken = defaultAccount.authToken;
    
    WPXMLRPCClient *api = [WPXMLRPCClient clientWithXMLRPCEndpoint:xmlrpc];
    [api setAuthorizationHeaderWithToken:authToken];
    [api callMethod:@"wp.getUsersBlogs"
         parameters:[NSArray arrayWithObjects:username, password, nil]
            success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSArray *usersBlogs = responseObject;
				
                if ([usersBlogs count] > 0) {
                    [usersBlogs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                        NSString *title = [obj valueForKey:@"blogName"];
                        title = [title stringByDecodingXMLCharacters];
                        [obj setValue:title forKey:@"blogName"];
                    }];
                }
				
				[[NSUserDefaults standardUserDefaults] setObject:usersBlogs forKey:@"wpcom_users_blogs"];
				
                NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
                AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
                WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

                [[defaultAccount restApi] GET:@"me"
                                       parameters:nil
                                          success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                              if ([usersBlogs count] < 1)
                                                  return;
                                              
                                              NSDictionary *dict = (NSDictionary *)responseObject;
                                              __block NSNumber *preferredBlogId;
                                              NSNumber *primaryBlog = [dict objectForKey:@"primary_blog"];
                                              [usersBlogs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                                  if ([primaryBlog isEqualToNumber:[obj numberForKey:@"blogid"]]) {
                                                      preferredBlogId = [obj numberForKey:@"blogid"];
                                                      *stop = YES;
                                                  }
                                              }];
                                              
                                              if (!preferredBlogId) {
                                                  NSDictionary *dict = [usersBlogs objectAtIndex:0];
                                                  preferredBlogId = [dict numberForKey:@"blogid"];
                                              }
                                              
                                              [[NSUserDefaults standardUserDefaults] setObject:preferredBlogId forKey:@"wpcom_users_prefered_blog_id"];
                                              [NSUserDefaults resetStandardUserDefaults];
                                              
                                          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                              // TODO: Handle Failure. Retry maybe?
                                          }];
                
                if ([usersBlogs count] == 0) {
                    return;
                }

			} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
				// Fail silently.
                DDLogError(@"Failed retrieving user blogs in ReaderPostsViewController: %@", error);
            }];
}

- (CGSize)tabBarSize {
    CGSize tabBarSize = CGSizeZero;
    if ([self tabBarController]) {
        tabBarSize = [[[self tabBarController] tabBar] bounds].size;
    }

    return tabBarSize;
}

#pragma mark - WPTableImageSourceDelegate

- (void)tableImageSource:(WPTableImageSource *)tableImageSource imageReady:(UIImage *)image forIndexPath:(NSIndexPath *)indexPath {
    ReaderPostTableViewCell *cell = (ReaderPostTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    
    // Don't do anything if the cell is out of view or out of range
    // (this is a safety check in case the Reader doesn't properly kill image requests when changing topics)
    if (cell == nil)
        return;

    [cell.postView setFeaturedImage:image];
    
    // Update the detail view if it's open and applicable
    ReaderPost *post = [self.resultsController objectAtIndexPath:indexPath];
    
    if (post == self.detailController.post) {
        [self.detailController updateFeaturedImage:image];
    }
}

@end
