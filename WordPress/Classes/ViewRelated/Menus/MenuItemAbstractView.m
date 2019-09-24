#import "MenuItemAbstractView.h"
#import "MenuItem+ViewDesign.h"
#import <WordPressShared/WPFontManager.h>
#import <WordPressShared/WPStyleGuide.h>
#import "WordPress-Swift.h"

@interface MenuItemDrawingView ()

@property (nonatomic, weak) id <MenuItemDrawingViewDelegate> drawDelegate;

@end

@implementation MenuItemDrawingView

- (void)drawRect:(CGRect)rect
{
    [self.drawDelegate drawingViewDrawRect:rect];
}

@end

CGFloat const MenuItemsStackableViewDefaultHeight = 44.0;

@interface MenuItemAbstractView ()

@property (nonatomic, assign) BOOL showsReorderingOptions;
@property (nonatomic, weak) NSLayoutConstraint *constraintForLeadingIndentation;

@end

@implementation MenuItemAbstractView

- (id)init
{
    self = [super init];
    if (self) {

        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.backgroundColor = [UIColor murielListForeground];

        _drawsLineSeparator = YES;

        [self setupContentView];
        [self setupStackView];
        [self setupIconView];
        [self setupTextLabel];
    }

    return self;
}

- (void)setupContentView
{
    MenuItemDrawingView *contentView = [[MenuItemDrawingView alloc] init];
    contentView.drawDelegate = self;
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    contentView.tintColor = [self iconTintColor];
    contentView.backgroundColor = [UIColor murielListForeground];

    [self addSubview:contentView];
    _contentView = contentView;

    NSLayoutConstraint *leadingConstraint = [contentView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor];
    _constraintForLeadingIndentation = leadingConstraint;
    leadingConstraint.active = YES;

    [NSLayoutConstraint activateConstraints:@[
                                              [contentView.topAnchor constraintEqualToAnchor:self.topAnchor],
                                              [contentView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
                                              [contentView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor]
                                              ]];
}

- (void)setupStackView
{
    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;

    NSAssert(_contentView != nil, @"contentView is nil");
    [_contentView addSubview:stackView];

    [NSLayoutConstraint activateConstraints:@[
                                              [stackView.topAnchor constraintEqualToAnchor:_contentView.topAnchor],
                                              [stackView.leadingAnchor constraintEqualToAnchor:_contentView.leadingAnchor],
                                              [stackView.trailingAnchor constraintEqualToAnchor:_contentView.trailingAnchor],
                                              [stackView.bottomAnchor constraintEqualToAnchor:_contentView.bottomAnchor]
                                              ]];

    UIEdgeInsets margins = UIEdgeInsetsZero;
    margins.top = 8.0;
    margins.bottom = 8.0;
    margins.left = MenusDesignDefaultContentSpacing;
    margins.right = MenusDesignDefaultContentSpacing;
    stackView.layoutMargins = margins;
    stackView.layoutMarginsRelativeArrangement = YES;
    stackView.distribution = UIStackViewDistributionFill;
    stackView.alignment = UIStackViewAlignmentCenter;
    stackView.spacing = MenusDesignDefaultContentSpacing / 2.0;

    _stackView = stackView;
}

- (void)setupIconView
{
    UIImageView *iconView = [[UIImageView alloc] init];
    iconView.translatesAutoresizingMaskIntoConstraints = NO;
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    iconView.backgroundColor = [UIColor clearColor];
    // width and height constraints are (less than or equal to) in case the view is hidden
    [iconView.widthAnchor constraintLessThanOrEqualToConstant:MenusDesignItemIconSize].active = YES;
    [iconView.heightAnchor constraintLessThanOrEqualToConstant:MenusDesignItemIconSize].active = YES;
    iconView.tintColor = [UIColor murielListIcon];
    _iconView = iconView;

    NSAssert(_stackView != nil, @"stackView is nil");
    [_stackView addArrangedSubview:iconView];
}

- (void)setupTextLabel
{
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.numberOfLines = 2;
    label.textColor = [self textLabelColor];
    label.font = [WPStyleGuide fontForTextStyle:UIFontTextStyleBody maximumPointSize:[WPStyleGuide maxFontSize]];
    label.adjustsFontForContentSizeCategory = YES;
    label.backgroundColor = [UIColor clearColor];

    NSAssert(_stackView != nil, @"stackView is nil");
    [_stackView addArrangedSubview:label];

    [label setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [label setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];

    _textLabel = label;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    /* Set the preferredMaxLayoutWidth to give a heads up to the constraint resolver.
     This speeds things up when hiding views such as the accessoryStackView's arranged views.
     */
    self.textLabel.preferredMaxLayoutWidth = self.accessoryStackView.frame.origin.x - self.textLabel.frame.origin.x;
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

        [self.delegate itemView:self highlighted:highlighted];
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

- (void)setDrawsLineSeparator:(BOOL)drawsLineSeparator
{
    if (_drawsLineSeparator != drawsLineSeparator) {
        _drawsLineSeparator = drawsLineSeparator;
        [self setNeedsDisplay];
        [self.contentView setNeedsDisplay];
    }
}

- (void)setIndentationLevel:(NSInteger)indentationLevel
{
    if (_indentationLevel != indentationLevel) {
        _indentationLevel = indentationLevel;
        self.constraintForLeadingIndentation.constant = (MenusDesignDefaultContentSpacing * indentationLevel);
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
        [stackView setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
        [stackView setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
        [self.stackView addArrangedSubview:stackView];
        _accessoryStackView = stackView;
    }

    [self.accessoryStackView addArrangedSubview:button];
    [self.accessoryStackView setNeedsLayout];
}

- (UIButton *)addAccessoryButtonIconViewWithImage:(UIImage *)image
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.backgroundColor = [UIColor clearColor];

    [button setImage:image forState:UIControlStateNormal];
    button.tintColor = [UIColor murielTextTertiary];

    CGFloat padding = 6.0;
    CGFloat width = MenusDesignItemIconSize + (padding * 2);
    CGFloat height = MenusDesignItemIconSize + (padding * 2);

    UIEdgeInsets inset = button.imageEdgeInsets;
    inset.top = padding;
    inset.bottom = padding;
    inset.left = padding;
    inset.right = padding;
    button.imageEdgeInsets = inset;

    NSLayoutConstraint *widthConstraint = [button.widthAnchor constraintEqualToConstant:width];
    widthConstraint.priority = 999;
    NSLayoutConstraint *heightConstraint = [button.heightAnchor constraintEqualToConstant:height];
    heightConstraint.priority = 999;
    [NSLayoutConstraint activateConstraints:@[
                                              widthConstraint,
                                              heightConstraint
                                              ]];
    [self addAccessoryButton:button];

    return button;
}

- (UIColor *)contentViewBackgroundColor
{
    UIColor *color = nil;
    if (self.highlighted) {
        color = [UIColor murielPrimary40];
    } else  {
        color = [UIColor murielListForeground];
    }

    return color;
}

- (UIColor *)textLabelColor
{
    UIColor *color = nil;
    if (self.highlighted) {
        color = [UIColor whiteColor];
    } else  {
        color = [UIColor murielText];
    }

    return color;
}

- (UIColor *)iconTintColor
{
    UIColor *color = nil;
    if (self.highlighted) {
        color = [UIColor whiteColor];
    } else  {
        color = [UIColor murielListIcon];
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

    CGContextSetStrokeColorWithColor(context, [[UIColor murielPrimary40] CGColor]);
    CGContextSetLineWidth(context, 1.0);

    const CGFloat dashLength = 6.0;
    const CGFloat dashFillPercentage = 60; // Fill % of the line with dashes, rest with white space.

    CGFloat(^spacingForLineLength)(CGFloat) = ^ CGFloat (CGFloat lineLength) {
        // Calculate the white spacing needed to fill the full line with dashes
        const CGFloat dashFill = (lineLength * dashFillPercentage) / 100;
        //// The white spacing is proportionate to amount of space the dashes will take.
        //// Uses (dashFill - dashLength) to ensure there is one extra dash to touch the end of the line.
        return ((lineLength - dashFill) * dashLength) / (dashFill - dashLength);
    };

    const CGFloat pointOffset = 0.5;

    // Draw the dashed lines.
    // First draw the horiztonal top and bottom lines, from left to right.
    CGFloat topBottomDashes[2] = {dashLength, spacingForLineLength(dashRect.size.width)};
    CGContextSetLineDash(context, 0, topBottomDashes, 2);

    const CGFloat leftX = dashRect.origin.x - pointOffset;
    const CGFloat rightX = dashRect.origin.x + dashRect.size.width + pointOffset;
    CGContextMoveToPoint(context, leftX, dashRect.origin.y);
    CGContextAddLineToPoint(context, rightX, dashRect.origin.y);
    CGContextMoveToPoint(context, leftX, dashRect.origin.y + dashRect.size.height);
    CGContextAddLineToPoint(context, rightX, dashRect.origin.y + dashRect.size.height);
    CGContextStrokePath(context);

    // Second draw the vertical left and right lines, from top to bottom.
    CGFloat leftRightDashes[2] = {dashLength, spacingForLineLength(dashRect.size.height)};
    CGContextSetLineDash(context, 0, leftRightDashes, 2);

    const CGFloat topY = dashRect.origin.y - pointOffset;
    const CGFloat bottomY = dashRect.origin.y + dashRect.size.height + pointOffset;
    CGContextMoveToPoint(context, dashRect.origin.x, topY);
    CGContextAddLineToPoint(context, dashRect.origin.x, bottomY);
    CGContextMoveToPoint(context, dashRect.origin.x + dashRect.size.width, topY);
    CGContextAddLineToPoint(context, dashRect.origin.x + dashRect.size.width, bottomY);
    CGContextStrokePath(context);
}

#pragma mark - MenuItemDrawingViewDelegate

- (void)drawingViewDrawRect:(CGRect)rect
{
    if (self.highlighted || !self.drawsLineSeparator) {
        return;
    }

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, MenusDesignStrokeWidth);

    // draw a line on the bottom
    CGContextMoveToPoint(context, self.stackView.layoutMargins.left, rect.size.height - (MenusDesignStrokeWidth / 2.0));
    CGContextAddLineToPoint(context, rect.size.width, rect.size.height - (MenusDesignStrokeWidth / 2.0));

    UIColor *borderColor = [UIColor murielNeutral10];
    CGContextSetStrokeColorWithColor(context, [borderColor CGColor]);
    CGContextStrokePath(context);
}

@end
