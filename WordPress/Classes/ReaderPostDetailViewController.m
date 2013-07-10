//
//  ReaderPostDetailViewController.m
//  WordPress
//
//  Created by Eric J on 3/21/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "ReaderPostDetailViewController.h"
#import <DTCoreText/DTCoreText.h>
#import <QuartzCore/QuartzCore.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "UIImageView+Gravatar.h"
#import "WPActivities.h"
#import "WPWebViewController.h"
#import "PanelNavigationConstants.h"
#import "WordPressAppDelegate.h"
#import "WordPressComApi.h"
#import "ReaderComment.h"
#import "ReaderCommentTableViewCell.h"
#import "ReaderPostDetailView.h"
#import "ReaderCommentFormView.h"
#import "ReaderReblogFormView.h"

NSInteger const ReaderCommentsToSync = 100;
NSTimeInterval const ReaderPostDetailViewControllerRefreshTimeout = 300; // 5 minutes

@interface ReaderPostDetailViewController ()<ReaderPostDetailViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate, ReaderTextFormDelegate> {
	BOOL _hasMoreContent;
	BOOL _loadingMore;
    CGFloat _previousOffset;
	CGPoint savedScrollOffset;
	CGFloat keyboardOffset;
	BOOL _infiniteScrollEnabled;
	BOOL _isSyncing;
}

@property (nonatomic, strong) ReaderPost *post;
@property (nonatomic, strong) ReaderPostDetailView *headerView;
@property (nonatomic, strong) ReaderCommentFormView *readerCommentFormView;
@property (nonatomic, strong) ReaderReblogFormView *readerReblogFormView;
@property (nonatomic) BOOL infiniteScrollEnabled;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIActivityIndicatorView *activityFooter;
@property (nonatomic, strong) UINavigationBar *navBar;
@property (nonatomic, strong) UIBarButtonItem *commentButton;
@property (nonatomic, strong) UIBarButtonItem *likeButton;
@property (nonatomic, strong) UIBarButtonItem *reblogButton;
@property (nonatomic, strong) UIBarButtonItem *shareButton;
@property (nonatomic, strong) UIActionSheet *linkOptionsActionSheet;
@property (nonatomic, strong) NSMutableArray *comments;
@property (nonatomic, strong) NSFetchedResultsController *resultsController;
@property (nonatomic) BOOL isScrollingCommentIntoView;
@property (nonatomic) BOOL isShowingCommentForm;
@property (nonatomic) BOOL isShowingReblogForm;
@property (nonatomic) BOOL canUseFullScreen;

- (void)buildHeader;
- (void)buildTopToolbar;
- (void)buildBottomToolbar;
- (void)buildForms;
- (void)prepareComments;
- (void)showStoredComment;
- (void)updateToolbar;
- (BOOL)isReplying;
- (BOOL)canComment;
- (void)showCommentForm;
- (void)hideCommentForm;
- (void)showReblogForm;
- (void)hideReblogForm;
- (void)enableInfiniteScrolling;
- (void)disableInfiniteScrolling;

- (void)handleCommentButtonTapped:(id)sender;
- (void)handleLikeButtonTapped:(id)sender;
- (void)handleReblogButtonTapped:(id)sender;
- (void)handleShareButtonTapped:(id)sender;
- (void)handleDismissForm:(id)sender;
- (BOOL)setMFMailFieldAsFirstResponder:(UIView*)view mfMailField:(NSString*)field;

- (void)syncWithUserInteraction:(BOOL)userInteraction;
- (void)loadMoreWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)handleKeyboardDidShow:(NSNotification *)notification;
- (void)handleKeyboardWillHide:(NSNotification *)notification;

@end

@implementation ReaderPostDetailViewController

@synthesize post;

#pragma mark - LifeCycle Methods

- (void)dealloc {
	_resultsController.delegate = nil;
    _tableView.delegate = nil;
}


- (id)initWithPost:(ReaderPost *)apost {
	self = [super init];
	if(self) {
		self.post = apost;
		self.comments = [NSMutableArray array];
        self.wantsFullScreenLayout = YES;
		self.canUseFullScreen = YES;
	}
	return self;
}


- (id)initWithDictionary:(NSDictionary *)dict {
	self = [super init];
	if(self) {
		// TODO: for supporting Twitter cards.
	}
	return self;
}


- (void)viewDidLoad {
	[super viewDidLoad];

	self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
	_tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_tableView.dataSource = self;
	_tableView.delegate = self;
	[self.view addSubview:_tableView];
	
	if (self.infiniteScrollEnabled) {
        [self enableInfiniteScrolling];
    }
	
	self.title = self.post.postTitle;
	
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.contentInset = UIEdgeInsetsMake(self.navigationController.navigationBar.frame.size.height, 0, self.navigationController.toolbar.frame.size.height, 0);
	
	[self buildHeader];
	[self buildTopToolbar];
	[self buildBottomToolbar];
	[self buildForms];
	
	[self prepareComments];
	[self showStoredComment];
}


- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	CGSize contentSize = self.tableView.contentSize;
    if(contentSize.height > savedScrollOffset.y) {
        [self.tableView scrollRectToVisible:CGRectMake(savedScrollOffset.x, savedScrollOffset.y, 0.0f, 0.0f) animated:NO];
    } else {
        [self.tableView scrollRectToVisible:CGRectMake(0.0f, contentSize.height, 0.0f, 0.0f) animated:NO];
    }
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardDidShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

	self.panelNavigationController.delegate = self;
    [self setFullScreen:NO];
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.toolbar.translucent = YES;

	UIToolbar *toolbar = self.navigationController.toolbar;
	[toolbar setBackgroundImage:nil forToolbarPosition:UIToolbarPositionBottom barMetrics:UIBarMetricsDefault];
	[toolbar setTintColor:[UIColor colorWithHexString:@"F1F1F1"]];
	
	if (IS_IPAD)
        [self.panelNavigationController setToolbarHidden:NO forViewController:self animated:NO];

	[_headerView updateLayout];
	[self showStoredComment];
}


- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	WordPressAppDelegate *appDelegate = [WordPressAppDelegate sharedWordPressApplicationDelegate];
    if( appDelegate.connectionAvailable == NO ) return; //do not start auto-sync if connection is down
	
    NSDate *lastSynced = [self lastSyncDate];
    if (lastSynced == nil || ABS([lastSynced timeIntervalSinceNow]) > ReaderPostDetailViewControllerRefreshTimeout) {
		[self syncWithUserInteraction:NO];
    }
	
	[self.post addObserver:self forKeyPath:@"isReblogged" options:NSKeyValueObservingOptionNew context:@"reblogging"];
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
	
	if (IS_IPHONE) {
        savedScrollOffset = self.tableView.contentOffset;
    }
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self.post removeObserver:self forKeyPath:@"isReblogged" context:@"reblogging"];
	
    self.panelNavigationController.delegate = nil;
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.toolbar.translucent = NO;
	[self.navigationController setToolbarHidden:YES animated:YES];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}


- (void)viewDidUnload {
	[super viewDidUnload];

	self.activityFooter = nil;
	self.tableView = nil;
	self.headerView = nil;
	self.readerCommentFormView = nil;
	self.readerReblogFormView = nil;
	self.navBar = nil;
	self.commentButton = nil;
	self.likeButton = nil;
	self.reblogButton = nil;
	self.shareButton = nil;
	
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];

	[_headerView updateLayout];

	// Make sure a selected comment is visible after rotating.
	if ([self.tableView indexPathForSelectedRow] != nil && self.isShowingCommentForm) {
		[self.tableView scrollToNearestSelectedRowAtScrollPosition:UITableViewScrollPositionNone animated:NO];
	}
}


#pragma mark - Instance Methods

- (void)buildHeader{
	self.headerView = [[ReaderPostDetailView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.tableView.frame.size.width, 190.0f) post:self.post delegate:self];
	_headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	_headerView.backgroundColor = [UIColor whiteColor];
	[self.tableView setTableHeaderView:_headerView];
	
	UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDismissForm:)];
	tgr.cancelsTouchesInView = NO;
	[_headerView addGestureRecognizer:tgr];
}


- (void)buildTopToolbar {
	// Top Navigation bar and Sharing.
	if ([[UIButton class] respondsToSelector:@selector(appearance)]) {
		UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
		
		[btn setImage:[UIImage imageNamed:@"navbar_actions.png"] forState:UIControlStateNormal];
		[btn setImage:[UIImage imageNamed:@"navbar_actions.png"] forState:UIControlStateHighlighted];
		
		UIImage *backgroundImage = [[UIImage imageNamed:@"navbar_button_bg"] stretchableImageWithLeftCapWidth:4 topCapHeight:0];
		[btn setBackgroundImage:backgroundImage forState:UIControlStateNormal];
		
		backgroundImage = [[UIImage imageNamed:@"navbar_button_bg_active"] stretchableImageWithLeftCapWidth:4 topCapHeight:0];
		[btn setBackgroundImage:backgroundImage forState:UIControlStateHighlighted];
		btn.frame = CGRectMake(0.0f, 0.0f, 44.0f, 30.0f);
		[btn addTarget:self action:@selector(handleShareButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
		
		self.shareButton = [[UIBarButtonItem alloc] initWithCustomView:btn];
	} else {
		self.shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
																		 target:self
																		 action:@selector(handleShareButtonTapped:)];
	}
	
	self.navigationItem.rightBarButtonItem = _shareButton;
	
	if(IS_IPAD) {
		
		self.navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, 44.0f)];
		_navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[_navBar pushNavigationItem:self.navigationItem animated:NO];
		[self.view addSubview:_navBar];
		
		CGRect frame = self.tableView.frame;
		frame.origin.y = 44.0f;
		frame.size.height -= 44.0f;
		self.tableView.frame = frame;
	}

}


- (void)buildBottomToolbar {
	
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
	
	[self updateToolbar];
}


- (void)buildForms {
	CGRect frame = CGRectMake(0.0f, self.tableView.frame.origin.y + self.tableView.bounds.size.height, self.view.bounds.size.width, [ReaderCommentFormView desiredHeight]);
	self.readerCommentFormView = [[ReaderCommentFormView alloc] initWithFrame:frame];
	_readerCommentFormView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
	_readerCommentFormView.navigationItem = self.navigationItem;
	_readerCommentFormView.post = self.post;
	_readerCommentFormView.delegate = self;
	
	if (_isShowingCommentForm) {
		[self showCommentForm];
	}
	
	frame = CGRectMake(0.0f, self.view.bounds.size.height, self.view.bounds.size.width, [ReaderReblogFormView desiredHeight]);
	self.readerReblogFormView = [[ReaderReblogFormView alloc] initWithFrame:frame];
	_readerReblogFormView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
	_readerReblogFormView.navigationItem = self.navigationItem;
	_readerReblogFormView.post = self.post;
	_readerReblogFormView.delegate = self;
	
	if (_isShowingReblogForm) {
		[self showReblogForm];
	}
}


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
			if([comment.childComments count] > 0) {
				flattenComments([comment.childComments allObjects]);
			}
		}
	};
	
	flattenComments(self.resultsController.fetchedObjects);
	if ([_comments count] > 0) {
		self.tableView.backgroundColor = [UIColor colorWithHexString:@"EFEFEF"];
	}
}


- (void)updateToolbar {
	if (!self.post) return;
	
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


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	[self updateToolbar];
}


- (void)handleCommentButtonTapped:(id)sender {
	if (_readerCommentFormView.window != nil) {
		[self hideCommentForm];
		return;
	}
	
	[self showCommentForm];
}


- (void)handleLikeButtonTapped:(id)sender {
	[self.post toggleLikedWithSuccess:^{
		
	} failure:^(NSError *error) {
		WPLog(@"Error Liking Post : %@", [error localizedDescription]);
		[self updateToolbar];
	}];
	[self updateToolbar];
}


- (void)handleReblogButtonTapped:(id)sender {
	if (_isShowingReblogForm) {
		[self hideReblogForm];
		return;
	}
	
	[self showReblogForm];
}


- (void)handleShareButtonTapped:(id)sender {
	
	if (self.linkOptionsActionSheet) {
        [self.linkOptionsActionSheet dismissWithClickedButtonIndex:-1 animated:NO];
        self.linkOptionsActionSheet = nil;
    }
    NSString* permaLink = self.post.permaLink;
    	
    if (NSClassFromString(@"UIActivity") != nil) {
        NSString *title = self.post.postTitle;
        SafariActivity *safariActivity = [[SafariActivity alloc] init];
        InstapaperActivity *instapaperActivity = [[InstapaperActivity alloc] init];
        PocketActivity *pocketActivity = [[PocketActivity alloc] init];
		
        NSMutableArray *activityItems = [NSMutableArray array];
        if (title) {
            [activityItems addObject:title];
        }
		
        [activityItems addObject:[NSURL URLWithString:permaLink]];
        UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:@[safariActivity, instapaperActivity, pocketActivity]];
        [self presentViewController:activityViewController animated:YES completion:nil];
        return;
    }
	
    self.linkOptionsActionSheet = [[UIActionSheet alloc] initWithTitle:permaLink delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Open in Safari", @"Open in Safari"), NSLocalizedString(@"Mail Link", @"Mail Link"),  NSLocalizedString(@"Copy Link", @"Copy Link"), nil];
    self.linkOptionsActionSheet.actionSheetStyle = UIActionSheetStyleDefault;
    if(IS_IPAD ){
        [self.linkOptionsActionSheet showFromBarButtonItem:_shareButton animated:YES];
    } else {
        [self.linkOptionsActionSheet showInView:self.view];
    }
	
}


- (void)handleDismissForm:(id)sender {
	if (_readerCommentFormView.window != nil) {
		[self hideCommentForm];
	} else {
		[self hideReblogForm];
	}
    BOOL hideBars = !self.navigationController.toolbarHidden;
    if (!hideBars || self.tableView.contentOffset.y > 60) {
        [self.navigationController setToolbarHidden:hideBars animated:YES];
        [self setFullScreen:hideBars];
    }
}

- (BOOL)isReplying {
	return ([self.tableView indexPathForSelectedRow] != nil) ? YES : NO;
}


- (void)showStoredComment {
	NSDictionary *storedComment = [self.post getStoredComment];
	if (!storedComment) {
		return;
	}
	
	[_readerCommentFormView setText:[storedComment objectForKey:@"comment"]];
	
	NSNumber *commentID = [storedComment objectForKey:@"commentID"];
	NSInteger cid = [commentID integerValue];
	
	if (cid == 0) return;

	NSUInteger idx = [_comments indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
		ReaderComment *c = (ReaderComment *)obj;
		if([c.commentID integerValue] == cid) {
			return YES;
		}
		return NO;
	}];
	NSIndexPath *path = [NSIndexPath indexPathForRow:idx inSection:0];
	[self.tableView selectRowAtIndexPath:path animated:NO scrollPosition:UITableViewScrollPositionNone];
	_readerCommentFormView.comment = [_comments objectAtIndex:idx];
}


- (void)showCommentForm {
	[self hideReblogForm];
	
	if (_readerCommentFormView.superview != nil) {
		return;
	}
	
	self.canUseFullScreen = NO;
	[self.navigationController setToolbarHidden:YES animated:NO];
	
	NSIndexPath *path = [self.tableView indexPathForSelectedRow];
	if (path) {
		_readerCommentFormView.comment = (ReaderComment *)[self.resultsController objectAtIndexPath:path];
	}
	
	CGFloat formHeight = [ReaderCommentFormView desiredHeight];
	CGRect tableFrame = self.tableView.frame;
	tableFrame.size.height = self.tableView.frame.size.height - formHeight;
	self.tableView.frame = tableFrame;
	
	CGFloat y = tableFrame.origin.y + tableFrame.size.height;
	_readerCommentFormView.frame = CGRectMake(0.0f, y, self.view.bounds.size.width, formHeight);
	[self.view addSubview:_readerCommentFormView];
	self.isShowingCommentForm = YES;
	[_readerCommentFormView.textView becomeFirstResponder];
}


- (void)hideCommentForm {
	if(_readerCommentFormView.superview == nil) {
		return;
	}
	
	_readerCommentFormView.comment = nil;
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:NO];
	
	CGRect tableFrame = self.tableView.frame;
	tableFrame.size.height = self.tableView.frame.size.height + _readerCommentFormView.frame.size.height;
	
	self.tableView.frame = tableFrame;
	[_readerCommentFormView removeFromSuperview];
	self.isShowingCommentForm = NO;
	[self.view endEditing:YES];
	self.canUseFullScreen = YES;
	[self.navigationController setToolbarHidden:NO animated:YES];
}


- (void)showReblogForm {
	[self hideCommentForm];
	
	self.canUseFullScreen = NO;
	[self.navigationController setToolbarHidden:YES animated:NO];
	
	if (_readerReblogFormView.superview != nil) {
		return;
	}
	
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
	
	self.canUseFullScreen = YES;
	[self.navigationController setToolbarHidden:NO animated:YES];
}


- (void)setCanUseFullScreen:(BOOL)canUseFullScreen{
	_canUseFullScreen = canUseFullScreen;
	if (!_canUseFullScreen){
		[self setFullScreen:NO];
	}
}


- (void)setFullScreen:(BOOL)fullScreen {
	if (!self.canUseFullScreen) {
		fullScreen = NO;
	}
	
    [self.navigationController setToolbarHidden:fullScreen animated:YES];
    [self.navigationController setNavigationBarHidden:fullScreen animated:YES];
    return;

    if (fullScreen) {
        [UIView animateWithDuration:.3f
                         animations:^{
                             self.navigationController.toolbar.alpha = 0.f;
                             self.navigationController.navigationBar.alpha = 0.f;
                         } completion:^(BOOL finished) {
                             [self.navigationController setToolbarHidden:YES animated:NO];
                             [self.navigationController setNavigationBarHidden:YES animated:NO];
                         }];
    } else {
        [self.navigationController setToolbarHidden:NO animated:NO];
        self.navigationController.toolbar.alpha = 0.f;
        [self.navigationController setNavigationBarHidden:NO animated:NO];
        self.navigationController.navigationBar.alpha = 0.f;
        [UIView animateWithDuration:.3f
                         animations:^{
                             self.navigationController.toolbar.alpha = 1.f;
                             self.navigationController.navigationBar.alpha = 1.f;
                         }];
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
	[self.navigationController setToolbarHidden:YES animated:NO];
	
	CGRect frame = self.view.frame;
	CGRect keyFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	
	CGPoint point = [self.view.window convertPoint:keyFrame.origin toView:self.view];
	frame.size.height = point.y - (frame.origin.y + keyboardOffset);
	self.view.frame = frame;
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
							   [self onSyncFailure:operation error:error];
						   }];
}


- (void)loadMoreWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
	if ([self.resultsController.fetchedObjects count] == 0) {
		return;
	}
	
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
							   [self onSyncFailure:operation error:error];
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
	
	if([commentsArr count] < ([_comments count] + ReaderCommentsToSync)) {
		_hasMoreContent = NO;
	}
	
	[ReaderComment syncAndThreadComments:commentsArr
								 forPost:self.post
							 withContext:[[WordPressAppDelegate sharedWordPressApplicationDelegate] managedObjectContext]];
	
	[self prepareComments];
	[self.tableView reloadData];

}


- (void)onSyncFailure:(AFHTTPRequestOperation *)operation error:(NSError *)error {
	// TODO: prompt about failure.
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


- (BOOL)infiniteScrollEnabled {
    return _infiniteScrollEnabled;
}


- (void)enableInfiniteScrolling {
    if (_activityFooter == nil) {
        CGRect rect = CGRectMake(145.0f, 10.0f, 30.0f, 30.0f);
        _activityFooter = [[UIActivityIndicatorView alloc] initWithFrame:rect];
        _activityFooter.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        _activityFooter.hidesWhenStopped = YES;
        _activityFooter.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [_activityFooter stopAnimating];
    }
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 50.0f)];
    footerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [footerView addSubview:_activityFooter];
    self.tableView.tableFooterView = footerView;
}


- (void)disableInfiniteScrolling {
    self.tableView.tableFooterView = nil;
    _activityFooter = nil;
}


#pragma mark - UITableView Delegate Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (![_comments count]) {
		return 0.0f;
	}
	
	ReaderComment *comment = [_comments objectAtIndex:indexPath.row];
	return [ReaderCommentTableViewCell heightForComment:comment
												  width:tableView.frame.size.width
											 tableStyle:tableView.style
										  accessoryType:UITableViewCellAccessoryNone];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [_comments count];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *cellIdentifier = @"ReaderCommentCell";
    ReaderCommentTableViewCell *cell = (ReaderCommentTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[ReaderCommentTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
		cell.parentController = self;
    }
	cell.accessoryType = UITableViewCellAccessoryNone;
	
	ReaderComment *comment = [_comments objectAtIndex:indexPath.row];
	[cell configureCell:comment];

	return cell;	
}


- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if (_readerReblogFormView.window != nil) {
		[self hideReblogForm];
		return nil;
	}
	
	if (_readerCommentFormView.window != nil) {
		UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
		if ([cell isSelected]) {
			[tableView deselectRowAtIndexPath:indexPath animated:NO];
		}
		
		[self hideCommentForm];
		return nil;
	}
	
	if ([self canComment]) {
		[self showCommentForm];
	}
	
	return indexPath;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if(![self canComment]) {
		[self.tableView deselectRowAtIndexPath:indexPath animated:NO];
		return;
	}
	
	_readerCommentFormView.comment = [_comments objectAtIndex:indexPath.row];
	if (IS_IPAD) {
		[self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
	} else {
		[self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
	}
}


- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}


- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (IS_IPAD == YES) {
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

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (self.panelNavigationController) {
        [self.panelNavigationController viewControllerWantsToBeFullyVisible:self];
    }
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	if (_isScrollingCommentIntoView){
		self.isScrollingCommentIntoView = NO;
	}
	
	if (!self.canUseFullScreen) {
		return;
	}
	
	// Toolbars can vanish if the content is smaller than the screen and the user swipes quickly. 
	if (self.tableView.contentSize.height < self.tableView.frame.size.height) {
		return;
	}
	
    CGFloat dY = scrollView.contentOffset.y - _previousOffset;
    BOOL toolbarHidden = self.navigationController.toolbarHidden;
    if (toolbarHidden &&
        (dY < 0
         || (dY > 0 && scrollView.contentOffset.y < 10)
         || (dY > 0 && scrollView.contentOffset.y > _headerView.frame.size.height))) {
            [self setFullScreen:NO];
    }

    // Should be around the start of the post
    CGFloat hideThreshold = 60;
    if (!toolbarHidden && _previousOffset < hideThreshold && scrollView.contentOffset.y > hideThreshold) {
        [self setFullScreen:YES];
    }

    _previousOffset = scrollView.contentOffset.y;
}


- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	
	if (_readerReblogFormView.window) {
		[self hideReblogForm];
		return;
	}
	
	NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
	if (!selectedIndexPath) {
		[self hideCommentForm];
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
	
	[self hideCommentForm];

}


#pragma mark - ReaderPostDetailView Delegate Methods

- (void)readerPostDetailViewLayoutChanged {
	self.tableView.tableHeaderView = _headerView;
}


#pragma mark - ReaderTextForm Delegate Methods

- (void)readerTextFormDidCancel:(ReaderTextFormView *)readerTextForm {
	if ([readerTextForm isEqual:_readerCommentFormView]) {
		[self hideCommentForm];
	} else {
		[self hideReblogForm];
	}
}


- (void)readerTextFormDidSend:(ReaderTextFormView *)readerTextForm {
	if ([readerTextForm isEqual:_readerCommentFormView]) {
		[self hideCommentForm];
		self.post.storedComment = nil;
		[self prepareComments];
		[self.tableView reloadData];
	} else {
		[self hideReblogForm];
	}
}


- (void)readerTextFormDidChange:(ReaderTextFormView *)readerTextForm {
	// If we are replying, and scrolled away from the comment, scroll back to it real quick.
	if ([readerTextForm isEqual:_readerCommentFormView] && [self isReplying] && !_isScrollingCommentIntoView) {
		NSIndexPath *path = [self.tableView indexPathForSelectedRow];
		NSArray *paths = [self.tableView indexPathsForVisibleRows];
		if ([paths count] > 0 && NSOrderedSame != [path compare:[paths objectAtIndex:0]]) {
			self.isScrollingCommentIntoView = YES;
			[self.tableView scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionTop animated:YES];
		}
	}
}


- (void)readerTextFormDidEndEditing:(ReaderTextFormView *)readerTextForm {
	if (![readerTextForm isEqual:_readerCommentFormView]) {
		return;
	}
	
	if ([readerTextForm.text length] > 0) {
		// Save the text
		NSNumber *commentID = nil;
		if ([self isReplying]){
			ReaderComment *comment = [_comments objectAtIndex:[self.tableView indexPathForSelectedRow].row];
			commentID = comment.commentID;
		}
		[self.post storeComment:commentID comment:[readerTextForm text]];
	} else {
		self.post.storedComment = nil;
	}
	[self.post save];

}


#pragma mark - DetailView Delegate Methods

- (void)resetView {
	
}


#pragma mark -
#pragma mark Fetched results controller

- (NSFetchedResultsController *)resultsController {
    if (_resultsController != nil) {
        return _resultsController;
    }
	
	NSString *entityName = @"ReaderComment";
	NSManagedObjectContext *moc = [[WordPressAppDelegate sharedWordPressApplicationDelegate] managedObjectContext];
	
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
	
    NSError *error = nil;
    if (![_resultsController performFetch:&error]) {
        WPFLog(@"%@ couldn't fetch %@: %@", self, entityName, [error localizedDescription]);
        _resultsController = nil;
    }
    
    return _resultsController;
}


#pragma mark - UIActionSheet Delegate Methods

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
	
	NSString *permaLink = self.post.permaLink;
	
	if (buttonIndex == 0) {
		NSURL *permaLinkURL;
		permaLinkURL = [[NSURL alloc] initWithString:(NSString *)permaLink];
        [[UIApplication sharedApplication] openURL:(NSURL *)permaLinkURL];
		
    } else if (buttonIndex == 1) {
        MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
        controller.mailComposeDelegate = self;
        
        NSString *title = self.post.postTitle;
        [controller setSubject: [title trim]];
        
        NSString *body = [permaLink trim];
        [controller setMessageBody:body isHTML:NO];
        
        if (controller)
            [self.panelNavigationController presentModalViewController:controller animated:YES];
		
        [self setMFMailFieldAsFirstResponder:controller.view mfMailField:@"MFRecipientTextField"];
		
    } else if ( buttonIndex == 2 ) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = permaLink;
    }
}


#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
	[self dismissModalViewControllerAnimated:YES];
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
