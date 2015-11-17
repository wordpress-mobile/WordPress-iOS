#import "MenuItemActionableView.h"
#import "WPStyleGuide.h"
#import "MenusDesign.h"

@protocol MenuItemDrawingViewDelegate <NSObject>
- (void)drawingViewDrawRect:(CGRect)rect;
@end

@interface MenuItemDrawingView ()

@property (nonatomic, weak) id <MenuItemDrawingViewDelegate> drawDelegate;

@end

@implementation MenuItemDrawingView

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    [self.drawDelegate drawingViewDrawRect:rect];
}

@end

CGFloat const MenuItemActionableViewDefaultHeight = 55.0;
CGFloat const MenuItemActionableViewAccessoryButtonHeight = 40.0;

static CGFloat const MenuItemActionableViewIconSize = 10.0;

@interface MenuItemActionableView () <MenuItemDrawingViewDelegate>

@property (nonatomic, weak) NSLayoutConstraint *constraintForLeadingIndentation;
@property (nonatomic, strong) UIStackView *accessoryStackView;

@end

@implementation MenuItemActionableView

- (id)init
{
    self = [super init];
    if(self) {
        [self setup];
    }
    
    return self;
}

- (void)setup
{
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.backgroundColor = [WPStyleGuide lightGrey];

    MenuItemDrawingView *contentView = [[MenuItemDrawingView alloc] init];
    contentView.drawDelegate = self;
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    contentView.tintColor = [self iconTintColor];
    contentView.backgroundColor = [self contentViewBackgroundColor];

    [self addSubview:contentView];
    self.contentView = contentView;
    
    NSLayoutConstraint *leadingConstraint = [contentView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor];
    self.constraintForLeadingIndentation = leadingConstraint;
    leadingConstraint.active = YES;
    
    [NSLayoutConstraint activateConstraints:@[
                                              [contentView.topAnchor constraintEqualToAnchor:self.topAnchor],
                                              [contentView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
                                              [contentView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor]
                                              ]];
    
    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:stackView];
    
    [NSLayoutConstraint activateConstraints:@[
                                             [stackView.topAnchor constraintEqualToAnchor:contentView.topAnchor],
                                             [stackView.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor],
                                             [stackView.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor],
                                             [stackView.bottomAnchor constraintEqualToAnchor:contentView.bottomAnchor]
                                              ]];
    
    UIEdgeInsets margins = UIEdgeInsetsZero;
    margins.left = MenusDesignDefaultContentSpacing;
    margins.right = MenusDesignDefaultContentSpacing;
    stackView.layoutMargins = margins;
    stackView.layoutMarginsRelativeArrangement = YES;
    stackView.distribution = UIStackViewDistributionFill;
    stackView.alignment = UIStackViewAlignmentCenter;
    stackView.spacing = MenusDesignDefaultContentSpacing;
    
    self.stackView = stackView;
    
    {
        UIImageView *iconView = [[UIImageView alloc] init];
        iconView.translatesAutoresizingMaskIntoConstraints = NO;
        iconView.contentMode = UIViewContentModeScaleAspectFit;
        iconView.backgroundColor = [UIColor clearColor];
        // width and height constraints are (less than or equal to) in case the view is hidden
        [iconView.widthAnchor constraintLessThanOrEqualToConstant:MenuItemActionableViewIconSize].active = YES;
        [iconView.heightAnchor constraintLessThanOrEqualToConstant:MenuItemActionableViewIconSize].active = YES;
        
        [stackView addArrangedSubview:iconView];
        self.iconView = iconView;
    }
    {
        UILabel *label = [[UILabel alloc] init];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.numberOfLines = 0;
        label.textColor = [self textLabelColor];
        label.font = [WPStyleGuide regularTextFont];
        label.backgroundColor = [UIColor clearColor];
        self.textLabel = label;
        [stackView addArrangedSubview:label];
        
        [label.heightAnchor constraintEqualToAnchor:self.heightAnchor].active = YES;
    }
}

- (void)setHighlighted:(BOOL)highlighted
{
    if(_highlighted != highlighted) {
        _highlighted = highlighted;
        
        self.textLabel.textColor = [self textLabelColor];
        self.contentView.tintColor = [self iconTintColor];
        self.contentView.backgroundColor = [self contentViewBackgroundColor];
        [self.contentView setNeedsDisplay];
    }
}

- (void)setIconType:(MenuItemActionableIconType)iconType
{
    if(_iconType != iconType) {
        _iconType = iconType;
        
        if(iconType == MenuItemActionableIconNone) {
            
            self.iconView.image = nil;
            self.iconView.hidden = YES;
            
        }else {
            
            self.iconView.hidden = NO;
            self.iconView.image = [[UIImage imageNamed:[self iconNameForType:self.iconType]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        }
    }
}

#pragma mark - instance

- (void)setIndentationLevel:(NSUInteger)indentationLevel
{
    if(_indentationLevel != indentationLevel) {
        _indentationLevel = indentationLevel;
        self.constraintForLeadingIndentation.constant = MenusDesignDefaultContentSpacing * indentationLevel;
    }
}

- (void)addAccessoryButton:(UIButton *)button
{
    if(!self.accessoryStackView) {
        UIStackView *stackView = [[UIStackView alloc] init];
        stackView.translatesAutoresizingMaskIntoConstraints = NO;
        stackView.distribution = UIStackViewDistributionFill;
        stackView.spacing = 0.0;
        [self.stackView addArrangedSubview:stackView];
        self.accessoryStackView = stackView;
    }
    
    [self.accessoryStackView addArrangedSubview:button];
    [self.accessoryStackView setNeedsLayout];
}

- (UIButton *)addAccessoryButtonIconViewWithType:(MenuItemActionableIconType)type
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.imageView.contentMode = UIViewContentModeScaleAspectFit;
    button.backgroundColor = [UIColor clearColor];
    
    if(type != MenuItemActionableIconNone) {
        [button setImage:[[UIImage imageNamed:[self iconNameForType:type]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    }
    
    CGFloat buttonWidth = 30.0;
    CGFloat buttonHeight = MenuItemActionableViewAccessoryButtonHeight;
    CGFloat iconSize = MenuItemActionableViewIconSize;
    UIEdgeInsets imageInset = UIEdgeInsetsZero;
    imageInset.top = (buttonHeight - iconSize) / 2.0;
    imageInset.bottom = imageInset.top;
    imageInset.left = (buttonWidth - iconSize) / 2.0;
    imageInset.right = imageInset.left;
    button.imageEdgeInsets = imageInset;
    
    // width and height constraints are (less than or equal to) in case the view is hidden
    [button.widthAnchor constraintLessThanOrEqualToConstant:buttonWidth].active = YES;
    [button.heightAnchor constraintEqualToConstant:buttonHeight].active = YES;
    
    [self addAccessoryButton:button];
    
    return button;
}

- (UIColor *)contentViewBackgroundColor
{
    UIColor *color = nil;
    if(self.highlighted) {
        color = [WPStyleGuide mediumBlue];
    }else {
        color = [UIColor whiteColor];
    }
    
    return color;
}

- (UIColor *)textLabelColor
{
    UIColor *color = nil;
    if(self.highlighted) {
        color = [UIColor whiteColor];
    }else {
        color = [WPStyleGuide darkGrey];
    }
    
    return color;
}

- (UIColor *)iconTintColor
{
    UIColor *color = nil;
    if(self.highlighted) {
        color = [UIColor whiteColor];
    }else {
        color = [WPStyleGuide mediumBlue];
    }
    
    return color;
}

#pragma mark - private

- (NSString *)iconNameForType:(MenuItemActionableIconType)type
{
    NSString *name;
    switch (type) {
        case MenuItemActionableIconNone:
            name = nil;
            break;
        case MenuItemActionableIconDefault:
            name = @"icon-menus-document";
            break;
        case MenuItemActionableIconEdit:
            name = @"icon-menus-edit";
            break;
        case MenuItemActionableIconAdd:
            name = @"icon-menus-plus";
            break;
    }
    
    return name;
}

#pragma mark - overrides

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    [self setNeedsDisplay];
}

#pragma mark - MenuItemDrawingViewDelegate

- (void)drawingViewDrawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
        
    // draw a line on the bottom
    CGContextSetLineWidth(context, 1.0);
    CGContextMoveToPoint(context, 0, rect.size.height);
    CGContextAddLineToPoint(context, rect.size.width, rect.size.height);
    
    CGContextMoveToPoint(context, 0, 0);
    CGContextAddLineToPoint(context, 0, rect.size.height);
    
    CGContextSetStrokeColorWithColor(context, [[WPStyleGuide greyLighten30] CGColor]);
    CGContextStrokePath(context);
}

#pragma mark - touches

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    self.highlighted = YES;
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    self.highlighted = NO;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    self.highlighted = NO;
}

@end
