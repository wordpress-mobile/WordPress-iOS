#import "PageListTableViewCell.h"
#import "WPStyleGuide+Posts.h"
#import "WordPress-Swift.h"

@interface PageListTableViewCell()

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UIButton *menuButton;

@end

@implementation PageListTableViewCell

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

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self configurePageLevel];
    
    CGFloat indentPoints = (CGFloat)self.indentationLevel * self.indentationWidth;
    self.contentView.frame = CGRectMake(indentPoints,
                                        self.contentView.frame.origin.y,
                                        self.contentView.frame.size.width - indentPoints,
                                        self.contentView.frame.size.height);
}


#pragma mark - Accessors

- (void)setPost:(AbstractPost *)post
{
    [super setPost:post];
    [self configureTitle];
    [self configureForStatus];
    [self configurePageLevel];
}

#pragma mark - Configuration

- (void)applyStyles
{
    [WPStyleGuide configureTableViewCell:self];
    
    self.titleLabel.textColor = [WPStyleGuide darkGrey];
    self.menuButton.tintColor = [WPStyleGuide greyLighten10];
    
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
    if (self.post.isFailed) {
        self.titleLabel.textColor = [WPStyleGuide errorRed];
        self.menuButton.tintColor = [WPStyleGuide errorRed];
    }
}

- (void)configurePageLevel
{
    Page *page = (Page *)self.post;
    self.indentationWidth = 16.0;
    self.indentationLevel = page.hierarchyIndex;
}

@end
