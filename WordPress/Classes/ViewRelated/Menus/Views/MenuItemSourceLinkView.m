#import "MenuItemSourceLinkView.h"
#import "MenusDesign.h"
#import "WPStyleGuide.h"
#import "WPFontManager.h"

@interface MenuItemSourceLinkView ()

@property (nonatomic, strong) UILabel *label;

@end

@implementation MenuItemSourceLinkView

- (id)init
{
    self = [super init];
    if(self) {
        
        {
            UILabel *label = [[UILabel alloc] init];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            label.text = [NSLocalizedString(@"Link Address (URL)", @"Menus title label when editing a menu item as a link.") uppercaseString];
            label.textColor = [WPStyleGuide greyLighten10];
            label.font = [WPFontManager openSansSemiBoldFontOfSize:12.0];
            
            [self.stackView addArrangedSubview:label];
            
            self.label = label;
        }
    }
    
    return self;
}

@end