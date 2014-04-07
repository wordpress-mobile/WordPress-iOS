#import "WPContentView.h"
#import "WPContentViewSubclass.h"

#import <DTCoreText/DTCoreText.h>
#import "UIImageView+Gravatar.h"
#import "WordPressAppDelegate.h"
#import "WPWebViewController.h"
#import "UIImageView+AFNetworkingExtra.h"
#import "UILabel+SuggestSize.h"
#import "WPAvatarSource.h"
#import "ContentActionButton.h"
#import "NSDate+StringFormatting.h"
#import "UIColor+Helpers.h"
#import "UIImage+Util.h"
#import "WPTableViewCell.h"
#import "DTTiledLayerWithoutFade.h"
#import "ReaderMediaView.h"
#import "ReaderImageView.h"
#import "ReaderVideoView.h"

const CGFloat RPVAuthorPadding = 8.0f;
const CGFloat RPVHorizontalInnerPadding = 12.0f;
const CGFloat RPVMetaViewHeight = 48.0f;
const CGFloat RPVAuthorViewHeight = 32.0f;
const CGFloat RPVVerticalPadding = 14.0f;
const CGFloat RPVAvatarSize = 32.0f;
const CGFloat RPVBorderHeight = 1.0f;
const CGFloat RPVMaxImageHeightPercentage = 0.59f;
const CGFloat RPVMaxSummaryHeight = 88.0f;
const CGFloat RPVFollowButtonWidth = 100.0f;
const CGFloat RPVTitlePaddingBottom = 3.0f;
const CGFloat RPVSmallButtonLeftPadding = 2; // Follow, tag
const CGFloat RPVLineHeightMultiple = 1.03f;

// Control buttons (Like, Reblog, ...)
const CGFloat RPVControlButtonHeight = 48.0f;
const CGFloat RPVControlButtonWidth = 48.0f;
const CGFloat RPVControlButtonSpacing = 12.0f;
const CGFloat RPVControlButtonBorderSize = 0.0f;

@interface WPContentView()

@property (nonatomic, strong) NSTimer *dateRefreshTimer;
@property (nonatomic, strong) NSMutableArray *mediaArray;
@property (nonatomic, strong) ReaderMediaQueue *mediaQueue;
@property (nonatomic, strong) NSMutableArray *actionButtons;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *snippetLabel;
@property (nonatomic, strong) DTAttributedTextContentView *textContentView;
@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, strong) CALayer *bottomBorder;
@property (nonatomic, strong) CALayer *titleBorder;
@property (nonatomic, strong) UIView *byView;
@property (nonatomic, strong) UIView *controlView;
@property (nonatomic, strong) UIButton *timeButton;
@property (nonatomic, strong) UILabel *bylineLabel;
@property (nonatomic, strong) UIButton *byButton;
@property (nonatomic, assign) BOOL willRefreshMediaLayout;

@end

@implementation WPContentView {
}

+ (UIFont *)titleFont {
    return (IS_IPAD ? [UIFont fontWithName:@"Merriweather-Bold" size:24.0f] : [UIFont fontWithName:@"Merriweather-Bold" size:19.0f]);
}

+ (UIFont *)summaryFont {
    return (IS_IPAD ? [UIFont fontWithName:@"OpenSans" size:16.0f] : [UIFont fontWithName:@"OpenSans" size:14.0f]);
}

+ (UIFont *)moreContentFont {
    return [UIFont fontWithName:@"OpenSans" size:12.0f];
}


#pragma mark - Lifecycle Methods

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _mediaArray = [NSMutableArray array];
        _mediaQueue = [[ReaderMediaQueue alloc] initWithDelegate:self];
        _actionButtons = [NSMutableArray arrayWithCapacity:4];

        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.opaque = YES;

        _cellImageView = [[UIImageView alloc] init];
		_cellImageView.backgroundColor = [WPStyleGuide readGrey];
		_cellImageView.contentMode = UIViewContentModeScaleAspectFill;
		_cellImageView.clipsToBounds = YES;
        _cellImageView.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:_cellImageView];

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.textColor = [UIColor colorWithHexString:@"333"];
        _titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _titleLabel.numberOfLines = 0;
        [self addSubview:_titleLabel];
        
        _titleBorder = [[CALayer alloc] init];
        _titleBorder.backgroundColor = [[UIColor colorWithHexString:@"f1f1f1"] CGColor];
        [self.layer addSublayer:_titleBorder];
        
        _byView = [[UIView alloc] init];
        _byView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _byView.backgroundColor = [UIColor clearColor];
        _byView.userInteractionEnabled = YES;
        [self addSubview:_byView];
        
        CGRect avatarFrame = CGRectMake(RPVHorizontalInnerPadding, RPVAuthorPadding, RPVAvatarSize, RPVAvatarSize);
        _avatarImageView = [[UIImageView alloc] initWithFrame:avatarFrame];
        [_byView addSubview:_avatarImageView];
        
        _bylineLabel = [[UILabel alloc] init];
        _bylineLabel.backgroundColor = [UIColor clearColor];
        _bylineLabel.numberOfLines = 1;
        _bylineLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _bylineLabel.font = [UIFont fontWithName:@"OpenSans" size:12.0f];
        _bylineLabel.adjustsFontSizeToFitWidth = NO;
        _bylineLabel.textColor = [UIColor colorWithHexString:@"333"];
        [_byView addSubview:_bylineLabel];
        
        _byButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _byButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        _byButton.backgroundColor = [UIColor clearColor];
        _byButton.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:12.0f];
        [_byButton addTarget:self action:@selector(authorLinkAction:) forControlEvents:UIControlEventTouchUpInside];
        [_byButton setTitleColor:[WPStyleGuide buttonActionColor] forState:UIControlStateNormal];
        [_byView addSubview:_byButton];
        
        _bottomView = [[UIView alloc] init];
        _bottomView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _bottomView.backgroundColor = [UIColor clearColor];
        [self addSubview:_bottomView];
        
        _bottomBorder = [[CALayer alloc] init];
        _bottomBorder.backgroundColor = [[UIColor colorWithHexString:@"f1f1f1"] CGColor];
        [_bottomView.layer addSublayer:_bottomBorder];
        
        _timeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _timeButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        _timeButton.backgroundColor = [UIColor clearColor];
        _timeButton.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:12.0f];
        [_timeButton setTitleEdgeInsets: UIEdgeInsetsMake(0, RPVSmallButtonLeftPadding, 0, 0)];
        
        // Disable it for now (could be used for permalinks in the future)
        [_timeButton setImage:[UIImage imageNamed:@"reader-postaction-time"] forState:UIControlStateDisabled];
        [_timeButton setTitleColor:[UIColor colorWithHexString:@"aaa"] forState:UIControlStateDisabled];
        [_timeButton setEnabled:NO];
        [_bottomView addSubview:_timeButton];
        
        // Update the relative timestamp once per minute
        _dateRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(refreshDate:) userInfo:nil repeats:YES];
    }
    return self;
}

- (void)dealloc {
	_contentProvider = nil;
    _delegate = nil;
    _textContentView.delegate = nil;
    _mediaQueue.delegate = nil;
    [_mediaQueue discardQueuedItems];

    [_dateRefreshTimer invalidate];
    _dateRefreshTimer = nil;
}

- (UIView *)viewForFullContent {
    if (_textContentView)
        return _textContentView;
    
    [DTAttributedTextContentView setLayerClass:[DTTiledLayerWithoutFade class]];
    
    // Needs an initial frame
    _textContentView = [[DTAttributedTextContentView alloc] initWithFrame:self.frame];
    _textContentView.delegate = self;
    _textContentView.backgroundColor = [UIColor whiteColor];
    _textContentView.edgeInsets = UIEdgeInsetsMake(0.0f, RPVHorizontalInnerPadding, 0.0f, RPVHorizontalInnerPadding);
    _textContentView.shouldDrawImages = NO;
    _textContentView.shouldDrawLinks = NO;

    return _textContentView;
}

- (UIView *)viewForContentPreview {
    if (_snippetLabel)
        return _snippetLabel;
    
    _snippetLabel = [[UILabel alloc] init];
    _snippetLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _snippetLabel.backgroundColor = [UIColor clearColor];
    _snippetLabel.textColor = [UIColor colorWithHexString:@"333"];
    _snippetLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    _snippetLabel.numberOfLines = 0;
    
    return _snippetLabel;
}


#pragma mark - Instance methods

- (void)reset {    
	_bylineLabel.text = nil;
	_titleLabel.text = nil;
	_snippetLabel.text = nil;
    
    [_cellImageView cancelImageRequestOperation];
	_cellImageView.image = nil;
}

- (BOOL)privateContent {
    // TODO: figure out how/if this applies to subclasses
    return NO;
}

- (void)setContentProvider:(id<WPContentViewProvider>)contentProvider {
    if (_contentProvider == contentProvider)
        return;
    
    _contentProvider = contentProvider;
    [self configureContentView:_contentProvider];
}

- (void)setAuthorDisplayName:(NSString *)authorName authorLink:(NSString *)authorLink {
    self.bylineLabel.text = authorName;
    [self.byButton setTitle:authorLink forState:UIControlStateNormal];
    [self.byButton setEnabled:YES];
    [self.byButton setHidden:NO];
}

- (void)configureContentView:(id<WPContentViewProvider>)contentProvider {
    self.bylineLabel.text = [contentProvider authorForDisplay];

    if ([[contentProvider blogNameForDisplay] length] > 0) {
        [self.byButton setEnabled:YES];
        [self.byButton setHidden:NO];
        [self.byButton setTitle:[contentProvider blogNameForDisplay] forState:UIControlStateNormal];
    } else {
        [self.byButton setEnabled:NO];
        [self.byButton setHidden:YES];
    }
    
    [self refreshDate];
    
	self.cellImageView.hidden = YES;
	
	[self updateActionButtons];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat yPos = [self layoutSubviewsFromY:0.0f];

    // Update own frame
    CGRect ownFrame = self.frame;
    if (CGRectGetHeight(self.frame) != yPos) {
        ownFrame.size.height = yPos;
        self.frame = ownFrame;
        
        if ([self.delegate respondsToSelector:@selector(contentViewHeightDidChange:)]) {
            [self.delegate contentViewHeightDidChange:self];
        }
    }
}

- (CGFloat)layoutSubviewsFromY:(CGFloat)yPos {
    yPos = [self layoutAttributionAt:yPos];
    yPos = [self layoutFeaturedImageAt:yPos];
    yPos = [self layoutTitleAt:yPos];
    yPos = [self layoutTextContentAt:yPos];
    yPos = [self layoutActionViewAt:yPos];
    return yPos;
}

- (CGFloat)layoutAttributionAt:(CGFloat)yPosition {
    CGFloat contentWidth = CGRectGetWidth(self.frame);
    self.byView.frame = CGRectMake(0.0f, [self topMarginHeight], contentWidth, RPVAuthorViewHeight + RPVAuthorPadding * 2);

    CGFloat bylineHeight = 18.0f;

    CGFloat bylineX = RPVAvatarSize + RPVAuthorPadding + RPVHorizontalInnerPadding;
    self.bylineLabel.frame = CGRectMake(bylineX, RPVAuthorPadding - 2, contentWidth - bylineX, bylineHeight);
    self.byButton.frame = CGRectMake(bylineX, CGRectGetMinY(self.bylineLabel.frame) + bylineHeight, contentWidth - bylineX, bylineHeight);
    
    return CGRectGetMaxY(self.byView.frame);
}

- (CGFloat)layoutFeaturedImageAt:(CGFloat)yPosition {
    return yPosition;
}

- (CGFloat)layoutTitleAt:(CGFloat)yPosition {
    return yPosition;
}

- (CGFloat)layoutTextContentAt:(CGFloat)yPosition {
    CGFloat contentWidth = CGRectGetWidth(self.frame);
    
    [self.textContentView relayoutText];
    CGFloat height = [self.textContentView suggestedFrameSizeToFitEntireStringConstraintedToWidth:contentWidth].height;
    self.textContentView.frame = CGRectMake(0.0f, yPosition, contentWidth, height);

    return CGRectGetMaxY(self.textContentView.frame) + RPVVerticalPadding;
}

- (CGFloat)layoutActionViewAt:(CGFloat)yPosition {
    CGFloat contentWidth = CGRectGetWidth(self.frame);
    
    // Position the meta view and its subviews
	self.bottomView.frame = CGRectMake(0.0f, yPosition, contentWidth, RPVMetaViewHeight);
    self.bottomBorder.frame = CGRectMake(RPVHorizontalInnerPadding, 0.0f, contentWidth - RPVHorizontalInnerPadding * 2, RPVBorderHeight);
    
    // Action buttons
    CGFloat buttonWidth = RPVControlButtonWidth;
    CGFloat buttonX = contentWidth - RPVControlButtonWidth;
    CGFloat buttonY = RPVBorderHeight; // Just below the line
    NSArray* reversedActionButtons = [[self.actionButtons reverseObjectEnumerator] allObjects];
    
    for (UIButton *actionButton in reversedActionButtons) {
        // Button order from right-to-left, ignoring hidden buttons
        if (actionButton.hidden)
            continue;
        
        actionButton.frame = CGRectMake(buttonX, buttonY, buttonWidth, RPVControlButtonHeight);
        buttonX -= buttonWidth + RPVControlButtonSpacing;
    }
    
    CGFloat timeWidth = contentWidth - buttonX;
    self.timeButton.frame = CGRectMake(RPVHorizontalInnerPadding, RPVBorderHeight, timeWidth, RPVControlButtonHeight);

    return CGRectGetMaxY(self.bottomView.frame);
}

- (UIButton *)addActionButtonWithImage:(UIImage *)buttonImage selectedImage:(UIImage *)selectedButtonImage {
    ContentActionButton *button = [ContentActionButton buttonWithType:UIButtonTypeCustom];
    button.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
    button.backgroundColor = [UIColor clearColor];
    [button setImage:buttonImage forState:UIControlStateNormal];
    [button setImage:selectedButtonImage forState:UIControlStateSelected];
    [self.bottomView addSubview:button];
    [self.actionButtons addObject:button];

    return button;
}

- (void)removeActionButton:(UIButton *)button {
    [button removeFromSuperview];
    [self.actionButtons removeObject:button];
}


#pragma mark - Actions

// Forward the actions to the delegate; do it this way instead of exposing buttons as properties
// because the view can have dynamically generated buttons (e.g. links)

- (void)featuredImageAction:(id)sender {
    if ([self.delegate respondsToSelector:@selector(contentView:didReceiveFeaturedImageAction:)]) {
        [self.delegate contentView:self didReceiveFeaturedImageAction:sender];
    }
}

- (void)followAction:(id)sender {
    if ([self.delegate respondsToSelector:@selector(contentView:didReceiveFollowAction:)]) {
        [self.delegate contentView:self didReceiveFollowAction:sender];
    }
}

- (void)tagAction:(id)sender {
    if ([self.delegate respondsToSelector:@selector(contentView:didReceiveTagAction:)]) {
        [self.delegate contentView:self didReceiveTagAction:sender];
    }
}

- (void)linkAction:(id)sender {
    if ([self.delegate respondsToSelector:@selector(contentView:didReceiveLinkAction:)]) {
        [self.delegate contentView:self didReceiveLinkAction:sender];
    }
}

- (void)imageLinkAction:(id)sender {
    if ([self.delegate respondsToSelector:@selector(contentView:didReceiveImageLinkAction:)]) {
        [self.delegate contentView:self didReceiveImageLinkAction:sender];
    }   
}

- (void)videoLinkAction:(id)sender {    
    if ([self.delegate respondsToSelector:@selector(contentView:didReceiveVideoLinkAction:)]) {
        [self.delegate contentView:self didReceiveVideoLinkAction:sender];
    }
}

- (void)authorLinkAction:(id)sender {
    if ([self.delegate respondsToSelector:@selector(contentView:didReceiveAuthorLinkAction:)]) {
        [self.delegate contentView:self didReceiveAuthorLinkAction:sender];
    }
}


#pragma mark - Helper methods

- (void)setFeaturedImage:(UIImage *)image {
    self.cellImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.cellImageView.image = image;
}

- (void)updateActionButtons {
    // Implemented by subclasses
}

- (BOOL)isEmoji:(NSURL *)url {
	return ([[url absoluteString] rangeOfString:@"wp.com/wp-includes/images/smilies"].location != NSNotFound);
}

- (void)handleMediaViewLoaded:(ReaderMediaView *)mediaView {
	
	BOOL frameChanged = [self updateMediaLayout:mediaView];
	
    if (frameChanged) {
        // need to reset the layouter because otherwise we get the old framesetter or cached layout frames
        self.textContentView.layouter = nil;
        
        // layout might have changed due to image sizes
        [self.textContentView relayoutText];
        [self setNeedsLayout];
    }
}

// Subclasses can override this to provide margin at the top of the view. See CommentView.
- (CGFloat)topMarginHeight {
    return 0.0f;
}

- (BOOL)updateMediaLayout:(ReaderMediaView *)imageView {
    BOOL frameChanged = NO;
	NSURL *url = imageView.contentURL;
	
	CGSize originalSize = imageView.frame.size;
	CGSize imageSize = imageView.image.size;
	
	if ([self isEmoji:url]) {
		CGFloat scale = [UIScreen mainScreen].scale;
		imageSize.width *= scale;
		imageSize.height *= scale;
	} else {
        if (imageView.image) {
            CGFloat ratio = imageSize.width / imageSize.height;
            CGFloat width = _textContentView.frame.size.width;
            CGFloat availableWidth = _textContentView.frame.size.width - (_textContentView.edgeInsets.left + _textContentView.edgeInsets.right);
            
            imageSize.width = availableWidth;
            imageSize.height = roundf(width / ratio) + imageView.edgeInsets.top;
        } else {
            imageSize = CGSizeMake(0.0f, 0.0f);
        }
	}
    
    // Widths should always match
    if (imageSize.height != originalSize.height) {
        frameChanged = YES;
    }
    
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"contentURL == %@", url];
	
	// update all attachments that matchin this URL (possibly multiple images with same size)
	for (DTTextAttachment *attachment in [self.textContentView.layoutFrame textAttachmentsWithPredicate:pred]) {
		attachment.originalSize = originalSize;
		attachment.displaySize = imageSize;
	}
    
    return frameChanged;
}

- (void)refreshDate:(NSTimer *)timer {
    NSString *title = [self.contentProvider.dateForDisplay shortString];
    [self.timeButton setTitle:title forState:UIControlStateNormal | UIControlStateDisabled];
}

- (void)refreshDate {
    [self refreshDate:nil];
}

// Relayout the textContentView after a brief delay.  Used to make sure there are no
// gaps in text due to outdated media frames.
- (void)refreshLayoutAfterDelay {
    if (self.willRefreshMediaLayout) {
        return;
    }
    self.willRefreshMediaLayout = YES;
    
    // The first time we're called we're in the middle of updating layout. Refreshing at
    // this point has no effect.  Dispatch async will let us refresh layout in a new loop
    // and correctly update. 
    dispatch_async(dispatch_get_main_queue(), ^{
        [self refreshMediaLayout];
        
        if ([self.delegate respondsToSelector:@selector(contentViewDidLoadAllMedia:)]) {
            [self.delegate contentViewDidLoadAllMedia:self]; // So the delegate can correct its size.
        }
    });
}

- (void)refreshMediaLayout {
    [self refreshMediaLayoutInArray:self.mediaArray];
}

- (void)refreshMediaLayoutInArray:(NSArray *)mediaArray {
    BOOL frameChanged = NO;
    
    for (ReaderMediaView *mediaView in mediaArray) {
        if ([self updateMediaLayout:mediaView]) {
            NSLog(@"Frame Changed");
            frameChanged = YES;
        }

        if (frameChanged) {
            [self relayoutTextContentView];
        }
    }
}

- (void)relayoutTextContentView {
    // need to reset the layouter because otherwise we get the old framesetter or
    self.textContentView.layouter = nil;

    // layout might have changed due to image sizes
    [self.textContentView relayoutText];
    [self setNeedsLayout];
}


#pragma mark ReaderMediaQueueDelegate methods

- (void)readerMediaQueue:(ReaderMediaQueue *)mediaQueue didLoadBatch:(NSArray *)batch {
    [self refreshMediaLayoutInArray:batch];
    if ([self.delegate respondsToSelector:@selector(contentViewDidLoadAllMedia:)]) {
        [self.delegate contentViewDidLoadAllMedia:self];
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
	[button addTarget:self action:@selector(linkAction:) forControlEvents:UIControlEventTouchUpInside];
	
	return button;
}


- (UIView *)attributedTextContentView:(DTAttributedTextContentView *)attributedTextContentView viewForAttachment:(DTTextAttachment *)attachment frame:(CGRect)frame {
    if (!attachment.contentURL)
        return nil;
    
    // The textContentView will render the first time with the original frame, and then update when media loads.
    // To avoid showing gaps in the layout due to the original attachment sizes, relayout the view after a brief delay.
    [self refreshLayoutAfterDelay];
    
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
                                isPrivate:[self privateContent]
                                  success:nil
                                  failure:nil];
			return imageView;
		}
		
        DTImageTextAttachment *imageAttachment = (DTImageTextAttachment *)attachment;
		
		if ([imageAttachment.image isKindOfClass:[UIImage class]]) {
			UIImage *image = imageAttachment.image;
			
            CGFloat ratio = image.size.width / image.size.height;
            frame.size.width = availableWidth;
            frame.size.height = roundf(width / ratio);
            
            // offset the top edge inset keeping the image from bumping the text above it.
            frame.size.height += edgeInsets.top;
		} else {
            // minimal frame to suppress drawing context errors with 0 height or width.
            frame.size.width = 1.0f;
            frame.size.height = 1.0f;
		}
        
		ReaderImageView *imageView = [[ReaderImageView alloc] initWithFrame:frame];
		imageView.edgeInsets = edgeInsets;
        
		[_mediaArray addObject:imageView];
		imageView.linkURL = attachment.hyperLinkURL;
		[imageView addTarget:self action:@selector(imageLinkAction:) forControlEvents:UIControlEventTouchUpInside];
		
		if ([imageAttachment.image isKindOfClass:[UIImage class]]) {
			[imageView setImage:imageAttachment.image];
		} else {
            
            [self.mediaQueue enqueueMedia:imageView
                                  withURL:attachment.contentURL
                         placeholderImage:nil
                                     size:CGSizeMake(width, 0.0f) // Passing zero for height to get the correct aspect ratio
                                isPrivate:[self privateContent]
                                  success:nil
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
        
        // we won't show the vid until we've loaded its thumb.
        // minimal frame to suppress drawing context errors with 0 height or width.
        frame.size.width = 1.0f;
        frame.size.height = 1.0f;
        
		ReaderVideoView *videoView = [[ReaderVideoView alloc] initWithFrame:frame];
		videoView.edgeInsets = edgeInsets;
        
		[_mediaArray addObject:videoView];
		[videoView setContentURL:attachment.contentURL ofType:videoType success:^(id readerVideoView) {
			[self handleMediaViewLoaded:readerVideoView];
		} failure:^(id readerVideoView, NSError *error) {
            // if the image is 404, just show a black image.
            ReaderVideoView *videoView = (ReaderVideoView *)readerVideoView;
            videoView.image = [UIImage imageWithColor:[UIColor blackColor] havingSize:CGSizeMake(2.0f, 1.0f)];
			[self handleMediaViewLoaded:readerVideoView];
		}];
        
		[videoView addTarget:self action:@selector(videoLinkAction:) forControlEvents:UIControlEventTouchUpInside];
        
		return videoView;
	}
}

@end
