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
#import "PanelNavigationConstants.h"
#import "NSString+XMLExtensions.h"
#import "ReaderReblogFormView.h"
#import "WPFriendFinderViewController.h"
#import "WPFriendFinderNudgeView.h"
#import "WPAccount.h"
#import "WPTableImageSource.h"
#import "WPInfoView.h"

NSString *const WPReaderViewControllerDisplayedNativeFriendFinder = @"DisplayedNativeFriendFinder";

@interface ReaderPostsViewController ()<ReaderTopicsDelegate, ReaderTextFormDelegate, WPTableImageSourceDelegate> {
	BOOL _hasMoreContent;
	BOOL _loadingMore;
    WPTableImageSource *_featuredImageSource;
	CGFloat keyboardOffset;
    NSInteger _rowsSeen;
}

//@property (nonatomic, strong) NSFetchedResultsController *resultsController;
@property (nonatomic, strong) ReaderReblogFormView *readerReblogFormView;
@property (nonatomic, strong) WPFriendFinderNudgeView *friendFinderNudgeView;
@property (nonatomic, strong) UINavigationBar *navBar;
@property (nonatomic) BOOL isShowingReblogForm;

- (void)configureTableHeader;
- (void)fetchBlogsAndPrimaryBlog;
- (void)handleReblogButtonTapped:(id)sender;
- (void)showReblogForm;
- (void)hideReblogForm;
- (void)onSyncSuccess:(AFHTTPRequestOperation *)operation response:(id)responseObject;
- (void)handleKeyboardDidShow:(NSNotification *)notification;
- (void)handleKeyboardWillHide:(NSNotification *)notification;

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
}


- (id)init {
	self = [super init];
	if (self) {
		// This is a convenient place to check for the user's blogs and primary blog for reblogging.
		_hasMoreContent = YES;
		self.infiniteScrollEnabled = YES;
		[self fetchBlogsAndPrimaryBlog];
	}
	return self;
}


- (void)viewDidLoad {
	[super viewDidLoad];


    CGFloat maxWidth = self.tableView.bounds.size.width;
    if (IS_IPHONE) {
        maxWidth = MAX(self.tableView.bounds.size.width, self.tableView.bounds.size.height);
    }
    maxWidth -= 20.f; // Container frame
    CGFloat maxHeight = maxWidth * 0.66f;
    _featuredImageSource = [[WPTableImageSource alloc] initWithMaxSize:CGSizeMake(maxWidth, maxHeight)];
    _featuredImageSource.delegate = self;
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	
	[self configureTableHeader];
	
	// Topics button
	UIBarButtonItem *button = nil;
    if ([[UIButton class] respondsToSelector:@selector(appearance)]) {
		
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setImage:[UIImage imageNamed:@"navbar_read"] forState:UIControlStateNormal];
        
		UIImage *backgroundImage = [[UIImage imageNamed:@"navbar_button_bg"] stretchableImageWithLeftCapWidth:4 topCapHeight:0];
        [btn setBackgroundImage:backgroundImage forState:UIControlStateNormal];
		
        backgroundImage = [[UIImage imageNamed:@"navbar_button_bg_active"] stretchableImageWithLeftCapWidth:4 topCapHeight:0];
        [btn setBackgroundImage:backgroundImage forState:UIControlStateHighlighted];
        
        btn.frame = CGRectMake(0.0f, 0.0f, 44.0f, 30.0f);
		
        [btn addTarget:self action:@selector(handleTopicsButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        button = [[UIBarButtonItem alloc] initWithCustomView:btn];
		
    } else {
        button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks
                                                               target:self
                                                               action:@selector(handleTopicsButtonTapped:)];
    }
	
    [button setAccessibilityLabel:NSLocalizedString(@"Topics", @"")];
    
    if ([button respondsToSelector:@selector(setTintColor:)]) {
        UIColor *color = [UIColor UIColorFromHex:0x464646];
        button.tintColor = color;
    }
    
	[self.navigationItem setRightBarButtonItem:button animated:YES];
    if (IS_IPAD) {

		self.navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, 44.0f)];
		_navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[_navBar pushNavigationItem:self.navigationItem animated:NO];
		[self.view addSubview:_navBar];

		CGRect frame = self.tableView.frame;
		frame.origin.y = 44.0f;
		frame.size.height -= 44.0f;
		self.tableView.frame = frame;
    }
	
	CGRect frame = CGRectMake(0.0f, self.view.bounds.size.height, self.view.bounds.size.width, [ReaderReblogFormView desiredHeight]);
	self.readerReblogFormView = [[ReaderReblogFormView alloc] initWithFrame:frame];
	_readerReblogFormView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
	_readerReblogFormView.navigationItem = self.navigationItem;
	_readerReblogFormView.delegate = self;
	
	if (_isShowingReblogForm) {
		[self showReblogForm];
	}
	
}


- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
    [self performSelector:@selector(showFriendFinderNudgeView:) withObject:self afterDelay:3.0];
    
	self.panelNavigationController.delegate = self;
	
	NSDictionary *dict = [ReaderPost currentTopic];
	NSString *title = [[dict objectForKey:@"title"] capitalizedString];
	self.title = NSLocalizedString(title, @"");
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardDidShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    if (selectedIndexPath) {
        [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:YES];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
	
    self.panelNavigationController.delegate = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)viewDidUnload {
	[super viewDidUnload];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	self.readerReblogFormView = nil;
	self.friendFinderNudgeView = nil;
	self.navBar = nil;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];

	CGFloat width;
	// The new width should be the window
	if (IS_IPAD) {
		width = IPAD_DETAIL_WIDTH;
	} else {
		CGRect frame = self.view.window.frame;
		width = UIInterfaceOrientationIsLandscape(toInterfaceOrientation) ? frame.size.height : frame.size.width;
	}
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

#pragma mark - Instance Methods

- (void)configureTableHeader {
	if ([self.resultsController.fetchedObjects count] == 0) {
		self.tableView.tableHeaderView = nil;
		return;
	}
	
	if (self.tableView.tableHeaderView != nil) {
		return;
	}
	
	UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, 10.0f)];
	paddingView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	paddingView.backgroundColor = [UIColor colorWithWhite:0.9453125f alpha:1.f];
;
	self.tableView.tableHeaderView = paddingView;
}


- (void)handleTopicsButtonTapped:(id)sender {
	ReaderTopicsViewController *controller = [[ReaderTopicsViewController alloc] initWithStyle:UITableViewStyleGrouped];
	controller.delegate = self;
	
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
    if (IS_IPAD) {
        navController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
		navController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
	
    [self presentModalViewController:navController animated:YES];
}


- (void)handleReblogButtonTapped:(id)sender {
	// Locate the cell this originated from. 
	UIView *v = (UIView *)sender;
	while (![v isKindOfClass:[UITableViewCell class]]) {
		v = (UIView *)v.superview;
	}
	
	NSIndexPath *selectedPath = [self.tableView indexPathForSelectedRow];
	
	UITableViewCell *cell = (UITableViewCell *)v;
	NSIndexPath *path = [self.tableView indexPathForCell:cell];
	
	// if not showing form, show the form.
	if (!selectedPath) {
		[self.tableView selectRowAtIndexPath:path animated:NO scrollPosition:UITableViewScrollPositionNone];
		[self showReblogForm];
		return;
	}
	
	// if showing form && same cell as before, dismiss the form.
	if([selectedPath compare:path] == NSOrderedSame) {
		[self hideReblogForm];
	} else {
		[self.tableView selectRowAtIndexPath:path animated:NO scrollPosition:UITableViewScrollPositionNone];
	}
}


- (void)handleKeyboardDidShow:(NSNotification *)notification {
	CGRect frame = self.view.frame;
	CGRect startFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
	CGRect endFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	
	// Figure out the difference between the bottom of this view, and the top of the keyboard.
	// This should account for any toolbars.
	CGPoint point = [self.view.window convertPoint:startFrame.origin toView:self.view];
	keyboardOffset = point.y - (frame.origin.y + frame.size.height);
	
	// if we're upside down, we need to adjust the origin.
	if (endFrame.origin.x == 0 && endFrame.origin.y == 0) {
		endFrame.origin.y = endFrame.origin.x += MIN(endFrame.size.height, endFrame.size.width);
	}
	
	point = [self.view.window convertPoint:endFrame.origin toView:self.view];
	frame.size.height = point.y;
	
	[UIView animateWithDuration:0.3f delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
		self.view.frame = frame;
	} completion:^(BOOL finished) {
		// BUG: When dismissing a modal view, and the keyboard is showing again, the animation can get clobbered in some cases.
		// When this happens the view is set to the dimensions of its wrapper view, hiding content that should be visible
		// above the keyboard.
		// For now use a fallback animation.
		if (CGRectEqualToRect(self.view.frame, frame) == false) {
			[UIView animateWithDuration:0.3 animations:^{
				self.view.frame = frame;
			}];
		}
	}];
}


- (void)handleKeyboardWillHide:(NSNotification *)notification {
	CGRect frame = self.view.frame;
	CGRect keyFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	
	CGPoint point = [self.view.window convertPoint:keyFrame.origin toView:self.view];
	frame.size.height = point.y - (frame.origin.y + keyboardOffset);
	self.view.frame = frame;
}


- (void)showReblogForm {
	if (_readerReblogFormView.superview != nil) {
		return;
	}
	
	NSIndexPath *path = [self.tableView indexPathForSelectedRow];
	_readerReblogFormView.post = (ReaderPost *)[self.resultsController objectAtIndexPath:path];
	
	CGFloat reblogHeight = [ReaderReblogFormView desiredHeight];
	CGRect tableFrame = self.tableView.frame;
	tableFrame.size.height = self.tableView.frame.size.height - reblogHeight;
	self.tableView.frame = tableFrame;
	
	CGFloat y = tableFrame.origin.y + tableFrame.size.height;
	_readerReblogFormView.frame = CGRectMake(0.0f, y, self.view.bounds.size.width, reblogHeight);
	[self.view addSubview:_readerReblogFormView];
	self.isShowingReblogForm = YES;
	[_readerReblogFormView.textView becomeFirstResponder];
}


- (void)hideReblogForm {
	if(_readerReblogFormView.superview == nil) {
		return;
	}
	
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:NO];
	
	CGRect tableFrame = self.tableView.frame;
	tableFrame.size.height = self.tableView.frame.size.height + _readerReblogFormView.frame.size.height;
	
	self.tableView.frame = tableFrame;
	[_readerReblogFormView removeFromSuperview];
	self.isShowingReblogForm = NO;
	[self.view endEditing:YES];
}


- (void)loadImagesForVisibleRows {
    NSArray *visiblePaths = [self.tableView indexPathsForVisibleRows];
    for (NSIndexPath *indexPath in visiblePaths)
    {
        ReaderPost *post = (ReaderPost *)[self.resultsController objectAtIndexPath:indexPath];

        ReaderPostTableViewCell *cell = (ReaderPostTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];

        UIImage *image = [post cachedAvatarWithSize:cell.avatarImageView.bounds.size];
        CGSize imageSize = cell.avatarImageView.bounds.size;
        if (image) {
            [cell setAvatar:image];
        } else {
            __weak UITableView *tableView = self.tableView;
            [post fetchAvatarWithSize:imageSize success:^(UIImage *image) {
                if (cell == [tableView cellForRowAtIndexPath:indexPath]) {
                    [cell setAvatar:image];
                }
            }];
        }

        if (post.featuredImageURL) {
            NSURL *imageURL = post.featuredImageURL;
            imageSize = cell.cellImageView.bounds.size;
            image = [_featuredImageSource imageForURL:imageURL withSize:imageSize];
            if (image) {
                [cell setFeaturedImage:image];
            } else {
                [_featuredImageSource fetchImageForURL:imageURL withSize:imageSize indexPath:indexPath];
            }
        }
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

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    // Instead of loading images only when scrolling stops, start loading them when
    // the scroll view starts decelerating, if it's not going too fast
    if (fabs(velocity.y) <= 2.f) {
        [self loadImagesForVisibleRows];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self loadImagesForVisibleRows];

	NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
	if (!selectedIndexPath) {
		return;
	}

	__block BOOL found = NO;
	[[self.tableView indexPathsForVisibleRows] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		NSIndexPath *objPath = (NSIndexPath *)obj;
		if ([objPath compare:selectedIndexPath] == NSOrderedSame) {
			found = YES;
		}
		*stop = YES;
	}];
	
	if (found) return;
	
	[self hideReblogForm];
}


#pragma mark - DetailView Delegate Methods

- (void)resetView {
	
}


#pragma mark - WPTableViewSublass methods


- (NSString *)noResultsPrompt {
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
		case 1:
			// Blogs I follow
			prompt = NSLocalizedString(@"You are not following any blogs.", @"");
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


- (UIView *)createNoResultsView {	
	return [WPInfoView WPInfoViewWithTitle:[self noResultsPrompt] message:nil cancelButton:nil];
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
	
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:[self entityName] inManagedObjectContext:[self managedObjectContext]]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(endpoint == %@)", endpoint]];
	
    NSSortDescriptor *sortDescriptorDate = [[NSSortDescriptor alloc] initWithKey:@"sortDate" ascending:NO];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptorDate, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];
	
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
		cell.parentController = self;
		[cell setReblogTarget:self action:@selector(handleReblogButtonTapped:)];
    }
	return cell;
}


- (void)configureCell:(UITableViewCell *)aCell atIndexPath:(NSIndexPath *)indexPath {
	if(!aCell) return;

	ReaderPostTableViewCell *cell = (ReaderPostTableViewCell *)aCell;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	cell.accessoryType = UITableViewCellAccessoryNone;
	
	ReaderPost *post = (ReaderPost *)[self.resultsController objectAtIndexPath:indexPath];
	[cell configureCell:post];
    if (post.featuredImageURL) {
        NSURL *imageURL = post.featuredImageURL;
        CGSize imageSize = cell.cellImageView.bounds.size;
        if (CGSizeEqualToSize(imageSize, CGSizeZero)) {
            imageSize.width = self.tableView.bounds.size.width;
            imageSize.height = round(imageSize.width * 0.66f);
        }
        UIImage *image = [_featuredImageSource imageForURL:imageURL withSize:imageSize];
        if (image) {
            [cell setFeaturedImage:image];
        } else if (!self.tableView.isDragging && !self.tableView.isDecelerating) {
            [_featuredImageSource fetchImageForURL:imageURL withSize:imageSize indexPath:indexPath];
        }
    }
	
    CGSize imageSize = cell.avatarImageView.bounds.size;
    UIImage *image = [post cachedAvatarWithSize:imageSize];
    if (image) {
        [cell setAvatar:image];
    } else if (!self.tableView.isDragging && !self.tableView.isDecelerating) {
        [post fetchAvatarWithSize:imageSize success:^(UIImage *image) {
            if (cell == [self.tableView cellForRowAtIndexPath:indexPath]) {
                [cell setAvatar:image];
            }
        }];
    }
}


- (BOOL)hasMoreContent {
	return _hasMoreContent;
}


- (void)syncItemsWithUserInteraction:(BOOL)userInteraction success:(void (^)())success failure:(void (^)(NSError *))failure {
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
}


- (void)loadMoreWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
	if ([self.resultsController.fetchedObjects count] == 0) {
		return;
	}
	
	if (_loadingMore) return;
	_loadingMore = YES;
	
	
	ReaderPost *post = self.resultsController.fetchedObjects.lastObject;
	NSNumber *numberToSync = [NSNumber numberWithInteger:ReaderPostsToSync];
	NSString *endpoint = [ReaderPost currentEndpoint];
	id before;
	if([endpoint isEqualToString:@"freshly-pressed"]) {
		// freshly-pressed wants an ISO string but the rest want a timestamp.
		before = [DateUtils isoStringFromDate:post.dateCreated];
	} else {
		before = [NSNumber numberWithInteger:[post.dateCreated timeIntervalSince1970]];
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
}


- (UITableViewRowAnimation)tableViewRowAnimation {
	return UITableViewRowAnimationNone;
}


- (void)onSyncSuccess:(AFHTTPRequestOperation *)operation response:(id)responseObject {
	_loadingMore = NO;
	
	NSDictionary *resp = (NSDictionary *)responseObject;
	NSArray *postsArr = [resp arrayForKey:@"posts"];
	
	if (!postsArr) {
		_hasMoreContent = NO;
		return;
	}
	
	// if # of results is less than # requested then no more content.
	if ([postsArr count] < ReaderPostsToSync) {
		_hasMoreContent = NO;
	}
	
	[self configureTableHeader];
}


#pragma mark -
#pragma mark TableView Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [ReaderPostTableViewCell cellHeightForPost:[self.resultsController objectAtIndexPath:indexPath] withWidth:self.tableView.bounds.size.width];
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

	ReaderPost *post = [self.resultsController.fetchedObjects objectAtIndex:indexPath.row];
	
	ReaderPostDetailViewController *controller = [[ReaderPostDetailViewController alloc] initWithPost:post];
	[self.panelNavigationController pushViewController:controller fromViewController:self animated:YES];
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	[super tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
	
    if (indexPath.row <= _rowsSeen) {
        return;
    }
    CGPoint origin = cell.center;
    CGFloat horizontalOffset = (rand() % 300) - 150.f;
    CGFloat verticalOffset = 20;
    CGFloat zoom = 1.2f;
    NSTimeInterval duration = .2;

    CAKeyframeAnimation *opacityAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    opacityAnimation.values = @[ @0, @.2, @1];

    CAKeyframeAnimation *movementAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, origin.x + horizontalOffset, origin.y + verticalOffset);
    CGPathAddQuadCurveToPoint(path, NULL, origin.x - 0.15 * horizontalOffset, origin.y + 0.2 * verticalOffset, origin.x, origin.y);
    movementAnimation.path = path;

    CAKeyframeAnimation *zoomAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    zoomAnimation.values = @[
                             [NSValue valueWithCATransform3D:CATransform3DIdentity],
                             [NSValue valueWithCATransform3D:CATransform3DMakeScale(zoom, zoom, zoom)],
                             [NSValue valueWithCATransform3D:CATransform3DIdentity],
                             ];

    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.animations = @[opacityAnimation, movementAnimation, zoomAnimation];
    group.duration = duration;

    [cell.layer addAnimation:group forKey:@"FlyIn"];

    _rowsSeen = MAX(_rowsSeen, indexPath.row);
}

#pragma mark - ReaderTopicsDelegate Methods

- (void)readerTopicChanged {
	if (IS_IPAD){
		[self.panelNavigationController popToRootViewControllerAnimated:YES];
	}
	
	_loadingMore = NO;
	_hasMoreContent = YES;
    _rowsSeen = 0;
	[[(WPInfoView *)self.noResultsView titleLabel] setText:[self noResultsPrompt]];

	[self.tableView setContentOffset:CGPointMake(0, 0) animated:NO];
	[self resetResultsController];
	[self.tableView reloadData];
	
    [self configureTableHeader];
	
	NSString *title = [[[ReaderPost currentTopic] stringForKey:@"title"] capitalizedString];
	self.title = NSLocalizedString(title, @"");

    if ([WordPressAppDelegate sharedWordPressApplicationDelegate].connectionAvailable == YES && ![self isSyncing] ) {
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:ReaderLastSyncDateKey];
		[NSUserDefaults resetStandardUserDefaults];
		if (IS_IPAD) {
			[self simulatePullToRefresh];
		}
    }
}


#pragma mark - Utility

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
				
                if([usersBlogs count] > 0) {
					
                    [usersBlogs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                        NSString *title = [obj valueForKey:@"blogName"];
                        title = [title stringByDecodingXMLCharacters];
                        [obj setValue:title forKey:@"blogName"];
                    }];
                    
                }
				
				[[NSUserDefaults standardUserDefaults] setObject:usersBlogs forKey:@"wpcom_users_blogs"];
				
                __block NSNumber *preferredBlogId;
                if ([usersBlogs count] > 1) {
					[[WordPressComApi sharedApi] getPath:@"me"
											  parameters:nil
												 success:^(AFHTTPRequestOperation *operation, id responseObject) {
													 NSDictionary *dict = (NSDictionary *)responseObject;
													 NSNumber *primaryBlog = [dict objectForKey:@"primary_blog"];
													 [usersBlogs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
														 if ([primaryBlog isEqualToNumber:[obj numberForKey:@"blogid"]]) {
                                                             preferredBlogId = [obj numberForKey:@"blogid"];
															 *stop = YES;
														 }
													 }];
												 } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
													 // TODO: Handle Failure. Retry maybe?
												 }];
					
					
				}

                if (!preferredBlogId) {
                    NSDictionary *dict = [usersBlogs objectAtIndex:0];
                    preferredBlogId = [dict numberForKey:@"blogid"];
                }
                
                [[NSUserDefaults standardUserDefaults] setObject:preferredBlogId forKey:@"wpcom_users_prefered_blog_id"];
                [NSUserDefaults resetStandardUserDefaults];
			} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
				// Fail silently.
            }];
}


#pragma mark - Friend Finder Button

- (BOOL) shouldDisplayfriendFinderNudgeView {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return ![userDefaults boolForKey:WPReaderViewControllerDisplayedNativeFriendFinder] && self.friendFinderNudgeView == nil;
}


- (void) showFriendFinderNudgeView:(id)sender {
    if ([self shouldDisplayfriendFinderNudgeView]) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        
        [userDefaults setBool:YES forKey:WPReaderViewControllerDisplayedNativeFriendFinder];
        [userDefaults synchronize];
        
        CGRect buttonFrame = CGRectMake(0,self.view.frame.size.height,self.view.frame.size.width, 0.f);
        WPFriendFinderNudgeView *nudgeView = [[WPFriendFinderNudgeView alloc] initWithFrame:buttonFrame];
        self.friendFinderNudgeView = nudgeView;
        self.friendFinderNudgeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        [self.view addSubview:self.friendFinderNudgeView];
        
        buttonFrame = self.friendFinderNudgeView.frame;
        CGRect viewFrame = self.view.frame;
        buttonFrame.origin.y = viewFrame.size.height - buttonFrame.size.height + 1.f;
        
        [self.friendFinderNudgeView.cancelButton addTarget:self action:@selector(hideFriendFinderNudgeView:) forControlEvents:UIControlEventTouchUpInside];
        [self.friendFinderNudgeView.confirmButton addTarget:self action:@selector(openFriendFinder:) forControlEvents:UIControlEventTouchUpInside];
        
        [UIView animateWithDuration:0.2 animations:^{
            self.friendFinderNudgeView.frame = buttonFrame;
        }];
    }
}


- (void) hideFriendFinderNudgeView:(id)sender {
    if (self.friendFinderNudgeView == nil) {
        return;
    }
    
    CGRect buttonFrame = self.friendFinderNudgeView.frame;
    CGRect viewFrame = self.view.frame;
    buttonFrame.origin.y = viewFrame.size.height + 1.f;
    [UIView animateWithDuration:0.1 animations:^{
        self.friendFinderNudgeView.frame = buttonFrame;
    } completion:^(BOOL finished) {
        [self.friendFinderNudgeView removeFromSuperview];
        self.friendFinderNudgeView = nil;
    }];
}


- (void)openFriendFinder:(id)sender {
    [self hideFriendFinderNudgeView:sender];
    WPFriendFinderViewController *controller = [[WPFriendFinderViewController alloc] initWithNibName:@"WPReaderViewController" bundle:nil];
	
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
    if (IS_IPAD) {
        navController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
		navController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
	
    [self presentModalViewController:navController animated:YES];
    
    [controller loadURL:kMobileReaderFFURL];
}


#pragma mark - WPTableImageSourceDelegate

- (void)tableImageSource:(WPTableImageSource *)tableImageSource imageReady:(UIImage *)image forIndexPath:(NSIndexPath *)indexPath
{
    if (!self.tableView.isDecelerating && !self.tableView.isDragging) {
        ReaderPostTableViewCell *cell = (ReaderPostTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        [cell setFeaturedImage:image];
    }
}

@end
