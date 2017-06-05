#import "PageListSectionHeaderView.h"
#import "WPStyleGuide+Posts.h"
#import <WordPressShared/WPDeviceIdentification.h>

@interface PageListSectionHeaderView()

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UIView *topBorderView;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *topBorderHeightConstraint;
@property (nonatomic, strong) IBOutlet UIView *bottomBorderView;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *bottomBorderHeightConstraint;

@end

@implementation PageListSectionHeaderView

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self applyStyles];
}

- (void)applyStyles
{
    self.backgroundColor = [WPStyleGuide lightGrey];
    [WPStyleGuide applySectionHeaderTitleStyle:self.titleLabel];

    self.topBorderView.backgroundColor = [WPStyleGuide greyLighten20];
    self.bottomBorderView.backgroundColor = self.topBorderView.backgroundColor;

    if ([WPDeviceIdentification isRetina]) {
        self.topBorderHeightConstraint.constant = 0.5;
        self.bottomBorderHeightConstraint.constant = self.topBorderHeightConstraint.constant;
    }
}

- (void)setTite:(NSString *)title
{
    self.titleLabel.text = [title uppercaseStringWithLocale:[NSLocale currentLocale]];
}

@end
