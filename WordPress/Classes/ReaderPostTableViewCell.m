//
//  ReaderPostTableViewCell.m
//  WordPress
//
//  Created by Eric J on 4/4/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "ReaderPostTableViewCell.h"
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

const CGFloat RPTVCAuthorPadding = 8.0f;
const CGFloat RPTVCHorizontalInnerPadding = 12.0f;
const CGFloat RPTVCHorizontalOuterPadding = 8.0f;
const CGFloat RPTVCMetaViewHeight = 48.0f;
const CGFloat RPTVCAuthorViewHeight = 32.0f;
const CGFloat RPTVCVerticalPadding = 16.0f;
const CGFloat RPTVCAvatarSize = 32.0f;
const CGFloat RPTVCBorderHeight = 1.0f;
const CGFloat RPTVCSmallButtonLeftPadding = 2; // Follow, tag
const CGFloat RPTVCMaxImageHeightPercentage = 0.59f;
const CGFloat RPTVCMaxSummaryHeight = 90.0f;
const CGFloat RPTVCLineHeightMultiple = 1.15f;

// Control buttons (Like, Reblog, ...)
const CGFloat RPTVCControlButtonHeight = 48.0f;
const CGFloat RPTVCControlButtonWidth = 48.0f;
const CGFloat RPTVCControlButtonSpacing = 12.0f;
const CGFloat RPTVCControlButtonBorderSize = 0.0f;

@interface ReaderPostTableViewCell()

@property (nonatomic, strong) UIView *containerView;
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

@implementation ReaderPostTableViewCell {
    BOOL _avatarIsSet;
    UIView *_sideBorderView;
}

+ (CGFloat)cellHeightForPost:(ReaderPost *)post withWidth:(CGFloat)width {
	CGFloat desiredHeight = 0.0f;

    // Margins
    CGFloat contentWidth = width;
    if (IS_IPAD) {
        contentWidth = contentWidth * (1 - WPTableViewCellMarginPercentage * 2);
    }
    
    // iPhone has extra padding around each cell
    if (IS_IPHONE) {
        contentWidth -= RPTVCHorizontalOuterPadding * 2;
    }

    desiredHeight += RPTVCAuthorPadding;
    desiredHeight += RPTVCAuthorViewHeight;
    desiredHeight += RPTVCAuthorPadding;

	// Are we showing an image? What size should it be?
	if (post.featuredImageURL) {
		CGFloat height = ceilf((contentWidth * RPTVCMaxImageHeightPercentage));
		desiredHeight += height;
	}
    
    // Everything but the image has inner padding
    contentWidth -= RPTVCHorizontalInnerPadding * 2;

    // Title
    desiredHeight += RPTVCVerticalPadding;
    NSAttributedString *postTitle = [self titleAttributedStringForPost:post];
    desiredHeight += [postTitle boundingRectWithSize:CGSizeMake(contentWidth, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size.height;
    desiredHeight += RPTVCVerticalPadding;

    // Post summary
    if ([post.summary length] > 0) {
        NSAttributedString *postSummary = [self summaryAttributedStringForPost:post];
        desiredHeight += [postSummary boundingRectWithSize:CGSizeMake(contentWidth, RPTVCMaxSummaryHeight) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size.height;
        desiredHeight += RPTVCVerticalPadding;
    }
    
    // Tag
    NSString *tagName = post.primaryTagName;
    if ([tagName length] > 0) {
        desiredHeight += [tagName sizeWithFont:[self summaryFont] constrainedToSize:CGSizeMake(contentWidth, CGFLOAT_MAX) lineBreakMode:NSLineBreakByClipping].height;
    }

    // Padding above and below the line
	desiredHeight += RPTVCVerticalPadding * 2;

	// Size of the meta view
    desiredHeight += RPTVCMetaViewHeight;

	return ceil(desiredHeight);
}

+ (NSAttributedString *)titleAttributedStringForPost:(ReaderPost *)post {
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineHeightMultiple:RPTVCLineHeightMultiple];
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
    [style setLineHeightMultiple:RPTVCLineHeightMultiple];
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

+ (ReaderPostTableViewCell *)cellForSubview:(UIView *)subview {
    UIView *view = subview;
	while (![view isKindOfClass:self]) {
		view = (UIView *)view.superview;
	}
    
    if (view == subview)
        return nil;
    
    return (ReaderPostTableViewCell *)view;
}


#pragma mark - Lifecycle Methods

- (void)dealloc {
	self.post = nil;
}


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0.9453125f alpha:1.f];
        self.contentView.backgroundColor = [WPStyleGuide itsEverywhereGrey];

        _sideBorderView = [[UIView alloc] init];
        _sideBorderView.backgroundColor = [UIColor colorWithWhite:0.9f alpha:1.f];
		_sideBorderView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.contentView addSubview:_sideBorderView];

		self.containerView = [[UIView alloc] init];
		_containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _containerView.backgroundColor = [UIColor whiteColor];
        _containerView.opaque = YES;
		[self.contentView addSubview:_containerView];

		[self buildPostContent];
		[self buildMetaContent];
    }
	
    return self;
}

- (void)setHighlightedEffect:(BOOL)highlighted animated:(BOOL)animated {
    [UIView animateWithDuration:animated ? .1f : 0.f
                          delay:0
                        options:UIViewAnimationCurveEaseInOut
                     animations:^{
                         _sideBorderView.hidden = highlighted;
                         self.alpha = highlighted ? .7f : 1.f;
                         if (highlighted) {
                             CGFloat perspective = IS_IPAD ? -0.00005 : -0.0001;
                             CATransform3D transform = CATransform3DIdentity;
                             transform.m24 = perspective;
                             transform = CATransform3DScale(transform, .98f, .98f, 1);
                             self.contentView.layer.transform = transform;
                             self.contentView.layer.shouldRasterize = YES;
                             self.contentView.layer.rasterizationScale = [[UIScreen mainScreen] scale];
                         } else {
                             self.contentView.layer.shouldRasterize = NO;
                             self.contentView.layer.transform = CATransform3DIdentity;
                         }
                     } completion:nil];
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

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    BOOL previouslyHighlighted = self.highlighted;
    [super setHighlighted:highlighted animated:animated];

    if (previouslyHighlighted == highlighted)
        return;

    if (highlighted) {
        [self setHighlightedEffect:highlighted animated:animated];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!self.selected) {
                [self setHighlightedEffect:highlighted animated:animated];
            }
        });
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    [self setHighlightedEffect:selected animated:animated];
}

- (void)buildPostContent {
	self.cellImageView.contentMode = UIViewContentModeScaleAspectFill;
	[_containerView addSubview:self.cellImageView];

	self.titleLabel = [[UILabel alloc] init];
	_titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	_titleLabel.backgroundColor = [UIColor clearColor];
	_titleLabel.textColor = [UIColor colorWithHexString:@"333"];
	_titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
	_titleLabel.numberOfLines = 0;
	[_containerView addSubview:_titleLabel];
    
    self.titleBorder = [[CALayer alloc] init];
    _titleBorder.backgroundColor = [[UIColor colorWithHexString:@"f1f1f1"] CGColor];
    [_containerView.layer addSublayer:_titleBorder];
	
	self.snippetLabel = [[UILabel alloc] init];
	_snippetLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	_snippetLabel.backgroundColor = [UIColor clearColor];
	_snippetLabel.textColor = [UIColor colorWithHexString:@"333"];
	_snippetLabel.lineBreakMode = NSLineBreakByTruncatingTail;
	_snippetLabel.numberOfLines = 4;
	[_containerView addSubview:_snippetLabel];
    
    self.byView = [[UIView alloc] init];
	_byView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	_byView.backgroundColor = [UIColor whiteColor];
    _byView.userInteractionEnabled = YES;
	[_containerView addSubview:_byView];
	
    CGRect avatarFrame = CGRectMake(RPTVCHorizontalInnerPadding, RPTVCAuthorPadding, RPTVCAvatarSize, RPTVCAvatarSize);
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
    [_followButton setTitleEdgeInsets: UIEdgeInsetsMake(0, RPTVCSmallButtonLeftPadding, 0, 0)];
    [_followButton setImage:[UIImage imageNamed:@"reader-postaction-follow"] forState:UIControlStateNormal];
    [_followButton setImage:[UIImage imageNamed:@"reader-postaction-following"] forState:UIControlStateSelected];
    [_followButton setTitleColor:[UIColor colorWithHexString:@"aaa"] forState:UIControlStateNormal];
    [_byView addSubview:_followButton];
    
    self.tagButton = [ReaderButton buttonWithType:UIButtonTypeCustom];
    _tagButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    _tagButton.backgroundColor = [UIColor clearColor];
    _tagButton.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:12.0f];
    [_tagButton setTitleEdgeInsets: UIEdgeInsetsMake(0, RPTVCSmallButtonLeftPadding, 0, 0)];
    [_tagButton setImage:[UIImage imageNamed:@"reader-postaction-tag"] forState:UIControlStateNormal];
    [_tagButton setTitleColor:[UIColor colorWithHexString:@"aaa"] forState:UIControlStateNormal];
    [_containerView addSubview:_tagButton];
}

- (void)buildMetaContent {
	self.metaView = [[UIView alloc] init];
	_metaView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	_metaView.backgroundColor = [UIColor clearColor];
	[_containerView addSubview:_metaView];
    
    self.metaBorder = [[CALayer alloc] init];
    _metaBorder.backgroundColor = [[UIColor colorWithHexString:@"f1f1f1"] CGColor];
    [_metaView.layer addSublayer:_metaBorder];
    
    self.timeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _timeButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    _timeButton.backgroundColor = [UIColor clearColor];
    _timeButton.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:12.0f];
    [_timeButton setTitleEdgeInsets: UIEdgeInsetsMake(0, RPTVCSmallButtonLeftPadding, 0, 0)];
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
    
    CGFloat leftPadding = IS_IPHONE ? RPTVCHorizontalOuterPadding : 0;
	CGFloat contentWidth = self.frame.size.width - leftPadding * 2;
    CGFloat innerContentWidth = contentWidth - RPTVCHorizontalInnerPadding * 2;
	CGFloat nextY = RPTVCAuthorPadding;
	CGFloat height = 0.0f;
    
    CGRect frame = CGRectMake(leftPadding, 0, contentWidth, self.frame.size.height - RPTVCVerticalPadding);
    _containerView.frame = frame;
    
    _byView.frame = CGRectMake(0, 0, contentWidth, RPTVCAuthorViewHeight + RPTVCAuthorPadding * 2);
    CGFloat bylineX = RPTVCAvatarSize + RPTVCAuthorPadding + RPTVCHorizontalInnerPadding;
    _bylineLabel.frame = CGRectMake(bylineX, RPTVCAuthorPadding - 2, contentWidth - bylineX, 18);
    
    if ([self.post isFollowable]) {
        _followButton.hidden = NO;
        CGFloat followX = bylineX - 4; // Fudge factor for image alignment
        CGFloat followY = RPTVCAuthorPadding + _bylineLabel.frame.size.height - 2;
        height = ceil([_followButton.titleLabel suggestedSizeForWidth:innerContentWidth].height);
        _followButton.frame = CGRectMake(followX, followY, contentWidth - bylineX, height);
    } else {
        _followButton.hidden = YES;
    }

    nextY += RPTVCAuthorViewHeight + RPTVCAuthorPadding;

	// Are we showing an image? What size should it be?
	if (_showImage) {
        _titleBorder.hidden = YES;
		height = ceilf(contentWidth * RPTVCMaxImageHeightPercentage);
		self.cellImageView.frame = CGRectMake(0, nextY, contentWidth, height);
		nextY += height;
    } else {
        _titleBorder.hidden = NO;
        _titleBorder.frame = CGRectMake(RPTVCHorizontalInnerPadding, nextY, contentWidth - RPTVCHorizontalInnerPadding * 2, RPTVCBorderHeight);
    }
    
	// Position the title
    nextY += RPTVCVerticalPadding;
	height = ceil([_titleLabel suggestedSizeForWidth:innerContentWidth].height);
	_titleLabel.frame = CGRectMake(RPTVCHorizontalInnerPadding, nextY, innerContentWidth, height);
	nextY += height + RPTVCVerticalPadding;

	// Position the snippet
    if ([self.post.summary length] > 0) {
        height = ceil([_snippetLabel suggestedSizeForWidth:innerContentWidth].height);
        height = MIN(height, RPTVCMaxSummaryHeight);
        _snippetLabel.frame = CGRectMake(RPTVCHorizontalInnerPadding, nextY, innerContentWidth, height);
        nextY += ceilf(height + RPTVCVerticalPadding);
    }

    // Tag
    if ([self.post.primaryTagName length] > 0) {
        height = ceil([_tagButton.titleLabel suggestedSizeForWidth:innerContentWidth].height);
        _tagButton.frame = CGRectMake(RPTVCHorizontalInnerPadding, nextY, innerContentWidth, height);
        nextY += height + RPTVCVerticalPadding;
        self.tagButton.hidden = NO;
    } else {
        self.tagButton.hidden = YES;
    }

	// Position the meta view and its subviews
	_metaView.frame = CGRectMake(0, nextY, contentWidth, RPTVCMetaViewHeight);
    _metaBorder.frame = CGRectMake(RPTVCHorizontalInnerPadding, 0, contentWidth - RPTVCHorizontalInnerPadding * 2, RPTVCBorderHeight);

    BOOL commentsOpen = [[self.post commentsOpen] boolValue];
	CGFloat buttonWidth = RPTVCControlButtonWidth;
    CGFloat buttonX = _metaView.frame.size.width - RPTVCControlButtonWidth;
    CGFloat buttonY = RPTVCBorderHeight; // Just below the line
    
    // Button order from right-to-left: Like, [Comment], Reblog,
    _likeButton.frame = CGRectMake(buttonX, buttonY, buttonWidth, RPTVCControlButtonHeight);
    buttonX -= buttonWidth + RPTVCControlButtonSpacing;
    
    if (commentsOpen) {
        self.commentButton.hidden = NO;
        self.commentButton.frame = CGRectMake(buttonX, buttonY, buttonWidth, RPTVCControlButtonHeight);
        buttonX -= buttonWidth + RPTVCControlButtonSpacing;
    } else {
        self.commentButton.hidden = YES;
    }
    _reblogButton.frame = CGRectMake(buttonX, buttonY, buttonWidth - RPTVCControlButtonBorderSize, RPTVCControlButtonHeight);
    
    CGFloat timeWidth = contentWidth - _reblogButton.frame.origin.x;
    _timeButton.frame = CGRectMake(RPTVCHorizontalInnerPadding, RPTVCBorderHeight, timeWidth, RPTVCControlButtonHeight);
    
    CGFloat sideBorderX = RPTVCHorizontalOuterPadding - 1; // Just to the left of the container
    CGFloat sideBorderHeight = self.frame.size.height - RPTVCVerticalPadding; // Just below it
    _sideBorderView.frame = CGRectMake(sideBorderX, 1, self.frame.size.width - sideBorderX * 2, sideBorderHeight);
}

- (void)prepareForReuse {
	[super prepareForReuse];

    _avatarIsSet = NO;

	_bylineLabel.text = nil;
	_titleLabel.text = nil;
	_snippetLabel.text = nil;
    [_tagButton setTitle:nil forState:UIControlStateNormal];

    [self setHighlightedEffect:NO animated:NO];
}


#pragma mark - Instance Methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	[self updateControlBar];
}

- (void)configureCell:(ReaderPost *)post {
	self.post = post;
    
    // This will show the placeholder avatar. Do this here instead of prepareForReusue
    // so avatars show up after a cell is created, and not dequeued.
    [self setAvatar:nil];

	_titleLabel.attributedText = [ReaderPostTableViewCell titleAttributedStringForPost:post];
	_snippetLabel.attributedText = [ReaderPostTableViewCell summaryAttributedStringForPost:post];

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

- (void)likeAction:(id)sender {
	[self.post toggleLikedWithSuccess:^{
        if ([self.post.isLiked boolValue]) {
            [WPMobileStats trackEventForWPCom:StatsEventReaderLikedPost];
        } else {
            [WPMobileStats trackEventForWPCom:StatsEventReaderUnlikedPost];
        }
	} failure:^(NSError *error) {
		DDLogError(@"Error Liking Post : %@", [error localizedDescription]);
		[self updateControlBar];
	}];
	
	[self updateControlBar];
}

@end
