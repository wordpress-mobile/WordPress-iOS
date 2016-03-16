#import "MenuItemEditingHeaderView.h"
#import "WPStyleGuide.h"
#import "MenusDesign.h"
#import "MenuItem.h"

@interface MenuItemEditingHeaderView () <UITextFieldDelegate>

@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, strong) NSLayoutConstraint *stackViewTopConstraint;
@property (nonatomic, strong) UIView *textFieldContainerView;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, assign) MenuIconType iconType;

@end

@implementation MenuItemEditingHeaderView

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChangeNotification) name:UIDeviceOrientationDidChangeNotification object:nil];
    
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.backgroundColor = [UIColor clearColor];

    {
        UIEdgeInsets margins = UIEdgeInsetsZero;
        const CGFloat margin = MenusDesignDefaultContentSpacing / 2.0;
        margins.left = MenusDesignDefaultContentSpacing;
        margins.right = margin;
        margins.top = margin;
        margins.bottom = margin;
        
        UIStackView *stackView = [[UIStackView alloc] init];
        stackView.translatesAutoresizingMaskIntoConstraints = NO;
        stackView.distribution = UIStackViewDistributionFill;
        stackView.alignment = UIStackViewAlignmentFill;
        stackView.spacing = MenusDesignDefaultContentSpacing;
        
        [self addSubview:stackView];
        
        NSLayoutConstraint *topConstraint = [stackView.topAnchor constraintEqualToAnchor:self.topAnchor constant:margins.top];
        topConstraint.priority = UILayoutPriorityDefaultHigh;
        self.stackViewTopConstraint  = topConstraint;
        
        NSLayoutConstraint *bottomConstraint = [stackView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-margins.bottom];
        bottomConstraint.priority = UILayoutPriorityDefaultHigh;
        
        [NSLayoutConstraint activateConstraints:@[
                                                  topConstraint,
                                                  bottomConstraint,
                                                  [stackView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:margins.left],
                                                  [stackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-margins.right]
                                                  ]];
        
        self.stackView = stackView;
    }
    {
        UIImageView *iconView = [[UIImageView alloc] init];
        iconView.translatesAutoresizingMaskIntoConstraints = NO;
        iconView.contentMode = UIViewContentModeScaleAspectFit;
        iconView.backgroundColor = [UIColor clearColor];
        iconView.tintColor = [UIColor whiteColor];

        NSLayoutConstraint *widthConstraint = [iconView.widthAnchor constraintEqualToConstant:MenusDesignItemIconSize + 4.0];
        widthConstraint.active = YES;
        
        [self.stackView addArrangedSubview:iconView];
        self.iconView = iconView;
    }
    {
        UIView *textFieldContainerView = [[UIView alloc] init];
        textFieldContainerView.translatesAutoresizingMaskIntoConstraints = NO;
        textFieldContainerView.backgroundColor = [UIColor whiteColor];
        [self.stackView addArrangedSubview:textFieldContainerView];

        self.textFieldContainerView = textFieldContainerView;

        UIEdgeInsets margins = UIEdgeInsetsZero;
        margins.top = [self defaultStackDesignMargin];
        margins.left = MenusDesignDefaultContentSpacing / 2.0;
        margins.right = MenusDesignDefaultContentSpacing / 4.0;
        margins.bottom = margins.top;
        textFieldContainerView.layoutMargins = margins;
        
        UILayoutGuide *marginGuide = textFieldContainerView.layoutMarginsGuide;
        
        UITextField *textField = [[UITextField alloc] init];
        textField.translatesAutoresizingMaskIntoConstraints = NO;
        textField.delegate = self;
        textField.placeholder = [MenuItem defaultItemNameLocalized];
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
        textField.returnKeyType = UIReturnKeyDone;
        textField.textColor = [WPStyleGuide darkGrey];
        textField.font = [WPStyleGuide regularTextFont];
        textField.backgroundColor = [UIColor clearColor];
        [textField addTarget:self action:@selector(textFieldKeyboardDidEndOnExit) forControlEvents:UIControlEventEditingDidEndOnExit];
        [textField addTarget:self action:@selector(textFieldValueDidChange:) forControlEvents:UIControlEventEditingChanged];

        [textFieldContainerView addSubview:textField];
        self.textField = textField;
        
        [NSLayoutConstraint activateConstraints:@[
                                                  [textField.topAnchor constraintEqualToAnchor:marginGuide.topAnchor],
                                                  [textField.leadingAnchor constraintEqualToAnchor:marginGuide.leadingAnchor],
                                                  [textField.trailingAnchor constraintEqualToAnchor:marginGuide.trailingAnchor],
                                                  [textField.bottomAnchor constraintEqualToAnchor:marginGuide.bottomAnchor],
                                                 ]];
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    [self setNeedsDisplay];
}

- (CGFloat)defaultStackDesignMargin
{
    return ceilf(MenusDesignDefaultContentSpacing / 2.0);
}

- (void)setNeedsTopConstraintsUpdateForStatusBarAppearence:(BOOL)hidden
{
    if (hidden) {
        
        self.stackViewTopConstraint.constant = [self defaultStackDesignMargin];
        
    } else  {
        
        self.stackViewTopConstraint.constant = [self defaultStackDesignMargin] + [[UIApplication sharedApplication] statusBarFrame].size.height;
    }
}

- (void)setIconType:(MenuIconType)iconType
{
    if (_iconType != iconType) {
        _iconType = iconType;
        
        if (iconType == MenuIconTypeNone) {
            
            self.iconView.image = nil;
            self.iconView.hidden = YES;
            
        } else  {
            
            self.iconView.hidden = NO;
            self.iconView.image = [[UIImage imageNamed:MenusDesignItemIconImageNameForType(iconType)] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        }
    }
}

- (void)setItem:(MenuItem *)item
{
    if (_item != item) {
        _item = item;
    }
    
    self.textField.text = item.name;
    self.iconType = MenuIconTypeDefault;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{    
    const CGRect iconRect = [self convertRect:self.iconView.frame fromView:self.iconView.superview];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGContextSetFillColorWithColor(context, [[WPStyleGuide mediumBlue] CGColor]);
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, rect.size.width, 0);
    CGContextAddLineToPoint(context, 0, 0);
    CGContextAddLineToPoint(context, 0, rect.size.height);
    CGContextAddLineToPoint(context, iconRect.origin.x - 3.0, rect.size.height);
    CGContextAddLineToPoint(context, CGRectGetMidX(iconRect), rect.size.height - 10.0);
    CGContextAddLineToPoint(context, iconRect.origin.x + iconRect.size.width + 3.0, rect.size.height);
    CGContextAddLineToPoint(context, rect.size.width, rect.size.height);
    CGContextClosePath(context);
    CGContextFillPath(context);
    CGContextRestoreGState(context);
}

#pragma mark - UITextField

- (void)textFieldKeyboardDidEndOnExit
{
    [self.textField resignFirstResponder];
}

- (void)textFieldValueDidChange:(UITextField *)textField
{
    NSLog(@"text value did change");
    self.item.name = textField.text.length ? textField.text : [MenuItem defaultItemNameLocalized];
    [self.delegate editingHeaderViewDidUpdateItem:self];
}

#pragma mark - notifications

- (void)deviceOrientationDidChangeNotification
{
    [self setNeedsDisplay];
}

@end
