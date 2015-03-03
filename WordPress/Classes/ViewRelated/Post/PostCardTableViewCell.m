#import "PostCardTableViewCell.h"
#import "NSDate+StringFormatting.h"
#import <WordPress-iOS-Shared/WPStyleGuide.h>
#import "WPStyleGuide+Posts.h"

static const CGFloat PostCardTitleLowerConstraintConstant = 4.0;
static const CGFloat PostCardSnippetLowerConstraintConstant = 8.0;
static const CGFloat PostCardStatusUpperConstraintConstant = 8.0;
static const CGFloat PostCardStatusHeightConstraintConstant = 18.0;

@interface PostCardTableViewCell()
@property (nonatomic, strong) id<WPContentViewProvider>contentProvider;
@end

@implementation PostCardTableViewCell

- (void)awakeFromNib {
    // Initialization code
    [self applyStyles];
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGFloat height = 0.0;
    CGFloat horizontalMargin = CGRectGetMinX(self.avatarImageView.frame) + CGRectGetMinX(self.postContentView.frame);
    CGFloat innerWidth = size.width - (horizontalMargin * 2);
    CGSize innerSize = CGSizeMake(innerWidth, CGFLOAT_MAX);

    // Add up all the things.
    height += CGRectGetHeight(self.avatarImageView.frame);
    height += [self.titleLabel sizeThatFits:innerSize].height;
    height += [self.snippetLabel sizeThatFits:innerSize].height;
    height += CGRectGetHeight(self.dateView.frame);
    height += self.statusHeightConstraint.constant;

    height += self.avatarImageViewLowerConstraint.constant;
    height += self.titleLowerConstraint.constant;
    height += self.snippetLowerConstraint.constant;
    height += self.dateViewLowerConstraint.constant;
    height += self.statusViewLowerConstraint.constant;
    height += self.wrapperViewLowerConstraint.constant;
    height += 8.0; // Standard content view bottom margin.
    
    return CGSizeMake(size.width, height);
}

- (void)applyStyles
{
    [WPStyleGuide applyPostCardStyle:self];
    [WPStyleGuide applyPostAuthorNameStyle:self.authorLabel];
    [WPStyleGuide applyPostTitleStyle:self.titleLabel];
    [WPStyleGuide applyPostSnippetStyle:self.snippetLabel];
    [WPStyleGuide applyPostDateStyle:self.dateLabel];
    [WPStyleGuide applyPostStatusStyle:self.statusLabel];
    [WPStyleGuide applyPostMetaButtonStyle:self.metaButtonRight];
    [WPStyleGuide applyPostMetaButtonStyle:self.metaButtonCenter];
    [WPStyleGuide applyPostMetaButtonStyle:self.metaButtonLeft];
    self.actionBar.backgroundColor = [WPStyleGuide lightGrey];
    self.shadowView.backgroundColor = [WPStyleGuide greyLighten20];
}

- (void)configureCell:(id<WPContentViewProvider>)contentProvider
{
    self.contentProvider = contentProvider;
}

- (void)setContentProvider:(id<WPContentViewProvider>)contentProvider
{
    _contentProvider = contentProvider;
    [self configureAuthor];
    [self configureFeaturedImage];
    [self configureTitle];
    [self configureSnippet];
    [self configureDate];
    [self configureStatusView];
    [self configureMetaButtons];
}

- (void)configureAuthor
{
    self.authorLabel.text = [self.contentProvider authorForDisplay];
}

- (void)configureFeaturedImage
{
    // TODO:
}

- (void)configureTitle
{
    NSString *str = [self.contentProvider titleForDisplay];
    self.titleLabel.attributedText = [[NSAttributedString alloc] initWithString:str attributes:[WPStyleGuide postCardTitleAttributes]];
    self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.titleLowerConstraint.constant = ([str length] > 0) ? PostCardTitleLowerConstraintConstant : 0;
}

- (void)configureSnippet
{
    NSString *str = [self.contentProvider contentPreviewForDisplay];
    self.snippetLabel.attributedText = [[NSAttributedString alloc] initWithString:str attributes:[WPStyleGuide postCardSnippetAttributes]];
    self.snippetLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.snippetLowerConstraint.constant = ([str length] > 0) ? PostCardSnippetLowerConstraintConstant : 0;
}

- (void)configureDate
{
    self.dateLabel.text = [[self.contentProvider dateForDisplay] shortString];
}

- (void)configureStatusView
{
    self.statusLabel.text = [self.contentProvider statusForDisplay];
    self.dateViewLowerConstraint.constant = 0;
    self.statusHeightConstraint.constant = 0;
}

- (void)configureMetaButtons
{
    [self resetMetaButton:self.metaButtonRight];
    [self resetMetaButton:self.metaButtonCenter];
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
