/*
 * ReaderPostDetailViewController.m
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "ReaderPostDetailViewController.h"
#import "ReaderPostsViewController.h"
#import <DTCoreText/DTCoreText.h>
#import <QuartzCore/QuartzCore.h>
#import <MediaPlayer/MediaPlayer.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "WPActivityDefaults.h"
#import "WordPressAppDelegate.h"
#import "ReaderComment.h"
#import "ReaderCommentTableViewCell.h"
#import "ReaderReblogFormView.h"
#import "IOS7CorrectedTextView.h"
#import "ReaderImageView.h"
#import "ReaderVideoView.h"
#import "WPImageViewController.h"
#import "WPWebVideoViewController.h"
#import "WPWebViewController.h"
#import "ContextManager.h"
#import "WPTableViewController.h"
#import "InlineComposeView.h"
#import "ReaderCommentPublisher.h"

static NSInteger const ReaderCommentsToSync = 100;
static NSTimeInterval const ReaderPostDetailViewControllerRefreshTimeout = 300; // 5 minutes
static CGFloat const SectionHeaderHeight = 25.0f;

typedef enum {
    ReaderDetailContentSection = 0,
    ReaderDetailCommentsSection,
    ReaderDetailSectionCount
} ReaderDetailSection;


@interface ReaderPostDetailViewController ()<UIActionSheetDelegate, MFMailComposeViewControllerDelegate, ReaderTextFormDelegate, UIPopoverControllerDelegate, ReaderCommentPublisherDelegate> {
    UIPopoverController *_popover;
}

@property (nonatomic, strong) ReaderPostView *postView;
@property (nonatomic, strong) ReaderReblogFormView *readerReblogFormView;
@property (nonatomic, strong) UIImage *featuredImage;
@property (nonatomic, strong) UIImage *avatarImage;
@property (nonatomic) BOOL infiniteScrollEnabled;
@property (nonatomic, strong) UIActivityIndicatorView *activityFooter;
@property (nonatomic, strong) UIBarButtonItem *commentButton;
@property (nonatomic, strong) UIBarButtonItem *likeButton;
@property (nonatomic, strong) UIBarButtonItem *reblogButton;
@property (nonatomic, strong) UIBarButtonItem *shareButton;
@property (nonatomic, strong) NSMutableArray *comments;
@property (nonatomic, strong) NSFetchedResultsController *resultsController;
@property (nonatomic) BOOL isShowingReblogForm;
@property (nonatomic) BOOL hasMoreContent;
@property (nonatomic) BOOL loadingMore;
@property (nonatomic) CGPoint savedScrollOffset;
@property (nonatomic) CGFloat keyboardOffset;
@property (nonatomic) BOOL isSyncing;
@property (nonatomic, strong) InlineComposeView *inlineComposeView;
@property (nonatomic, strong) ReaderCommentPublisher *commentPublisher;

@end

@implementation ReaderPostDetailViewController

#pragma mark - LifeCycle Methods

- (void)dealloc {
	_resultsController.delegate = nil;
    self.tableView.delegate = nil;
    self.postView.delegate = nil;
    
    self.activityFooter = nil;
	self.postView = nil;
	self.readerReblogFormView = nil;
	self.commentButton = nil;
	self.likeButton = nil;
	self.reblogButton = nil;
	self.shareButton = nil;

    self.inlineComposeView = nil;
    self.commentPublisher.delegate = nil;
    self.commentPublisher = nil;
	
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithPost:(ReaderPost *)post featuredImage:(UIImage *)image avatarImage:(UIImage *)avatarImage {
	self = [super init];
	if (self) {
		_post = post;
		_comments = [NSMutableArray array];
        _featuredImage = image;
        _avatarImage = avatarImage;
        _showInlineActionBar = YES;
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];

    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;

	if (self.infiniteScrollEnabled) {
        [self enableInfiniteScrolling];
    }
	
	self.title = self.post.postTitle;
	
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView registerClass:[WPTableViewCell class] forCellReuseIdentifier:@"PostCell"];
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    self.tableView.backgroundColor = [UIColor whiteColor];

	[self buildHeader];
	[WPStyleGuide setRightBarButtonItemWithCorrectSpacing:self.shareButton forNavigationItem:self.navigationItem];
	[self buildForms];
    
    if (!self.showInlineActionBar) {
        [self buildActionBar];
    }
	
	[self prepareComments];

    self.inlineComposeView = [[InlineComposeView alloc] initWithFrame:CGRectZero];

    // comment composer responds to the inline compose view to publish comments
    self.commentPublisher = [[ReaderCommentPublisher alloc]
                             initWithComposer:self.inlineComposeView
                             andPost:self.post];

    self.commentPublisher.delegate = self;
    self.tableView.tableHeaderView = self.inlineComposeView;

}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	CGSize contentSize = self.tableView.contentSize;
    if (contentSize.height > _savedScrollOffset.y) {
        [self.tableView scrollRectToVisible:CGRectMake(_savedScrollOffset.x, _savedScrollOffset.y, 0.0f, 0.0f) animated:NO];
    } else {
        [self.tableView scrollRectToVisible:CGRectMake(0.0f, contentSize.height, 0.0f, 0.0f) animated:NO];
    }
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardDidShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

	UIToolbar *toolbar = self.navigationController.toolbar;
    toolbar.barTintColor = [WPStyleGuide littleEddieGrey];
    toolbar.tintColor = [UIColor whiteColor];
    toolbar.translucent = NO;

}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
    // Do not start auto-sync if connection is down
	WordPressAppDelegate *appDelegate = [WordPressAppDelegate sharedWordPressApplicationDelegate];
    if (appDelegate.connectionAvailable == NO)
        return;
	
    NSDate *lastSynced = [self lastSyncDate];
    if ((lastSynced == nil || ABS([lastSynced timeIntervalSinceNow]) > ReaderPostDetailViewControllerRefreshTimeout) && _post.isWPCom) {
		[self syncWithUserInteraction:NO];
    }
    
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
	
	if (IS_IPHONE) {
        _savedScrollOffset = self.tableView.contentOffset;
    }

    [self.inlineComposeView dismissComposer];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];

    [self.postView refreshMediaLayout]; // Resize media in the post detail to match the width of the new orientation.
    [self.postView setNeedsLayout];

	// Make sure a selected comment is visible after rotating.
	if ([self.tableView indexPathForSelectedRow] != nil && self.inlineComposeView.isDisplayed) {
		[self.tableView scrollToNearestSelectedRowAtScrollPosition:UITableViewScrollPositionNone animated:NO];
	}
}


#pragma mark - View getters/builders

- (void)updateFeaturedImage: (UIImage *)image {
    self.featuredImage = image;
    [self.postView setFeaturedImage:self.featuredImage];
}

- (void)buildHeader {
    // The text view in postView needs an initial frame
    CGFloat postHeight = [ReaderPostView heightForPost:self.post withWidth:self.view.frame.size.width];
    CGRect postFrame = CGRectMake(0.0f, 0.0f, self.tableView.frame.size.width, postHeight);
	self.postView = [[ReaderPostView alloc] initWithFrame:postFrame showFullContent:YES];
    self.postView.delegate = self;
    [self.postView configurePost:self.post];
    self.postView.backgroundColor = [UIColor whiteColor];
    
    if (self.avatarImage) {
        [self.postView setAvatar:self.avatarImage];
    }
    
    if (self.featuredImage) {
        [self.postView setFeaturedImage: self.featuredImage];
    }

	UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDismissForm:)];
	tgr.cancelsTouchesInView = NO;
	[self.postView addGestureRecognizer:tgr];
}

- (UIBarButtonItem *)shareButton {
    if (_shareButton)
        return _shareButton;
    
	// Top Navigation bar and Sharing
    UIImage *image = [UIImage imageNamed:@"icon-posts-share"];
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, image.size.width, image.size.height)];
    [button setImage:image forState:UIControlStateNormal];
    [button addTarget:self action:@selector(handleShareButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    _shareButton = [[UIBarButtonItem alloc] initWithCustomView:button];

        return _shareButton;
}

- (void)buildActionBar {
	UIButton *commentBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [commentBtn setImage:[UIImage imageNamed:@"reader-postaction-comment"] forState:UIControlStateNormal];
    [commentBtn setImage:[UIImage imageNamed:@"reader-postaction-comment-active"] forState:UIControlStateHighlighted];
	commentBtn.frame = CGRectMake(0.0f, 0.0f, 40.0f, 40.0f);
	[commentBtn addTarget:self action:@selector(handleCommentButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
	self.commentButton = [[UIBarButtonItem alloc] initWithCustomView:commentBtn];
	
	UIButton *likeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
	[likeBtn.titleLabel setFont:[UIFont fontWithName:@"OpenSans-Bold" size:10.0f]];
	[likeBtn setTitleEdgeInsets:UIEdgeInsetsMake(0.0f, -5.0f, 0.0f, 0.0f)];
	[likeBtn setTitleColor:[UIColor colorWithRed:84.0f/255.0f green:173.0f/255.0f blue:211.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
	[likeBtn setTitleColor:[UIColor colorWithRed:221.0f/255.0f green:118.0f/255.0f blue:43.0f/255.0f alpha:1.0f] forState:UIControlStateSelected];
    [likeBtn setImage:[UIImage imageNamed:@"reader-postaction-like"] forState:UIControlStateNormal];
    [likeBtn setImage:[UIImage imageNamed:@"reader-postaction-like-active"] forState:UIControlStateSelected];
	likeBtn.frame = CGRectMake(0.0f, 0.0f, 60.0f, 40.0f);
	likeBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
	[likeBtn addTarget:self action:@selector(handleLikeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
	self.likeButton = [[UIBarButtonItem alloc] initWithCustomView:likeBtn];
	
	UIButton *reblogBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [reblogBtn setImage:[UIImage imageNamed:@"reader-postaction-reblog"] forState:UIControlStateNormal];
    [reblogBtn setImage:[UIImage imageNamed:@"reader-postaction-reblog-active"] forState:UIControlStateHighlighted];
    [reblogBtn setImage:[UIImage imageNamed:@"reader-postaction-reblog-done"] forState:UIControlStateSelected];
	reblogBtn.frame = CGRectMake(0.0f, 0.0f, 40.0f, 40.0f);
	reblogBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
	[reblogBtn addTarget:self action:@selector(handleReblogButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
	self.reblogButton = [[UIBarButtonItem alloc] initWithCustomView:reblogBtn];
	
	[self updateActionBar];
}

- (void)updateToolbar {
	if (!self.post)
        return;
	
	UIButton *btn = (UIButton *)_likeButton.customView;
	[btn setSelected:[self.post.isLiked boolValue]];
	NSString *str = ([self.post.likeCount integerValue] > 0) ? [self.post.likeCount stringValue] : nil;
	[btn setTitle:str forState:UIControlStateNormal];
	_likeButton.customView = btn;
	
	btn = (UIButton *)_reblogButton.customView;
	[btn setSelected:[self.post.isReblogged boolValue]];
	btn.userInteractionEnabled = !btn.selected;
	_reblogButton.customView = btn;
	
	UIBarButtonItem *placeholder = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	NSMutableArray *items = [NSMutableArray arrayWithObject:placeholder];
	if ([self canComment]) {
		[items addObjectsFromArray:@[_commentButton, placeholder]];
	}
	
	if ([self.post isWPCom]) {
		[items addObjectsFromArray:@[_likeButton, placeholder, _reblogButton]];
	}
	
	[items addObject:placeholder];
	[self setToolbarItems:items animated:YES];
	self.navigationController.toolbarHidden = NO;
}

- (void)buildForms {

	CGRect frame = CGRectMake(0.0f, self.view.bounds.size.height, self.view.bounds.size.width, [ReaderReblogFormView desiredHeight]);
	self.readerReblogFormView = [[ReaderReblogFormView alloc] initWithFrame:frame];
	_readerReblogFormView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
	_readerReblogFormView.navigationItem = self.navigationItem;
	_readerReblogFormView.post = self.post;
	_readerReblogFormView.delegate = self;
	
	if (_isShowingReblogForm) {
		[self showReblogForm];
	}
}

- (UIActivityIndicatorView *)activityFooter {
    if (_activityFooter)
        return _activityFooter;

    CGRect rect = CGRectMake(145.0f, 10.0f, 30.0f, 30.0f);
    _activityFooter = [[UIActivityIndicatorView alloc] initWithFrame:rect];
    _activityFooter.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    _activityFooter.hidesWhenStopped = YES;
    _activityFooter.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [_activityFooter stopAnimating];
    
    return _activityFooter;
}


#pragma mark - Comments

- (BOOL)canComment {
	return [self.post.commentsOpen boolValue];
}

- (void)prepareComments {
	self.resultsController = nil;
	[_comments removeAllObjects];
	
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
			[_comments addObject:comment];
			if ([comment.childComments count] > 0) {
				flattenComments([comment.childComments allObjects]);
			}
		}
	};
	
	flattenComments(self.resultsController.fetchedObjects);
	
	// Cache attributed strings.
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, NULL), ^{
		for (ReaderComment *comment in _comments) {
			comment.attributedContent = [ReaderCommentTableViewCell convertHTMLToAttributedString:comment.content withOptions:nil];
		}
        __weak ReaderPostDetailViewController *weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.tableView reloadData];
        });
	});
}

- (void)updateActionBar {
	if (!self.post)
        return;
	
	UIButton *btn = (UIButton *)_likeButton.customView;
	[btn setSelected:[self.post.isLiked boolValue]];
	NSString *str = ([self.post.likeCount integerValue] > 0) ? [self.post.likeCount stringValue] : nil;
	[btn setTitle:str forState:UIControlStateNormal];
	_likeButton.customView = btn;
	
	btn = (UIButton *)_reblogButton.customView;
	[btn setSelected:[self.post.isReblogged boolValue]];
	btn.userInteractionEnabled = !btn.selected;
	_reblogButton.customView = btn;
	
	UIBarButtonItem *placeholder = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	NSMutableArray *items = [NSMutableArray arrayWithObject:placeholder];
	if ([self canComment]) {
		[items addObjectsFromArray:@[_commentButton, placeholder]];
	}
	
	if ([self.post isWPCom]) {
		[items addObjectsFromArray:@[_likeButton, placeholder, _reblogButton]];
	}
	
	[items addObject:placeholder];
	
    // Could put these in the title bar instead. We're preserving this code for now pending design decisions.
	//[self setToolbarItems:items animated:YES];
}

- (void)handleShareButtonTapped:(id)sender {
    NSString *permaLink = self.post.permaLink;
    NSString *title = self.post.postTitle;

    NSMutableArray *activityItems = [NSMutableArray array];
    if (title) {
        [activityItems addObject:title];
    }
    
    [activityItems addObject:[NSURL URLWithString:permaLink]];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:[WPActivityDefaults defaultActivities]];
    if (title) {
        [activityViewController setValue:title forKey:@"subject"];
    }
    activityViewController.completionHandler = ^(NSString *activityType, BOOL completed) {
        if (!completed)
            return;
        [WPActivityDefaults trackActivityType:activityType withPrefix:@"ReaderDetail"];
    };
    if (IS_IPAD) {
        if (_popover) {
            [self dismissPopover];
            return;
        }
        _popover = [[UIPopoverController alloc] initWithContentViewController:activityViewController];
        _popover.delegate = self;
        [_popover presentPopoverFromBarButtonItem:self.shareButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        [self presentViewController:activityViewController animated:YES completion:nil];
    }
}

- (void)handleDismissForm:(id)sender {
    [self hideReblogForm];
}

- (BOOL)isReplying {
	return ([self.tableView indexPathForSelectedRow] != nil) ? YES : NO;
}

- (void)showReblogForm {

	if (_readerReblogFormView.superview != nil)
		return;
	
	CGFloat reblogHeight = [ReaderReblogFormView desiredHeight];
	CGRect tableFrame = self.tableView.frame;
	tableFrame.size.height = self.tableView.frame.size.height - reblogHeight;
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
	[_readerReblogFormView removeFromSuperview];
	[self.view endEditing:YES];
	self.isShowingReblogForm = NO;
}

- (CGSize)tabBarSize {
    CGSize tabBarSize = CGSizeZero;
    if ([self tabBarController]) {
        tabBarSize = [[[self tabBarController] tabBar] bounds].size;
    }
    
    return tabBarSize;
}

- (void)dismissPopover {
    if (_popover) {
        [_popover dismissPopoverAnimated:YES];
        _popover = nil;
    }
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    _popover = nil;
}

- (void)handleKeyboardDidShow:(NSNotification *)notification {

    // only for handling reblog form now
    if (!_isShowingReblogForm) {
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

- (void)handleKeyboardWillHide:(NSNotification *)notification {

    //deselect the selected comment if there is one
    NSArray *selection = [self.tableView indexPathsForSelectedRows];
    if ([selection count] > 0) {
        [self.tableView deselectRowAtIndexPath:[selection objectAtIndex:0] animated:YES];
    }

    // only modify view when displaying the reblog form
    if (!_isShowingReblogForm) {
        return;
    }

    UIView *view = self.view.superview;
	CGRect frame = view.frame;
	CGRect keyFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	
	CGPoint point = [view.window convertPoint:keyFrame.origin toView:view];
	frame.size.height = point.y - (frame.origin.y + self.keyboardOffset);
	view.frame = frame;
}

- (void)moviePlaybackDidFinish:(NSNotification *)notification {
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
        [[[WordPressAppDelegate sharedWordPressApplicationDelegate].window rootViewController] dismissViewControllerAnimated:YES completion:nil];
    }
}


#pragma mark - ReaderPostView delegate methods

- (void)postView:(ReaderPostView *)postView didReceiveReblogAction:(id)sender {
	if (_isShowingReblogForm) {
		[self hideReblogForm];
		return;
	}
	
	[self showReblogForm];
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
    ReaderPost *post = postView.post;
    
    if (![post isFollowable])
        return;
    
    followButton.selected = ![post.isFollowing boolValue]; // Set it optimistically
	[post toggleFollowingWithSuccess:^{
	} failure:^(NSError *error) {
		DDLogError(@"Error Following Blog : %@", [error localizedDescription]);
		[followButton setSelected:[post.isFollowing boolValue]];
	}];
}

- (void)postView:(ReaderPostView *)postView didReceiveCommentAction:(id)sender {

    self.commentPublisher.comment = nil;
    [self.inlineComposeView toggleComposer];

}

- (void)contentView:(WPContentView *)contentView didReceiveLinkAction:(id)sender {
    WPWebViewController *controller = [[WPWebViewController alloc] init];
	[controller setUrl:((DTLinkButton *)sender).URL];
	[self.navigationController pushViewController:controller animated:YES];
}

- (void)contentView:(WPContentView *)contentView didReceiveImageLinkAction:(id)sender {
    ReaderImageView *imageView = (ReaderImageView *)sender;
	UIViewController *controller;
    
	if (imageView.linkURL) {
		NSString *url = [imageView.linkURL absoluteString];
		
		BOOL matched = NO;
		NSArray *types = @[@".png", @".jpg", @".gif", @".jpeg"];
		for (NSString *type in types) {
			if (NSNotFound != [url rangeOfString:type].location) {
				matched = YES;
				break;
			}
		}
		
		if (matched) {
            controller = [[WPImageViewController alloc] initWithImage:imageView.image andURL:imageView.linkURL];
		} else {
            controller = [[WPWebViewController alloc] init];
			[(WPWebViewController *)controller setUrl:((ReaderImageView *)sender).linkURL];
		}
	} else {
        controller = [[WPImageViewController alloc] initWithImage:imageView.image];
	}
    
    controller.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    controller.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)contentView:(WPContentView *)contentView didReceiveVideoLinkAction:(id)sender {
    ReaderVideoView *videoView = (ReaderVideoView *)sender;
	if (videoView.contentType == ReaderVideoContentTypeVideo) {

		MPMoviePlayerViewController *controller = [[MPMoviePlayerViewController alloc] initWithContentURL:videoView.contentURL];
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
        [self.navigationController presentViewController:controller animated:YES completion:nil];

	} else {
		// Should either be an iframe, or an object embed. In either case a src attribute should have been parsed for the contentURL.
		// Assume this is content we can show and try to load it.
        UIViewController *controller = [[WPWebVideoViewController alloc] initWithURL:videoView.contentURL];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
        navController.navigationBar.translucent = NO;
        navController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        navController.modalPresentationStyle = UIModalPresentationFullScreen;
		navController.title = (videoView.title != nil) ? videoView.title : @"Video";
        [self.navigationController presentViewController:navController animated:YES completion:nil];
	}
}

- (void)postView:(ReaderPostView *)postView didReceiveTagAction:(id)sender {
    ReaderPost *post = postView.post;
    
    NSString *endpoint = [NSString stringWithFormat:@"read/tags/%@/posts", post.primaryTagSlug];
    NSDictionary *dict = @{@"endpoint" : endpoint,
                           @"title" : post.primaryTagName};
    
	[[NSUserDefaults standardUserDefaults] setObject:dict forKey:ReaderCurrentTopicKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
    
    [self.navigationController popViewControllerAnimated:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:ReaderTopicDidChangeNotification object:self];
}

- (void)postView:(ReaderPostView *)postView didReceiveFeaturedImageAction:(id)sender {
    UITapGestureRecognizer *gesture = (UITapGestureRecognizer *)sender;
    UIImageView *imageView = (UIImageView *)gesture.view;
    WPImageViewController *controller = [[WPImageViewController alloc] initWithImage:imageView.image];

    controller.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    controller.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)contentViewDidLoadAllMedia:(WPContentView *)contentView {
    [self.postView layoutIfNeeded];
    [self.tableView reloadData];
}


#pragma mark - Sync methods

- (NSDate *)lastSyncDate {
	return self.post.dateCommentsSynced;
}

- (void)syncWithUserInteraction:(BOOL)userInteraction {
	if ([self.post.postID integerValue] == 0 ) { // Weird that this should ever happen. 
		self.post.dateCommentsSynced = [NSDate date];
		return;
	}
	_isSyncing = YES;
	NSDictionary *params = @{@"number":[NSNumber numberWithInteger:ReaderCommentsToSync]};

	[ReaderPost getCommentsForPost:[self.post.postID integerValue]
						  fromSite:[self.post.siteID stringValue]
					withParameters:params
						   success:^(AFHTTPRequestOperation *operation, id responseObject) {
							   [self onSyncSuccess:operation response:responseObject];
						   } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
						   }];
}

- (void)loadMoreWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
	if ([self.resultsController.fetchedObjects count] == 0)
		return;
	
	if (_loadingMore) return;
	_loadingMore = YES;
	_isSyncing = YES;
	NSUInteger numberToSync = [_comments count] + ReaderCommentsToSync;
	NSDictionary *params = @{@"number":[NSNumber numberWithInteger:numberToSync]};

	[ReaderPost getCommentsForPost:[self.post.postID integerValue]
						  fromSite:[self.post.siteID stringValue]
					withParameters:params
						   success:^(AFHTTPRequestOperation *operation, id responseObject) {
							   [self onSyncSuccess:operation response:responseObject];
						   } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
						   }];
}

- (void)onSyncSuccess:(AFHTTPRequestOperation *)operation response:(id)responseObject {
	self.post.dateCommentsSynced = [NSDate date];
	_loadingMore = NO;
	_isSyncing = NO;
	NSDictionary *resp = (NSDictionary *)responseObject;
	NSArray *commentsArr = [resp arrayForKey:@"comments"];
	
	if (!commentsArr) {
		_hasMoreContent = NO;
		return;
	}
	
	if ([commentsArr count] < ([_comments count] + ReaderCommentsToSync)) {
		_hasMoreContent = NO;
	}
	
	[ReaderComment syncAndThreadComments:commentsArr
								 forPost:self.post
							 withContext:[[ContextManager sharedInstance] mainContext]];
	
	[self prepareComments];
}


#pragma mark - Infinite Scrolling

- (void)setInfiniteScrollEnabled:(BOOL)infiniteScrollEnabled {
    if (infiniteScrollEnabled == _infiniteScrollEnabled)
        return;
	
    _infiniteScrollEnabled = infiniteScrollEnabled;
    if (self.isViewLoaded) {
        if (_infiniteScrollEnabled) {
            [self enableInfiniteScrolling];
        } else {
            [self disableInfiniteScrolling];
        }
    }
}

- (void)enableInfiniteScrolling {
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 50.0f)];
    footerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [footerView addSubview:self.activityFooter];
    self.tableView.tableFooterView = footerView;
}

- (void)disableInfiniteScrolling {
    self.tableView.tableFooterView = nil;
    _activityFooter = nil;
}


#pragma mark - UITableView Delegate Methods

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [[UIView alloc] initWithFrame:CGRectZero];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return IS_IPHONE ? 1 : WPTableViewTopMargin;
    }
    
    return SectionHeaderHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == ReaderDetailContentSection) {
        return self.postView.frame.size.height;
    }
    
	if ([_comments count] == 0) {
		return 0.0f;
	}
    
    CGFloat width = IS_IPAD ? WPTableViewFixedWidth : tableView.frame.size.width;
	
	ReaderComment *comment = [_comments objectAtIndex:indexPath.row];
	return [ReaderCommentTableViewCell heightForComment:comment
												  width:width
											 tableStyle:tableView.style
										  accessoryType:UITableViewCellAccessoryNone];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == ReaderDetailContentSection) {
        return 1;
    }

	return [_comments count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return ReaderDetailSectionCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == ReaderDetailContentSection) {
        UITableViewCell *postCell = [self.tableView dequeueReusableCellWithIdentifier:@"PostCell"];
        postCell.selectionStyle = UITableViewCellSelectionStyleNone;
        [postCell.contentView addSubview:self.postView];
        
        // Make the postView matches the width of its cell.
        // When the postView is first created it matches the width of the tableView
        // which may or may not be the same width as the cells when we get to this point.
        // On the iPhone, when viewing in landscape orientation, there can be a 20px difference.
        CGRect frame = self.postView.frame;
        frame.size.width = postCell.frame.size.width;
        self.postView.frame = frame;
        
        return postCell;
    }
    
	NSString *cellIdentifier = @"ReaderCommentCell";
    ReaderCommentTableViewCell *cell = (ReaderCommentTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[ReaderCommentTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
	cell.accessoryType = UITableViewCellAccessoryNone;
	
	ReaderComment *comment = [_comments objectAtIndex:indexPath.row];
	[cell configureCell:comment];

	return cell;	
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    ReaderComment *comment = [_comments objectAtIndex:indexPath.row];

    // if a row is already selected don't allow selection of another
    if (self.inlineComposeView.isDisplayed) {
        if (comment == self.commentPublisher.comment) {
            [self.inlineComposeView toggleComposer];
        }
        return nil;
    }

    self.commentPublisher.comment = comment;

	if (_readerReblogFormView.window != nil) {
		[self hideReblogForm];
		return nil;
	}

	if ([self canComment]) {
		[self.inlineComposeView displayComposer];
	}
	
	return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == ReaderDetailContentSection)
        return;
    
	if (![self canComment]) {
		[self.tableView deselectRowAtIndexPath:indexPath animated:NO];
		return;
	}

    [self.tableView scrollToNearestSelectedRowAtScrollPosition:UITableViewRowAnimationTop animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == ReaderDetailContentSection)
        return NO;

    // if we selected the already active comment allow highlight
    // so we can toggle the inline composer
    ReaderComment *comment = [_comments objectAtIndex:indexPath.row];
    if (comment == self.commentPublisher.comment) {
        return YES;
    }

    return !self.inlineComposeView.isDisplayed;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == ReaderDetailContentSection)
        return;
    
	if (IS_IPAD) {
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	
    // Are we approaching the end of the table?
    if ((indexPath.section + 1 == [self numberOfSectionsInTableView:tableView]) &&
		(indexPath.row + 4 >= [self tableView:tableView numberOfRowsInSection:indexPath.section]) &&
		[self tableView:tableView numberOfRowsInSection:indexPath.section] > 10) {
        
		// Only 3 rows till the end of table
        if (!_isSyncing && _hasMoreContent) {
            [_activityFooter startAnimating];
            [self loadMoreWithSuccess:^{
                [_activityFooter stopAnimating];
            } failure:^(NSError *error) {
                [_activityFooter stopAnimating];
            }];
        }
    }
}


#pragma mark - UIScrollView Delegate Methods

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    NSArray *selectedRows = [self.tableView indexPathsForSelectedRows];
    [self.tableView deselectRowAtIndexPath:[selectedRows objectAtIndex:0] animated:YES];

    if (self.inlineComposeView.isDisplayed) {
        [self.inlineComposeView dismissComposer];
    }

	if (_readerReblogFormView.window) {
		[self hideReblogForm];
		return;
	}
}

#pragma mark - ReaderCommentPublisherDelegate methods

- (void)commentPublisherDidPublishComment:(ReaderCommentPublisher *)composer {
    [self.inlineComposeView dismissComposer];
    [self syncWithUserInteraction:NO];
}

#pragma mark - ReaderTextForm Delegate Methods

- (void)readerTextFormDidCancel:(ReaderTextFormView *)readerTextForm {
    [self hideReblogForm];
}

- (void)readerTextFormDidSend:(ReaderTextFormView *)readerTextForm {
    [self hideReblogForm];
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)resultsController {
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

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView reloadData];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
}


#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

//Returns true if the ToAddress field was found any of the sub views and made first responder
//passing in @"MFComposeSubjectView"     as the value for field makes the subject become first responder
//passing in @"MFComposeTextContentView" as the value for field makes the body become first responder
//passing in @"RecipientTextField"       as the value for field makes the to address field become first responder
- (BOOL)setMFMailFieldAsFirstResponder:(UIView*)view mfMailField:(NSString*)field {
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

@end
