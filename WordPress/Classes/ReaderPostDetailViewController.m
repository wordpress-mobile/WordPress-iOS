//
//  ReaderPostDetailViewController.m
//  WordPress
//
//  Created by Eric J on 3/21/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "ReaderPostDetailViewController.h"
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

@interface ReaderPostDetailViewController ()<ReaderPostDetailViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate, ReaderTextFormDelegate>

@property (nonatomic, strong) ReaderPost *post;
@property (nonatomic, strong) ReaderPostDetailView *headerView;
@property (nonatomic, strong) ReaderCommentFormView *readerCommentFormView;
@property (nonatomic, strong) ReaderReblogFormView *readerReblogFormView;
@property (nonatomic, strong) UIBarButtonItem *commentButton;
@property (nonatomic, strong) UIBarButtonItem *likeButton;
@property (nonatomic, strong) UIBarButtonItem *followButton;
@property (nonatomic, strong) UIBarButtonItem *reblogButton;
@property (nonatomic, strong) UIBarButtonItem *shareButton;
@property (nonatomic, strong) UIActionSheet *linkOptionsActionSheet;
@property (nonatomic, strong) NSMutableArray *comments;
@property (nonatomic, strong) NSArray *rowHeights;
@property (nonatomic, strong) NSFetchedResultsController *resultsController;
@property (nonatomic) BOOL isShowingKeyboard;
//@property (nonatomic) BOOL shouldShowKeyboard;
@property (nonatomic) BOOL isScrollingCommentIntoView;
@property (nonatomic) BOOL isShowingCommentForm;
@property (nonatomic) BOOL isShowingReblogForm;

- (void)prepareComments;
- (void)showStoredComment;
- (void)updateRowHeightsForWidth:(CGFloat)width;
- (void)updateToolbar;
- (BOOL)isReplying;
- (BOOL)canComment;
- (void)showCommentForm:(BOOL)animated;
- (void)hideCommentForm:(BOOL)animated;
- (void)showReblogForm:(BOOL)animated;
- (void)hideReblogForm:(BOOL)animated;

- (void)handleCommentButtonTapped:(id)sender;
- (void)handleFollowButtonTapped:(id)sender;
- (void)handleLikeButtonTapped:(id)sender;
- (void)handleReblogButtonTapped:(id)sender;
- (void)handleShareButtonTapped:(id)sender;
- (void)handleCloseKeyboard:(id)sender;
- (void)handleFooterViewTapped:(id)sender;
- (BOOL)setMFMailFieldAsFirstResponder:(UIView*)view mfMailField:(NSString*)field;

@end

@implementation ReaderPostDetailViewController

@synthesize post;

#pragma mark - LifeCycle Methods

- (void)doBeforeDealloc {
	[super doBeforeDealloc];
	_resultsController.delegate = nil;
}


- (id)initWithPost:(ReaderPost *)apost {
	self = [super init];
	if(self) {
		self.post = apost;
		self.comments = [NSMutableArray array];
		self.rowHeights = [NSArray array];
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

	if ([self.resultsController.fetchedObjects count] > 0) {
		self.tableView.backgroundColor = [UIColor colorWithHexString:@"EFEFEF"];
	}
	
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	
	self.title = self.post.postTitle;
	
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

	if(IS_IPAD) {
		self.toolbarItems = @[_shareButton];
	} else {
		self.navigationItem.rightBarButtonItem = _shareButton;
	}

	UIColor *color = [UIColor colorWithHexString:@"3478E3"];
	CGFloat fontSize = 16.0f;
	
	UIButton *commentBtn = [UIButton buttonWithType:UIButtonTypeCustom];
	[commentBtn.titleLabel setFont:[UIFont systemFontOfSize:fontSize]];
	[commentBtn setTitleColor:color forState:UIControlStateNormal];
	[commentBtn setImage:[UIImage imageNamed:@"toolbar_comment"] forState:UIControlStateNormal];
    [commentBtn setImage:[UIImage imageNamed:@"toolbar_comment_active"] forState:UIControlStateHighlighted];
    [commentBtn setImage:[UIImage imageNamed:@"toolbar_comment_active"] forState:UIControlStateSelected];
	commentBtn.frame = CGRectMake(0.0f, 0.0f, 40.0f, 40.0f);
	[commentBtn addTarget:self action:@selector(handleCommentButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
	
	UIButton *likeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
	[likeBtn.titleLabel setFont:[UIFont systemFontOfSize:fontSize]];
	[likeBtn setTitleColor:color forState:UIControlStateNormal];
	[likeBtn setImage:[UIImage imageNamed:@"toolbar_like"] forState:UIControlStateNormal];
    [likeBtn setImage:[UIImage imageNamed:@"toolbar_like_active"] forState:UIControlStateHighlighted];
    [likeBtn setImage:[UIImage imageNamed:@"toolbar_like_active"] forState:UIControlStateSelected];
	likeBtn.frame = CGRectMake(0.0f, 0.0f, 40.0f, 40.0f);
	likeBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
	[likeBtn addTarget:self action:@selector(handleLikeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
	
	UIButton *followBtn = [UIButton buttonWithType:UIButtonTypeCustom];
	[followBtn.titleLabel setFont:[UIFont systemFontOfSize:fontSize]];
	[followBtn setTitleColor:color forState:UIControlStateNormal];
	[followBtn setImage:[UIImage imageNamed:@"toolbar_follow"] forState:UIControlStateNormal];
    [followBtn setImage:[UIImage imageNamed:@"toolbar_follow_active"] forState:UIControlStateHighlighted];
    [followBtn setImage:[UIImage imageNamed:@"toolbar_follow_active"] forState:UIControlStateSelected];
	followBtn.frame = CGRectMake(0.0f, 0.0f, 40.0f, 40.0f);
	[followBtn addTarget:self action:@selector(handleFollowButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
	
	UIButton *reblogBtn = [UIButton buttonWithType:UIButtonTypeCustom];
	[reblogBtn.titleLabel setFont:[UIFont systemFontOfSize:fontSize]];
	[reblogBtn setTitleColor:color forState:UIControlStateNormal];
	[reblogBtn setImage:[UIImage imageNamed:@"toolbar_reblog"] forState:UIControlStateNormal];
    [reblogBtn setImage:[UIImage imageNamed:@"toolbar_reblog_active"] forState:UIControlStateHighlighted];
    [reblogBtn setImage:[UIImage imageNamed:@"toolbar_reblog_active"] forState:UIControlStateSelected];
	reblogBtn.frame = CGRectMake(0.0f, 0.0f, 40.0f, 40.0f);
	reblogBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
	[reblogBtn addTarget:self action:@selector(handleReblogButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
	
	self.commentButton = [[UIBarButtonItem alloc] initWithCustomView:commentBtn];
	self.likeButton = [[UIBarButtonItem alloc] initWithCustomView:likeBtn];
	self.followButton = [[UIBarButtonItem alloc] initWithCustomView:followBtn];
	self.reblogButton = [[UIBarButtonItem alloc] initWithCustomView:reblogBtn];
	[self updateToolbar];

	self.headerView = [[ReaderPostDetailView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.tableView.frame.size.width, 190.0f) post:self.post delegate:self];
	_headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	_headerView.backgroundColor = [UIColor whiteColor];
	[self.tableView setTableHeaderView:_headerView];
	
	UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleCloseKeyboard:)];
	tgr.cancelsTouchesInView = NO;
	[_headerView addGestureRecognizer:tgr];
	
	CGRect frame = CGRectMake(0.0f, self.view.bounds.size.height, self.view.bounds.size.width, [ReaderCommentFormView desiredHeight]);
	self.readerCommentFormView = [[ReaderCommentFormView alloc] initWithFrame:frame];
	_readerCommentFormView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
	_readerCommentFormView.navigationItem = self.navigationItem;
	_readerCommentFormView.post = self.post;
	_readerCommentFormView.delegate = self;

	if (_isShowingCommentForm) {
		[self showCommentForm:NO]; // show the form but don't animate it.
	}
	
	frame = CGRectMake(0.0f, self.view.bounds.size.height, self.view.bounds.size.width, [ReaderReblogFormView desiredHeight]);
	self.readerReblogFormView = [[ReaderReblogFormView alloc] initWithFrame:frame];
	_readerReblogFormView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
	_readerReblogFormView.navigationItem = self.navigationItem;
	_readerReblogFormView.post = self.post;
	_readerReblogFormView.delegate = self;
	
	if (_isShowingReblogForm) {
		[self showReblogForm:NO]; // show the form but don't animate it.
	}
	
	[self prepareComments];
	[self updateRowHeightsForWidth:self.tableView.frame.size.width];
	[self showStoredComment];

}


- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	self.panelNavigationController.delegate = self;
	[self.navigationController setToolbarHidden:NO animated:YES];
	[_headerView updateLayout];
	[self updateRowHeightsForWidth:self.tableView.frame.size.width];
	[self showStoredComment];
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
	
    self.panelNavigationController.delegate = nil;
	[self.navigationController setToolbarHidden:YES animated:YES];
}


- (void)viewDidUnload {
	[super viewDidUnload];
    
	// TODO: Release views
	
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
	
	[self updateRowHeightsForWidth:width];
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];

	[_headerView updateLayout];
}


#pragma mark - Instance Methods

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
}


- (void)updateRowHeightsForWidth:(CGFloat)width {
	self.rowHeights = [ReaderCommentTableViewCell cellHeightsForComments:_comments
																   width:width
															  tableStyle:UITableViewStylePlain
															   cellStyle:UITableViewCellStyleDefault
														 reuseIdentifier:@"ReaderCommentCell"];
}


- (void)updateToolbar {
	if (!self.post) return;

	UIColor *activeColor = [UIColor colorWithHexString:@"F1831E"];
	UIColor *inactiveColor = [UIColor colorWithHexString:@"3478E3"];
	
	UIImage *img = nil;
	UIColor *color;
	UIButton *btn;
	if (self.post.isLiked.boolValue) {
		img = [UIImage imageNamed:@"note_navbar_icon_like"];
		color = activeColor;
	} else {
		img = [UIImage imageNamed:@"toolbar_like"];
		color = inactiveColor;
	}
	btn = (UIButton *)_likeButton.customView;
	[btn.imageView setImage:img];
	[btn setTitleColor:color forState:UIControlStateNormal];
	
	if (self.post.isReblogged.boolValue) {
		img = [UIImage imageNamed:@"note_navbar_icon_reblog"];
		color = activeColor;
	} else {
		img = [UIImage imageNamed:@"toolbar_reblog"];
		color = inactiveColor;
	}
	btn = (UIButton *)_reblogButton.customView;
	[btn.imageView setImage:img];
	[btn setTitleColor:color forState:UIControlStateNormal];
	
	if (self.post.isFollowing.boolValue) {
		img = [UIImage imageNamed:@"note_navbar_icon_follow"];
		color = activeColor;
	} else {
		img = [UIImage imageNamed:@"toolbar_follow"];
		color = inactiveColor;
	}
	btn = (UIButton *)_followButton.customView;
	[btn.imageView setImage:img];
	[btn setTitleColor:color forState:UIControlStateNormal];
	
	UIBarButtonItem *placeholder = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	
	NSMutableArray *items = [NSMutableArray array];
	if ([self.post.commentsOpen boolValue]) {
		[items addObjectsFromArray:@[_commentButton, placeholder]];
	}
	[items addObjectsFromArray:@[_likeButton, placeholder, _followButton]];
	if ([self.post isWPCom]) {
		[items addObjectsFromArray:@[placeholder, _reblogButton]];
	}
	
	[self setToolbarItems:items animated:YES];
	
	self.navigationController.toolbarHidden = NO;

}


- (void)handleCommentButtonTapped:(id)sender {
	
	if (_isShowingCommentForm) {
		[self hideCommentForm:YES];
		return;
	}
	
	[self showCommentForm:YES];
}


- (void)handleFollowButtonTapped:(id)sender {
	NSLog(@"Follow tapped");
	[self.post toggleFollowingWithSuccess:^{
		
	} failure:^(NSError *error) {
		[self updateToolbar];
	}];
	[self updateToolbar];
}


- (void)handleLikeButtonTapped:(id)sender {
	NSLog(@"Like Tapped");
	[self.post toggleLikedWithSuccess:^{
		
	} failure:^(NSError *error) {
		[self updateToolbar];
	}];
	[self updateToolbar];
}


- (void)handleReblogButtonTapped:(id)sender {
	NSLog(@"Reblog tapped");
	
	if (_isShowingReblogForm) {
		[self hideReblogForm:YES];
		return;
	}
	
	[self showReblogForm:YES];
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


- (void)handleCloseKeyboard:(id)sender {
	[self.view endEditing:YES];
}


- (void)handleFooterViewTapped:(id)sender {
	if (_isShowingKeyboard) {
		if([self.tableView indexPathForSelectedRow]) {
			[self.tableView scrollToRowAtIndexPath:[self.tableView indexPathForSelectedRow] atScrollPosition:UITableViewScrollPositionTop animated:YES];
		}
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


- (void)showCommentForm:(BOOL)animated {
	[self hideReblogForm:NO];
	if (_readerCommentFormView.superview == nil) {
		CGRect frame = CGRectMake(0.0f, self.view.bounds.size.height, self.view.bounds.size.width, [ReaderCommentFormView desiredHeight]);
		_readerCommentFormView.frame = frame;
		[self.view addSubview:_readerCommentFormView];
	}
	
	if (_isShowingCommentForm) {
		[_readerCommentFormView.textView becomeFirstResponder];
		
		NSIndexPath *path = [self.tableView indexPathForSelectedRow];
		if (path) {
			[self.tableView scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionTop animated:YES];
		}
		
		return;
	}
	
	self.isShowingCommentForm = YES;
	CGRect formFrame = _readerCommentFormView.frame;
	CGRect tableFrame = self.tableView.frame;
	tableFrame.size.height = self.view.bounds.size.height - formFrame.size.height;
	formFrame.origin.y = tableFrame.origin.y + tableFrame.size.height;	

	self.tableView.frame = tableFrame;
	_readerCommentFormView.frame = formFrame;
	[_readerCommentFormView.textView becomeFirstResponder];
}


- (void)hideCommentForm:(BOOL)animated {
	if (!_isShowingCommentForm) {
		return;
	}
	
	CGRect formFrame = _readerCommentFormView.frame;
	CGRect tableFrame = self.tableView.frame;
	tableFrame.size.height = self.view.bounds.size.height;
	formFrame.origin.y = tableFrame.origin.y + tableFrame.size.height;
	
	if (!animated) {
		self.tableView.frame = tableFrame;
		_readerCommentFormView.frame = formFrame;
		self.isShowingCommentForm = NO;
		return;
	}
	
	_commentButton.enabled = NO;
	[UIView animateWithDuration:0.3 animations:^{
		self.tableView.frame = tableFrame;
		_readerCommentFormView.frame = formFrame;
	} completion:^(BOOL finished) {
		_commentButton.enabled = YES;
		self.isShowingCommentForm = NO;
		
		// Remove the view so we don't glympse it on the iPad when rotating
		[_readerCommentFormView removeFromSuperview];
	}];
}


- (void)showReblogForm:(BOOL)animated {
	[self hideCommentForm:NO];
	if (_readerReblogFormView.superview == nil) {
		CGRect frame = CGRectMake(0.0f, self.view.bounds.size.height, self.view.bounds.size.width, [ReaderReblogFormView desiredHeight]);
		_readerReblogFormView.frame = frame;
		[self.view addSubview:_readerReblogFormView];
	}
	
	NSIndexPath *path = [self.tableView indexPathForSelectedRow];
	if (path) {
		[self.tableView deselectRowAtIndexPath:path animated:NO];
	}
	
	if (_isShowingReblogForm) {
		[_readerReblogFormView.textView becomeFirstResponder];
		return;
	}
	
	self.isShowingReblogForm = YES;
	CGRect formFrame = _readerReblogFormView.frame;
	CGRect tableFrame = self.tableView.frame;
	tableFrame.size.height = self.view.bounds.size.height - formFrame.size.height;
	formFrame.origin.y = tableFrame.origin.y + tableFrame.size.height;
	
	self.tableView.frame = tableFrame;
	_readerReblogFormView.frame = formFrame;
	[_readerReblogFormView.textView becomeFirstResponder];

}


- (void)hideReblogForm:(BOOL)animated {
	if (!_isShowingReblogForm) {
		return;
	}
	
	CGRect formFrame = _readerReblogFormView.frame;
	CGRect tableFrame = self.tableView.frame;
	tableFrame.size.height = self.view.bounds.size.height;
	formFrame.origin.y = tableFrame.origin.y + tableFrame.size.height;
	
	if (!animated) {
		self.tableView.frame = tableFrame;
		_readerReblogFormView.frame = formFrame;
		self.isShowingReblogForm = NO;
		return;
	}
	
	_reblogButton.enabled = NO;
	[UIView animateWithDuration:0.3 animations:^{
		self.tableView.frame = tableFrame;
		_readerReblogFormView.frame = formFrame;
	} completion:^(BOOL finished) {
		_reblogButton.enabled = YES;
		self.isShowingReblogForm = NO;
		
		// Remove the view so we don't glympse it on the iPad when rotating
		[_readerReblogFormView removeFromSuperview];
	}];
}


#pragma mark - Sync methods

- (void)syncWithUserInteraction:(BOOL)userInteraction {
	
	if ([self.post.postID integerValue] == 0 ) { // Weird that this should ever happen. 
		self.post.dateCommentsSynced = [NSDate date];
		[self performSelector:@selector(hideRefreshHeader) withObject:self afterDelay:0.5f];
		return;
	}
	
	NSDictionary *params = @{@"number":@100};
	
	[ReaderPost getCommentsForPost:[self.post.postID integerValue]
						  fromSite:[self.post.siteID stringValue]
					withParameters:params
						   success:^(AFHTTPRequestOperation *operation, id responseObject) {
							   self.post.dateCommentsSynced = [NSDate date];
							   
							   NSDictionary *resp = (NSDictionary *)responseObject;
							   NSArray *commentsArr = [resp objectForKey:@"comments"];
							   
							   [ReaderComment syncAndThreadComments:commentsArr
															forPost:self.post
														withContext:[[WordPressAppDelegate sharedWordPressApplicationDelegate] managedObjectContext]];
							   
							   [self prepareComments];
							   [self updateRowHeightsForWidth:self.tableView.frame.size.width];
							   [self.tableView reloadData];
							   [self hideRefreshHeader];
							   
							   if ([self.resultsController.fetchedObjects count] > 0) {
								   self.tableView.backgroundColor = [UIColor colorWithHexString:@"EFEFEF"];
							   }
							   
						   } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
							   [self hideRefreshHeader];
							   
						   }];
}


- (NSDate *)lastSyncDate {
	return self.post.dateCommentsSynced;
}


#pragma mark - UITableView Delegate Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return [[_rowHeights objectAtIndex:indexPath.row] floatValue];
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
	if (_isShowingKeyboard) {
		[self.view endEditing:YES];
		return nil;
	}
	
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	if ([cell isSelected]) {
		_readerCommentFormView.comment = nil;
		[tableView deselectRowAtIndexPath:indexPath animated:NO];
		[self hideCommentForm:YES];
		return nil;
	}

	[self showCommentForm:YES];

	return indexPath;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
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


#pragma mark - UIScrollView Delegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	if (_isScrollingCommentIntoView){
		self.isScrollingCommentIntoView = NO;
	}
}


- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	if (_isShowingKeyboard) {
		if ([_comments count] == 0) {
			CGRect rect = [self.tableView rectForFooterInSection:0];
			if (self.tableView.contentOffset.y < rect.origin.y - (self.tableView.bounds.size.height - rect.size.height) ){
				[self handleCloseKeyboard:nil];
			}
		} else if([self.tableView.visibleCells count] == 0) {
			[self handleCloseKeyboard:nil];
		}
	}
}


#pragma mark - ReaderPostDetailView Delegate Methods

- (void)readerPostDetailViewLayoutChanged {
	self.tableView.tableHeaderView = _headerView;
}


#pragma mark - ReaderTextForm Delegate Methods

- (void)readerTextFormDidSend:(ReaderTextFormView *)readerTextForm {
	self.post.storedComment = nil;
	[self prepareComments];
	[self updateRowHeightsForWidth:self.tableView.frame.size.width];
	[self.tableView reloadData];
	[self hideRefreshHeader];
}


- (void)readerTextFormDidBeginEditing:(ReaderTextFormView *)readerTextForm {
	self.isShowingKeyboard = YES;
}


- (void)readerTextFormDidChange:(ReaderTextFormView *)readerTextForm {
	// If we are replying, and scrolled away from the comment, scroll back to it real quick.
	if ([self isReplying] && !_isScrollingCommentIntoView) {
		NSIndexPath *path = [self.tableView indexPathForSelectedRow];
		if (NSOrderedSame != [path compare:[self.tableView.indexPathsForVisibleRows objectAtIndex:0]]) {
			self.isScrollingCommentIntoView = YES;
			[self.tableView scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionTop animated:YES];
		}
	}
}


- (void)readerTextFormDidEndEditing:(ReaderTextFormView *)readerTextForm {
	self.isShowingKeyboard = NO;
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
