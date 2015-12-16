#import "MenuItemSourceSearchBar.h"
#import "MenusDesign.h"
#import "WPStyleGuide.h"
#import "WPFontManager.h"

@interface MenuItemSourceSearchBar () <UITextFieldDelegate>

@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UIImageView *iconView;

@end

@implementation MenuItemSourceSearchBar

- (id)init
{
    self = [super init];
    if(self) {
        
        self.backgroundColor = [UIColor whiteColor];
        self.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.layoutMargins = UIEdgeInsetsZero;
        UILayoutGuide *marginsGuide = self.layoutMarginsGuide;
        const CGFloat spacing = ceilf(MenusDesignDefaultContentSpacing / 2.0);

        {
            UIImageView *iconView = [[UIImageView alloc] init];
            iconView.translatesAutoresizingMaskIntoConstraints = NO;
            iconView.tintColor = [WPStyleGuide greyDarken30];
            iconView.image = [[UIImage imageNamed:@"icon-menus-search"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            iconView.contentMode = UIViewContentModeScaleAspectFit;
            
            [self addSubview:iconView];
            
            [NSLayoutConstraint activateConstraints:@[
                                                      [iconView.topAnchor constraintEqualToAnchor:marginsGuide.topAnchor constant:spacing],
                                                      [iconView.leadingAnchor constraintEqualToAnchor:marginsGuide.leadingAnchor constant:spacing + 4.0],
                                                      [iconView.bottomAnchor constraintEqualToAnchor:marginsGuide.bottomAnchor constant:-spacing],
                                                      [iconView.widthAnchor constraintEqualToConstant:14.0],
                                                      ]];
            
            self.iconView = iconView;
        }
        {
            UITextField *textField = [[UITextField alloc] init];
            textField.translatesAutoresizingMaskIntoConstraints = NO;
            textField.delegate = self;
            textField.clearButtonMode = UITextFieldViewModeWhileEditing;
            
            UIFont *font = [WPFontManager openSansRegularFontOfSize:16.0];
            NSString *placeholder = NSLocalizedString(@"Search...", @"");
            NSDictionary *attributes = @{NSFontAttributeName: font, NSForegroundColorAttributeName: [WPStyleGuide greyLighten10]};
            textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholder attributes:attributes];
            textField.font = font;
            
            [self addSubview:textField];
            [NSLayoutConstraint activateConstraints:@[
                                                      [textField.topAnchor constraintEqualToAnchor:marginsGuide.topAnchor],
                                                      [textField.leadingAnchor constraintEqualToAnchor:self.iconView.trailingAnchor constant:spacing],
                                                      [textField.bottomAnchor constraintEqualToAnchor:marginsGuide.bottomAnchor],
                                                      [textField.trailingAnchor constraintEqualToAnchor:marginsGuide.trailingAnchor constant:-4.0]
                                                      ]];
            
            self.textField = textField;
        }
    }
    
    return self;
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 1.0);
    CGContextSetStrokeColorWithColor(context, [[WPStyleGuide greyLighten20] CGColor]);
    CGContextStrokeRect(context, CGRectInset(rect, 1.0, 1.0));

}

#pragma mark - UITextFieldDelegate

@end
