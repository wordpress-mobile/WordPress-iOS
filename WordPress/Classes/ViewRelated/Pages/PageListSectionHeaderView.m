#import "PageListSectionHeaderView.h"
#import "WPStyleGuide+Posts.h"

@interface PageListSectionHeaderView()

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UIView *contentView;

@end

@implementation PageListSectionHeaderView

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self applyStyles];
}

- (void)applyStyles
{
    self.backgroundColor = [WPStyleGuide greyLighten30];
    self.contentView.backgroundColor = [WPStyleGuide lightGrey];
    [WPStyleGuide applySectionHeaderTitleStyle:self.titleLabel];
}

- (void)setTite:(NSString *)title
{
    self.titleLabel.text = [title uppercaseStringWithLocale:[NSLocale currentLocale]];
}

@end
