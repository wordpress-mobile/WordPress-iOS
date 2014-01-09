//
//  ReaderPostView.m
//  WordPress
//
//  Created by Michael Johnston on 11/19/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "ReaderPostView.h"

#import <DTCoreText/DTCoreText.h>
#import <QuartzCore/QuartzCore.h>
#import "UIImageView+Gravatar.h"
#import "WordPressAppDelegate.h"
#import "WPWebViewController.h"
#import "UIImageView+AFNetworkingExtra.h"
#import "UILabel+SuggestSize.h"
#import "WPAvatarSource.h"
#import "ReaderButton.h"
#import "NSDate+StringFormatting.h"
#import "UIColor+Helpers.h"
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
const CGFloat RPVSmallButtonLeftPadding = 2; // Follow, tag
const CGFloat RPVMaxImageHeightPercentage = 0.59f;
const CGFloat RPVMaxSummaryHeight = 88.0f;
const CGFloat RPVLineHeightMultiple = 1.10f;
const CGFloat RPVFollowButtonWidth = 100.0f;
const CGFloat RPVTitlePaddingBottom = 4.0f;

// Control buttons (Like, Reblog, ...)
const CGFloat RPVControlButtonHeight = 48.0f;
const CGFloat RPVControlButtonWidth = 48.0f;
const CGFloat RPVControlButtonSpacing = 12.0f;
const CGFloat RPVControlButtonBorderSize = 0.0f;

@interface ReaderPostView()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) CALayer *titleBorder;
@property (nonatomic, strong) UILabel *snippetLabel;
@property (nonatomic, strong) UIButton *followButton;
@property (nonatomic, strong) UIButton *tagButton;
@property (nonatomic, strong) UIButton *likeButton;
@property (nonatomic, strong) UIButton *reblogButton;
@property (nonatomic, strong) UIButton *commentButton;
@property (nonatomic, strong) UIButton *timeButton;
@property (nonatomic, strong) DTAttributedTextContentView *textContentView;

@property (nonatomic, strong) UIView *metaView;
@property (nonatomic, strong) CALayer *metaBorder;
@property (nonatomic, strong) UIView *byView;
@property (nonatomic, strong) UILabel *bylineLabel;
@property (nonatomic, strong) UIView *controlView;
@property (nonatomic, strong) NSTimer *dateRefreshTimer;

@property (nonatomic, assign) BOOL showImage;
@property (nonatomic, assign) BOOL showFullContent;
@property (nonatomic, strong) NSMutableArray *mediaArray;
@property (nonatomic, strong) ReaderMediaQueue *mediaQueue;

@end

@implementation ReaderPostView {
    BOOL _avatarIsSet;
}

+ (CGFloat)heightForPost:(ReaderPost *)post withWidth:(CGFloat)width {
	CGFloat desiredHeight = 0.0f;
    
    // Margins
    CGFloat contentWidth = width;
    if (IS_IPAD) {
        contentWidth = WPTableViewFixedWidth;
    }
    
    desiredHeight += RPVAuthorPadding;
    desiredHeight += RPVAuthorViewHeight;
    desiredHeight += RPVAuthorPadding;
    
	// Are we showing an image? What size should it be?
	if (post.featuredImageURL) {
		CGFloat height = ceilf((contentWidth * RPVMaxImageHeightPercentage));
		desiredHeight += height;
	}
    
    // Everything but the image has inner padding
    contentWidth -= RPVHorizontalInnerPadding * 2;
    
    // Title
    desiredHeight += RPVVerticalPadding;
    NSAttributedString *postTitle = [self titleAttributedStringForPost:post];
    desiredHeight += [postTitle boundingRectWithSize:CGSizeMake(contentWidth, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size.height;
    desiredHeight += RPVTitlePaddingBottom;
    
    // Post summary
    if ([post.summary length] > 0) {
        NSAttributedString *postSummary = [self summaryAttributedStringForPost:post];
        desiredHeight += [postSummary boundingRectWithSize:CGSizeMake(contentWidth, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size.height;
        desiredHeight += RPVVerticalPadding;
    }
    
    // Tag
    // TODO: reenable tags once a better browsing experience is implemented
/*    NSString *tagName = post.primaryTagName;
    if ([tagName length] > 0) {
        CGRect tagRect = [tagName boundingRectWithSize:CGSizeMake(contentWidth, CGFLOAT_MAX)
                                                options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                             attributes:@{NSFontAttributeName : [self summaryFont]}
                                                context:nil];
        desiredHeight += tagRect.size.height;
    }
 */
    
    // Padding below the line
	desiredHeight += RPVVerticalPadding;
    
	// Size of the meta view
    desiredHeight += RPVMetaViewHeight;
    
	return ceil(desiredHeight);
}

+ (NSAttributedString *)titleAttributedStringForPost:(ReaderPost *)post {
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineHeightMultiple:RPVLineHeightMultiple];
    NSDictionary *attributes = @{NSParagraphStyleAttributeName : style,
                                 NSFontAttributeName : [self titleFont]};
    NSMutableAttributedString *titleString = [[NSMutableAttributedString alloc] initWithString:[post.postTitle trim]
                                                                                    attributes:attributes];
    
    return titleString;
}

+ (NSAttributedString *)summaryAttributedStringForPost:(ReaderPost *)post {
    NSString *summary = [post.summary trim];
    NSInteger newline = [post.summary rangeOfString:@"\n"].location;
    
    if (newline != NSNotFound)
        summary = [post.summary substringToIndex:newline];
    
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineHeightMultiple:RPVLineHeightMultiple];
    NSDictionary *attributes = @{NSParagraphStyleAttributeName : style,
                                 NSFontAttributeName : [self summaryFont]};
    NSMutableAttributedString *attributedSummary = [[NSMutableAttributedString alloc] initWithString:summary
                                                                                          attributes:attributes];
    
    NSDictionary *moreContentAttributes = @{NSParagraphStyleAttributeName: style,
                                            NSFontAttributeName: [self moreContentFont],
                                            NSForegroundColorAttributeName: [WPStyleGuide baseLighterBlue]};
    NSAttributedString *moreContent = [[NSAttributedString alloc] initWithString:[@"   " stringByAppendingString:NSLocalizedString(@"more", @"")] attributes:moreContentAttributes];
    [attributedSummary appendAttributedString:moreContent];
    
    return attributedSummary;
}

+ (UIFont *)titleFont {
    return [UIFont fontWithName:@"Merriweather-Bold" size:21.0f];
}

+ (UIFont *)summaryFont {
    return [UIFont fontWithName:@"OpenSans" size:14.0f];
}

+ (UIFont *)moreContentFont {
    return [UIFont fontWithName:@"OpenSans" size:12.0f];
}

#pragma mark - Lifecycle Methods

- (id)initWithFrame:(CGRect)frame showFullContent:(BOOL)showFullContent {
    self = [super initWithFrame:frame];
    if (self) {
        self.mediaArray = [NSMutableArray array];
        self.mediaQueue = [[ReaderMediaQueue alloc] initWithDelegate:self];

        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.opaque = YES;
        self.showFullContent = showFullContent;

        self.cellImageView = [[UIImageView alloc] init];
		_cellImageView.backgroundColor = [WPStyleGuide readGrey];
		_cellImageView.contentMode = UIViewContentModeScaleAspectFill;
		_cellImageView.clipsToBounds = YES;

		[self buildPostContent];
		[self buildMetaContent];
        
        // Update the relative timestamp once per minute
        self.dateRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(refreshDate:) userInfo:nil repeats:YES];
    }
    return self;
}

- (void)dealloc {
	self.post = nil;
    self.delegate = nil;
    _textContentView.delegate = nil;
    _mediaQueue.delegate = nil;
    [_mediaQueue discardQueuedItems];

    [self.dateRefreshTimer invalidate];
    self.dateRefreshTimer = nil;
}

- (void)configurePost:(ReaderPost *)post {
    self.post = post;
    
    // This will show the placeholder avatar. Do this here instead of prepareForReuse
    // so avatars show up after a cell is created, and not dequeued.
    [self setAvatar:nil];
    
	_titleLabel.attributedText = [ReaderPostView titleAttributedStringForPost:post];
    
    if (self.showFullContent) {
        NSData *data = [self.post.content dataUsingEncoding:NSUTF8StringEncoding];
		_textContentView.attributedString = [[NSAttributedString alloc] initWithHTMLData:data
                                                                                 options:[WPStyleGuide defaultDTCoreTextOptions]
                                                                      documentAttributes:nil];
        [_textContentView relayoutText];
    } else {
        _snippetLabel.attributedText = [ReaderPostView summaryAttributedStringForPost:post];
    }
    
    _bylineLabel.text = [post authorString];
    [self refreshDate:nil];
    
	self.showImage = NO;
	self.cellImageView.hidden = YES;
	if (post.featuredImageURL) {
		self.showImage = YES;
		self.cellImageView.hidden = NO;
	}
    
    if ([self.post.primaryTagName length] > 0) {
        _tagButton.hidden = NO;
        [_tagButton setTitle:self.post.primaryTagName forState:UIControlStateNormal];
    } else {
        _tagButton.hidden = YES;
    }
    
	if ([self.post isWPCom]) {
		_likeButton.hidden = NO;
		_reblogButton.hidden = NO;
        _commentButton.hidden = NO;
	} else {
		_likeButton.hidden = YES;
		_reblogButton.hidden = YES;
        _commentButton.hidden = YES;
	}
    
    [_followButton setSelected:[self.post.isFollowing boolValue]];
	_reblogButton.userInteractionEnabled = ![post.isReblogged boolValue];
	
	[self updateActionButtons];
}

- (void)setPost:(ReaderPost *)post {
	if ([post isEqual:_post])
		return;

	_post = post;
}

- (UIView *)buildContentView {
    UIView *contentView;
    
    if (self.showFullContent) {
        [DTAttributedTextContentView setLayerClass:[DTTiledLayerWithoutFade class]];
        
        // Needs an initial frame
        self.textContentView = [[DTAttributedTextContentView alloc] initWithFrame:self.frame];
        _textContentView.delegate = self;
        _textContentView.backgroundColor = [UIColor whiteColor];
        _textContentView.edgeInsets = UIEdgeInsetsMake(0.0f, RPVHorizontalInnerPadding, 0.0f, RPVHorizontalInnerPadding);
        _textContentView.shouldDrawImages = NO;
        _textContentView.shouldDrawLinks = NO;
        contentView = _textContentView;
    } else {
        self.snippetLabel = [[UILabel alloc] init];
        _snippetLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _snippetLabel.backgroundColor = [UIColor clearColor];
        _snippetLabel.textColor = [UIColor colorWithHexString:@"333"];
        _snippetLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _snippetLabel.numberOfLines = 0;
        contentView = _snippetLabel;
    }
    
    return contentView;
}

- (void)buildPostContent {
	self.cellImageView.contentMode = UIViewContentModeScaleAspectFill;
    
    // For the full view, allow the featured image to be tapped
    if (self.showFullContent) {
        UITapGestureRecognizer *imageTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(featuredImageAction:)];
        self.cellImageView.userInteractionEnabled = YES;
        [self.cellImageView addGestureRecognizer:imageTap];
    }
	[self addSubview:self.cellImageView];
    
	self.titleLabel = [[UILabel alloc] init];
	_titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	_titleLabel.backgroundColor = [UIColor clearColor];
	_titleLabel.textColor = [UIColor colorWithHexString:@"333"];
	_titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
	_titleLabel.numberOfLines = 0;
	[self addSubview:_titleLabel];
    
    self.titleBorder = [[CALayer alloc] init];
    _titleBorder.backgroundColor = [[UIColor colorWithHexString:@"f1f1f1"] CGColor];
    [self.layer addSublayer:_titleBorder];
	
	[self addSubview:[self buildContentView]];
    
    self.byView = [[UIView alloc] init];
	_byView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	_byView.backgroundColor = [UIColor clearColor];
    _byView.userInteractionEnabled = YES;
	[self addSubview:_byView];
	
    CGRect avatarFrame = CGRectMake(RPVHorizontalInnerPadding, RPVAuthorPadding, RPVAvatarSize, RPVAvatarSize);
	self.avatarImageView = [[UIImageView alloc] initWithFrame:avatarFrame];
	[_byView addSubview:_avatarImageView];
	
	self.bylineLabel = [[UILabel alloc] init];
	_bylineLabel.backgroundColor = [UIColor clearColor];
	_bylineLabel.numberOfLines = 1;
	_bylineLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	_bylineLabel.font = [UIFont fontWithName:@"OpenSans" size:12.0f];
	_bylineLabel.adjustsFontSizeToFitWidth = NO;
	_bylineLabel.textColor = [UIColor colorWithHexString:@"333"];
	[_byView addSubview:_bylineLabel];
    
    self.followButton = [ReaderButton buttonWithType:UIButtonTypeCustom];
    _followButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    _followButton.backgroundColor = [UIColor clearColor];
    _followButton.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:12.0f];
    NSString *followString = NSLocalizedString(@"Follow", @"Prompt to follow a blog.");
    NSString *followedString = NSLocalizedString(@"Following", @"User is following the blog.");
    [_followButton setTitle:followString forState:UIControlStateNormal];
    [_followButton setTitle:followedString forState:UIControlStateSelected];
    [_followButton setTitleEdgeInsets: UIEdgeInsetsMake(0, RPVSmallButtonLeftPadding, 0, 0)];
    [_followButton setImage:[UIImage imageNamed:@"reader-postaction-follow"] forState:UIControlStateNormal];
    [_followButton setImage:[UIImage imageNamed:@"reader-postaction-following"] forState:UIControlStateSelected];
    [_followButton setTitleColor:[UIColor colorWithHexString:@"aaa"] forState:UIControlStateNormal];
    [_followButton addTarget:self action:@selector(followAction:) forControlEvents:UIControlEventTouchUpInside];
    [_byView addSubview:_followButton];
    
    self.tagButton = [ReaderButton buttonWithType:UIButtonTypeCustom];
    _tagButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    _tagButton.backgroundColor = [UIColor clearColor];
    _tagButton.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:12.0f];
    [_tagButton setTitleEdgeInsets: UIEdgeInsetsMake(0, RPVSmallButtonLeftPadding, 0, 0)];
    [_tagButton setImage:[UIImage imageNamed:@"reader-postaction-tag"] forState:UIControlStateNormal];
    [_tagButton setTitleColor:[UIColor colorWithHexString:@"aaa"] forState:UIControlStateNormal];
    [_tagButton addTarget:self action:@selector(tagAction:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_tagButton];
}

- (void)buildMetaContent {
	self.metaView = [[UIView alloc] init];
	_metaView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	_metaView.backgroundColor = [UIColor clearColor];
	[self addSubview:_metaView];
    
    self.metaBorder = [[CALayer alloc] init];
    _metaBorder.backgroundColor = [[UIColor colorWithHexString:@"f1f1f1"] CGColor];
    [_metaView.layer addSublayer:_metaBorder];
    
    self.timeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _timeButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    _timeButton.backgroundColor = [UIColor clearColor];
    _timeButton.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:12.0f];
    [_timeButton setTitleEdgeInsets: UIEdgeInsetsMake(0, RPVSmallButtonLeftPadding, 0, 0)];
    [_timeButton setImage:[UIImage imageNamed:@"reader-postaction-time"] forState:UIControlStateNormal];
    [_timeButton setTitleColor:[UIColor colorWithHexString:@"aaa"] forState:UIControlStateNormal];
	[_metaView addSubview:_timeButton];
    
	self.likeButton = [ReaderButton buttonWithType:UIButtonTypeCustom];
	_likeButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
	_likeButton.backgroundColor = [UIColor clearColor];
	[_likeButton setImage:[UIImage imageNamed:@"reader-postaction-like-blue"] forState:UIControlStateNormal];
	[_likeButton setImage:[UIImage imageNamed:@"reader-postaction-like-active"] forState:UIControlStateSelected];
    [_likeButton addTarget:self action:@selector(likeAction:) forControlEvents:UIControlEventTouchUpInside];
	[_metaView addSubview:_likeButton];
	
	self.reblogButton = [ReaderButton buttonWithType:UIButtonTypeCustom];
	_reblogButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
	_reblogButton.backgroundColor = [UIColor clearColor];
	[_reblogButton setImage:[UIImage imageNamed:@"reader-postaction-reblog-blue"] forState:UIControlStateNormal];
	[_reblogButton setImage:[UIImage imageNamed:@"reader-postaction-reblog-done"] forState:UIControlStateSelected];
    [_reblogButton addTarget:self action:@selector(reblogAction:) forControlEvents:UIControlEventTouchUpInside];
	[_metaView addSubview:_reblogButton];
    
    self.commentButton = [ReaderButton buttonWithType:UIButtonTypeCustom];
	_commentButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
	_commentButton.backgroundColor = [UIColor clearColor];
	[_commentButton setImage:[UIImage imageNamed:@"reader-postaction-comment-blue"] forState:UIControlStateNormal];
	[_commentButton setImage:[UIImage imageNamed:@"reader-postaction-comment-active"] forState:UIControlStateSelected];
    [_commentButton addTarget:self action:@selector(commentAction:) forControlEvents:UIControlEventTouchUpInside];
	[_metaView addSubview:_commentButton];
}

- (void)layoutSubviews {
	[super layoutSubviews];
    
	CGFloat contentWidth;
    
    // On iPad, get the width from the cell instead in order to account for margins
    if (IS_IPHONE) {
        contentWidth = self.frame.size.width;
    } else {
        contentWidth = self.superview.frame.size.width;
    }
    
    CGFloat innerContentWidth = contentWidth - RPVHorizontalInnerPadding * 2;
	CGFloat nextY = RPVAuthorPadding;
	CGFloat height = 0.0f;

    _byView.frame = CGRectMake(0, 0, contentWidth, RPVAuthorViewHeight + RPVAuthorPadding * 2);
    CGFloat bylineX = RPVAvatarSize + RPVAuthorPadding + RPVHorizontalInnerPadding;
    _bylineLabel.frame = CGRectMake(bylineX, RPVAuthorPadding - 2, contentWidth - bylineX, 18);
    
    if ([self.post isFollowable]) {
        _followButton.hidden = NO;
        CGFloat followX = bylineX - 4; // Fudge factor for image alignment
        CGFloat followY = RPVAuthorPadding + _bylineLabel.frame.size.height - 2;
        height = ceil([_followButton.titleLabel suggestedSizeForWidth:innerContentWidth].height);
        _followButton.frame = CGRectMake(followX, followY, RPVFollowButtonWidth, height);
    } else {
        _followButton.hidden = YES;
    }
    
    nextY += RPVAuthorViewHeight + RPVAuthorPadding;
    
	// Are we showing an image? What size should it be?
	if (_showImage) {
        _titleBorder.hidden = YES;
		height = ceilf(contentWidth * RPVMaxImageHeightPercentage);
		self.cellImageView.frame = CGRectMake(0, nextY, contentWidth, height);
		nextY += height;
    } else {
        _titleBorder.hidden = NO;
        _titleBorder.frame = CGRectMake(RPVHorizontalInnerPadding, nextY, contentWidth - RPVHorizontalInnerPadding * 2, RPVBorderHeight);
    }
    
	// Position the title
    nextY += RPVVerticalPadding;
	height = ceil([_titleLabel suggestedSizeForWidth:innerContentWidth].height);
	_titleLabel.frame = CGRectMake(RPVHorizontalInnerPadding, nextY, innerContentWidth, height);
	nextY += height + RPVTitlePaddingBottom;
    
	// Position the snippet / content
    if ([self.post.summary length] > 0) {
        if (self.showFullContent) {
            [self.textContentView relayoutText];
            height = [self.textContentView suggestedFrameSizeToFitEntireStringConstraintedToWidth:contentWidth].height;
            CGRect textContainerFrame = _textContentView.frame;
            textContainerFrame.size.width = contentWidth;
            textContainerFrame.size.height = height;
            textContainerFrame.origin.y = nextY;
            self.textContentView.frame = textContainerFrame;
        } else {
            height = ceil([_snippetLabel suggestedSizeForWidth:innerContentWidth].height);
            _snippetLabel.frame = CGRectMake(RPVHorizontalInnerPadding, nextY, innerContentWidth, height);
        }
        nextY += ceilf(height) + RPVVerticalPadding;
    }
    
    // Tag
    // TODO: reenable tags once a better browsing experience is implemented
/*    if ([self.post.primaryTagName length] > 0) {
        height = ceil([_tagButton.titleLabel suggestedSizeForWidth:innerContentWidth].height);
        _tagButton.frame = CGRectMake(RPVHorizontalInnerPadding, nextY, innerContentWidth, height);
        nextY += height + RPVVerticalPadding;
        self.tagButton.hidden = NO;
    } else {
        self.tagButton.hidden = YES;
    }
 */
    
	// Position the meta view and its subviews
	_metaView.frame = CGRectMake(0, nextY, contentWidth, RPVMetaViewHeight);
    _metaBorder.frame = CGRectMake(RPVHorizontalInnerPadding, 0, contentWidth - RPVHorizontalInnerPadding * 2, RPVBorderHeight);
    
    BOOL commentsOpen = [[self.post commentsOpen] boolValue] && [self.post isWPCom];
	CGFloat buttonWidth = RPVControlButtonWidth;
    CGFloat buttonX = _metaView.frame.size.width - RPVControlButtonWidth;
    CGFloat buttonY = RPVBorderHeight; // Just below the line
    
    // Button order from right-to-left: Like, [Comment], Reblog,
    _likeButton.frame = CGRectMake(buttonX, buttonY, buttonWidth, RPVControlButtonHeight);
    buttonX -= buttonWidth + RPVControlButtonSpacing;
    
    if (commentsOpen) {
        self.commentButton.hidden = NO;
        self.commentButton.frame = CGRectMake(buttonX, buttonY, buttonWidth, RPVControlButtonHeight);
        buttonX -= buttonWidth + RPVControlButtonSpacing;
    } else {
        self.commentButton.hidden = YES;
    }
    _reblogButton.frame = CGRectMake(buttonX, buttonY, buttonWidth - RPVControlButtonBorderSize, RPVControlButtonHeight);
    
    CGFloat timeWidth = contentWidth - _reblogButton.frame.origin.x;
    _timeButton.frame = CGRectMake(RPVHorizontalInnerPadding, RPVBorderHeight, timeWidth, RPVControlButtonHeight);
    
    // Update own frame
    CGRect ownFrame = self.frame;
    
    ownFrame.size.height = nextY + RPVMetaViewHeight - 1;
    self.frame = ownFrame;
}

- (void)reset {
    self.post = nil;
    _avatarIsSet = NO;
    
	_bylineLabel.text = nil;
	_titleLabel.text = nil;
	_snippetLabel.text = nil;
    [_tagButton setTitle:nil forState:UIControlStateNormal];
    [_followButton setSelected:NO];
    
    [_cellImageView cancelImageRequestOperation];
	_cellImageView.image = nil;
}


#pragma mark - Actions

// Forward the actions to the delegate; do it this way instead of exposing buttons as properties
// because the view can have dynamically generated buttons (e.g. links)

- (void)featuredImageAction:(id)sender {
    if ([self.delegate respondsToSelector:@selector(postView:didReceiveFeaturedImageAction:)]) {
        [self.delegate postView:self didReceiveFeaturedImageAction:sender];
    }
}

- (void)followAction:(id)sender {
    if ([self.delegate respondsToSelector:@selector(postView:didReceiveFollowAction:)]) {
        [self.delegate postView:self didReceiveFollowAction:sender];
    }
}

- (void)tagAction:(id)sender {
    if ([self.delegate respondsToSelector:@selector(postView:didReceiveTagAction:)]) {
        [self.delegate postView:self didReceiveTagAction:sender];
    }
}

- (void)reblogAction:(id)sender {
    if ([self.delegate respondsToSelector:@selector(postView:didReceiveReblogAction:)]) {
        [self.delegate postView:self didReceiveReblogAction:sender];
    }
}

- (void)commentAction:(id)sender {
    if ([self.delegate respondsToSelector:@selector(postView:didReceiveCommentAction:)]) {
        [self.delegate postView:self didReceiveCommentAction:sender];
    }
}

- (void)likeAction:(id)sender {
    if ([self.delegate respondsToSelector:@selector(postView:didReceiveLikeAction:)]) {
        [self.delegate postView:self didReceiveLikeAction:sender];
    }
}

- (void)linkAction:(id)sender {
    if ([self.delegate respondsToSelector:@selector(postView:didReceiveLinkAction:)]) {
        [self.delegate postView:self didReceiveLinkAction:sender];
    }
}

- (void)imageLinkAction:(id)sender {
    if ([self.delegate respondsToSelector:@selector(postView:didReceiveImageLinkAction:)]) {
        [self.delegate postView:self didReceiveImageLinkAction:sender];
    }   
}

- (void)videoLinkAction:(id)sender {    
    if ([self.delegate respondsToSelector:@selector(postView:didReceiveVideoLinkAction:)]) {
        [self.delegate postView:self didReceiveVideoLinkAction:sender];
    }
}


#pragma mark - Instance Methods

- (void)setAvatar:(UIImage *)avatar {
    if (_avatarIsSet)
        return;
    
    static UIImage *wpcomBlavatar;
    static UIImage *wporgBlavatar;
    if (!wpcomBlavatar) {
        wpcomBlavatar = [UIImage imageNamed:@"wpcom_blavatar"];
    }
    
    if (!wporgBlavatar) {
        wporgBlavatar = [UIImage imageNamed:@"wporg_blavatar"];
    }
    
    if (avatar) {
        self.avatarImageView.image = avatar;
        _avatarIsSet = YES;
    } else {
        self.avatarImageView.image = [self.post isWPCom] ? wpcomBlavatar : wporgBlavatar;
    }
}

- (void)setFeaturedImage:(UIImage *)image {
    self.cellImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.cellImageView.image = image;
}

- (void)updateActionButtons {
	if (!_post)
        return;
	
    _likeButton.selected = _post.isLiked.boolValue;
    _reblogButton.selected = _post.isReblogged.boolValue;
	_reblogButton.userInteractionEnabled = !_reblogButton.selected;
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
    [self.timeButton setTitle:[self.post.date_created_gmt shortString] forState:UIControlStateNormal];
}

- (void)refreshMediaLayout {
    [self refreshMediaLayoutInArray:self.mediaArray];
}

- (void)refreshMediaLayoutInArray:(NSArray *)mediaArray {
    BOOL frameChanged = NO;
    
    for (ReaderMediaView *mediaView in mediaArray) {
        if ([self updateMediaLayout:mediaView]) {
            frameChanged = YES;
        }
    }
    
    if (frameChanged) {
        [self relayoutTextContentView];
    }
}

- (void)relayoutTextContentView {
    // need to reset the layouter because otherwise we get the old framesetter or cached layout frames
    self.textContentView.layouter = nil;
    
    // layout might have changed due to image sizes
    [self.textContentView relayoutText];
    [self setNeedsLayout];
}

#pragma mark ReaderMediaQueueDelegate methods

- (void)readerMediaQueue:(ReaderMediaQueue *)mediaQueue didLoadBatch:(NSArray *)batch {
    [self refreshMediaLayoutInArray:batch];    
    [self.delegate postViewDidLoadAllMedia:self];
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
                                isPrivate:self.post.isPrivate
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
			[self handleMediaViewLoaded:readerVideoView];
		}];
        
		[videoView addTarget:self action:@selector(videoLinkAction:) forControlEvents:UIControlEventTouchUpInside];
        
		return videoView;
	}
}


@end
