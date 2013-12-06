//
//  ReaderPostsViewController.m
//  WordPress
//
//  Created by Eric J on 3/21/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <DTCoreText/DTCoreText.h>
#import "DTCoreTextFontDescriptor.h"
#import "WPTableViewControllerSubclass.h"
#import "ReaderPostsViewController.h"
#import "ReaderPostTableViewCell.h"
#import "ReaderTopicsViewController.h"
#import "ReaderPostDetailViewController.h"
#import "ReaderPost.h"
#import "WordPressComApi.h"
#import "WordPressAppDelegate.h"
#import "NSString+XMLExtensions.h"
#import "ReaderReblogFormView.h"
#import "WPFriendFinderViewController.h"
#import "WPAccount.h"
#import "WPTableImageSource.h"
#import "WPNoResultsView.h"
#import "WPCookie.h"
#import "NSString+Helpers.h"
#import "IOS7CorrectedTextView.h"
#import "WPAnimatedBox.h"

static CGFloat const RPVCScrollingFastVelocityThreshold = 30.f;
static CGFloat const RPVCHeaderHeightPhone = 10.f;
static CGFloat const RPVCMaxImageHeightPercentage = 0.58f;
static CGFloat const RPVCExtraTableViewHeightPercentage = 2.0f;

NSString * const ReaderTopicDidChangeNotification = @"ReaderTopicDidChangeNotification";
NSString * const RPVCDisplayedNativeFriendFinder = @"DisplayedNativeFriendFinder";

@interface ReaderPostsViewController ()<ReaderTextFormDelegate, WPTableImageSourceDelegate> {
	BOOL _hasMoreContent;
	BOOL _loadingMore;
    WPTableImageSource *_featuredImageSource;
	CGFloat keyboardOffset;
    CGFloat _lastOffset;
    UIPopoverController *_popover;
    WPAnimatedBox *_animatedBox;
}

@property (nonatomic, strong) ReaderReblogFormView *readerReblogFormView;
@property (nonatomic, strong) ReaderPostDetailViewController *detailController;
@property (nonatomic, strong) UINavigationBar *navBar;
@property (nonatomic) BOOL isShowingReblogForm;

@end

@implementation ReaderPostsViewController

+ (void)initialize {
	// DTCoreText will cache font descriptors on a background thread. However, because the font cache
	// updated synchronously, the detail view controller ends up waiting for the fonts to load anyway
	// (at least for the first time). We'll have DTCoreText prime its font cache here so things are ready
	// for the detail view, and avoid a perceived lag. 
	[DTCoreTextFontDescriptor fontDescriptorWithFontAttributes:nil];
    
    [AFImageRequestOperation addAcceptableContentTypes:[NSSet setWithObject:@"image/jpg"]];
}


#pragma mark - Life Cycle methods

- (void)dealloc {
    _featuredImageSource.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	self.readerReblogFormView = nil;
}

- (id)init {
	self = [super init];
	if (self) {
		// This is a convenient place to check for the user's blogs and primary blog for reblogging.
		_hasMoreContent = YES;
		self.infiniteScrollEnabled = YES;
        self.incrementalLoadingSupported = YES;
        
        [[NSNotificationCenter defaultCenter] addObserverForName:ReaderTopicDidChangeNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
            [self readerTopicDidChange];
        }];
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
    
    [self fetchBlogsAndPrimaryBlog];

    CGFloat maxWidth = self.tableView.bounds.size.width;
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
    [button setAccessibilityLabel:NSLocalizedString(@"Topics", @"")];
    self.navigationItem.rightBarButtonItem = button;
    
	CGRect frame = CGRectMake(0.0f, self.view.bounds.size.height, self.view.bounds.size.width, [ReaderReblogFormView desiredHeight]);
	self.readerReblogFormView = [[ReaderReblogFormView alloc] initWithFrame:frame];
	_readerReblogFormView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
	_readerReblogFormView.navigationItem = self.navigationItem;
	_readerReblogFormView.delegate = self;
	
	if (_isShowingReblogForm) {
		[self showReblogForm];
	}

    [WPMobileStats trackEventForWPCom:StatsEventReaderOpened properties:[self categoryPropertyForStats]];
    [WPMobileStats pingWPComStatsEndpoint:@"home_page"];
    [WPMobileStats logQuantcastEvent:@"newdash.home_page"];
    [WPMobileStats logQuantcastEvent:@"mobile.home_page"];
    if ([self isCurrentCategoryFreshlyPressed]) {
        [WPMobileStats logQuantcastEvent:@"newdash.freshly"];
        [WPMobileStats logQuantcastEvent:@"mobile.freshly"];
    }
    
    // Sync content as soon as login or creation occurs
    [[NSNotificationCenter defaultCenter] addObserverForName:WordPressComApiDidLoginNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *notification){
                                                      [self syncItems];
                                                  }];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	   
	self.title = [[[ReaderPost currentTopic] objectForKey:@"title"] capitalizedString];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardDidShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    if (self.noResultsView && _animatedBox) {
        [_animatedBox prepareAnimation:NO];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    // WPTableViewController's viewDidAppear triggers a sync, but only do it if authenticated
    // (this prevents an attempted sync when the app launches for the first time before authenticating)
    if ([[WordPressAppDelegate sharedWordPressApplicationDelegate] isWPcomAuthenticated]) {
        [super viewDidAppear:animated];
    }

    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    if (selectedIndexPath) {
        [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:YES];
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
    [super viewWillDisappear:animated];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self resizeTableViewForImagePreloading];
}


#pragma mark - Instance Methods

- (void)resizeTableViewForImagePreloading {
    // Use a little trick to preload more images by making the table view longer
    CGRect rect = self.tableView.frame;
    CGFloat navigationHeight = self.navigationController.view.frame.size.height;
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
	[post toggleLikedWithSuccess:^{
        if ([post.isLiked boolValue]) {
            [WPMobileStats trackEventForWPCom:StatsEventReaderLikedPost];
        } else {
            [WPMobileStats trackEventForWPCom:StatsEventReaderUnlikedPost];
        }
	} failure:^(NSError *error) {
		DDLogError(@"Error Liking Post : %@", [error localizedDescription]);
		[postView updateActionButtons];
	}];
	
	[postView updateActionButtons];
}

- (void)postView:(ReaderPostView *)postView didReceiveFollowAction:(id)sender {
    UIButton *followButton = (UIButton *)sender;
    ReaderPostTableViewCell *cell = [ReaderPostTableViewCell cellForSubview:sender];
    ReaderPost *post = postView.post;
    
    if (![post isFollowable])
        return;

    followButton.selected = ![post.isFollowing boolValue]; // Set it optimistically
	[cell setNeedsLayout];
	[post toggleFollowingWithSuccess:^{
	} failure:^(NSError *error) {
		DDLogError(@"Error Following Blog : %@", [error localizedDescription]);
		[followButton setSelected:[post.isFollowing boolValue]];
		[cell setNeedsLayout];
	}];
}

- (void)postView:(ReaderPostView *)postView didReceiveCommentAction:(id)sender {
    // TODO: allow commenting
}

- (void)postView:(ReaderPostView *)postView didReceiveTagAction:(id)sender {
    ReaderPost *post = postView.post;

    NSString *endpoint = [NSString stringWithFormat:@"read/tags/%@/posts", post.primaryTagSlug];
    NSDictionary *dict = @{@"endpoint" : endpoint,
                           @"title" : post.primaryTagName};
    
	[[NSUserDefaults standardUserDefaults] setObject:dict forKey:ReaderCurrentTopicKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
    [self readerTopicDidChange];
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
	NSString *prompt;
	NSString *endpoint = [ReaderPost currentEndpoint];
	NSArray *endpoints = [ReaderPost readerEndpoints];
	NSInteger idx = [endpoints indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
		BOOL match = NO;
		
		if ([endpoint isEqualToString:[obj objectForKey:@"endpoint"]]) {
			match = YES;
			*stop = YES;
		}
				
		return match;
	}];
	
	switch (idx) {
		case 0:
			// Blogs I follow
			prompt = NSLocalizedString(@"You're not following any blogs yet.", @"");
			break;
			
		case 2:
			// Posts I like
			prompt = NSLocalizedString(@"You have not liked any posts.", @"");
			break;
			
		default:
			// Topics // freshly pressed.
			prompt = NSLocalizedString(@"Sorry. No posts yet.", @"");
			break;
			

	}
	return prompt;
}


- (NSString *)noResultsMessageText {
	return NSLocalizedString(@"Tap the tag icon to browse posts from popular blogs.", nil);
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

- (NSString *)resultsControllerCacheName {
	return [ReaderPost currentEndpoint];
}

- (NSDate *)lastSyncDate {
	return (NSDate *)[[NSUserDefaults standardUserDefaults] objectForKey:ReaderLastSyncDateKey];
}

- (NSFetchRequest *)fetchRequest {
	NSString *endpoint = [ReaderPost currentEndpoint];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[self entityName]];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"(endpoint == %@)", endpoint];
    NSSortDescriptor *sortDescriptorDate = [NSSortDescriptor sortDescriptorWithKey:@"sortDate" ascending:NO];
    fetchRequest.sortDescriptors = @[sortDescriptorDate];
	fetchRequest.fetchBatchSize = 10;
	return fetchRequest;
}

- (NSString *)sectionNameKeyPath {
	return nil;
}

- (UITableViewCell *)newCell {
    NSString *cellIdentifier = @"ReaderPostCell";
    ReaderPostTableViewCell *cell = (ReaderPostTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[ReaderPostTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
	return cell;
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
    
    cell.postView.delegate = self;

    CGSize imageSize = cell.postView.avatarImageView.bounds.size;
    UIImage *image = [post cachedAvatarWithSize:imageSize];
    if (image) {
        [cell.postView setAvatar:image];
    } else if (!self.tableView.isDragging && !self.tableView.isDecelerating) {
        [post fetchAvatarWithSize:imageSize success:^(UIImage *image) {
            if (cell == [self.tableView cellForRowAtIndexPath:indexPath]) {
                [cell.postView setAvatar:image];
            }
        }];
    }
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

- (void)syncItemsWithSuccess:(void (^)())success failure:(void (^)(NSError *))failure {
    WPFLogMethod();
    // if needs auth.
    if ([WPCookie hasCookieForURL:[NSURL URLWithString:@"https://wordpress.com"] andUsername:[[WPAccount defaultWordPressComAccount] username]]) {
       [self syncReaderItemsWithSuccess:success failure:failure];
        return;
    }

    [[WordPressAppDelegate sharedWordPressApplicationDelegate] useDefaultUserAgent];
    NSString *username = [[WPAccount defaultWordPressComAccount] username];
    NSString *password = [[WPAccount defaultWordPressComAccount] password];
    NSMutableURLRequest *mRequest = [[NSMutableURLRequest alloc] init];
    NSString *requestBody = [NSString stringWithFormat:@"log=%@&pwd=%@&redirect_to=http://wordpress.com",
                             [username stringByUrlEncoding],
                             [password stringByUrlEncoding]];
    
    [mRequest setURL:[NSURL URLWithString:@"https://wordpress.com/wp-login.php"]];
    [mRequest setHTTPBody:[requestBody dataUsingEncoding:NSUTF8StringEncoding]];
    [mRequest setValue:[NSString stringWithFormat:@"%d", [requestBody length]] forHTTPHeaderField:@"Content-Length"];
    [mRequest addValue:@"*/*" forHTTPHeaderField:@"Accept"];
    [mRequest setHTTPMethod:@"POST"];
    
    
    AFHTTPRequestOperation *authRequest = [[AFHTTPRequestOperation alloc] initWithRequest:mRequest];
    [authRequest setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [[WordPressAppDelegate sharedWordPressApplicationDelegate] useAppUserAgent];
        [self syncReaderItemsWithSuccess:success failure:failure];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [[WordPressAppDelegate sharedWordPressApplicationDelegate] useAppUserAgent];
        [self syncReaderItemsWithSuccess:success failure:failure];
    }];
    
    [authRequest start];    
}

- (void)syncReaderItemsWithSuccess:(void (^)())success failure:(void (^)(NSError *))failure {
    WPFLogMethod();
	NSString *endpoint = [ReaderPost currentEndpoint];
	NSNumber *numberToSync = [NSNumber numberWithInteger:ReaderPostsToSync];
	NSDictionary *params = @{@"number":numberToSync, @"per_page":numberToSync};
	[ReaderPost getPostsFromEndpoint:endpoint
					  withParameters:params
						 loadingMore:_loadingMore
							 success:^(AFHTTPRequestOperation *operation, id responseObject) {
								 if (success) {
									success();
								 }
								 [self onSyncSuccess:operation response:responseObject];
							 }
							 failure:^(AFHTTPRequestOperation *operation, NSError *error) {
								 if (failure) {
									 failure(error);
								 }
							 }];
    [WPMobileStats trackEventForWPCom:StatsEventReaderHomePageRefresh];
    [WPMobileStats pingWPComStatsEndpoint:@"home_page_refresh"];
}

- (void)loadMoreWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    WPFLogMethod();
	if ([self.resultsController.fetchedObjects count] == 0)
		return;
	
	if (_loadingMore)
        return;
    
	_loadingMore = YES;
	
	ReaderPost *post = self.resultsController.fetchedObjects.lastObject;
	NSNumber *numberToSync = [NSNumber numberWithInteger:ReaderPostsToSync];
	NSString *endpoint = [ReaderPost currentEndpoint];
	id before;
	if ([endpoint isEqualToString:@"freshly-pressed"]) {
		// freshly-pressed wants an ISO string but the rest want a timestamp.
		before = [DateUtils isoStringFromDate:post.date_created_gmt];
	} else {
		before = [NSNumber numberWithInteger:[post.date_created_gmt timeIntervalSince1970]];
	}

	NSDictionary *params = @{@"before":before, @"number":numberToSync, @"per_page":numberToSync};

	[ReaderPost getPostsFromEndpoint:endpoint
					  withParameters:params
						 loadingMore:_loadingMore
							 success:^(AFHTTPRequestOperation *operation, id responseObject) {
								 if (success) {
									 success();
								 }
								 [self onSyncSuccess:operation response:responseObject];
							 }
							 failure:^(AFHTTPRequestOperation *operation, NSError *error) {
								 if (failure) {
									 failure(error);
								 }
							 }];
    
    [WPMobileStats trackEventForWPCom:StatsEventReaderInfiniteScroll properties:[self categoryPropertyForStats]];
    [WPMobileStats logQuantcastEvent:@"newdash.infinite_scroll"];
    [WPMobileStats logQuantcastEvent:@"mobile.infinite_scroll"];
}

- (UITableViewRowAnimation)tableViewRowAnimation {
	return UITableViewRowAnimationNone;
}

- (void)onSyncSuccess:(AFHTTPRequestOperation *)operation response:(id)responseObject {
    WPFLogMethod();
	BOOL wasLoadingMore = _loadingMore;
	_loadingMore = NO;
	
	NSDictionary *resp = (NSDictionary *)responseObject;
	NSArray *postsArr = [resp arrayForKey:@"posts"];
	
	if (!postsArr) {
		if (wasLoadingMore) {
			_hasMoreContent = NO;
		}
		return;
	}
	
	// if # of results is less than # requested then no more content.
	if ([postsArr count] < ReaderPostsToSync && wasLoadingMore) {
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

	self.detailController = [[ReaderPostDetailViewController alloc] initWithPost:post featuredImage:image];
    
    [self.navigationController pushViewController:self.detailController animated:YES];
    
    [WPMobileStats trackEventForWPCom:StatsEventReaderOpenedArticleDetails];
    [WPMobileStats pingWPComStatsEndpoint:@"details_page"];
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


#pragma mark - ReaderTopicsDelegate Methods

- (void)readerTopicDidChange {
	if (IS_IPAD){
        [self dismissPopover];
	}
	
	_loadingMore = NO;
	_hasMoreContent = YES;
	[(WPNoResultsView *)self.noResultsView setTitleText:[self noResultsTitleText]];

	[self.tableView setContentOffset:CGPointMake(0, 0) animated:NO];
	[self resetResultsController];
	[self.tableView reloadData];
    [self syncItems];
	[self configureNoResultsView];
    
	self.title = [[ReaderPost currentTopic] stringForKey:@"title"];

    if ([WordPressAppDelegate sharedWordPressApplicationDelegate].connectionAvailable == YES && ![self isSyncing] ) {
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:ReaderLastSyncDateKey];
		[NSUserDefaults resetStandardUserDefaults];
    }

    if ([self isCurrentCategoryFreshlyPressed]) {
        [WPMobileStats trackEventForWPCom:StatsEventReaderSelectedFreshlyPressedTopic];
        [WPMobileStats pingWPComStatsEndpoint:@"freshly"];
        [WPMobileStats logQuantcastEvent:@"newdash.fresh"];
        [WPMobileStats logQuantcastEvent:@"mobile.fresh"];
    } else {
        [WPMobileStats trackEventForWPCom:StatsEventReaderSelectedCategory properties:[self categoryPropertyForStats]];
    }
}


#pragma mark - Utility

- (BOOL)isCurrentCategoryFreshlyPressed {
    return [[self currentCategory] isEqualToString:@"freshly-pressed"];
}

- (NSString *)currentCategory {
    NSDictionary *categoryDetails = [[NSUserDefaults standardUserDefaults] objectForKey:ReaderCurrentTopicKey];
    NSString *category = [categoryDetails stringForKey:@"endpoint"];
    if (category == nil)
        return @"reader/following";
    
    return category;
}

- (NSDictionary *)categoryPropertyForStats {
    return @{@"category": [self currentCategory]};
}

- (void)fetchBlogsAndPrimaryBlog {
	NSURL *xmlrpc;
    NSString *username, *password;
    WPAccount *account = [WPAccount defaultWordPressComAccount];
	xmlrpc = [NSURL URLWithString:@"https://wordpress.com/xmlrpc.php"];
	username = account.username;
	password = account.password;
	
    WPXMLRPCClient *api = [WPXMLRPCClient clientWithXMLRPCEndpoint:xmlrpc];
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
				
                [[WordPressComApi sharedApi] getPath:@"me"
                                          parameters:nil
                                             success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                 if ([usersBlogs count] < 1)
                                                     return;
                                                 
                                                 NSDictionary *dict = (NSDictionary *)responseObject;
                                                 NSString *userID = [dict stringForKey:@"ID"];
                                                 if (userID != nil) {
                                                     [WPMobileStats updateUserIDForStats:userID];
                                                     [[NSUserDefaults standardUserDefaults] setObject:userID forKey:@"wpcom_user_id"];
                                                     [NSUserDefaults resetStandardUserDefaults];
                                                 }
                                                 
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
    [cell.postView setFeaturedImage:image];
    
    ReaderPost *post = [self.resultsController objectAtIndexPath:indexPath];
    
    // Update the detail view if it's open and applicable
    if (post == self.detailController.post) {
        [self.detailController updateFeaturedImage:image];
    }
}

@end
