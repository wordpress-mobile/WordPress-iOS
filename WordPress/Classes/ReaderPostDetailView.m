//
//  ReaderPostDetailView.m
//  WordPress
//
//  Created by Eric J on 5/24/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "ReaderPostDetailView.h"
#import <DTCoreText/DTCoreText.h>
#import <MediaPlayer/MediaPlayer.h>
#import <QuartzCore/QuartzCore.h>
#import "DTTiledLayerWithoutFade.h"
#import "ReaderMediaView.h"
#import "ReaderImageView.h"
#import "ReaderVideoView.h"
#import "WPImageViewController.h"
#import "WordPressAppDelegate.h"
#import "WPWebViewController.h"
#import "WPWebVideoViewController.h"
#import "UIImageView+Gravatar.h"
#import "UILabel+SuggestSize.h"
#import "ReaderMediaQueue.h"

#define ContentTextViewYOffset -32

@interface ReaderPostDetailView()<DTAttributedTextContentViewDelegate, ReaderMediaQueueDelegate>

@property (nonatomic, strong) ReaderPost *post;
@property (nonatomic, strong) UIView *authorView;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *authorLabel;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UILabel *blogLabel;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *followButton;
@property (nonatomic, strong) DTAttributedTextContentView *textContentView;
@property (nonatomic, strong) NSMutableArray *mediaArray;
@property (nonatomic, strong) ReaderMediaQueue *mediaQueue;
@property (nonatomic, weak) id<ReaderPostDetailViewDelegate>delegate;

- (void)_updateLayout;
- (void)updateAttributedString:(NSAttributedString *)attrString;
- (BOOL)updateMediaLayout:(ReaderMediaView *)mediaView;
- (void)handleAuthorViewTapped:(id)sender;
- (void)handleImageLinkTapped:(id)sender;
- (void)handleLinkTapped:(id)sender;
- (void)handleVideoTapped:(id)sender;
- (void)handleMediaViewLoaded:(ReaderMediaView *)mediaView;
- (void)handleFollowButtonTapped:(id)sender;
- (void)handleFollowButtonInteraction:(id)sender;
- (BOOL)isEmoji:(NSURL *)url;

@end

@implementation ReaderPostDetailView

- (void)dealloc
{
    _textContentView.delegate = nil;
    _mediaQueue.delegate = nil;
    [_mediaQueue discardQueuedItems];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithFrame:(CGRect)frame post:(ReaderPost *)post delegate:(id<ReaderPostDetailViewDelegate>)delegate {
    self = [super initWithFrame:frame];
    if (self) {

		self.post = post;
		self.delegate = delegate;
		
		self.mediaArray = [NSMutableArray array];
        self.mediaQueue = [[ReaderMediaQueue alloc] initWithDelegate:self];
        
		CGFloat width = frame.size.width;
        CGFloat padding = 20.0f;
        CGFloat labelWidth = width - 100.0f;
        CGFloat labelHeight = 20.0f;
        CGFloat avatarSize = 60.0f;
		
		self.authorView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, width, 80.0f)];
		_authorView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[self addSubview:_authorView];
		
		
		UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
		button.frame = _authorView.frame;
		[button addTarget:self action:@selector(handleAuthorViewTapped:) forControlEvents:UIControlEventTouchUpInside];
		[_authorView addSubview:button];
		
		self.avatarImageView = [[UIImageView alloc] initWithFrame:CGRectMake(padding, padding, avatarSize, avatarSize)];
		_avatarImageView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
				
		if ([post avatar] != nil) {
			[self.avatarImageView setImageWithURL:[NSURL URLWithString:[post avatar]] placeholderImage:[UIImage imageNamed:@"gravatar.jpg"]];
		} else {
			NSString *img = ([post isWPCom]) ? @"wpcom_blavatar.png" : @"wporg_blavatar.png";
			[self.avatarImageView setImageWithURL:[self.avatarImageView blavatarURLForHost:[[NSURL URLWithString:post.blogURL] host]] placeholderImage:[UIImage imageNamed:img]];
		}
		
		[_authorView addSubview:_avatarImageView];
		
		self.authorLabel = [[UILabel alloc] initWithFrame:CGRectMake(avatarSize + padding + 10.0f, padding, labelWidth, labelHeight)];
		_authorLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		_authorLabel.backgroundColor = [UIColor clearColor];
		_authorLabel.font = [UIFont fontWithName:@"OpenSans" size:13.0f];//[UIFont boldSystemFontOfSize:14.0f];
		_authorLabel.text = (self.post.author != nil) ? self.post.author : self.post.authorDisplayName;
		_authorLabel.textColor = [UIColor colorWithHexString:@"404040"];
		[_authorView addSubview:_authorLabel];
		
		self.dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(avatarSize + padding + 10.0f, padding + labelHeight, labelWidth, labelHeight)];
		_dateLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		_dateLabel.backgroundColor = [UIColor clearColor];
		_dateLabel.font = [UIFont fontWithName:@"OpenSans" size:13.0f];//[UIFont systemFontOfSize:14.0f];
		_dateLabel.text = [NSString stringWithFormat:@"%@ on", [self.post prettyDateString]];
		_dateLabel.textColor = [UIColor colorWithHexString:@"404040"];//[UIColor colorWithHexString:@"aaaaaa"];
		[_authorView addSubview:_dateLabel];
		
		self.blogLabel = [[UILabel alloc] initWithFrame:CGRectMake(avatarSize + padding + 10.0f, padding + labelHeight * 2, labelWidth, labelHeight)];
		_blogLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		_blogLabel.backgroundColor = [UIColor clearColor];
		_blogLabel.font = [UIFont fontWithName:@"OpenSans" size:13.0f];//[UIFont systemFontOfSize:14.0f];
		_blogLabel.text = self.post.blogName;
		_blogLabel.textColor = [UIColor colorWithHexString:@"278dbc"];
		[_authorView addSubview:_blogLabel];
		
		CGRect followFrame = _blogLabel.frame;
		followFrame.origin.y += 2.0f;
		followFrame.size.height += 4.0f;
		self.followButton = [UIButton buttonWithType:UIButtonTypeCustom];
		_followButton.frame = followFrame; // Arbitrary width and x. The height and y are correct.
		[_followButton setSelected:[post.isFollowing boolValue]];
		_followButton.layer.cornerRadius = 3.0f;
		_followButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
		_followButton.backgroundColor = [UIColor colorWithRed:234.0f/255.0f green:234.0f/255.0f blue:234.0f/255.0f alpha:1.0f];
		_followButton.titleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:10.0f];
        NSString *followString = NSLocalizedString(@"Follow", @"Prompt to follow a blog.");
        NSString *followedString = NSLocalizedString(@"Following", @"User is following the blog.");
        // -[NSString uppercaseStringWithLocale:] available since iOS6
        if ([followString respondsToSelector:@selector(uppercaseStringWithLocale:)]) {
            followString = [followString uppercaseStringWithLocale:[NSLocale currentLocale]];
            followedString = [followedString uppercaseStringWithLocale:[NSLocale currentLocale]];
        } else {
            followString = [followString uppercaseString];
            followedString = [followedString uppercaseString];
        }
		[_followButton setTitle:followString forState:UIControlStateNormal];
		[_followButton setTitle:followedString forState:UIControlStateSelected];
		[_followButton setImage:[UIImage imageNamed:@"reader-postaction-follow"] forState:UIControlStateNormal];
		[_followButton setImage:[UIImage imageNamed:@"reader-postaction-following"] forState:UIControlStateSelected];
		[_followButton setTitleColor:[UIColor colorWithRed:116.0f/255.0f green:116.0f/255.0f blue:116.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
		[_followButton addTarget:self action:@selector(handleFollowButtonInteraction:) forControlEvents:UIControlEventAllTouchEvents];
		[_followButton addTarget:self action:@selector(handleFollowButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
		
		[_authorView addSubview:_followButton];
		
		CGFloat contentY = _authorView.frame.size.height;
		
		if ([self.post.postTitle length]) {		
			CGRect titleFrame = CGRectMake(padding, contentY + padding, width - (padding * 2), 44.0f);
			self.titleLabel = [[UILabel alloc] initWithFrame:titleFrame];
			_titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
			_titleLabel.backgroundColor = [UIColor whiteColor];
			_titleLabel.font = [WPStyleGuide largePostTitleFont];
			_titleLabel.textColor = [WPStyleGuide littleEddieGrey];
			_titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
			_titleLabel.numberOfLines = 0;
            if (IS_IOS7) {
                _titleLabel.attributedText = [[NSAttributedString alloc] initWithString:self.post.postTitle attributes:[WPStyleGuide largePostTitleAttributes]];
            } else {
                _titleLabel.text = self.post.postTitle;
            }
			[self addSubview:_titleLabel];
			titleFrame.size.height = [_titleLabel suggestedSizeForWidth:_titleLabel.frame.size.width].height;
			_titleLabel.frame = titleFrame;
			contentY = titleFrame.origin.y + titleFrame.size.height;
		}

		[DTAttributedTextContentView setLayerClass:[DTTiledLayerWithoutFade class]];
		self.textContentView = [[DTAttributedTextContentView alloc] initWithFrame:CGRectMake(0.0f, contentY + ContentTextViewYOffset, width, 100.0f)]; // Starting height is arbitrary
		_textContentView.delegate = self;
		_textContentView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		_textContentView.backgroundColor = [UIColor whiteColor];
		_textContentView.edgeInsets = UIEdgeInsetsMake(0.0f, padding, 0.0f, padding);
		_textContentView.shouldDrawImages = NO;
		_textContentView.shouldDrawLinks = NO;
		[self addSubview:_textContentView];
		
		// There seems to be a bug with DTCoreText causing images on the first line to have a negative y origin.
		// As a work around, let the first line always be empty. We shift the text view's origin to compensate.
		NSString *str = [NSString stringWithFormat:@"<p> </p>%@", self.post.content];
		[self updateAttributedString: [[NSAttributedString alloc] initWithHTMLData:[str dataUsingEncoding:NSUTF8StringEncoding]
																		   options:[WPStyleGuide defaultDTCoreTextOptions]
																documentAttributes:nil]];
		[self sendSubviewToBack:_textContentView];
    }
    return self;
}


- (void)updateAttributedString:(NSAttributedString *)attrString {
	_textContentView.attributedString = attrString;
}


- (void)layoutSubviews {
	[super layoutSubviews];
	
	NSString *str = _followButton.currentTitle;
	CGSize sz = [str sizeWithFont:_followButton.titleLabel.font];
	[_followButton sizeToFit];
	sz = _followButton.frame.size;
	sz.width += 5.0f; // just a little extra width so the text has better padding on the right.
	
	CGFloat desiredWidth = [_blogLabel.text sizeWithFont:_blogLabel.font].width;
	CGFloat availableWidth = (_authorView.frame.size.width - _blogLabel.frame.origin.x) - 20.0f;
	availableWidth -= (sz.width + 10.0f);

	CGRect frame = _blogLabel.frame;
	frame.size.width = MIN(availableWidth, desiredWidth);
	_blogLabel.frame = frame;
	
	frame = _followButton.frame;
	frame.origin.x = _blogLabel.frame.origin.x + _blogLabel.frame.size.width + 5.0f;
	frame.size.width = sz.width;
	_followButton.frame = frame;
}


- (void)updateLayout {
	// Figure out image sizes after orientation change.
	for (ReaderMediaView *mediaView in _mediaArray) {
		[self updateMediaLayout:mediaView];
	}

	if (_titleLabel) {
		CGRect titleFrame = _titleLabel.frame;
		titleFrame.size.height = [_titleLabel suggestedSizeForWidth:titleFrame.size.width].height;
        titleFrame = CGRectIntegral(titleFrame);
		_titleLabel.frame = titleFrame;
		
		CGRect contentFrame = _textContentView.frame;
		contentFrame.origin.y = titleFrame.origin.y + titleFrame.size.height + ContentTextViewYOffset;
		_textContentView.frame = contentFrame;
	}
	
	// Then update the layout
	// need to reset the layouter because otherwise we get the old framesetter or cached layout frames
	_textContentView.layouter = nil;

	// layout might have changed due to image sizes
	[_textContentView relayoutText];

	[self _updateLayout];
}


- (void)_updateLayout {
	// Size the textContentView
	CGRect frame = _textContentView.frame;
	CGFloat height = [_textContentView suggestedFrameSizeToFitEntireStringConstraintedToWidth:frame.size.width].height;
	frame.size.height = height;
	_textContentView.frame = frame;
	
	frame = self.frame;
	frame.size.height = height + _textContentView.frame.origin.y + 10.0f; // + bottom padding
	self.frame = frame;
	
	[self.delegate readerPostDetailViewLayoutChanged];
}


- (BOOL)updateMediaLayout:(ReaderMediaView *)imageView {
    BOOL frameChanged = NO;
	NSURL *url = imageView.contentURL;
	
	CGSize originalSize = imageView.frame.size;
	CGSize viewSize = imageView.image.size;
	
	if ([self isEmoji:url]) {
		CGFloat scale = [UIScreen mainScreen].scale;
		viewSize.width *= scale;
		viewSize.height *= scale;
	} else {
        CGFloat ratio = viewSize.width / viewSize.height;
        CGFloat width = _textContentView.frame.size.width;
        CGFloat availableWidth = _textContentView.frame.size.width - (_textContentView.edgeInsets.left + _textContentView.edgeInsets.right);
        
        viewSize.width = availableWidth;
        
        if (imageView.isShowingPlaceholder) {
            viewSize.height = roundf(width / imageView.placeholderRatio);
        } else {
            viewSize.height = roundf(width / ratio);
        }

        viewSize.height += imageView.edgeInsets.top; // account for the top edge inset.
	}

    // Widths should always match
    if (viewSize.height != originalSize.height) {
        frameChanged = YES;
    }
    
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"contentURL == %@", url];
	
	// update all attachments that matchin this URL (possibly multiple images with same size)
	for (DTTextAttachment *attachment in [self.textContentView.layoutFrame textAttachmentsWithPredicate:pred]) {
		attachment.originalSize = originalSize;
		attachment.displaySize = viewSize;
	}
    
    return frameChanged;
}


- (BOOL)isEmoji:(NSURL *)url {
	return ([[url absoluteString] rangeOfString:@"wp.com/wp-includes/images/smilies"].location != NSNotFound);
}


- (void)handleFollowButtonInteraction:(id)sender {
	[self setNeedsLayout];
}


- (void)handleFollowButtonTapped:(id)sender {
	self.followButton.selected = ![self.post.isFollowing boolValue]; // to fake the call.
	[self setNeedsLayout];
	[self.post toggleFollowingWithSuccess:^{
		self.followButton.selected = [self.post.isFollowing boolValue]; // for good measure!
		[self setNeedsLayout];
	} failure:^(NSError *error) {
		DDLogError(@"Error Following Blog : %@", [error localizedDescription]);
		[_followButton setSelected:self.post.isFollowing];
		[self setNeedsLayout];
		
		NSString *title;
		NSString *description;
		if (self.post.isFollowing) {
			title = NSLocalizedString(@"Could Not Unfollow Blog", @"Title of prompt. Says a blog could not be unfollowed.");
			description = NSLocalizedString(@"There was a problem unfollowing this blog.", @"Prompts the user that there was a problem unfollowing a blog.");
		} else {
			title = NSLocalizedString(@"Could Not Follow Blog", @"Title of prompt. Says a blog could not be followed.");
			description = NSLocalizedString(@"There was a problem following this blog.", @"Prompts the user there was a problem following a blog.");
		}
		
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
															message:description
														   delegate:nil
												  cancelButtonTitle:NSLocalizedString(@"OK", @"")
												  otherButtonTitles:nil];
		[alertView show];
		
	}];
	[_followButton setSelected:self.post.isFollowing];
	[self setNeedsLayout];
}


- (void)handleAuthorViewTapped:(id)sender {
	WPWebViewController *controller = [[WPWebViewController alloc] init];
	[controller setUrl:[NSURL URLWithString:self.post.permaLink]];
	[[[WordPressAppDelegate sharedWordPressApplicationDelegate] panelNavigationController] pushViewController:controller animated:YES];
}


- (void)handleImageLinkTapped:(id)sender {
	ReaderImageView *imageView = (ReaderImageView *)sender;
	
	if(imageView.linkURL) {
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
			[WPImageViewController presentAsModalWithImage:imageView.image andURL:((ReaderImageView *)sender).linkURL];
//			[WPImageViewController presentAsModalWithURL:((ReaderImageView *)sender).linkURL];
		} else {
			WPWebViewController *controller = [[WPWebViewController alloc] init];
			[controller setUrl:((ReaderImageView *)sender).linkURL];
			[[[WordPressAppDelegate sharedWordPressApplicationDelegate] panelNavigationController] pushViewController:controller animated:YES];
		}
	} else {
		[WPImageViewController presentAsModalWithImage:imageView.image];
	}
}


- (void)handleLinkTapped:(id)sender {
	WPWebViewController *controller = [[WPWebViewController alloc] init];
	[controller setUrl:((DTLinkButton *)sender).URL];
	[[[WordPressAppDelegate sharedWordPressApplicationDelegate] panelNavigationController] pushViewController:controller animated:YES];
}


- (void)handleVideoTapped:(id)sender {
	ReaderVideoView *videoView = (ReaderVideoView *)sender;
	if(videoView.contentType == ReaderVideoContentTypeVideo) {
		
		MPMoviePlayerViewController *controller = [[MPMoviePlayerViewController alloc] initWithContentURL:videoView.contentURL];
        // Remove the movie player view controller from the "playback did finish" notification observers
        [[NSNotificationCenter defaultCenter] removeObserver:controller
                                                        name:MPMoviePlayerPlaybackDidFinishNotification
                                                      object:controller.moviePlayer];
        
        // Register this class as an observer instead
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleMoviePlaybackFinishedNotification:)
                                                     name:MPMoviePlayerPlaybackDidFinishNotification
                                                   object:controller.moviePlayer];
        
		controller.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
		controller.modalPresentationStyle = UIModalPresentationFormSheet;
        [[[WordPressAppDelegate sharedWordPressApplicationDelegate] panelNavigationController] presentViewController:controller animated:YES completion:nil];
		
	} else {
		// Should either be an iframe, or an object embed. In either case a src attribute should have been parsed for the contentURL.
		// Assume this is content we can show and try to load it.
		WPWebVideoViewController *controller = [WPWebVideoViewController presentAsModalWithURL:videoView.contentURL];
		controller.title = (videoView.title != nil) ? videoView.title : @"Video";
	}
}


- (void)handleMediaViewLoaded:(ReaderMediaView *)mediaView {
	
	BOOL frameChanged = [self updateMediaLayout:mediaView];
	
    if (frameChanged) {
        // need to reset the layouter because otherwise we get the old framesetter or cached layout frames
        self.textContentView.layouter = nil;

        // layout might have changed due to image sizes
        [self.textContentView relayoutText];

        [self _updateLayout];
    }
}


- (void)handleMoviePlaybackFinishedNotification:(NSNotification *)notification {
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
        [[[WordPressAppDelegate sharedWordPressApplicationDelegate] panelNavigationController] dismissViewControllerAnimated:YES completion:nil];
    }
}


#pragma mark - DTCoreAttributedTextContentView Delegate Methods

- (UIView *)attributedTextContentView:(DTAttributedTextContentView *)attributedTextContentView viewForAttributedString:(NSAttributedString *)string frame:(CGRect)frame {
	NSDictionary *attributes = [string attributesAtIndex:0 effectiveRange:nil];
	
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
	
    CGFloat width = _textContentView.frame.size.width;
    CGFloat availableWidth = _textContentView.frame.size.width - (_textContentView.edgeInsets.left + _textContentView.edgeInsets.right);

	// The ReaderImageView view will conform to the width constraints of the _textContentView. We want the image itself to run out to the edges,
	// so position it offset by the inverse of _textContentView's edgeInsets. Also add top padding so we don't bump into a line of text.
	// Remeber to add an extra 10px to the frame to preserve aspect ratio.
	UIEdgeInsets edgeInsets = _textContentView.edgeInsets;
	edgeInsets.left = 0.0f - edgeInsets.left;
	edgeInsets.top = 15.0f;
	edgeInsets.right = 0.0f - edgeInsets.right;
	edgeInsets.bottom = 0.0f;
	
	if ([attachment isKindOfClass:[DTImageTextAttachment class]]) {
		if ([self isEmoji:attachment.contentURL]) {
			// minimal frame to suppress drawing context errors with 0 height or width.
			frame.size.width = MAX(frame.size.width, 1.0f);
			frame.size.height = MAX(frame.size.height, 1.0f);
			ReaderImageView *imageView = [[ReaderImageView alloc] initWithFrame:frame];
            [_mediaArray addObject:imageView];
            [self.mediaQueue enqueueMedia:imageView
                                  withURL:attachment.contentURL
                         placeholderImage:nil
                                     size:CGSizeMake(15.0f, 15.0f)
                                isPrivate:self.post.isPrivate
                                  success:nil
                                  failure:nil];
			return imageView;
		}
		
        DTImageTextAttachment *imageAttachment = (DTImageTextAttachment *)attachment;
		UIImage *image;
		
		if( [imageAttachment.image isKindOfClass:[UIImage class]] ) {
			image = imageAttachment.image;
			
            CGFloat ratio = image.size.width / image.size.height;
            frame.size.width = availableWidth;
            frame.size.height = roundf(width / ratio);
		} else {
			image = [UIImage imageNamed:@"wp_img_placeholder.png"];

			if (frame.size.width > 1.0f && frame.size.height > 1.0f) {
                CGFloat ratio = frame.size.width / frame.size.height;
                frame.size.width = availableWidth;
                frame.size.height = roundf(width / ratio);
            } else {
                frame.size.width = availableWidth;
                frame.size.height = roundf(width * 0.66f);
            }
		}
		
		// offset the top edge inset keeping the image from bumping the text above it.
		frame.size.height += edgeInsets.top;
		
		ReaderImageView *imageView = [[ReaderImageView alloc] initWithFrame:frame];
		imageView.contentMode = UIViewContentModeScaleAspectFit;
		imageView.edgeInsets = edgeInsets;

		[_mediaArray addObject:imageView];
		imageView.linkURL = attachment.hyperLinkURL;
		[imageView addTarget:self action:@selector(handleImageLinkTapped:) forControlEvents:UIControlEventTouchUpInside];
		
		if ([imageAttachment.image isKindOfClass:[UIImage class]]) {
			[imageView setImage:image];
		} else {
			imageView.contentMode = UIViewContentModeCenter;
			imageView.backgroundColor = [UIColor colorWithRed:192.0f/255.0f green:192.0f/255.0f blue:192.0f/255.0f alpha:1.0];
            
            [self.mediaQueue enqueueMedia:imageView
                                  withURL:attachment.contentURL
                         placeholderImage:image
                                     size:CGSizeMake(width, 0)
                                isPrivate:self.post.isPrivate
                                  success:^(ReaderMediaView *readerMediaView) {
                                      ReaderImageView *imageView = (ReaderImageView *)readerMediaView;
                                      imageView.contentMode = UIViewContentModeScaleAspectFit;
                                      imageView.backgroundColor = [UIColor clearColor];
                                  }
                                  failure:nil];
		}

		return imageView;
		
	} else {
		
		ReaderVideoContentType videoType;
		
		if ([attachment isKindOfClass:[DTVideoTextAttachment class]]) {
			videoType = ReaderVideoContentTypeVideo;
		} else if ([attachment isKindOfClass:[DTIframeTextAttachment class]]) {
			videoType = ReaderVideoContentTypeIFrame;
		} else if ([attachment isKindOfClass:[DTObjectTextAttachment class]]) {
			videoType = ReaderVideoContentTypeEmbed;
		} else {
			return nil; // Can't handle whatever this is :P
		}
	
		// make sure we have a reasonable size.
		if (frame.size.width > width) {
            if (frame.size.height == 0) {
                frame.size.height = roundf(frame.size.width * 0.66f);
            }
            CGFloat ratio = frame.size.width / frame.size.height;
            frame.size.width = availableWidth;
            frame.size.height = roundf(width / ratio);
		}
		
		// offset the top edge inset keeping the image from bumping the text above it.
		frame.size.height += edgeInsets.top;

		ReaderVideoView *videoView = [[ReaderVideoView alloc] initWithFrame:frame];
		videoView.contentMode = UIViewContentModeCenter;
		videoView.backgroundColor = [UIColor colorWithRed:192.0f/255.0f green:192.0f/255.0f blue:192.0f/255.0f alpha:1.0];
		videoView.edgeInsets = edgeInsets;

		[_mediaArray addObject:videoView];
		[videoView setContentURL:attachment.contentURL ofType:videoType success:^(id readerVideoView) {
			[(ReaderVideoView *)readerVideoView setContentMode:UIViewContentModeScaleAspectFit];
			[self handleMediaViewLoaded:readerVideoView];
		} failure:^(id readerVideoView, NSError *error) {
			[self handleMediaViewLoaded:readerVideoView];
			
		}];
        
		[videoView addTarget:self action:@selector(handleVideoTapped:) forControlEvents:UIControlEventTouchUpInside];

		return videoView;
	}
	
}

#pragma mark ReaderMediaQueueDelegate methods

- (void)readerMediaQueue:(ReaderMediaQueue *)mediaQueue didLoadBatch:(NSArray *)batch {
    BOOL frameChanged = NO;
    
    for (NSInteger i = 0; i < [batch count]; i++) {
        ReaderMediaView *mediaView = [batch objectAtIndex:i];
        if ([self updateMediaLayout:mediaView]) {
            frameChanged = YES;
        }
    }

    if (frameChanged) {
        // need to reset the layouter because otherwise we get the old framesetter or cached layout frames
        self.textContentView.layouter = nil;
        
        // layout might have changed due to image sizes
        [self.textContentView relayoutText];
        
        [self _updateLayout];
    }
}

@end
