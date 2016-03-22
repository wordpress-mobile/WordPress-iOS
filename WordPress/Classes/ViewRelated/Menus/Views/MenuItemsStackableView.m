#import "MenuItemsStackableView.h"
#import "WPStyleGuide.h"
#import "MenuItem+ViewDesign.h"

@interface MenuItemDrawingView ()

@property (nonatomic, weak) id <MenuItemDrawingViewDelegate> drawDelegate;

@end

@implementation MenuItemDrawingView

- (void)drawRect:(CGRect)rect
{
    [self.drawDelegate drawingViewDrawRect:rect];
}

@end

CGFloat const MenuItemsStackableViewDefaultHeight = 55.0;

@interface MenuItemsStackableView ()

@property (nonatomic, assign) BOOL showsReorderingOptions;
@property (nonatomic, weak) NSLayoutConstraint *constraintForLeadingIndentation;
@property (nonatomic, strong) UIStackView *accessoryStackView;

@end

@implementation MenuItemsStackableView

- (id)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    
    return self;
}

- (void)setup
{
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.backgroundColor = [UIColor clearColor];

    MenuItemDrawingView *contentView = [[MenuItemDrawingView alloc] init];
    contentView.drawDelegate = self;
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    contentView.tintColor = [self iconTintColor];
    contentView.backgroundColor = [self contentViewBackgroundColor];

    [self addSubview:contentView];
    self.contentView = contentView;
    
    NSLayoutConstraint *leadingConstraint = [contentView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:MenusDesignDefaultContentSpacing];
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
        [iconView.widthAnchor constraintLessThanOrEqualToConstant:MenusDesignItemIconSize].active = YES;
        [iconView.heightAnchor constraintLessThanOrEqualToConstant:MenusDesignItemIconSize].active = YES;
        iconView.tintColor = [WPStyleGuide mediumBlue];
        
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
        [label setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
        [label setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    }
}

#pragma mark - instance

- (void)setHighlighted:(BOOL)highlighted
{
    if (_highlighted != highlighted) {
        _highlighted = highlighted;
        
        self.textLabel.textColor = [self textLabelColor];
        self.iconView.tintColor = [self iconTintColor];
        self.contentView.tintColor = [self iconTintColor];
        self.contentView.backgroundColor = [self contentViewBackgroundColor];
        [self.contentView setNeedsDisplay];
    }
}

- (void)setIsPlaceholder:(BOOL)isPlaceholder
{
    if (_isPlaceholder != isPlaceholder) {
        _isPlaceholder = isPlaceholder;
        
        self.contentView.alpha = isPlaceholder ? 0.45 : 1.0;
        
        [self setNeedsDisplay];
        [self.contentView setNeedsDisplay];
    }
}

- (void)setIndentationLevel:(NSInteger)indentationLevel
{
    if (_indentationLevel != indentationLevel) {
        _indentationLevel = indentationLevel;
        self.constraintForLeadingIndentation.constant = (MenusDesignDefaultContentSpacing * indentationLevel) + MenusDesignDefaultContentSpacing;
        [self setNeedsDisplay];
        [self.contentView setNeedsDisplay];
    }
}

- (void)addAccessoryButton:(UIButton *)button
{
    if (!self.accessoryStackView) {
        UIStackView *stackView = [[UIStackView alloc] init];
        stackView.translatesAutoresizingMaskIntoConstraints = NO;
        stackView.distribution = UIStackViewDistributionFill;
        stackView.spacing = -(MenusDesignItemIconSize / 4.0);
        [self.stackView addArrangedSubview:stackView];
        
        self.accessoryStackView = stackView;
    }
    
    [self.accessoryStackView addArrangedSubview:button];
    [self.accessoryStackView setNeedsLayout];
}

- (UIButton *)addAccessoryButtonIconViewWithImageName:(NSString *)imageName
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.imageView.contentMode = UIViewContentModeScaleAspectFit;
    button.backgroundColor = [UIColor clearColor];
    
    [button setImage:[[UIImage imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    
    CGFloat width = MenusDesignItemIconSize * 2;
    CGFloat height = width;
    
    UIEdgeInsets inset = button.imageEdgeInsets;
    inset.top = (height - MenusDesignItemIconSize) / 2.0;
    inset.bottom = inset.top;
    button.imageEdgeInsets = inset;
    
    // width and height constraints are (less than or equal to) in case the view is hidden
    [button.widthAnchor constraintLessThanOrEqualToConstant:width].active = YES;
    [button.heightAnchor constraintEqualToConstant:height].active = YES;
    
    [self addAccessoryButton:button];
    
    return button;
}

- (UIColor *)contentViewBackgroundColor
{
    UIColor *color = nil;
    if (self.highlighted) {
        color = [WPStyleGuide mediumBlue];
    } else  {
        color = [UIColor whiteColor];
    }
    
    return color;
}

- (UIColor *)textLabelColor
{
    UIColor *color = nil;
    if (self.highlighted) {
        color = [UIColor whiteColor];
    } else  {
        color = [WPStyleGuide darkGrey];
    }
    
    return color;
}

- (UIColor *)iconTintColor
{
    UIColor *color = nil;
    if (self.highlighted) {
        color = [UIColor whiteColor];
    } else  {
        color = [WPStyleGuide mediumBlue];
    }
    
    return color;
}

#pragma mark - touches

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    self.highlighted = YES;
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    self.highlighted = NO;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    self.highlighted = NO;
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    self.highlighted = NO;
}

#pragma mark - overrides

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    [self setNeedsDisplay];
    [self.contentView setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect dashRect = CGRectInset(self.contentView.frame, 8.0, 8.0);
    
    CGContextSetStrokeColorWithColor(context, [[WPStyleGuide greyLighten10] CGColor]);
    CGContextSetLineWidth(context, 1.0);
    
    const CGFloat dashLength = 6.0;
    const CGFloat dashFillPercentage = 60; // fill % of the line with dashes, rest with white space
    
    CGFloat(^spacingForLineLength)(CGFloat) = ^ CGFloat (CGFloat lineLength) {
        // calculate the white spacing needed to fill the full line with dashes
        const CGFloat dashFill = (lineLength * dashFillPercentage) / 100;
        //// the white spacing is proportionate to amount of space the dashes will take
        //// uses (dashFill - dashLength) to ensure there is one extra dash to touch the end of the line
        return ((lineLength - dashFill) * dashLength) / (dashFill - dashLength);
    };
    
    const CGFloat pointOffset = 0.5;
    {
        CGFloat dash[2] = {dashLength, spacingForLineLength(dashRect.size.width)};
        CGContextSetLineDash(context, 0, dash, 2);
        
        const CGFloat leftX = dashRect.origin.x - pointOffset;
        const CGFloat rightX = dashRect.origin.x + dashRect.size.width + pointOffset;
        CGContextMoveToPoint(context, leftX, dashRect.origin.y);
        CGContextAddLineToPoint(context, rightX, dashRect.origin.y);
        CGContextMoveToPoint(context, leftX, dashRect.origin.y + dashRect.size.height);
        CGContextAddLineToPoint(context, rightX, dashRect.origin.y + dashRect.size.height);
        CGContextStrokePath(context);
        
    }
    {
        CGFloat dash[2] = {dashLength, spacingForLineLength(dashRect.size.height)};
        CGContextSetLineDash(context, 0, dash, 2);
        
        const CGFloat topY = dashRect.origin.y - pointOffset;
        const CGFloat bottomY = dashRect.origin.y + dashRect.size.height + pointOffset;
        CGContextMoveToPoint(context, dashRect.origin.x, topY);
        CGContextAddLineToPoint(context, dashRect.origin.x, bottomY);
        CGContextMoveToPoint(context, dashRect.origin.x + dashRect.size.width, topY);
        CGContextAddLineToPoint(context, dashRect.origin.x + dashRect.size.width, bottomY);
        CGContextStrokePath(context);
    }
}

#pragma mark - MenuItemDrawingViewDelegate

- (void)drawingViewDrawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 1.0);
    
    if (_isPlaceholder) {
        // draw a line on the top
        // but only while reordering
        // otherwise the line stacks against the other line on the top
        CGContextMoveToPoint(context, 0, 0);
        CGContextAddLineToPoint(context, rect.size.width, 0);
    }
    
    // draw a line on the bottom
    CGContextMoveToPoint(context, 0, rect.size.height);
    CGContextAddLineToPoint(context, rect.size.width, rect.size.height);
    
    // draw a line on the left
    CGContextMoveToPoint(context, 0, 0);
    CGContextAddLineToPoint(context, 0, rect.size.height);
    
    UIColor *borderColor = _isPlaceholder ? [WPStyleGuide lightBlue] : [WPStyleGuide greyLighten30];
    CGContextSetStrokeColorWithColor(context, [borderColor CGColor]);
    CGContextStrokePath(context);
}

@end