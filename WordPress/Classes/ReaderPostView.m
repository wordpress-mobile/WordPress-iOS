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

const CGFloat RPVAuthorPadding = 8.0f;
const CGFloat RPVHorizontalInnerPadding = 12.0f;
const CGFloat RPVMetaViewHeight = 48.0f;
const CGFloat RPVAuthorViewHeight = 32.0f;
const CGFloat RPVVerticalPadding = 16.0f;
const CGFloat RPVAvatarSize = 32.0f;
const CGFloat RPVBorderHeight = 1.0f;
const CGFloat RPVSmallButtonLeftPadding = 2; // Follow, tag
const CGFloat RPVMaxImageHeightPercentage = 0.59f;
const CGFloat RPVMaxSummaryHeight = 88.0f;
const CGFloat RPVLineHeightMultiple = 1.15f;

// Control buttons (Like, Reblog, ...)
const CGFloat RPVControlButtonHeight = 48.0f;
const CGFloat RPVControlButtonWidth = 48.0f;
const CGFloat RPVControlButtonSpacing = 12.0f;
const CGFloat RPVControlButtonBorderSize = 0.0f;

@interface ReaderPostView()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) CALayer *titleBorder;
@property (nonatomic, strong) UILabel *snippetLabel;

@property (nonatomic, strong) UIView *metaView;
@property (nonatomic, strong) CALayer *metaBorder;
@property (nonatomic, strong) UIView *byView;
@property (nonatomic, strong) UILabel *bylineLabel;
@property (nonatomic, strong) UIView *controlView;

@property (nonatomic, assign) BOOL showImage;

@end

@implementation ReaderPostView {
    BOOL _avatarIsSet;
}

+ (CGFloat)heightForPost:(ReaderPost *)post withWidth:(CGFloat)width {
	CGFloat desiredHeight = 0.0f;
    
    // Margins
    CGFloat contentWidth = width;
    if (IS_IPAD) {
        contentWidth = contentWidth * (1 - WPTableViewCellMarginPercentage * 2);
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
    desiredHeight += RPVVerticalPadding;
    
    // Post summary
    if ([post.summary length] > 0) {
        NSAttributedString *postSummary = [self summaryAttributedStringForPost:post];
        desiredHeight += [postSummary boundingRectWithSize:CGSizeMake(contentWidth, RPVMaxSummaryHeight) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size.height;
        desiredHeight += RPVVerticalPadding;
    }
    
    // Tag
    NSString *tagName = post.primaryTagName;
    if ([tagName length] > 0) {
        desiredHeight += [tagName sizeWithFont:[self summaryFont] constrainedToSize:CGSizeMake(contentWidth, CGFLOAT_MAX) lineBreakMode:NSLineBreakByClipping].height;
    }
    
    // Padding above and below the line
	desiredHeight += RPVVerticalPadding * 2;
    
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
    
    return attributedSummary;
}

+ (UIFont *)titleFont {
    return [UIFont fontWithName:@"Merriweather-Bold" size:21.0f];
}

+ (UIFont *)summaryFont {
    return [UIFont fontWithName:@"OpenSans" size:14.0f];
}


#pragma mark - Lifecycle Methods

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.opaque = YES;

        self.cellImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 44.0f, 44.0f)]; // arbitrary size.
		_cellImageView.backgroundColor = [WPStyleGuide readGrey];
		_cellImageView.contentMode = UIViewContentModeScaleAspectFill;
		_cellImageView.clipsToBounds = YES;

		[self buildPostContent];
		[self buildMetaContent];
    }
    return self;
}



- (void)dealloc {
	self.post = nil;
}

- (void)setPost:(ReaderPost *)post {
	if ([post isEqual:_post])
		return;
	
	if (_post) {
		[_post removeObserver:self forKeyPath:@"isReblogged" context:@"reblogging"];
	}
	
	_post = post;
	[_post addObserver:self forKeyPath:@"isReblogged" options:NSKeyValueObservingOptionNew context:@"reblogging"];
}

- (void)buildPostContent {
	self.cellImageView.contentMode = UIViewContentModeScaleAspectFill;
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
	
	self.snippetLabel = [[UILabel alloc] init];
	_snippetLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	_snippetLabel.backgroundColor = [UIColor clearColor];
	_snippetLabel.textColor = [UIColor colorWithHexString:@"333"];
	_snippetLabel.lineBreakMode = NSLineBreakByTruncatingTail;
	_snippetLabel.numberOfLines = 4;
	[self addSubview:_snippetLabel];
    
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
    [_followButton setSelected:[self.post.isFollowing boolValue]];
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
    [_byView addSubview:_followButton];
    
    self.tagButton = [ReaderButton buttonWithType:UIButtonTypeCustom];
    _tagButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    _tagButton.backgroundColor = [UIColor clearColor];
    _tagButton.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:12.0f];
    [_tagButton setTitleEdgeInsets: UIEdgeInsetsMake(0, RPVSmallButtonLeftPadding, 0, 0)];
    [_tagButton setImage:[UIImage imageNamed:@"reader-postaction-tag"] forState:UIControlStateNormal];
    [_tagButton setTitleColor:[UIColor colorWithHexString:@"aaa"] forState:UIControlStateNormal];
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
	_likeButton.backgroundColor = [UIColor whiteColor];
	[_likeButton setImage:[UIImage imageNamed:@"reader-postaction-like-blue"] forState:UIControlStateNormal];
	[_likeButton setImage:[UIImage imageNamed:@"reader-postaction-like-active"] forState:UIControlStateSelected];
	[_metaView addSubview:_likeButton];
	
	self.reblogButton = [ReaderButton buttonWithType:UIButtonTypeCustom];
	_reblogButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
	_reblogButton.backgroundColor = [UIColor whiteColor];
	[_reblogButton setImage:[UIImage imageNamed:@"reader-postaction-reblog-blue"] forState:UIControlStateNormal];
	[_reblogButton setImage:[UIImage imageNamed:@"reader-postaction-reblog-done"] forState:UIControlStateSelected];
	[_metaView addSubview:_reblogButton];
    
    self.commentButton = [ReaderButton buttonWithType:UIButtonTypeCustom];
	_commentButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
	_commentButton.backgroundColor = [UIColor whiteColor];
	[_commentButton setImage:[UIImage imageNamed:@"reader-postaction-comment-blue"] forState:UIControlStateNormal];
	[_commentButton setImage:[UIImage imageNamed:@"reader-postaction-comment-active"] forState:UIControlStateSelected];
	[_metaView addSubview:_commentButton];
}

- (void)layoutSubviews {
	[super layoutSubviews];
    
	CGFloat contentWidth = self.frame.size.width;
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
        _followButton.frame = CGRectMake(followX, followY, contentWidth - bylineX, height);
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
	nextY += height + RPVVerticalPadding;
    
	// Position the snippet
    if ([self.post.summary length] > 0) {
        height = ceil([_snippetLabel suggestedSizeForWidth:innerContentWidth].height);
        height = MIN(height, RPVMaxSummaryHeight);
        _snippetLabel.frame = CGRectMake(RPVHorizontalInnerPadding, nextY, innerContentWidth, height);
        nextY += ceilf(height + RPVVerticalPadding);
    }
    
    // Tag
    if ([self.post.primaryTagName length] > 0) {
        height = ceil([_tagButton.titleLabel suggestedSizeForWidth:innerContentWidth].height);
        _tagButton.frame = CGRectMake(RPVHorizontalInnerPadding, nextY, innerContentWidth, height);
        nextY += height + RPVVerticalPadding;
        self.tagButton.hidden = NO;
    } else {
        self.tagButton.hidden = YES;
    }
    
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
}

- (void)reset {
    _avatarIsSet = NO;
    
	_bylineLabel.text = nil;
	_titleLabel.text = nil;
	_snippetLabel.text = nil;
    [_tagButton setTitle:nil forState:UIControlStateNormal];
    
    [_cellImageView cancelImageRequestOperation];
	_cellImageView.image = nil;
}


#pragma mark - Instance Methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	[self updateControlBar];
}

- (void)configure:(ReaderPost *)post {
	self.post = post;
    
    // This will show the placeholder avatar. Do this here instead of prepareForReusue
    // so avatars show up after a cell is created, and not dequeued.
    [self setAvatar:nil];
    
	_titleLabel.attributedText = [ReaderPostView titleAttributedStringForPost:post];
	_snippetLabel.attributedText = [ReaderPostView summaryAttributedStringForPost:post];
    
    _bylineLabel.text = [post authorString];
    
    [_timeButton setTitle:[post.dateCreated shortString] forState:UIControlStateNormal];
    
	self.showImage = NO;
	self.cellImageView.hidden = YES;
    self.cellImageView.contentMode = UIViewContentModeCenter;
    self.cellImageView.image = [UIImage imageNamed:@"wp_img_placeholder"];
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
	
	_reblogButton.userInteractionEnabled = ![post.isReblogged boolValue];
	
	[self updateControlBar];
}

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

- (void)updateControlBar {
	if (!_post)
        return;
	
    _likeButton.selected = _post.isLiked.boolValue;
    _reblogButton.selected = _post.isReblogged.boolValue;
	_reblogButton.userInteractionEnabled = !_reblogButton.selected;
}

@end
