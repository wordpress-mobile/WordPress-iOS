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
#import "ContentActionButton.h"
#import "UILabel+SuggestSize.h"
#import "NSAttributedString+HTML.h"
#import "NSString+Helpers.h" 

static NSInteger const MaxNumberOfLinesForTitleForSummary = 3;

@interface ReaderPostView()

@property (nonatomic, assign) BOOL showImage;
@property (nonatomic, strong) UIButton *tagButton;
@property (nonatomic, strong) UIButton *likeButton;
@property (nonatomic, strong) UIButton *reblogButton;
@property (nonatomic, strong) UIButton *commentButton;
@property (assign) BOOL showFullContent;

@end

@implementation ReaderPostView

+ (CGFloat)heightForPost:(ReaderPost *)post withWidth:(CGFloat)width showFullContent:(BOOL)showFullContent {
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
    NSAttributedString *postTitle = [self titleAttributedStringForPost:post showFullContent:showFullContent withWidth:contentWidth];
    desiredHeight += [postTitle boundingRectWithSize:CGSizeMake(contentWidth, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size.height;
    desiredHeight += RPVTitlePaddingBottom;
    
    // Post summary
    if ([post.summary length] > 0) {
        NSAttributedString *postSummary = [self summaryAttributedStringForPost:post];
        desiredHeight += [postSummary boundingRectWithSize:CGSizeMake(contentWidth, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size.height;
    }
    desiredHeight += RPVVerticalPadding;
    
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

+ (CGFloat)heightWithoutAttributionForPost:(ReaderPost *)post withWidth:(CGFloat)width showFullContent:(BOOL)showFullContent {
    CGFloat desiredHeight = [self heightForPost:post withWidth:width showFullContent:showFullContent];
    desiredHeight -= RPVAuthorViewHeight;
    desiredHeight -= RPVAuthorPadding;
    return desiredHeight;
}

+ (NSAttributedString *)titleAttributedStringForPost:(ReaderPost *)post showFullContent:(BOOL)showFullContent withWidth:(CGFloat) width {
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineHeightMultiple:RPVLineHeightMultiple];
    NSDictionary *attributes = @{NSParagraphStyleAttributeName : style,
                                 NSFontAttributeName : [self titleFont]};
    NSString *postTitle = [post.postTitle trim];
    if (postTitle == nil) {
        postTitle = @"";
    }
    
    NSMutableAttributedString *titleString = [[NSMutableAttributedString alloc] initWithString:postTitle
                                                                                    attributes:attributes];
    if(!showFullContent) //Ellipsizing long titles
    {
        if([postTitle length] > 0)
        {
            
            CGFloat currentHeightOfTitle = [titleString
                                            boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX)
                                            options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                            context:nil].size.height;
            
            
            CGFloat heightOfSingleLine = [[titleString attributedSubstringFromRange:NSMakeRange(0,1)]
                                          boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX)
                                          options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                          context:nil].size.height;
            
            NSInteger numberOfLines = currentHeightOfTitle / heightOfSingleLine;
            
            if(numberOfLines > MaxNumberOfLinesForTitleForSummary)
            {
                NSInteger newLength = [ReaderPostView calculateTitleLengthWithSingleLineHeight:heightOfSingleLine
                                                                             currentLineHeight:currentHeightOfTitle
                                                                                  currentTitle:titleString];
                
                
                titleString = [[NSMutableAttributedString alloc]initWithString:[postTitle stringByEllipsizingWithMaxLength:newLength preserveWords:YES]
                                                                    attributes:attributes];
                
            }
        }
    }
    
    return titleString;
}

+ (NSInteger)calculateTitleLengthWithSingleLineHeight:(CGFloat)singleLineHeight currentLineHeight:(CGFloat)currentLineHeight currentTitle:(NSAttributedString *)postTitle
{
    CGFloat allowedHeight = singleLineHeight * MaxNumberOfLinesForTitleForSummary;
    CGFloat overageRatio = allowedHeight / currentLineHeight;
    return [postTitle length] * overageRatio;
    
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

- (id)initWithFrame:(CGRect)frame {
    self = [self initWithFrame:frame showFullContent:NO];
    
    return self;
}

- (id)initWithFrame:(CGRect)frame showFullContent:(BOOL)showFullContent {
    self = [super initWithFrame:frame];
    
    if (self) {
        _showFullContent = showFullContent;
        UIView *contentView = _showFullContent ? [self viewForFullContent] : [self viewForContentPreview];
        [self addSubview:contentView];

        // For the full view, allow the featured image to be tapped
        if (self.showFullContent) {
            UITapGestureRecognizer *imageTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(featuredImageAction:)];
            super.cellImageView.userInteractionEnabled = YES;
            [super.cellImageView addGestureRecognizer:imageTap];
        }

        [self.followButton addTarget:self action:@selector(followAction:) forControlEvents:UIControlEventTouchUpInside];
        
        _tagButton = [ContentActionButton buttonWithType:UIButtonTypeCustom];
        _tagButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        _tagButton.backgroundColor = [UIColor clearColor];
        _tagButton.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:12.0f];
        [_tagButton setTitleEdgeInsets: UIEdgeInsetsMake(0, RPVSmallButtonLeftPadding, 0, 0)];
        [_tagButton setImage:[UIImage imageNamed:@"reader-postaction-tag"] forState:UIControlStateNormal];
        [_tagButton setTitleColor:[UIColor colorWithHexString:@"aaa"] forState:UIControlStateNormal];
        [_tagButton addTarget:self action:@selector(tagAction:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_tagButton];

        // Action buttons
        _reblogButton = [super addActionButtonWithImage:[UIImage imageNamed:@"reader-postaction-reblog-blue"] selectedImage:[UIImage imageNamed:@"reader-postaction-reblog-done"]];
        [_reblogButton addTarget:self action:@selector(reblogAction:) forControlEvents:UIControlEventTouchUpInside];
        
        _commentButton = [super addActionButtonWithImage:[UIImage imageNamed:@"reader-postaction-comment-blue"] selectedImage:[UIImage imageNamed:@"reader-postaction-comment-active"]];
        [_commentButton addTarget:self action:@selector(commentAction:) forControlEvents:UIControlEventTouchUpInside];
        
        _likeButton = [super addActionButtonWithImage:[UIImage imageNamed:@"reader-postaction-like-blue"] selectedImage:[UIImage imageNamed:@"reader-postaction-like-active"]];
        [_likeButton addTarget:self action:@selector(likeAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return self;
}

- (void)configurePost:(ReaderPost *)post withWidth:(CGFloat)width {
   
    // Margins
    CGFloat contentWidth = width;
    if (IS_IPAD) {
        contentWidth = WPTableViewFixedWidth;
    }
    
    contentWidth -= RPVHorizontalInnerPadding * 2;
    
    
    _post = post;
    self.contentProvider = post;
    
    // This will show the placeholder avatar. Do this here instead of prepareForReuse
    // so avatars show up after a cell is created, and not dequeued.
    [self setAvatar:nil];
    
	self.titleLabel.attributedText = [[self class] titleAttributedStringForPost:post
                                                                showFullContent:self.showFullContent
                                                                      withWidth:contentWidth];
    
    if (self.showFullContent) {
        NSData *data = [self.post.content dataUsingEncoding:NSUTF8StringEncoding];
		self.textContentView.attributedString = [[NSAttributedString alloc] initWithHTMLData:data
                                                                                 options:[WPStyleGuide defaultDTCoreTextOptions]
                                                                      documentAttributes:nil];
        [self.textContentView relayoutText];
    } else {
        self.snippetLabel.attributedText = [[self class] summaryAttributedStringForPost:post];
    }
    
    self.attributionView.authorName = [post authorString];
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

- (void)layoutSubviews {

    // Determine button visibility before parent lays them out
    BOOL commentsOpen = [[self.post commentsOpen] boolValue] && [self.post isWPCom];
    self.commentButton.hidden = !commentsOpen;

	[super layoutSubviews];
    
	CGFloat contentWidth;
    
    // On iPad, get the width from the cell instead in order to account for margins
    if (IS_IPHONE) {
        contentWidth = self.frame.size.width;
    } else {
        contentWidth = self.superview.frame.size.width;
    }
    
    CGFloat innerContentWidth = contentWidth - RPVHorizontalInnerPadding * 2;
    CGFloat nextY = [self hidesAttribution] ? 0.0f : RPVAuthorPadding;
	CGFloat height = 0.0f;

    self.followButton.hidden = ![self.post isFollowable];
    
    if (!self.hidesAttribution) {
        nextY += RPVAuthorViewHeight + RPVAuthorPadding;
    }
    
	// Are we showing an image? What size should it be?
	if (_showImage) {
        self.titleBorder.hidden = YES;
		height = ceilf(contentWidth * RPVMaxImageHeightPercentage);
		self.cellImageView.frame = CGRectMake(0, nextY, contentWidth, height);
		nextY += height;
    } else {
        self.titleBorder.hidden = [self hidesAttribution];
        self.titleBorder.frame = CGRectMake(RPVHorizontalInnerPadding, nextY, contentWidth - RPVHorizontalInnerPadding * 2, RPVBorderHeight);
    }
    
	// Position the title
    nextY += RPVVerticalPadding;
	height = ceil([self.titleLabel suggestedSizeForWidth:innerContentWidth].height);
	self.titleLabel.frame = CGRectMake(RPVHorizontalInnerPadding, nextY, innerContentWidth, height);
	nextY += height + RPVTitlePaddingBottom * (self.showFullContent ? 2.0 : 1.0);
    
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
        nextY += ceilf(height);
    }
    nextY += RPVVerticalPadding;
    
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
    self.likeButton.selected = self.post.isLiked.boolValue;
    self.reblogButton.selected = self.post.isReblogged.boolValue;
	self.reblogButton.userInteractionEnabled = !self.reblogButton.selected;
}

- (void)setAvatar:(UIImage *)avatar {
    if (avatar) {
        self.avatarImageView.image = avatar;
    } else {
        self.avatarImageView.image = [UIImage imageNamed:@"gravatar-reader"];
    }
}

- (BOOL)privateContent {
    return self.post.isPrivate;
}

- (BOOL)hidesAttribution {
    return self.attributionView.hidden;
}

- (void)setHidesAttribution:(BOOL)hidesAttribution {
    self.attributionView.hidden = hidesAttribution;
}

#pragma mark - Actions

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

@end
