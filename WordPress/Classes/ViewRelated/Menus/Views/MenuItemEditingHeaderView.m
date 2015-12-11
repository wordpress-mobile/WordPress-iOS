#import "MenuItemEditingHeaderView.h"
#import "WPStyleGuide.h"
#import "MenusDesign.h"
#import "MenuItem.h"

@interface MenuItemEditingHeaderView () <UITextFieldDelegate>

@property (nonatomic, strong) IBOutlet UIStackView *stackView;
@property (nonatomic, strong) UIView *textFieldContainerView;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, assign) MenuItemIconType iconType;

@end

@implementation MenuItemEditingHeaderView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.backgroundColor = [WPStyleGuide mediumBlue];
    
    {
        UIEdgeInsets margins = UIEdgeInsetsZero;
        const CGFloat margin = MenusDesignDefaultContentSpacing / 2.0;
        margins.top = margin;
        margins.top += [[UIApplication sharedApplication] statusBarFrame].size.height;
        margins.left = MenusDesignDefaultContentSpacing;
        margins.right = margin;
        margins.bottom = margin;
        self.stackView.layoutMargins = margins;
        self.stackView.layoutMarginsRelativeArrangement = YES;
        self.stackView.distribution = UIStackViewDistributionFillProportionally;
        self.stackView.alignment = UIStackViewAlignmentCenter;
        self.stackView.spacing = MenusDesignDefaultContentSpacing;
    }
    {
        UIImageView *iconView = [[UIImageView alloc] init];
        iconView.translatesAutoresizingMaskIntoConstraints = NO;
        iconView.contentMode = UIViewContentModeScaleAspectFit;
        iconView.backgroundColor = [UIColor clearColor];
        [iconView.widthAnchor constraintEqualToConstant:MenusDesignItemIconSize].active = YES;
        [iconView.heightAnchor constraintEqualToConstant:MenusDesignItemIconSize].active = YES;
        iconView.tintColor = [UIColor whiteColor];
        
        [self.stackView addArrangedSubview:iconView];
        self.iconView = iconView;
    }
    {
        UIView *textFieldContainerView = [[UIView alloc] init];
        textFieldContainerView.translatesAutoresizingMaskIntoConstraints = NO;
        textFieldContainerView.backgroundColor = [UIColor whiteColor];
        [self.stackView addArrangedSubview:textFieldContainerView];
        
        [textFieldContainerView setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
        [textFieldContainerView setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        
        self.textFieldContainerView = textFieldContainerView;
        
        UIEdgeInsets margins = UIEdgeInsetsZero;
        margins.top = MenusDesignDefaultContentSpacing / 2.0;
        margins.left = MenusDesignDefaultContentSpacing;
        margins.right = MenusDesignDefaultContentSpacing;
        margins.bottom = MenusDesignDefaultContentSpacing / 2.0;
        textFieldContainerView.layoutMargins = margins;
        
        UILayoutGuide *marginGuide = textFieldContainerView.layoutMarginsGuide;
        
        UITextField *textField = [[UITextField alloc] init];
        textField.translatesAutoresizingMaskIntoConstraints = NO;
        textField.delegate = self;
        textField.placeholder = NSLocalizedString(@"Title...", @"");
        textField.textColor = [WPStyleGuide darkGrey];
        textField.font = [WPStyleGuide regularTextFont];
        textField.backgroundColor = [UIColor clearColor];
        
        [textFieldContainerView addSubview:textField];
        
        self.textField = textField;
        
        [NSLayoutConstraint activateConstraints:@[
                                                  [textField.topAnchor constraintEqualToAnchor:marginGuide.topAnchor],
                                                  [textField.leadingAnchor constraintEqualToAnchor:marginGuide.leadingAnchor],
                                                  [textField.trailingAnchor constraintEqualToAnchor:marginGuide.trailingAnchor],
                                                  [textField.bottomAnchor constraintEqualToAnchor:marginGuide.bottomAnchor]
                                                 ]];
    }
}

- (void)setIconType:(MenuItemIconType)iconType
{
    if(_iconType != iconType) {
        _iconType = iconType;
        
        if(iconType == MenuItemIconNone) {
            
            self.iconView.image = nil;
            self.iconView.hidden = YES;
            
        }else {
            
            self.iconView.hidden = NO;
            self.iconView.image = [[UIImage imageNamed:MenusDesignItemIconImageNameForType(iconType)] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        }
    }
}

- (void)setItem:(MenuItem *)item
{
    if(_item != item) {
        _item = item;
        
        self.textField.text = item.name;
        self.iconType = MenuItemIconDefault;
    }
}

#pragma mark - UITextFieldDelegate

@end
