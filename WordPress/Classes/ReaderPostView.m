#import <AFNetworking/UIKit+AFNetworking.h>
#import <QuartzCore/QuartzCore.h>
#import "ReaderPostView.h"
#import "WPAccount.h"
#import "WPContentViewSubclass.h"
#import "ContentActionButton.h"
#import "UILabel+SuggestSize.h"
#import "NSAttributedString+HTML.h"
#import "NSString+Helpers.h" 
#import "ContextManager.h"
#import "AccountService.h"

static NSInteger const MaxNumberOfLinesForTitleForSummary = 3;
NSString * const ReaderPostViewDidFinishLayoutNotification = @"ReaderPostViewDidFinishLayoutNotification";

@interface ReaderPostView()

@property (nonatomic, assign) BOOL showImage;
@property (nonatomic, strong) UIButton *tagButton;
@property (nonatomic, strong) UIButton *followButton;
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
    desiredHeight += ceil([postTitle boundingRectWithSize:CGSizeMake(contentWidth, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size.height);
    desiredHeight += RPVTitlePaddingBottom;
    
    // Post summary
    if (!showFullContent) {
        NSAttributedString *postSummary = [self summaryAttributedStringForPost:post];
        if([postSummary length] > 0) {
            desiredHeight += [postSummary boundingRectWithSize:CGSizeMake(contentWidth, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size.height;
        }
    }
    desiredHeight += RPVVerticalPadding;
    
    // Padding below the line
	desiredHeight += RPVVerticalPadding;
    
	// Size of the meta view
    desiredHeight += RPVMetaViewHeight;
    
	return ceil(desiredHeight);
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
    if (summary == nil) {
        summary = @"";
    }
    
    NSInteger newline = [summary rangeOfString:@"\n"].location;
    
    if (newline != NSNotFound) {
        summary = [summary substringToIndex:newline];
    }
    
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineHeightMultiple:RPVLineHeightMultiple];
    NSDictionary *attributes = @{NSParagraphStyleAttributeName : style,
                                 NSFontAttributeName : [self summaryFont]};
    NSMutableAttributedString *attributedSummary = [[NSMutableAttributedString alloc] initWithString:summary
                                                                                          attributes:attributes];
    if ([summary length] > 0) {
        NSDictionary *moreContentAttributes = @{NSParagraphStyleAttributeName: style,
                                                NSFontAttributeName: [self moreContentFont],
                                                NSForegroundColorAttributeName: [WPStyleGuide baseLighterBlue]};
        NSAttributedString *moreContent = [[NSAttributedString alloc] initWithString:[@"   " stringByAppendingString:NSLocalizedString(@"more", @"")] attributes:moreContentAttributes];
        [attributedSummary appendAttributedString:moreContent];
    }
    
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

        _followButton = [ContentActionButton buttonWithType:UIButtonTypeCustom];
        [WPStyleGuide configureFollowButton:_followButton];
        [_followButton setTitleEdgeInsets: UIEdgeInsetsMake(0, RPVSmallButtonLeftPadding, 0, 0)];
        [_followButton addTarget:self action:@selector(followAction:) forControlEvents:UIControlEventTouchUpInside];
        [super.byView addSubview:_followButton];
        
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

- (void)configurePost:(ReaderPost *)post {
   
    // Margins
    CGFloat contentWidth = self.frame.size.width;
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
    
    self.bylineLabel.text = [post authorString];
    [self refreshDate];
    
	self.showImage = NO;
	self.cellImageView.hidden = YES;
    
    // If ReaderPostView has a featured image, show it unless you're showing full detail & featured image is in the post already
	if (post.featuredImageURL &&
        (self.showFullContent == NO || [self.post.content rangeOfString:[post.featuredImageURL absoluteString]].length == 0)) {
		self.showImage = YES;
		self.cellImageView.hidden = NO;
	}
    
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

	if (self.post.isWPCom && defaultAccount != nil) {
		self.likeButton.hidden = NO;
		self.reblogButton.hidden = NO;
        self.commentButton.hidden = NO;
	} else {
        self.likeButton.hidden = YES;
		self.reblogButton.hidden = YES;
        self.commentButton.hidden = YES;
	}

    if ([self.post.likeCount integerValue] > 0) {
        [self.likeButton setTitle:[self.post.likeCount stringValue] forState:UIControlStateNormal];
        [self.likeButton setTitle:[self.post.likeCount stringValue] forState:UIControlStateSelected];
    } else {
        [self.likeButton setTitle:@"" forState:UIControlStateNormal];
        [self.likeButton setTitle:@"" forState:UIControlStateSelected];
    }

    if ([self.post.commentCount integerValue] > 0) {
        [self.commentButton setTitle:[self.post.commentCount stringValue] forState:UIControlStateNormal];
        [self.commentButton setTitle:[self.post.commentCount stringValue] forState:UIControlStateSelected];
    } else {
        [self.commentButton setTitle:@"" forState:UIControlStateNormal];
        [self.commentButton setTitle:@"" forState:UIControlStateSelected];
    }

    [self.followButton setSelected:self.post.isFollowing];
	self.reblogButton.userInteractionEnabled = !post.isReblogged;
	
	[self updateActionButtons];
}

- (void)layoutSubviews {

    // Determine button visibility before parent lays them out
    BOOL commentsOpen = self.post.commentsOpen && self.post.isWPCom;
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
	CGFloat nextY = RPVAuthorPadding;
	CGFloat height = 0.0f;
    CGFloat bylineX = RPVAvatarSize + RPVAuthorPadding + RPVHorizontalInnerPadding;

    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

    if ([self.post isFollowable] && defaultAccount != nil) {
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
	nextY += height + RPVTitlePaddingBottom * (self.showFullContent ? 2.0 : 1.0);
    
	// Position the snippet / content
    height = 0;
    if (self.showFullContent) {
        [self.textContentView relayoutText];
        height = [self.textContentView suggestedFrameSizeToFitEntireStringConstraintedToWidth:contentWidth].height;
        CGRect textContainerFrame = self.textContentView.frame;
        textContainerFrame.size.width = contentWidth;
        textContainerFrame.size.height = height;
        textContainerFrame.origin.y = nextY;
        self.textContentView.frame = textContainerFrame;
    } else if ([self.snippetLabel.attributedText length] > 0) {
        height = ceil([self.snippetLabel suggestedSizeForWidth:innerContentWidth].height);
        self.snippetLabel.frame = CGRectMake(RPVHorizontalInnerPadding, nextY, innerContentWidth, height);
    }
    nextY += ceilf(height) + RPVVerticalPadding;
    
	// Position the meta view and its subviews
	self.bottomView.frame = CGRectMake(0, nextY, contentWidth, RPVMetaViewHeight);
    self.bottomBorder.frame = CGRectMake(RPVHorizontalInnerPadding, 0, contentWidth - RPVHorizontalInnerPadding * 2, RPVBorderHeight);

    // Update own frame
    CGRect ownFrame = self.frame;
    
    ownFrame.size.height = nextY + RPVMetaViewHeight - 1;
    self.frame = ownFrame;
    
    // Notify others that our layout has changed.
    // This is needed because the layout would change after a containing tableViewCell's height was determined based on old values
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSValue valueWithCGRect:ownFrame] forKey:@"OptimalFrame"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ReaderPostViewDidFinishLayoutNotification object:self userInfo:userInfo];
}

- (void)reset {
    [super reset];
    [self.tagButton setTitle:nil forState:UIControlStateNormal];
    [self.followButton setSelected:NO];
}

- (void)updateActionButtons {
    [super updateActionButtons];
    self.likeButton.selected = self.post.isLiked;
    self.reblogButton.selected = self.post.isReblogged;
	self.reblogButton.userInteractionEnabled = !self.reblogButton.selected;
}

- (void)setAvatar:(UIImage *)avatar {
    if (avatar) {
        self.avatarImageView.image = avatar;
    } else if (self.post.isWPCom) {
        self.avatarImageView.image = [UIImage imageNamed:@"wpcom_blavatar"];
    } else {
        self.avatarImageView.image = [UIImage imageNamed:@"gravatar-reader"];
    }
}

- (void)setAvatarWithURL:(NSURL *)avatarURL {
    [self.avatarImageView setImageWithURL:avatarURL];
}

- (BOOL)privateContent {
    return self.post.isPrivate;
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
