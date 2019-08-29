#import "MenuItemEditingHeaderView.h"
#import "MenuItem.h"
#import "MenuItem+ViewDesign.h"
#import <WordPressShared/WPStyleGuide.h>
#import "WordPress-Swift.h"

@interface MenuItemEditingHeaderView () <UITextFieldDelegate>

@property (nonatomic, strong, readonly) UIStackView *stackView;
@property (nonatomic, strong, readonly) NSLayoutConstraint *stackViewTopConstraint;
@property (nonatomic, strong, readonly) UIView *textFieldContainerView;
@property (nonatomic, strong, readonly) UIImageView *iconView;

@end

@implementation MenuItemEditingHeaderView

- (void)awakeFromNib
{
    [super awakeFromNib];

    self.backgroundColor = [UIColor clearColor];

    [self setupStackView];
    [self setupIconView];
    [self setupTextField];
}

- (void)setupStackView
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
    _stackViewTopConstraint  = topConstraint;

    NSLayoutConstraint *bottomConstraint = [stackView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-margins.bottom];
    bottomConstraint.priority = UILayoutPriorityDefaultHigh;

    [NSLayoutConstraint activateConstraints:@[
                                              topConstraint,
                                              bottomConstraint,
                                              [stackView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:margins.left],
                                              [stackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-margins.right]
                                              ]];

    _stackView = stackView;
}

- (void)setupIconView
{
    UIImageView *iconView = [[UIImageView alloc] init];
    iconView.translatesAutoresizingMaskIntoConstraints = NO;
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    iconView.backgroundColor = [UIColor clearColor];
    iconView.tintColor = [UIColor whiteColor];

    NSLayoutConstraint *widthConstraint = [iconView.widthAnchor constraintEqualToConstant:MenusDesignItemIconSize];
    widthConstraint.active = YES;
    _iconView = iconView;

    NSAssert(_stackView != nil, @"stackView is nil");
    [_stackView addArrangedSubview:iconView];
}

- (void)setupTextField
{
    UIView *textFieldContainerView = [[UIView alloc] init];
    textFieldContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    textFieldContainerView.backgroundColor = [UIColor murielListForeground];

    NSAssert(_stackView != nil, @"stackView is nil");
    [_stackView addArrangedSubview:textFieldContainerView];

    _textFieldContainerView = textFieldContainerView;

    UIEdgeInsets margins = UIEdgeInsetsZero;
    margins.top = [self defaultStackDesignMargin];
    // Margins for the textFieldContainerView inset the textField.
    margins.left = MenusDesignDefaultContentSpacing / 2.0;
    // Inset the right margin a bit less than the left
    // since the textField also draws the close button and
    // input area inset on the right.
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
    textField.textColor = [UIColor murielNeutral70];
    textField.font = [WPStyleGuide regularTextFont];
    textField.backgroundColor = [UIColor clearColor];
    [textField addTarget:self action:@selector(textFieldKeyboardDidEndOnExit) forControlEvents:UIControlEventEditingDidEndOnExit];
    [textField addTarget:self action:@selector(textFieldValueDidChange:) forControlEvents:UIControlEventEditingChanged];

    [textFieldContainerView addSubview:textField];
    _textField = textField;

    [NSLayoutConstraint activateConstraints:@[
                                              [textField.topAnchor constraintEqualToAnchor:marginGuide.topAnchor],
                                              [textField.leadingAnchor constraintEqualToAnchor:marginGuide.leadingAnchor],
                                              [textField.trailingAnchor constraintEqualToAnchor:marginGuide.trailingAnchor],
                                              [textField.bottomAnchor constraintEqualToAnchor:marginGuide.bottomAnchor],
                                              ]];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
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

- (void)setItemType:(NSString *)itemType
{
    if (_itemType != itemType) {
        _itemType = itemType;
        self.iconView.image = [MenuItem iconImageForItemType:itemType];
    }
}

- (void)setItem:(MenuItem *)item
{
    if (_item != item) {
        _item = item;
    }

    self.textField.text = item.name;
    self.itemType = item.type;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    // Draw a mask around the view with a bottom-left arrow cut into the view.
    const CGRect iconRect = [self convertRect:self.iconView.frame fromView:self.iconView.superview];
    const CGFloat arrowDrawingInsetX = 3.0;
    const CGFloat arrowDrawingHeight = 10.0;

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGContextSetFillColorWithColor(context, [[UIColor murielPrimary40] CGColor]);
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, rect.size.width, 0);
    CGContextAddLineToPoint(context, 0, 0);
    CGContextAddLineToPoint(context, 0, rect.size.height);
    CGContextAddLineToPoint(context, iconRect.origin.x - arrowDrawingInsetX, rect.size.height);
    CGContextAddLineToPoint(context, CGRectGetMidX(iconRect), rect.size.height - arrowDrawingHeight);
    CGContextAddLineToPoint(context, iconRect.origin.x + iconRect.size.width + arrowDrawingInsetX, rect.size.height);
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
    [self.delegate editingHeaderView:self didUpdateTextForItemName:textField.text];
}

@end
