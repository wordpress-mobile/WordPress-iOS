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

@interface ReaderPostDetailViewController ()<DTAttributedTextContentViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) DTAttributedTextContentView *textContentView;
@property (nonatomic, strong) NSMutableSet *mediaPlayers;
@property (nonatomic, strong) UIActionSheet *linkOptionsActionSheet;
@property (nonatomic, strong) NSMutableArray *mediaArray;

- (void)updateLayout;
- (void)updateMediaLayout:(id<ReaderMediaView>)imageView;
- (void)handleLinkTapped:(id)sender;
- (BOOL)setMFMailFieldAsFirstResponder:(UIView*)view mfMailField:(NSString*)field;
- (void)handleImageViewLoaded:(ReaderImageView *)imageView;
- (void)handleCloseModal:(id)sender;

@end

@implementation ReaderPostDetailViewController

@synthesize post;

#pragma mark - LifeCycle Methods

- (void)dealloc {
	
}


- (id)initWithPost:(ReaderPost *)apost {
	self = [super initWithStyle:UITableViewStylePlain];
	if(self) {
		self.post = apost;
		self.mediaArray = [NSMutableArray array];
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
	
	self.likeButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@""] style:UIBarButtonItemStylePlain target:self action:@selector(handleLikeButtonTapped:)];
	self.followButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@""] style:UIBarButtonItemStylePlain target:self action:@selector(handleFollowButtonTapped:)];
	self.reblogButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@""] style:UIBarButtonItemStylePlain target:self action:@selector(handleReblogButtonTapped:)];
	self.actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(handleActionButtonTapped:)];
	UIBarButtonItem *placeholder = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	[self setToolbarItems:@[placeholder, _likeButton, placeholder, _followButton, placeholder, _reblogButton, placeholder, _actionButton, placeholder] animated:YES];
	self.navigationController.toolbarHidden = NO;
	
	CGRect frame = self.tableView.frame;
	self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, frame.size.width, 44.0f)];
	_contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	
	self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, frame.size.width, 44.0f)];
	_headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	_headerView.backgroundColor = [UIColor colorWithWhite:0.9f alpha:1.0];
	
	self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(44.0f, 0.0f, frame.size.width - 76.0f, 44.0f)];
	_titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	_titleLabel.text = [self.post.blogName stringByReplacingHTMLEntities];
	_titleLabel.backgroundColor = [UIColor clearColor];
	
	self.blavatarImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 44.0f, 44.0f)];
	[_blavatarImageView setImageWithBlavatarUrl:[self.post blogURL]];
	
	UIImageView *disclosureImage = [[UIImageView alloc] initWithFrame:CGRectMake(frame.size.width - 32.0f, 11.0f, 22.0f, 22.0f)];
	disclosureImage.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
	disclosureImage.image = [UIImage imageNamed:@""];

	[_headerView addSubview:disclosureImage];
	[_headerView addSubview:_blavatarImageView];
	[_headerView addSubview:_titleLabel];
	[_contentView addSubview:_headerView];
	
	self.textContentView = [[DTAttributedTextContentView alloc] initWithFrame:CGRectMake(0.0f, 44.0f, self.view.frame.size.width, 44.0f)];
	_textContentView.delegate = self;
	_textContentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_textContentView.backgroundColor = [UIColor clearColor];
	_textContentView.edgeInsets = UIEdgeInsetsMake(0.f, 10.f, 0.f, 10.f);
	_textContentView.shouldDrawImages = NO;
	_textContentView.shouldDrawLinks = NO;
	[_contentView addSubview:_textContentView];
	
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:@{
														  DTDefaultFontFamily: @"Helvetica",
										   NSTextSizeMultiplierDocumentOption: [NSNumber numberWithFloat:1.3]
								 }];
	_textContentView.attributedString = [[NSAttributedString alloc] initWithHTMLData:[post.content dataUsingEncoding:NSUTF8StringEncoding] options:dict documentAttributes:NULL];
	
	[self updateLayout];
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];

	// Figure out image sizes after orientation change.
	for (id<ReaderMediaView>mediaView in _mediaArray) {
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

- (void)updateLayout {
	// Size the textContentView
	CGFloat height = [_textContentView suggestedFrameSizeToFitEntireStringConstraintedToWidth:self.view.frame.size.width].height;
	CGRect frame = CGRectMake(0.0f, 44.0f, self.view.frame.size.width, height);
	_textContentView.frame = frame;
	
	// Size the scrollView's content view.
	frame = self.contentView.frame;
	frame.size.width = self.tableView.frame.size.width;
	frame.size.height = 64.0f + height;
	_contentView.frame = frame;
	
	[self.tableView reloadData];
}


- (void)updateMediaLayout:(id<ReaderMediaView>)imageView {

	NSURL *url = imageView.contentURL;
	
	CGSize viewSize = imageView.image.size;
	
	// First the imageView
	CGFloat width = _textContentView.frame.size.width;
	CGRect frame = UIEdgeInsetsInsetRect(_textContentView.frame, _textContentView.edgeInsets);
	if(imageView.image.size.width > frame.size.width) {
		
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
	}
	
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
	[self setToolbarItems:@[placeholder, _likeButton, placeholder, _followButton, placeholder, _reblogButton, placeholder, _actionButton, placeholder] animated:YES];
}


- (void)handleTitleButtonTapped:(id)sender {
	NSLog(@"Title Tapped");
	
	WPWebViewController *controller = [[WPWebViewController alloc] init];
	[controller setUrl:[NSURL URLWithString:self.post.permaLink]];
	[self.panelNavigationController pushViewController:controller animated:YES];
}


- (void)handleLikeButtonTapped:(id)sender {
	NSLog(@"Like Tapped");
	[self.post toggleLikedWithSuccess:^{
		
	} failure:^(NSError *error) {
		[self updateToolbar];
	}];
	[self updateToolbar];
}


- (void)handleFollowButtonTapped:(id)sender {
	NSLog(@"Follow tapped");
	[self.post toggleFollowingWithSuccess:^{
		
	} failure:^(NSError *error) {
		[self updateToolbar];
	}];
	[self updateToolbar];
}


- (void)handleReblogButtonTapped:(id)sender {
	NSLog(@"Reblog tapped");
	[self.post reblogPostToSite:nil success:^{
		
	} failure:^(NSError *error) {
		[self updateToolbar];
	}];
	[self updateToolbar];
}


- (void)handleActionButtonTapped:(id)sender {
	
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
        [self.linkOptionsActionSheet showFromBarButtonItem:self.actionButton animated:YES];
    } else {
        [self.linkOptionsActionSheet showInView:self.view];
    }
	
}


- (void)handleLinkTapped:(id)sender {
	WPWebViewController *controller = [[WPWebViewController alloc] init];
	[controller setUrl:((DTLinkButton *)sender).URL];
	[self.panelNavigationController pushViewController:controller animated:YES];
}


- (void)handleImageViewLoaded:(ReaderImageView *)imageView {
	
	[self updateMediaLayout:imageView];
	
	// need to reset the layouter because otherwise we get the old framesetter or cached layout frames
	self.textContentView.layouter = nil;
	
	// layout might have changed due to image sizes
	[self.textContentView relayoutText];
	
	[self updateLayout];
}


- (void)handleImageLinkURL:(id)sender {	
	WPWebViewController *controller = [[WPWebViewController alloc] init];
	[controller setUrl:((ReaderImageView *)sender).linkURL];
	[self.panelNavigationController pushViewController:controller animated:YES];
}


- (void)handleVideoTapped:(id)sender {
	ReaderVideoView *videoView = (ReaderVideoView *)sender;
	if(videoView.contentType == ReaderVideoContentTypeVideo) {
		
		MPMoviePlayerViewController *controller = [[MPMoviePlayerViewController alloc] initWithContentURL:videoView.contentURL];
		controller.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
		controller.modalPresentationStyle = UIModalPresentationFormSheet;
		[self.panelNavigationController presentModalViewController:controller animated:YES];
		
	} else if(videoView.contentType == ReaderVideoContentTypeIFrame) {
		
		WPWebViewController *controller = [[WPWebViewController alloc] init];
		[controller setUrl:videoView.contentURL];
		
		UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(handleCloseModal:)];
		controller.navigationItem.leftBarButtonItem = closeButton;
		
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
		navController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
		navController.modalPresentationStyle = UIModalPresentationFormSheet;
		[self.panelNavigationController presentModalViewController:navController animated:YES];
		
	} else if (videoView.contentType == ReaderVideoContentTypeEmbed) {
		// TODO: hmm... gonna be a webview and we'll set its content I suppose.
	}
}


- (void)handleCloseModal:(id)sender {
	[self dismissModalViewControllerAnimated:YES];
}


#pragma mark - UITableView Delegate Methods

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	if (section != 0) return nil;
	
	return _contentView;
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	if (section != 0) return 0.0f;
	
	return _contentView.frame.size.height;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.post.comments count]; // number of comments
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ReaderCommentCell"];
	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ReaderCommentCell"];
	}
	return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
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
		
		if (attachment.hyperLinkURL) {
			imageView.linkURL = attachment.hyperLinkURL;
			[imageView addTarget:self action:@selector(handleImageLinkURL:) forControlEvents:UIControlEventTouchUpInside];
		}
		
		if (attachment.contents) {
			[imageView setImage:attachment.contents];
		} else {
			[imageView setImageWithURL:attachment.contentURL
					  placeholderImage:[UIImage imageNamed:@""]
							   success:^(ReaderImageView *readerImageView) {
								   [self handleImageViewLoaded:readerImageView];
							   } failure:^(ReaderImageView *readerImageView, NSError *error) {
								   [self handleImageViewLoaded:readerImageView];
							   }];
		}
NSLog(@"ATTACHMENT IMAGE VIEW : %@ ", imageView);
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
		[videoView setContentURL:attachment.contentURL andContent:attachment.contents ofType:videoType];
		[videoView addTarget:self action:@selector(handleVideoTapped:) forControlEvents:UIControlEventTouchUpInside];

		[self updateMediaLayout:videoView];
NSLog(@"ATTACHMENT VIDEO VIEW : %@ ", videoView);
		return videoView;
	}

}

@end
