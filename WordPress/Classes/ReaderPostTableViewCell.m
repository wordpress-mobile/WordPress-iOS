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

#define RPTVCVerticalPadding 10.0f
#define MetaViewHeightWithButtons 101.0f
#define MetaViewHeightSansButtons 52.0f

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

@property (nonatomic, assign) BOOL showImage;

- (void)buildPostContent;
- (void)buildMetaContent;
- (void)handleLikeButtonTapped:(id)sender;

@end

@implementation ReaderPostTableViewCell {
    BOOL _featuredImageIsSet;
    BOOL _avatarIsSet;
    UIView *_sideBorderView;
    UIView *_bottomBorderView;
}

+ (CGFloat)cellHeightForPost:(ReaderPost *)post withWidth:(CGFloat)width {
	CGFloat desiredHeight = 0.0f;
	CGFloat vpadding = RPTVCVerticalPadding;

	// Do the math. We can't trust the cell's contentView's frame because
	// its not updated at a useful time during rotation.
	CGFloat contentWidth = width - 20.0f; // 10px padding on either side.

	// Are we showing an image? What size should it be?
	if(post.featuredImageURL) {
		CGFloat height = ceilf((contentWidth * 0.66f));
		desiredHeight += height;
	}

	desiredHeight += vpadding;

	desiredHeight += [post.postTitle sizeWithFont:[UIFont fontWithName:@"OpenSans-Light" size:20.0f] constrainedToSize:CGSizeMake(contentWidth, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap].height;
	desiredHeight += vpadding;

	desiredHeight += [post.summary sizeWithFont:[UIFont fontWithName:@"OpenSans" size:13.0f] constrainedToSize:CGSizeMake(contentWidth, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap].height;
	desiredHeight += vpadding;

	// Size of the meta view
	if ([post isWPCom]) {
		desiredHeight += MetaViewHeightWithButtons;
	} else {
		desiredHeight += MetaViewHeightSansButtons;
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
        self.contentView.backgroundColor = [UIColor colorWithWhite:0.9453125f alpha:1.f];
		CGRect frame = CGRectMake(10.0f, 0.0f, self.contentView.frame.size.width - 20.0f, self.contentView.frame.size.height - 10.0f);

        _sideBorderView = [[UIView alloc] initWithFrame:CGRectMake(9.f, 0.f, self.contentView.frame.size.width - 18.f, frame.size.height + 3.f)];
        _sideBorderView.backgroundColor = [UIColor colorWithWhite:0.9296875f alpha:1.f];
		_sideBorderView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.contentView addSubview:_sideBorderView];

        _bottomBorderView = [[UIView alloc] initWithFrame:CGRectMake(10.f, CGRectGetMaxY(frame) + 1.f, self.contentView.frame.size.width - 20.f, 2.f)];
        _bottomBorderView.backgroundColor = [UIColor colorWithWhite:0.90625f alpha:1.f];
		_bottomBorderView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        [self.contentView addSubview:_bottomBorderView];

		self.containerView = [[UIView alloc] initWithFrame:frame];
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
                         _bottomBorderView.hidden = highlighted;
                         self.alpha = highlighted ? .7f : 1.f;
                         if (highlighted) {
                             CGFloat perspective = -0.0001;
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
	if ([post isEqual:_post]) {
		return;
	}
	
	if (_post) {
		[_post removeObserver:self forKeyPath:@"isReblogged" context:@"reblogging"];
	}
	
	_post = post;
	[_post addObserver:self forKeyPath:@"isReblogged" options:NSKeyValueObservingOptionNew context:@"reblogging"];
}


- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    BOOL previouslyHighlighted = self.highlighted;
    [super setHighlighted:highlighted animated:animated];

    if (previouslyHighlighted == highlighted) {
        return;
    }

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

	CGFloat width = _containerView.frame.size.width - 20.0f;
	self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 0.0, width, 44.0f)];
	_titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	_titleLabel.backgroundColor = [UIColor clearColor];
	_titleLabel.font = [UIFont fontWithName:@"OpenSans-Light" size:20.0f];
	_titleLabel.textColor = [UIColor colorWithRed:64.0f/255.0f green:64.0f/255.0f blue:64.0f/255.0f alpha:1.0];
	_titleLabel.lineBreakMode = UILineBreakModeWordWrap;
	_titleLabel.numberOfLines = 0;
	[_containerView addSubview:_titleLabel];
	
	self.snippetLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 0.0, width, 44.0f)];
	_snippetLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	_snippetLabel.backgroundColor = [UIColor clearColor];
	_snippetLabel.font = [UIFont fontWithName:@"OpenSans" size:13.0f];
	_snippetLabel.textColor = [UIColor colorWithRed:64.0f/255.0f green:64.0f/255.0f blue:64.0f/255.0f alpha:1.0];
	_snippetLabel.lineBreakMode = UILineBreakModeWordWrap;
	_snippetLabel.numberOfLines = 0;
	[_containerView addSubview:_snippetLabel];
}


- (void)buildMetaContent {
	CGFloat width = _containerView.frame.size.width;
	self.metaView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, width, 102.0f)];
	_metaView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	_metaView.backgroundColor = [UIColor colorWithWhite:0.95703125f alpha:1.f];
	[_containerView addSubview:_metaView];

	self.byView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, width, 52.0f)];
	_byView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	_byView.backgroundColor = [UIColor whiteColor];
	[_metaView addSubview:_byView];
	
	self.avatarImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10.0f, 10.0f, 32.0f, 32.0f)];
	[_byView addSubview:_avatarImageView];
	
	self.bylineLabel = [[UILabel alloc] initWithFrame:CGRectMake(47.0f, 8.0f, width - 57.0f, 36.0f)];
	_bylineLabel.backgroundColor = [UIColor clearColor];
	_bylineLabel.numberOfLines = 2;
	_bylineLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	_bylineLabel.font = [UIFont fontWithName:@"OpenSans" size:12.0f];
	_bylineLabel.adjustsFontSizeToFitWidth = NO;
	_bylineLabel.textColor = [UIColor colorWithHexString:@"c0c0c0"];
	[_byView addSubview:_bylineLabel];
	
	
	CGFloat w = width / 2.0f;
	self.likeButton = [ReaderButton buttonWithType:UIButtonTypeCustom];
	_likeButton.frame = CGRectMake(0.0f, 53.0f, w, 48.0f);
	_likeButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
	_likeButton.backgroundColor = [UIColor whiteColor];
	[_likeButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0f, -5.0f, 0.0f, 0.0f)];
	[_likeButton.titleLabel setFont:[UIFont fontWithName:@"OpenSans-Bold" size:10.0f]];
	[_likeButton setTitleColor:[UIColor colorWithRed:84.0f/255.0f green:173.0f/255.0f blue:211.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
	[_likeButton setTitleColor:[UIColor colorWithRed:221.0f/255.0f green:118.0f/255.0f blue:43.0f/255.0f alpha:1.0f] forState:UIControlStateSelected];
	[_likeButton setImage:[UIImage imageNamed:@"reader-postaction-like"] forState:UIControlStateNormal];
	[_likeButton setImage:[UIImage imageNamed:@"reader-postaction-like-active"] forState:UIControlStateSelected];
	[_likeButton addTarget:self action:@selector(handleLikeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
	[_metaView addSubview:_likeButton];
	
	self.reblogButton = [ReaderButton buttonWithType:UIButtonTypeCustom];
	_reblogButton.frame = CGRectMake(w + 1.0f, 53.0f, width - w - 1.f, 48.0f);
	_reblogButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
	_reblogButton.backgroundColor = [UIColor whiteColor];
	[_reblogButton setImage:[UIImage imageNamed:@"reader-postaction-reblog"] forState:UIControlStateNormal];
	[_reblogButton setImage:[UIImage imageNamed:@"reader-postaction-reblog-active"] forState:UIControlStateHighlighted];
	[_reblogButton setImage:[UIImage imageNamed:@"reader-postaction-reblog-done"] forState:UIControlStateSelected];
	[_metaView addSubview:_reblogButton];
	
}

- (void)layoutSubviews {
	[super layoutSubviews];

	CGFloat contentWidth = _containerView.frame.size.width;
	CGFloat nextY = 0.0f;
	CGFloat vpadding = RPTVCVerticalPadding;
	CGFloat height = 0.0f;

	// Are we showing an image? What size should it be?
	if(_showImage) {
		height = ceilf(contentWidth * 0.66f);
		self.cellImageView.frame = CGRectMake(0.0f, nextY, contentWidth, height);
		nextY += height + vpadding;
	} else {
		nextY += vpadding;
	}

	// Position the title
	height = ceil([_titleLabel suggestedSizeForWidth:contentWidth].height);
	_titleLabel.frame = CGRectMake(10.0f, nextY, contentWidth-20.0f, height);
	nextY += height + vpadding;

	// Position the snippet
	height = ceil([_snippetLabel suggestedSizeForWidth:contentWidth].height);
	_snippetLabel.frame = CGRectMake(10.0f, nextY, contentWidth-20.0f, height);
	nextY += ceilf(height + vpadding);

	// position the meta view
	height = [self.post isWPCom] ? MetaViewHeightWithButtons : MetaViewHeightSansButtons;
	_metaView.frame = CGRectMake(0.0f, nextY, contentWidth, height);
	
	CGFloat w = ceilf(contentWidth / 2.0f);
	CGRect frame = _likeButton.frame;
	frame.size.width = w;
	_likeButton.frame = frame;
	
	frame = _reblogButton.frame;
	frame.origin.x = w + 1.0f;
	frame.size.width = w - 1.0f;
	_reblogButton.frame = frame;
}


- (void)prepareForReuse {
	[super prepareForReuse];

    self.cellImageView.contentMode = UIViewContentModeCenter;
    self.cellImageView.image = [UIImage imageNamed:@"wp_img_placeholder"];
    _featuredImageIsSet = NO;
    _avatarIsSet = NO;

	[self setAvatar:nil];
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

	_titleLabel.text = [post.postTitle trim];
	_snippetLabel.text = post.summary;
	
	_bylineLabel.text = [NSString stringWithFormat:@"%@ \non %@", [post prettyDateString], post.blogName];

	self.showImage = NO;
	self.cellImageView.hidden = YES;
	if (post.featuredImageURL) {
		self.showImage = YES;
		self.cellImageView.hidden = NO;

		NSInteger width = ceil(_containerView.frame.size.width);
        NSInteger height = ceil(width * 0.66f);
        CGRect imageFrame = self.cellImageView.frame;
        imageFrame.size.width = width;
        imageFrame.size.height = height;
        self.cellImageView.frame = imageFrame;
	}

	if ([self.post isWPCom]) {
		CGRect frame = _metaView.frame;
		frame.size.height = MetaViewHeightWithButtons;
		_metaView.frame = frame;
		_likeButton.hidden = NO;
		_reblogButton.hidden = NO;
	} else {
		CGRect frame = _metaView.frame;
		frame.size.height = MetaViewHeightSansButtons;
		_metaView.frame = frame;
		_likeButton.hidden = YES;
		_reblogButton.hidden = YES;
	}
	
	_reblogButton.userInteractionEnabled = ![post.isReblogged boolValue];
	
	[self updateControlBar];
}


- (void)setAvatar:(UIImage *)avatar {
    if (_avatarIsSet) {
        return;
    }
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
    if (_featuredImageIsSet) {
        return;
    }
    _featuredImageIsSet = YES;
    self.cellImageView.image = image;
}


- (void)updateControlBar {
	if (!_post) return;
	
    _likeButton.selected = _post.isLiked.boolValue;
    _reblogButton.selected = _post.isReblogged.boolValue;
	_reblogButton.userInteractionEnabled = !_reblogButton.selected;

	NSString *str = ([self.post.likeCount integerValue] > 0) ? [self.post.likeCount stringValue] : nil;
	[_likeButton setTitle:str forState:UIControlStateNormal];
}


- (void)handleLikeButtonTapped:(id)sender {

	[self.post toggleLikedWithSuccess:^{
		// Nothing to see here?
	} failure:^(NSError *error) {
		WPLog(@"Error Liking Post : %@", [error localizedDescription]);
		[self updateControlBar];
	}];
	
	[self updateControlBar];
}


@end
