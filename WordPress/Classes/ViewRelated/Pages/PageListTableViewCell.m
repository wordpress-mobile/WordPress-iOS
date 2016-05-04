#import "PageListTableViewCell.h"
#import "WPStyleGuide+Posts.h"
#import "WordPress-Swift.h"

@interface PageListTableViewCell()

@property (nonatomic, strong) IBOutlet UIView *pageContentView;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UIButton *menuButton;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *maxIPadWidthConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *titleLabelTopMarginConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *titleLabelBottomMarginConstraint;

@end

@implementation PageListTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self applyStyles];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    // Don't respond to taps in margins.
    if (!CGRectContainsPoint(self.pageContentView.frame, point)) {
        return nil;
    }
    return [super hitTest:point withEvent:event];
}


#pragma mark - Accessors

- (CGSize)sizeThatFits:(CGSize)size
{
    CGFloat innerWidth = [self innerWidthForSize:size];

    CGFloat availableWidth = innerWidth - CGRectGetWidth(self.menuButton.frame);
    CGSize availableSize = CGSizeMake(availableWidth, CGFLOAT_MAX);

    // Add up all the things.
    CGFloat height = self.titleLabelTopMarginConstraint.constant;
    height += self.titleLabelBottomMarginConstraint.constant;
    height += [self.titleLabel sizeThatFits:availableSize].height;

    height = MAX(height, CGRectGetHeight(self.menuButton.frame));
    height += 1; // 1 pixel rule.

    return CGSizeMake(size.width, height);
}

- (CGFloat)innerWidthForSize:(CGSize)size
{
    CGFloat width = 0.0;
    CGFloat titleMargin = CGRectGetMinX(self.titleLabel.frame);
    // FIXME: Ideally we'd check `self.maxIPadWidthConstraint.isActive` but that
    // property is iOS 8 only. When iOS 7 support is ended update this and check
    // the constraint.
    if ([UIDevice isPad]) {
        width = self.maxIPadWidthConstraint.constant;
    } else {
        width = size.width;
        width -= (CGRectGetMinX(self.pageContentView.frame) * 2);
    }
    width -= titleMargin;
    return width;
}

- (void)setPost:(AbstractPost *)post
{
    [super setPost:post];
    [self configureTitle];
}


#pragma mark - Configuration

- (void)applyStyles
{
    [WPStyleGuide applyPostCardStyle:self];
    [WPStyleGuide applyPageTitleStyle:self.titleLabel];
}

- (void)configureTitle
{
    AbstractPost *post = [self.post hasRevision] ? [self.post revision] : self.post;
    NSString *str = [post titleForDisplay] ?: [NSString string];
    self.titleLabel.attributedText = [[NSAttributedString alloc] initWithString:str attributes:[WPStyleGuide pageCellTitleAttributes]];
    self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
}

@end
