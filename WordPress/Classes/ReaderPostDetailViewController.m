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
#import <MediaPlayer/MediaPlayer.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "UIImageView+Gravatar.h"
#import "WPActivities.h"
#import "WPWebViewController.h"
#import "ReaderMediaView.h"
#import "ReaderImageView.h"
#import "ReaderVideoView.h"
#import "PanelNavigationConstants.h"
#import "WordPressAppDelegate.h"
#import "WordPressComApi.h"
#import "ReaderComment.h"
#import "ReaderCommentTableViewCell.h"
#import "WPImageViewController.h"
#import "WPWebVideoViewController.h"

@interface ReaderPostDetailViewController ()<DTAttributedTextContentViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) ReaderPost *post;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIView *authorView;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *authorLabel;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UILabel *blogLabel;
@property (nonatomic, strong) UIBarButtonItem *commentButton;
@property (nonatomic, strong) UIBarButtonItem *likeButton;
@property (nonatomic, strong) UIBarButtonItem *followButton;
@property (nonatomic, strong) UIBarButtonItem *reblogButton;
@property (nonatomic, strong) UIBarButtonItem *shareButton;
@property (nonatomic, strong) DTAttributedTextContentView *textContentView;
@property (nonatomic, strong) NSMutableSet *mediaPlayers;
@property (nonatomic, strong) UIActionSheet *linkOptionsActionSheet;
@property (nonatomic, strong) NSMutableArray *mediaArray;
@property (nonatomic, strong) NSMutableArray *comments;
@property (nonatomic, strong) NSArray *rowHeights;
@property (nonatomic, strong) NSFetchedResultsController *resultsController;

- (void)prepareComments;
- (void)updateRowHeightsForWidth:(CGFloat)width;
- (void)updateLayout;
- (void)updateMediaLayout:(ReaderMediaView *)mediaView;
- (void)updateToolbar;

- (void)handleAuthorViewTapped:(id)sender;
- (void)handleCommentButtonTapped:(id)sender;
- (void)handleFollowButtonTapped:(id)sender;
- (void)handleImageLinkTapped:(id)sender;
- (void)handleLikeButtonTapped:(id)sender;
- (void)handleLinkTapped:(id)sender;
- (void)handleReblogButtonTapped:(id)sender;
- (void)handleShareButtonTapped:(id)sender;
- (void)handleTitleButtonTapped:(id)sender;
- (void)handleVideoTapped:(id)sender;
- (void)handleCloseModal:(id)sender;
- (void)handleMediaViewLoaded:(ReaderMediaView *)mediaView;
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
	self = [super initWithStyle:UITableViewStylePlain];
	if(self) {
		self.post = apost;
		self.mediaArray = [NSMutableArray array];
		self.comments = [NSMutableArray array];
		self.rowHeights = [NSArray array];
	}
	return self;
}


- (id)initWithDictionary:(NSDictionary *)dict {
	self = [super initWithStyle:UITableViewStylePlain];
	if(self) {
		// TODO: for supporting Twitter cards.
	}
	return self;
}


- (void)viewDidLoad {
	[super viewDidLoad];
	
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
	self.navigationItem.rightBarButtonItem = _shareButton;

	self.commentButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@""] style:UIBarButtonItemStylePlain target:self action:@selector(handleCommentButtonTapped:)];
	self.likeButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@""] style:UIBarButtonItemStylePlain target:self action:@selector(handleLikeButtonTapped:)];
	self.followButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@""] style:UIBarButtonItemStylePlain target:self action:@selector(handleFollowButtonTapped:)];
	self.reblogButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@""] style:UIBarButtonItemStylePlain target:self action:@selector(handleReblogButtonTapped:)];

	UIBarButtonItem *placeholder = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	[self setToolbarItems:@[_likeButton, placeholder, _followButton, placeholder, _reblogButton] animated:YES];
	self.navigationController.toolbarHidden = NO;
	
	CGFloat width = self.tableView.frame.size.width;
	
	self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, width, 190.0f)];
	_headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	_headerView.backgroundColor = [UIColor whiteColor];
	
	self.authorView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, width, 80.0f)];
	_authorView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	_authorView.backgroundColor = [UIColor colorWithRed:30.0f/255.0f green:140.0f/255.0f blue:190.0f/255.0f alpha:1.0f];
	[_headerView addSubview:_authorView];
	
	CGRect rect = CGRectMake(0, 0, 1, 1);
	UIGraphicsBeginImageContext(rect.size);
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetFillColorWithColor(context, [[UIColor colorWithRed:241.0f/255.0f green:131.0/255.0f blue:30.0f/255.0f alpha:1.0] CGColor]);
	CGContextFillRect(context, rect);
	UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	button.frame = _authorView.frame;
	[button setBackgroundImage:img forState:UIControlStateHighlighted];
	button.backgroundColor = [UIColor clearColor];
	[button addTarget:self action:@selector(handleAuthorViewTapped:) forControlEvents:UIControlEventTouchUpInside];
	[_authorView addSubview:button];
	
	self.avatarImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10.0f, 10.0f, 40.0f, 40.0f)];
	_avatarImageView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
	[_avatarImageView setImageWithURL:[NSURL URLWithString:self.post.authorAvatarURL] placeholderImage:[UIImage imageNamed:@""]];
	[_authorView addSubview:_avatarImageView];
	
	self.authorLabel = [[UILabel alloc] initWithFrame:CGRectMake(55.0f, 10.0f, width - 70.0f, 20.0f)];
	_authorLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	_authorLabel.backgroundColor = [UIColor clearColor];
	_authorLabel.font = [UIFont systemFontOfSize:14.0f];
	_authorLabel.text = (self.post.author != nil) ? self.post.author : self.post.authorDisplayName;
	_authorLabel.textColor = [UIColor whiteColor];
	[_authorView addSubview:_authorLabel];
	
	self.dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(55.0f, 30.0f, width - 70.0f, 20.0f)];
	_dateLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	_dateLabel.backgroundColor = [UIColor clearColor];
	_dateLabel.font = [UIFont systemFontOfSize:14.0f];
	_dateLabel.text = [NSString stringWithFormat:@"%@ on", [self.post prettyDateString]];
	_dateLabel.textColor = [UIColor whiteColor];
	[_authorView addSubview:_dateLabel];
	
	self.blogLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0f, 50.0f, width - 20.0f, 20.0f)];
	_blogLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	_blogLabel.backgroundColor = [UIColor clearColor];
	_blogLabel.font = [UIFont systemFontOfSize:14.0f];
	_blogLabel.text = self.post.blogName;
	_blogLabel.textColor = [UIColor whiteColor];
	[_authorView addSubview:_blogLabel];
	
	UIImageView *commentImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"note_icon_comment.png"]];
	commentImageView.frame = CGRectMake(width - 26.0f, 12.0f, 16.0f, 16.0f);
	commentImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
	[_authorView addSubview:commentImageView];
	
	UILabel *commentLabel = [[UILabel alloc] initWithFrame:CGRectMake(width - 60.0f, 10.0f, 30.0f, 20.0f)];
	commentLabel.font = [UIFont systemFontOfSize:14.0f];
	commentLabel.textColor = [UIColor whiteColor];
	commentLabel.textAlignment = UITextAlignmentRight;
	commentLabel.backgroundColor = [UIColor clearColor];
	commentLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
	commentLabel.text = [self.post.commentCount stringValue];
	[_authorView addSubview:commentLabel];
	
	UIImageView *likesImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"note_icon_like.png"]];
	likesImageView.frame = CGRectMake(width - 26.0f, 32.0f, 16.0f, 16.0f);
	likesImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
	[_authorView addSubview:likesImageView];
	
	UILabel *likesLabel = [[UILabel alloc] initWithFrame:CGRectMake(width - 60.0f, 30.0f, 30.0f, 20.0f)];
	likesLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
	likesLabel.font = [UIFont systemFontOfSize:14.0f];
	likesLabel.textColor = [UIColor whiteColor];
	likesLabel.textAlignment = UITextAlignmentRight;
	likesLabel.backgroundColor = [UIColor clearColor];
	likesLabel.text = [self.post.likeCount stringValue];
	[_authorView addSubview:likesLabel];
	
	self.textContentView = [[DTAttributedTextContentView alloc] initWithFrame:CGRectMake(0.0f, 90.0f, width, 100.0f)]; // Starting height is arbitrary
	_textContentView.delegate = self;
	_textContentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_textContentView.backgroundColor = [UIColor clearColor];
	_textContentView.edgeInsets = UIEdgeInsetsMake(0.0f, 10.0f, 0.0f, 10.0f);
	_textContentView.shouldDrawImages = NO;
	_textContentView.shouldDrawLinks = NO;
	[_headerView addSubview:_textContentView];
		
	NSString *str = @"";
	if([self.post.postTitle length] > 0) {
		str = [NSString stringWithFormat:@"<h2>%@</h2>%@", self.post.postTitle, self.post.content];
	} else {
		str = post.content;
	}
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:@{
														  DTDefaultFontFamily: @"Helvetica",
										   NSTextSizeMultiplierDocumentOption: [NSNumber numberWithFloat:1.3f]
								 }];
	_textContentView.attributedString = [[NSAttributedString alloc] initWithHTMLData:[str dataUsingEncoding:NSUTF8StringEncoding]
																			 options:dict
																  documentAttributes:NULL];
	
	[self prepareComments];
	[self updateRowHeightsForWidth:self.tableView.frame.size.width];
	[self updateLayout];
}


- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	self.panelNavigationController.delegate = self;
	[self.navigationController setToolbarHidden:NO animated:YES];
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
	
    self.panelNavigationController.delegate = nil;
	[self.navigationController setToolbarHidden:YES animated:YES];
}


- (void)viewDidUnload {
	[super viewDidUnload];
    
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

	// Figure out image sizes after orientation change.
	for (ReaderMediaView *mediaView in _mediaArray) {
		[self updateMediaLayout:mediaView];
	}
	
	// Then update the layout
	// need to reset the layouter because otherwise we get the old framesetter or cached layout frames
	_textContentView.layouter = nil;
	
	// layout might have changed due to image sizes
	[_textContentView relayoutText];
	
	[self updateLayout];
}


#pragma mark - Instance Methods

- (void)prepareComments {
	self.resultsController = nil;
	[_comments removeAllObjects];
	
	__block void(__weak ^flattenComments)(NSArray *) = ^void (NSArray *comments) {
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


- (void)updateLayout {
	// Size the textContentView
	CGFloat width = self.tableView.frame.size.width;
	CGFloat height = [_textContentView suggestedFrameSizeToFitEntireStringConstraintedToWidth:self.view.frame.size.width].height;
	CGRect frame = _textContentView.frame;
	frame.size.width = width;
	frame.size.height = height;
	_textContentView.frame = frame;
	
	frame = _headerView.frame;
	frame.size.height = height + _textContentView.frame.origin.y + 10.0f; // + bottom padding
	_headerView.frame = frame;
	
	self.tableView.tableHeaderView = _headerView;
}


- (void)updateMediaLayout:(ReaderMediaView *)imageView {

	NSURL *url = imageView.contentURL;
	
	CGSize viewSize = imageView.image.size;
	
	// First the imageView
	CGFloat width = _textContentView.frame.size.width;

	// The ReaderImageView view will conform to the width constraints of the _textContentView. We want the image itself to run out to the edges,
	// so position it offset by the inverse of _textContentView's edgeInsets.
	UIEdgeInsets edgeInsets = _textContentView.edgeInsets;
	edgeInsets.left = 0.0f - edgeInsets.left;
	edgeInsets.top = 0.0f;
	edgeInsets.right = 0.0f - edgeInsets.right;
	edgeInsets.bottom = 0.0f;
	imageView.edgeInsets = edgeInsets;
	
	viewSize.width = width - (_textContentView.edgeInsets.left + _textContentView.edgeInsets.right);
	viewSize.height = imageView.image.size.height * (width / imageView.image.size.width);
	
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"contentURL == %@", url];
	
	// update all attachments that matchin this URL (possibly multiple images with same size)
	for (DTTextAttachment *attachment in [self.textContentView.layoutFrame textAttachmentsWithPredicate:pred]) {
		attachment.originalSize = imageView.image.size;
		attachment.displaySize = viewSize;
	}
}


- (void)updateToolbar {
	if (!self.post) return;
	
	UIImage *img = nil;
	if (self.post.isLiked.boolValue) {
		img = [UIImage imageNamed:@""];
	} else {
		img = [UIImage imageNamed:@""];
	}
	[self.likeButton setImage:img];
	
	if (self.post.isFollowing.boolValue) {
		img = [UIImage imageNamed:@""];
	} else {
		img = [UIImage imageNamed:@""];
	}
	[self.followButton setImage:img];
	
	if (self.post.isReblogged.boolValue) {
		img = [UIImage imageNamed:@""];
	} else {
		img = [UIImage imageNamed:@""];
	}
	[self.reblogButton setImage:img];
	
	UIBarButtonItem *placeholder = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	[self setToolbarItems:@[_likeButton, placeholder, _followButton, placeholder, _reblogButton] animated:YES];
}


- (void)handleAuthorViewTapped:(id)sender {
	WPWebViewController *controller = [[WPWebViewController alloc] init];
	[controller setUrl:[NSURL URLWithString:self.post.permaLink]];
	[self.panelNavigationController pushViewController:controller animated:YES];
}


- (void)handleCommentButtonTapped:(id)sender {
	
}


- (void)handleFollowButtonTapped:(id)sender {
	NSLog(@"Follow tapped");
	[self.post toggleFollowingWithSuccess:^{
		
	} failure:^(NSError *error) {
		[self updateToolbar];
	}];
	[self updateToolbar];
}


- (void)handleImageLinkTapped:(id)sender {
	ReaderImageView *imageView = (ReaderImageView *)sender;
	
	if(imageView.linkURL) {
		NSString *url = [imageView.linkURL absoluteString];
		
		BOOL match = NO;
		NSArray *types = @[@".png", @".jpg", @".gif", @".jpeg"];
		for (NSString *type in types) {
			if (NSNotFound != [url rangeOfString:type].location) {
				match = YES;
				break;
			}
		}
		
		if (match) {
			[WPImageViewController presentAsModalWithURL:((ReaderImageView *)sender).linkURL];
		} else {
			WPWebViewController *controller = [[WPWebViewController alloc] init];
			[controller setUrl:((ReaderImageView *)sender).linkURL];
			[self.panelNavigationController pushViewController:controller animated:YES];		
		}
	} else {
		[WPImageViewController presentAsModalWithImage:imageView.image];
	}
}


- (void)handleLikeButtonTapped:(id)sender {
	NSLog(@"Like Tapped");
	[self.post toggleLikedWithSuccess:^{
		
	} failure:^(NSError *error) {
		[self updateToolbar];
	}];
	[self updateToolbar];
}


- (void)handleLinkTapped:(id)sender {
	WPWebViewController *controller = [[WPWebViewController alloc] init];
	[controller setUrl:((DTLinkButton *)sender).URL];
	[self.panelNavigationController pushViewController:controller animated:YES];
}


- (void)handleReblogButtonTapped:(id)sender {
	NSLog(@"Reblog tapped");
	[self.post reblogPostToSite:nil success:^{
		
	} failure:^(NSError *error) {
		[self updateToolbar];
	}];
	[self updateToolbar];
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


- (void)handleTitleButtonTapped:(id)sender {
	NSLog(@"Title Tapped");
	
	WPWebViewController *controller = [[WPWebViewController alloc] init];
	[controller setUrl:[NSURL URLWithString:self.post.permaLink]];
	[self.panelNavigationController pushViewController:controller animated:YES];
}


- (void)handleVideoTapped:(id)sender {
	ReaderVideoView *videoView = (ReaderVideoView *)sender;
	if(videoView.contentType == ReaderVideoContentTypeVideo) {
		
		MPMoviePlayerViewController *controller = [[MPMoviePlayerViewController alloc] initWithContentURL:videoView.contentURL];
		controller.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
		controller.modalPresentationStyle = UIModalPresentationFormSheet;
		[self.panelNavigationController presentModalViewController:controller animated:YES];
		
	} else {
		// Should either be an iframe, or an object embed. In either case a src attribute should have been parsed for the contentURL.
		// Assume this is content we can show and try to load it.
		WPWebVideoViewController *controller = [WPWebVideoViewController presentAsModalWithURL:videoView.contentURL];
		controller.title = (videoView.title != nil) ? videoView.title : @"Video";
	}
}


- (void)handleMediaViewLoaded:(ReaderMediaView *)mediaView {
	
	[self updateMediaLayout:mediaView];
	
	// need to reset the layouter because otherwise we get the old framesetter or cached layout frames
	self.textContentView.layouter = nil;
	
	// layout might have changed due to image sizes
	[self.textContentView relayoutText];
	
	[self updateLayout];
}


- (void)handleCloseModal:(id)sender {
	[self dismissModalViewControllerAnimated:YES];
}


#pragma mark - Sync methods

- (void)syncWithUserInteraction:(BOOL)userInteraction {
	
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
    }
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	cell.accessoryType = UITableViewCellAccessoryNone;
		
	ReaderComment *comment = [_comments objectAtIndex:indexPath.row];
	[cell configureCell:comment];

	return cell;	
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}


- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}


- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
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


#pragma mark - DTCoreAttributedTextContentView Delegate Methods

- (UIView *)attributedTextContentView:(DTAttributedTextContentView *)attributedTextContentView viewForAttributedString:(NSAttributedString *)string frame:(CGRect)frame {
	NSDictionary *attributes = [string attributesAtIndex:0 effectiveRange:NULL];
	
	NSURL *URL = [attributes objectForKey:DTLinkAttribute];
	NSString *identifier = [attributes objectForKey:DTGUIDAttribute];
	
	DTLinkButton *button = [[DTLinkButton alloc] initWithFrame:frame];
	button.URL = URL;
	button.minimumHitSize = CGSizeMake(25, 25); // adjusts it's bounds so that button is always large enough
	button.GUID = identifier;
	
	// get image with normal link text
	UIImage *normalImage = [attributedTextContentView contentImageWithBounds:frame options:DTCoreTextLayoutFrameDrawingDefault];
	[button setImage:normalImage forState:UIControlStateNormal];
	
	// get image for highlighted link text
	UIImage *highlightImage = [attributedTextContentView contentImageWithBounds:frame options:DTCoreTextLayoutFrameDrawingDrawLinksHighlighted];
	[button setImage:highlightImage forState:UIControlStateHighlighted];
	
	// use normal push action for opening URL
	[button addTarget:self action:@selector(handleLinkTapped:) forControlEvents:UIControlEventTouchUpInside];

	return button;
}


- (UIView *)attributedTextContentView:(DTAttributedTextContentView *)attributedTextContentView viewForAttachment:(DTTextAttachment *)attachment frame:(CGRect)frame {
	
	if (attachment.contentType == DTTextAttachmentTypeImage) {
		
		ReaderImageView *imageView = [[ReaderImageView alloc] initWithFrame:frame];
		[_mediaArray addObject:imageView];
		imageView.linkURL = attachment.hyperLinkURL;
		[imageView addTarget:self action:@selector(handleImageLinkTapped:) forControlEvents:UIControlEventTouchUpInside];
		
		if (attachment.contents) {
			[imageView setImage:(UIImage *)attachment.contents];
		} else {
			[imageView setImageWithURL:attachment.contentURL
					  placeholderImage:[UIImage imageNamed:@""]
							   success:^(id readerImageView) {
								   [self handleMediaViewLoaded:readerImageView];
							   } failure:^(id readerImageView, NSError *error) {
								   [self handleMediaViewLoaded:readerImageView];
							   }];
		}
		return imageView;
		
	} else {
		
		ReaderVideoContentType videoType;
		
		if (attachment.contentType == DTTextAttachmentTypeVideoURL) {
			videoType = ReaderVideoContentTypeVideo;
		} else if (attachment.contentType == DTTextAttachmentTypeIframe) {
			videoType = ReaderVideoContentTypeIFrame;
		} else if (attachment.contentType == DTTextAttachmentTypeObject) {
			videoType = ReaderVideoContentTypeEmbed;
		} else {
			return nil; // Can't handle whatever this is :P
		}
		
		ReaderVideoView *videoView = [[ReaderVideoView alloc] initWithFrame:frame];
		[_mediaArray addObject:videoView];
		[videoView setContentURL:attachment.contentURL ofType:videoType success:^(id readerVideoView) {
			[self handleMediaViewLoaded:readerVideoView];
			
		} failure:^(id readerVideoView, NSError *error) {
			[self handleMediaViewLoaded:readerVideoView];
			
		}];
		
		[videoView addTarget:self action:@selector(handleVideoTapped:) forControlEvents:UIControlEventTouchUpInside];

		[self handleMediaViewLoaded:videoView];
		return videoView;
	}

}

@end
