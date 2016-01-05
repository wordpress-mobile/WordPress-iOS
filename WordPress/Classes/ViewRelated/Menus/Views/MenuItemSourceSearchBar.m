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
        self.contentMode = UIViewContentModeRedraw;
        
        UIEdgeInsets margin = UIEdgeInsetsZero;
        margin.top = MenusDesignDefaultContentSpacing / 2.0;
        margin.left = MenusDesignDefaultContentSpacing;
        margin.right = MenusDesignDefaultContentSpacing;
        margin.bottom = MenusDesignDefaultContentSpacing / 2.0;
        self.layoutMargins = margin;
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
            textField.returnKeyType = UIReturnKeyDone;
            
            [textField addTarget:self action:@selector(textFieldDidEndOnExit:) forControlEvents:UIControlEventEditingDidEndOnExit];
            [textField addTarget:self action:@selector(textFieldValueDidChange:) forControlEvents:UIControlEventValueChanged];
            
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

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [[WPStyleGuide greyLighten20] CGColor]);
    CGContextSetLineWidth(context, 1.0);
    UIEdgeInsets margins = self.layoutMargins;
    CGContextStrokeRect(context, CGRectInset(rect, margins.left, margins.bottom));
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self.delegate sourceSearchBarDidBeginSearching:self];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self.delegate sourceSearchBarDidEndSearching:self];
}

- (void)textFieldValueDidChange:(UITextField *)textField
{
    [self.delegate sourceSearchBar:self didUpdateSearchWithText:textField.text];
}

- (void)textFieldDidEndOnExit:(UITextField *)textField
{
    [textField resignFirstResponder];
}

@end
