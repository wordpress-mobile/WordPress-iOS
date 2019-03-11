#import "PageListSectionHeaderView.h"
#import "WPStyleGuide+Posts.h"
#import <WordPressShared/WPDeviceIdentification.h>

@interface PageListSectionHeaderView()

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;

@end

@implementation PageListSectionHeaderView

- (void)setTitle:(NSString *)title
{
    self.titleLabel.text = [title uppercaseStringWithLocale:[NSLocale currentLocale]];
}

@end
