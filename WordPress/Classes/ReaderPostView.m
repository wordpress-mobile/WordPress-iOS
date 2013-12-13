//
//  ReaderPostView.m
//  WordPress
//
//  Created by Michael Johnston on 11/19/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ReaderPostView.h"
#import "WPContentViewSubclass.h"
#import "ReaderButton.h"
#import "UILabel+SuggestSize.h"
#import "NSAttributedString+HTML.h"

@interface ReaderPostView()

@property (nonatomic, assign) BOOL showImage;
@property (nonatomic, strong) UIButton *tagButton;
@property (nonatomic, strong) UIButton *followButton;
@property (nonatomic, strong) UIButton *likeButton;
@property (nonatomic, strong) UIButton *reblogButton;
@property (nonatomic, strong) UIButton *commentButton;

@end

@implementation ReaderPostView

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


- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        
    }
    
    return self;
}

- (void)configurePost:(ReaderPost *)post {
    _post = post;
    self.contentProvider = post;
    
    // This will show the placeholder avatar. Do this here instead of prepareForReuse
    // so avatars show up after a cell is created, and not dequeued.
    [self setAvatar:nil];
    
	self.titleLabel.attributedText = [[self class] titleAttributedStringForPost:post];
    
    if (self.showFullContent) {
        NSData *data = [self.post.content dataUsingEncoding:NSUTF8StringEncoding];
		self.textContentView.attributedString = [[NSAttributedString alloc] initWithHTMLData:data
                                                                                 options:[WPStyleGuide defaultDTCoreTextOptions]
                                                                      documentAttributes:nil];
        [self.textContentView relayoutText];
    } else {
        self.snippetLabel.attributedText = [[self class] summaryAttributedStringForPost:post];
    }
    
    self.bylineLabel.text = [post authorString];
    [self refreshDate];
    
	self.showImage = NO;
	self.cellImageView.hidden = YES;
	if (post.featuredImageURL) {
		self.showImage = YES;
		self.cellImageView.hidden = NO;
	}
    
    if ([self.post.primaryTagName length] > 0) {
        self.tagButton.hidden = NO;
        [self.tagButton setTitle:self.post.primaryTagName forState:UIControlStateNormal];
    } else {
        self.tagButton.hidden = YES;
    }
    
	if ([self.post isWPCom]) {
		self.likeButton.hidden = NO;
		self.reblogButton.hidden = NO;
        self.commentButton.hidden = NO;
	} else {
		self.likeButton.hidden = YES;
		self.reblogButton.hidden = YES;
        self.commentButton.hidden = YES;
	}
    
    [self.followButton setSelected:[self.post.isFollowing boolValue]];
	self.reblogButton.userInteractionEnabled = ![post.isReblogged boolValue];
	
	[self updateActionButtons];

}

- (UIView *)buildContentView {
    return self.showFullContent ? [self viewForFullContent] : [self viewForContentPreview];
}

- (void)buildContent {
    [super buildContent];
    
    [self addSubview:[self buildContentView]];

    self.cellImageView.contentMode = UIViewContentModeScaleAspectFill;
    
    // For the full view, allow the featured image to be tapped
    if (self.showFullContent) {
        UITapGestureRecognizer *imageTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(featuredImageAction:)];
        self.cellImageView.userInteractionEnabled = YES;
        [self.cellImageView addGestureRecognizer:imageTap];
    }
	[self addSubview:self.cellImageView];

    
    _followButton = [ReaderButton buttonWithType:UIButtonTypeCustom];
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
    [super.byView addSubview:_followButton];
    
    _tagButton = [ReaderButton buttonWithType:UIButtonTypeCustom];
    _tagButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    _tagButton.backgroundColor = [UIColor clearColor];
    _tagButton.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:12.0f];
    [_tagButton setTitleEdgeInsets: UIEdgeInsetsMake(0, RPVSmallButtonLeftPadding, 0, 0)];
    [_tagButton setImage:[UIImage imageNamed:@"reader-postaction-tag"] forState:UIControlStateNormal];
    [_tagButton setTitleColor:[UIColor colorWithHexString:@"aaa"] forState:UIControlStateNormal];
    [_tagButton addTarget:self action:@selector(tagAction:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_tagButton];
    
	_likeButton = [ReaderButton buttonWithType:UIButtonTypeCustom];
	_likeButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
	_likeButton.backgroundColor = [UIColor clearColor];
	[_likeButton setImage:[UIImage imageNamed:@"reader-postaction-like-blue"] forState:UIControlStateNormal];
	[_likeButton setImage:[UIImage imageNamed:@"reader-postaction-like-active"] forState:UIControlStateSelected];
    [_likeButton addTarget:self action:@selector(likeAction:) forControlEvents:UIControlEventTouchUpInside];
	[super.bottomView addSubview:_likeButton];
	
	_reblogButton = [ReaderButton buttonWithType:UIButtonTypeCustom];
	_reblogButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
	_reblogButton.backgroundColor = [UIColor clearColor];
	[_reblogButton setImage:[UIImage imageNamed:@"reader-postaction-reblog-blue"] forState:UIControlStateNormal];
	[_reblogButton setImage:[UIImage imageNamed:@"reader-postaction-reblog-done"] forState:UIControlStateSelected];
    [_reblogButton addTarget:self action:@selector(reblogAction:) forControlEvents:UIControlEventTouchUpInside];
	[super.bottomView addSubview:_reblogButton];
    
    _commentButton = [ReaderButton buttonWithType:UIButtonTypeCustom];
	_commentButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
	_commentButton.backgroundColor = [UIColor clearColor];
	[_commentButton setImage:[UIImage imageNamed:@"reader-postaction-comment-blue"] forState:UIControlStateNormal];
	[_commentButton setImage:[UIImage imageNamed:@"reader-postaction-comment-active"] forState:UIControlStateSelected];
    [_commentButton addTarget:self action:@selector(commentAction:) forControlEvents:UIControlEventTouchUpInside];
	[super.bottomView addSubview:_commentButton];
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
    
    self.byView.frame = CGRectMake(0, 0, contentWidth, RPVAuthorViewHeight + RPVAuthorPadding * 2);
    CGFloat bylineX = RPVAvatarSize + RPVAuthorPadding + RPVHorizontalInnerPadding;
    self.bylineLabel.frame = CGRectMake(bylineX, RPVAuthorPadding - 2, contentWidth - bylineX, 18);
    
    if ([self.post isFollowable]) {
        self.followButton.hidden = NO;
        CGFloat followX = bylineX - 4; // Fudge factor for image alignment
        CGFloat followY = RPVAuthorPadding + self.bylineLabel.frame.size.height - 2;
        height = ceil([self.followButton.titleLabel suggestedSizeForWidth:innerContentWidth].height);
        self.followButton.frame = CGRectMake(followX, followY, RPVFollowButtonWidth, height);
    } else {
        self.followButton.hidden = YES;
    }
    
    nextY += RPVAuthorViewHeight + RPVAuthorPadding;
    
	// Are we showing an image? What size should it be?
	if (_showImage) {
        self.titleBorder.hidden = YES;
		height = ceilf(contentWidth * RPVMaxImageHeightPercentage);
		self.cellImageView.frame = CGRectMake(0, nextY, contentWidth, height);
		nextY += height;
    } else {
        self.titleBorder.hidden = NO;
        self.titleBorder.frame = CGRectMake(RPVHorizontalInnerPadding, nextY, contentWidth - RPVHorizontalInnerPadding * 2, RPVBorderHeight);
    }
    
	// Position the title
    nextY += RPVVerticalPadding;
	height = ceil([self.titleLabel suggestedSizeForWidth:innerContentWidth].height);
	self.titleLabel.frame = CGRectMake(RPVHorizontalInnerPadding, nextY, innerContentWidth, height);
	nextY += height + RPVTitlePaddingBottom;
    
	// Position the snippet / content
    if ([self.post.summary length] > 0) {
        if (self.showFullContent) {
            [self.textContentView relayoutText];
            height = [self.textContentView suggestedFrameSizeToFitEntireStringConstraintedToWidth:contentWidth].height;
            CGRect textContainerFrame = self.textContentView.frame;
            textContainerFrame.size.width = contentWidth;
            textContainerFrame.size.height = height;
            textContainerFrame.origin.y = nextY;
            self.textContentView.frame = textContainerFrame;
        } else {
            height = ceil([self.snippetLabel suggestedSizeForWidth:innerContentWidth].height);
            self.snippetLabel.frame = CGRectMake(RPVHorizontalInnerPadding, nextY, innerContentWidth, height);
        }
        nextY += ceilf(height) + RPVVerticalPadding;
    }
    
    // Tag
    // TODO: reenable tags once a better browsing experience is implemented
    /*    if ([self.post.primaryTagName length] > 0) {
     height = ceil([self.tagButton.titleLabel suggestedSizeForWidth:innerContentWidth].height);
     self.tagButton.frame = CGRectMake(RPVHorizontalInnerPadding, nextY, innerContentWidth, height);
     nextY += height + RPVVerticalPadding;
     self.tagButton.hidden = NO;
     } else {
     self.tagButton.hidden = YES;
     }
     */
    
	// Position the meta view and its subviews
	self.bottomView.frame = CGRectMake(0, nextY, contentWidth, RPVMetaViewHeight);
    self.bottomBorder.frame = CGRectMake(RPVHorizontalInnerPadding, 0, contentWidth - RPVHorizontalInnerPadding * 2, RPVBorderHeight);
    
    BOOL commentsOpen = [[self.post commentsOpen] boolValue] && [self.post isWPCom];
	CGFloat buttonWidth = RPVControlButtonWidth;
    CGFloat buttonX = self.bottomView.frame.size.width - RPVControlButtonWidth;
    CGFloat buttonY = RPVBorderHeight; // Just below the line
    
    // Button order from right-to-left: Like, [Comment], Reblog,
    self.likeButton.frame = CGRectMake(buttonX, buttonY, buttonWidth, RPVControlButtonHeight);
    buttonX -= buttonWidth + RPVControlButtonSpacing;
    
    if (commentsOpen) {
        self.commentButton.hidden = NO;
        self.commentButton.frame = CGRectMake(buttonX, buttonY, buttonWidth, RPVControlButtonHeight);
        buttonX -= buttonWidth + RPVControlButtonSpacing;
    } else {
        self.commentButton.hidden = YES;
    }
    self.reblogButton.frame = CGRectMake(buttonX, buttonY, buttonWidth - RPVControlButtonBorderSize, RPVControlButtonHeight);
    
    CGFloat timeWidth = contentWidth - self.reblogButton.frame.origin.x;
    self.timeButton.frame = CGRectMake(RPVHorizontalInnerPadding, RPVBorderHeight, timeWidth, RPVControlButtonHeight);
    
    // Update own frame
    CGRect ownFrame = self.frame;
    
    ownFrame.size.height = nextY + RPVMetaViewHeight - 1;
    self.frame = ownFrame;
}

- (void)reset {
    [super reset];
    [self.tagButton setTitle:nil forState:UIControlStateNormal];
    [self.followButton setSelected:NO];
}

- (void)updateActionButtons {
    [super updateActionButtons];
    self.likeButton.selected = _post.isLiked.boolValue;
    self.reblogButton.selected = _post.isReblogged.boolValue;
	self.reblogButton.userInteractionEnabled = !_reblogButton.selected;
}

- (void)setAvatar:(UIImage *)avatar {
    if (self.avatarImageView.image)
        return;
    
    if (avatar) {
        self.avatarImageView.image = avatar;
    } else if ([self.post isWPCom]) {
        self.avatarImageView.image = [UIImage imageNamed:@"wpcom_blavatar"];
    } else {
        self.avatarImageView.image = [UIImage imageNamed:@"wporg_blavatar"];
    }
}

- (BOOL)privateContent {
    return self.post.isPrivate;
}

@end