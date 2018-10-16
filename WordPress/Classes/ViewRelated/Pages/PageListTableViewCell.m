#import "PageListTableViewCell.h"
#import "WPStyleGuide+Posts.h"
#import "WordPress-Swift.h"


static CGFloat const PageListTableViewCellTagLabelRadius = 2.0;

@interface PageListTableViewCell()

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *privateBadgeLabel;
@property (strong, nonatomic) IBOutlet UILabel *localChangesLabel;
@property (strong, nonatomic) IBOutlet UIView *privateBadge;
@property (strong, nonatomic) IBOutlet UIView *localChangesBadge;
@property (nonatomic, strong) IBOutlet UIButton *menuButton;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *localChangesLeading;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *bottomPadding;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *leadingContentConstraint;

@end

@implementation PageListTableViewCell {
    CGFloat _indentationWidth;
    NSInteger _indentationLevel;
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    [self applyStyles];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    [self applyStyles];
}

- (CGFloat)indentationWidth
{
    return _indentationWidth;
}

- (NSInteger)indentationLevel
{
    return _indentationLevel;
}

- (void)setIndentationWidth:(CGFloat)indentationWidth
{
    _indentationWidth = indentationWidth;
    [self updateLeadingContentConstraint];
}

- (void)setIndentationLevel:(NSInteger)indentationLevel
{
    _indentationLevel = indentationLevel;
    [self updateLeadingContentConstraint];
}


#pragma mark - Accessors

- (void)setPost:(AbstractPost *)post
{
    [super setPost:post];
    [self configureTitle];
    [self configureForStatus];
    [self configureBadges];
}

#pragma mark - Configuration

- (void)applyStyles
{
    [WPStyleGuide configureTableViewCell:self];
    
    self.titleLabel.textColor = [WPStyleGuide darkGrey];
    self.menuButton.tintColor = [WPStyleGuide greyLighten10];

    self.privateBadgeLabel.text = NSLocalizedString(@"Private", @"Title of the Private Badge");
    self.localChangesLabel.text = NSLocalizedString(@"Local changes", @"Title of the Local Changes Badge");

    self.privateBadge.layer.cornerRadius = PageListTableViewCellTagLabelRadius;
    self.localChangesBadge.layer.cornerRadius = self.privateBadge.layer.cornerRadius;

    self.backgroundColor = [WPStyleGuide greyLighten30];
    self.contentView.backgroundColor = [WPStyleGuide greyLighten30];
}

- (void)configureTitle
{
    AbstractPost *post = [self.post hasRevision] ? [self.post revision] : self.post;
    NSString *str = [post titleForDisplay] ?: [NSString string];
    self.titleLabel.attributedText = [[NSAttributedString alloc] initWithString:str attributes:[WPStyleGuide pageCellTitleAttributes]];
}

- (void)configureForStatus
{
    if (self.post.isFailed && !self.post.hasLocalChanges) {
        self.titleLabel.textColor = [WPStyleGuide errorRed];
        self.menuButton.tintColor = [WPStyleGuide errorRed];
    }
}

- (void)updateLeadingContentConstraint
{
    self.leadingContentConstraint.constant = (CGFloat)_indentationLevel * _indentationWidth;
}

- (void)configureBadges
{
    Page *page = (Page *)self.post;

    if (page.hasPendingReviewState) {
       self.privateBadgeLabel.text = NSLocalizedString(@"Pending review", @"Title of the Pending Review Badge");
    }

    self.bottomPadding.active = !page.canDisplayTags;
    self.privateBadge.hidden = !(page.hasPrivateState || page.hasPendingReviewState);
    self.localChangesBadge.hidden = !page.hasLocalChanges;
    self.localChangesLeading.active = !self.privateBadge.isHidden;
}

@end
