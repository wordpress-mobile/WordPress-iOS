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

const CGFloat RPTVCVerticalPadding = 10.0f;
const CGFloat RPTVCHorizontalPadding = 10.0f;
const CGFloat RPTVCMetaViewHeightWithButtons = 101.0f;
const CGFloat RPTVCMetaViewHeightSansButtons = 52.0f;

// Control buttons (Like, Reblog, ...)
const CGFloat RPTVCControlButtonHeight = 48.0f;
const CGFloat RPTVCControlButtonWidth = 48.0f;
const CGFloat RPTVCControlButtonVerticalPadding = 4.0f;
const CGFloat RPTVCControlButtonSpacing = 12.0f;
const CGFloat RPTVCControlButtonBorderSize = 0.0f;

@interface ReaderPostTableViewCell()

@property (nonatomic, strong) ReaderPost *post;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *snippetLabel;

@property (nonatomic, strong) UIView *metaView;

@property (nonatomic, strong) UIView *byView;
@property (nonatomic, strong) UILabel *bylineLabel;

@property (nonatomic, strong) UIView *controlView;
@property (nonatomic, strong) UIButton *likeButton;
@property (nonatomic, strong) UIButton *reblogButton;
@property (nonatomic, strong) UIButton *commentButton;

@property (nonatomic, assign) BOOL showImage;

- (void)buildPostContent;
- (void)buildMetaContent;
- (void)handleLikeButtonTapped:(id)sender;

@end

@implementation ReaderPostTableViewCell {
    BOOL _avatarIsSet;
    UIView *_sideBorderView;
}

+ (CGFloat)cellHeightForPost:(ReaderPost *)post withWidth:(CGFloat)width {
	CGFloat desiredHeight = 0.0f;
	CGFloat vpadding = RPTVCVerticalPadding;

    // Margins
    CGFloat contentWidth = width;
    if (IS_IPAD) {
        contentWidth = contentWidth * (1 - WPTableViewCellMarginPercentage * 2);
    }
    
    // iPhone has extra padding around each cell
    if (IS_IPHONE) {
        contentWidth -= RPTVCHorizontalPadding * 2;
    }

	// Are we showing an image? What size should it be?
	if (post.featuredImageURL) {
		CGFloat height = ceilf((contentWidth * 0.66f));
		desiredHeight += height;
	}

	desiredHeight += vpadding;

	desiredHeight += [post.postTitle sizeWithFont:[UIFont fontWithName:@"OpenSans-Light" size:20.0f] constrainedToSize:CGSizeMake(contentWidth, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping].height;
	desiredHeight += vpadding;

	desiredHeight += [post.summary sizeWithFont:[UIFont fontWithName:@"OpenSans" size:13.0f] constrainedToSize:CGSizeMake(contentWidth, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping].height;
	desiredHeight += vpadding;

	// Size of the meta view
	if ([post isWPCom]) {
		desiredHeight += RPTVCMetaViewHeightWithButtons;
	} else {
		desiredHeight += RPTVCMetaViewHeightSansButtons;
	}
	
	// bottom padding
	desiredHeight += vpadding;

	return ceil(desiredHeight);
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
	_titleLabel.font = [UIFont fontWithName:@"OpenSans-Light" size:20.0f];
	_titleLabel.textColor = [UIColor colorWithRed:64.0f/255.0f green:64.0f/255.0f blue:64.0f/255.0f alpha:1.0];
	_titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
	_titleLabel.numberOfLines = 0;
	[_containerView addSubview:_titleLabel];
	
	self.snippetLabel = [[UILabel alloc] init];
	_snippetLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	_snippetLabel.backgroundColor = [UIColor clearColor];
	_snippetLabel.font = [UIFont fontWithName:@"OpenSans" size:13.0f];
	_snippetLabel.textColor = [UIColor colorWithRed:64.0f/255.0f green:64.0f/255.0f blue:64.0f/255.0f alpha:1.0];
	_snippetLabel.lineBreakMode = NSLineBreakByWordWrapping;
	_snippetLabel.numberOfLines = 0;
	[_containerView addSubview:_snippetLabel];
}

- (void)buildMetaContent {
	self.metaView = [[UIView alloc] init];
	_metaView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	_metaView.backgroundColor = [UIColor clearColor];
	[_containerView addSubview:_metaView];

	self.byView = [[UIView alloc] init];
	_byView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	_byView.backgroundColor = [UIColor whiteColor];
	[_metaView addSubview:_byView];
	
	self.avatarImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10.0f, 10.0f, 32.0f, 32.0f)];
	[_byView addSubview:_avatarImageView];
	
	self.bylineLabel = [[UILabel alloc] init];
	_bylineLabel.backgroundColor = [UIColor clearColor];
	_bylineLabel.numberOfLines = 2;
	_bylineLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	_bylineLabel.font = [UIFont fontWithName:@"OpenSans" size:12.0f];
	_bylineLabel.adjustsFontSizeToFitWidth = NO;
	_bylineLabel.textColor = [UIColor colorWithHexString:@"c0c0c0"];
	[_byView addSubview:_bylineLabel];

	self.likeButton = [ReaderButton buttonWithType:UIButtonTypeCustom];
	_likeButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
	_likeButton.backgroundColor = [UIColor whiteColor];
	[_likeButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0f, -5.0f, 0.0f, 0.0f)];
	[_likeButton.titleLabel setFont:[UIFont fontWithName:@"OpenSans-Bold" size:10.0f]];
	[_likeButton setTitleColor:[UIColor colorWithRed:84.0f/255.0f green:173.0f/255.0f blue:211.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
	[_likeButton setTitleColor:[UIColor colorWithRed:221.0f/255.0f green:118.0f/255.0f blue:43.0f/255.0f alpha:1.0f] forState:UIControlStateSelected];
	[_likeButton setImage:[UIImage imageNamed:@"reader-postaction-like-blue"] forState:UIControlStateNormal];
	[_likeButton setImage:[UIImage imageNamed:@"reader-postaction-like-active"] forState:UIControlStateSelected];
	[_likeButton addTarget:self action:@selector(handleLikeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
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
    
    CGFloat leftPadding = IS_IPHONE ? RPTVCHorizontalPadding : 0;
	CGFloat contentWidth = self.frame.size.width - leftPadding * 2;
    CGFloat innerContentWidth = contentWidth - RPTVCHorizontalPadding * 2;
	CGFloat vpadding = RPTVCVerticalPadding;
	CGFloat nextY = vpadding;
	CGFloat height = 0.0f;
    
    CGRect frame = CGRectMake(leftPadding, 0.0f, contentWidth, self.frame.size.height - RPTVCVerticalPadding);
    _containerView.frame = frame;

	// Are we showing an image? What size should it be?
	if (_showImage) {
		height = ceilf(contentWidth * 0.66f);
		self.cellImageView.frame = CGRectMake(RPTVCHorizontalPadding, nextY, innerContentWidth, height);
		nextY += height;
    }
    
	// Position the title
	height = ceil([_titleLabel suggestedSizeForWidth:contentWidth].height);
	_titleLabel.frame = CGRectMake(RPTVCHorizontalPadding, nextY, innerContentWidth, height);
	nextY += height + vpadding;

	// Position the snippet
	height = ceil([_snippetLabel suggestedSizeForWidth:contentWidth].height);
	_snippetLabel.frame = CGRectMake(RPTVCHorizontalPadding, nextY, innerContentWidth, height);
	nextY += ceilf(height + vpadding);

	// position the meta view and its subviews
    _byView.frame = CGRectMake(0.0f, 0.0f, contentWidth, 52.0f);
    
	height = [self.post isWPCom] ? RPTVCMetaViewHeightWithButtons : RPTVCMetaViewHeightSansButtons;
	_metaView.frame = CGRectMake(0.0f, nextY, contentWidth, height);
	
    BOOL commentsOpen = [[self.post commentsOpen] boolValue];
	CGFloat buttonWidth = RPTVCControlButtonWidth - RPTVCControlButtonBorderSize;
    CGFloat buttonX = _metaView.frame.size.width - RPTVCControlButtonWidth;
    CGFloat buttonY = RPTVCControlButtonHeight + RPTVCControlButtonVerticalPadding;
    
    // Button order from right-to-left: Like, [Comment], Reblog,
    _likeButton.frame = CGRectMake(buttonX, buttonY, buttonWidth, RPTVCControlButtonHeight);
    buttonX -= buttonWidth + RPTVCControlButtonBorderSize;
    
    if (commentsOpen) {
        self.commentButton.hidden = NO;
        self.commentButton.frame = CGRectMake(buttonX, buttonY, buttonWidth, RPTVCControlButtonHeight);
        buttonX -= buttonWidth + RPTVCControlButtonBorderSize;
    } else {
        self.commentButton.hidden = YES;
    }
    _reblogButton.frame = CGRectMake(buttonX, buttonY, buttonWidth - RPTVCControlButtonBorderSize, RPTVCControlButtonHeight);
    
    _bylineLabel.frame = CGRectMake(47.0f, 8.0f, contentWidth - 57.0f, 36.0f);
    
    CGFloat sideBorderX = RPTVCHorizontalPadding - 1; // Just to the left of the container
    CGFloat sideBorderHeight = self.frame.size.height - RPTVCVerticalPadding + 1.f; // Just below it
    _sideBorderView.frame = CGRectMake(sideBorderX, 1.f, self.frame.size.width - sideBorderX*2, sideBorderHeight);
}

- (void)prepareForReuse {
	[super prepareForReuse];

    _avatarIsSet = NO;

	_bylineLabel.text = nil;
	_titleLabel.text = nil;
	_snippetLabel.text = nil;

    [self setHighlightedEffect:NO animated:NO];
}


#pragma mark - Instance Methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	[self updateControlBar];
}

- (void)setReblogTarget:(id)target action:(SEL)selector {
	[_reblogButton addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
}

- (void)configureCell:(ReaderPost *)post {
	self.post = post;
    
    // This will show the placeholder avatar. Do this here instead of prepareForReusue
    // so avatars show up after a cell is created, and not dequeued.
    [self setAvatar:nil];

	_titleLabel.text = [post.postTitle trim];
	_snippetLabel.text = post.summary;

    NSString *onBlog = [NSString stringWithFormat:NSLocalizedString(@"on %@", @"'on <Blog Name>', displayed on reader list for each post"), post.blogName];
	_bylineLabel.text = [NSString stringWithFormat:@"%@\n%@", [post prettyDateString], onBlog];

	self.showImage = NO;
	self.cellImageView.hidden = YES;
    self.cellImageView.contentMode = UIViewContentModeCenter;
    self.cellImageView.image = [UIImage imageNamed:@"wp_img_placeholder"];
	if (post.featuredImageURL) {
		self.showImage = YES;
		self.cellImageView.hidden = NO;
	}

	if ([self.post isWPCom]) {
		_likeButton.hidden = NO;
		_reblogButton.hidden = NO;
	} else {
		_likeButton.hidden = YES;
		_reblogButton.hidden = YES;
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

- (void)handleLikeButtonTapped:(id)sender {

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
