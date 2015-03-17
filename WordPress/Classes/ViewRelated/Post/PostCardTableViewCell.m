#import "PostCardTableViewCell.h"
#import "NSDate+StringFormatting.h"
#import "UIImageView+Gravatar.h"
#import "WPStyleGuide+Posts.h"
#import <WordPress-iOS-Shared/WPStyleGuide.h>
#import "Wordpress-Swift.h"

#import <SDWebImage/UIImageView+WebCache.h>

@interface PostCardTableViewCell()

@property (nonatomic, strong) id<WPPostContentViewProvider>contentProvider;
@property (nonatomic, assign) CGFloat headerViewHeight;
@property (nonatomic, assign) CGFloat headerViewLowerMargin;
@property (nonatomic, assign) CGFloat titleViewLowerMargin;
@property (nonatomic, assign) CGFloat snippetViewLowerMargin;
@property (nonatomic, assign) CGFloat dateViewLowerMargin;
@property (nonatomic, assign) CGFloat statusViewHeight;
@property (nonatomic, assign) CGFloat statusViewLowerMargin;

@end

@implementation PostCardTableViewCell

- (void)awakeFromNib {
    [self applyStyles];

    self.headerViewHeight = self.headerViewHeightConstraint.constant;
    self.headerViewLowerMargin = self.headerViewLowerConstraint.constant;
    self.titleViewLowerMargin = self.titleLowerConstraint.constant;
    self.snippetViewLowerMargin = self.snippetLowerConstraint.constant;
    self.dateViewLowerMargin = self.dateViewLowerConstraint.constant;
    self.statusViewHeight = self.statusHeightConstraint.constant;
    self.statusViewLowerMargin = self.statusViewLowerConstraint.constant;
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGFloat innerWidth = [self innerWidthForSize:size];
    CGSize innerSize = CGSizeMake(innerWidth, CGFLOAT_MAX);

    // Add up all the things.
    CGFloat height = CGRectGetMinY(self.postContentView.frame);

    height += CGRectGetMinY(self.headerView.frame);
    height += self.headerViewHeight;
    height += self.headerViewLowerMargin;

    height += [self.titleLabel sizeThatFits:innerSize].height;
    height += self.titleLowerConstraint.constant;

    height += [self.snippetLabel sizeThatFits:innerSize].height;
    height += self.snippetLowerConstraint.constant;

    height += CGRectGetHeight(self.dateView.frame);
    height += self.dateViewLowerConstraint.constant;

    height += self.statusHeightConstraint.constant;
    height += self.statusViewLowerConstraint.constant;

    height += CGRectGetHeight(self.actionBar.frame);

    height += self.postContentBottomConstraint.constant;

    return CGSizeMake(size.width, height);
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    [super setBackgroundColor:backgroundColor];
    self.innerContentView.backgroundColor = backgroundColor;
}

- (CGFloat)innerWidthForSize:(CGSize)size
{
    CGFloat width = 0.0;
    if (self.maxIPadWidthConstraint.isActive) {
        width = self.maxIPadWidthConstraint.constant;
    } else {
        CGFloat horizontalMargin = CGRectGetMinX(self.postContentView.frame) + CGRectGetMinX(self.headerView.frame);
        width = size.width - (horizontalMargin * 2.0);
    }
    return width;
}

- (void)applyStyles
{
    [WPStyleGuide applyPostCardStyle:self];
    [WPStyleGuide applyPostAuthorSiteStyle:self.authorBlogLabel];
    [WPStyleGuide applyPostAuthorNameStyle:self.authorNameLabel];
    [WPStyleGuide applyPostTitleStyle:self.titleLabel];
    [WPStyleGuide applyPostSnippetStyle:self.snippetLabel];
    [WPStyleGuide applyPostDateStyle:self.dateLabel];
    [WPStyleGuide applyPostStatusStyle:self.statusLabel];
    [WPStyleGuide applyPostMetaButtonStyle:self.metaButtonRight];
    [WPStyleGuide applyPostMetaButtonStyle:self.metaButtonLeft];
    self.actionBar.backgroundColor = [WPStyleGuide lightGrey];
    self.shadowView.backgroundColor = [WPStyleGuide greyLighten20];
}

- (void)configureCell:(id<WPPostContentViewProvider>)contentProvider
{
    self.contentProvider = contentProvider;
}

- (void)setContentProvider:(id<WPPostContentViewProvider>)contentProvider
{
    _contentProvider = contentProvider;
    [self configureHeader];
    [self configureFeaturedImage];
    [self configureTitle];
    [self configureSnippet];
    [self configureDate];
    [self configureStatusView];
    [self configureMetaButtons];

    [self setNeedsUpdateConstraints];
}

- (void)configureHeader
{
    self.authorBlogLabel.text = [self.contentProvider blogNameForDisplay];
    self.authorNameLabel.text = [self.contentProvider authorNameForDisplay];
    [self.avatarImageView sd_setImageWithURL:[self blavatarURL]
                            placeholderImage:[UIImage imageNamed:@"post-blavatar-placeholder"]];
}

- (NSURL *)blavatarURL
{
    NSInteger size = (NSInteger)ceil(CGRectGetWidth(self.avatarImageView.frame) * [[UIScreen mainScreen] scale]);
    return [self.avatarImageView blavatarURLForHost:[self.contentProvider blogURLForDisplay] withSize:size];
}

- (void)configureFeaturedImage
{
    // TODO:
}

- (void)configureTitle
{
    NSString *str = [self.contentProvider titleForDisplay] ?: [NSString string];
    self.titleLabel.attributedText = [[NSAttributedString alloc] initWithString:str attributes:[WPStyleGuide postCardTitleAttributes]];
    self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.titleLowerConstraint.constant = ([str length] > 0) ? self.titleViewLowerMargin : 0.0;
}

- (void)configureSnippet
{
    NSString *str = [self.contentProvider contentPreviewForDisplay];
    self.snippetLabel.attributedText = [[NSAttributedString alloc] initWithString:str attributes:[WPStyleGuide postCardSnippetAttributes]];
    self.snippetLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.snippetLowerConstraint.constant = ([str length] > 0) ? self.snippetViewLowerMargin : 0.0;
}

- (void)configureDate
{
    self.dateLabel.text = [[self.contentProvider dateForDisplay] shortString];
}

- (void)configureStatusView
{
    NSString *str = [self.contentProvider statusForDisplay];
    self.statusLabel.text = str;
    self.statusView.hidden = ([str length] == 0);
    if (self.statusView.hidden) {
        self.dateViewLowerConstraint.constant = 0.0;
        self.statusHeightConstraint.constant = 0.0;
    } else {
        self.dateViewLowerConstraint.constant = self.dateViewLowerMargin;
        self.statusHeightConstraint.constant = self.statusViewHeight;
    }
    [self.statusView setNeedsUpdateConstraints];
}

- (void)configureMetaButtons
{
    [self resetMetaButton:self.metaButtonRight];
    [self resetMetaButton:self.metaButtonLeft];
//TODO:
//    NSArray *buttons = @[self.metaButtonRight, self.metaButtonCenter, self.metaButtonLeft];
//    NSInteger index = 0;
    // If comment count
    // If like count
    // If reblogged?
}

- (void)resetMetaButton:(UIButton *)metaButton
{
    [metaButton setTitle:nil forState:UIControlStateNormal | UIControlStateSelected];
    [metaButton setImage:nil forState:UIControlStateNormal | UIControlStateSelected];
    metaButton.selected = NO;
    metaButton.hidden = YES;
}

@end
