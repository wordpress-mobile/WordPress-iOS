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

#pragma mark - Accessors

- (void)setPost:(AbstractPost *)post
{
    [super setPost:post];
    [self configureTitle];
}

#pragma mark - Configuration

- (void)applyStyles
{
    [WPStyleGuide applyPageTitleStyle:self.titleLabel];
}

- (void)configureTitle
{
    AbstractPost *post = [self.post hasRevision] ? [self.post revision] : self.post;
    NSString *str = [post titleForDisplay] ?: [NSString string];
    self.titleLabel.attributedText = [[NSAttributedString alloc] initWithString:str attributes:[WPStyleGuide pageCellTitleAttributes]];
}

@end
