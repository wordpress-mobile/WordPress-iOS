#import "MenuItemsActionableView.h"
#import "WPStyleGuide.h"
#import "MenusDesign.h"

@protocol MenuItemDrawingViewDelegate <NSObject>
- (void)drawingViewDrawRect:(CGRect)rect;
@end

@interface MenuItemDrawingView : UIView
@property (nonatomic, weak) id <MenuItemDrawingViewDelegate> drawDelegate;
@end

@implementation MenuItemDrawingView

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    [self.drawDelegate drawingViewDrawRect:rect];
}

@end

static CGFloat const MenuItemsActionableViewIconSize = 10.0;

@interface MenuItemsActionableView () <MenuItemDrawingViewDelegate>

@property (nonatomic, strong) MenuItemDrawingView *contentView;
@property (nonatomic, assign) BOOL drawsHighlighted;
@property (nonatomic, weak) NSLayoutConstraint *constraintForLeadingIndentation;

@end

@implementation MenuItemsActionableView

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
    self.contentBackgroundColor = [UIColor whiteColor];

    MenuItemDrawingView *contentView = [[MenuItemDrawingView alloc] init];
    contentView.drawDelegate = self;
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    contentView.tintColor = [WPStyleGuide mediumBlue];

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
        [iconView.widthAnchor constraintLessThanOrEqualToConstant:MenuItemsActionableViewIconSize].active = YES;
        [iconView.heightAnchor constraintLessThanOrEqualToConstant:MenuItemsActionableViewIconSize].active = YES;
        
        [stackView addArrangedSubview:iconView];
        self.iconView = iconView;
    }
    {
        UILabel *label = [[UILabel alloc] init];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.numberOfLines = 0;
        label.textColor = [WPStyleGuide darkGrey];
        label.font = [WPStyleGuide regularTextFont];
        label.backgroundColor = [UIColor clearColor];
        self.textLabel = label;
        [stackView addArrangedSubview:label];
        
        [label.heightAnchor constraintEqualToAnchor:self.heightAnchor].active = YES;
    }
}

- (void)setDrawsHighlighted:(BOOL)drawsHighlighted
{
    if(_drawsHighlighted != drawsHighlighted) {
        _drawsHighlighted = drawsHighlighted;
        [self.contentView setNeedsDisplay];
    }
}

- (void)setIconType:(MenuItemsActionableIconType)iconType
{
    if(_iconType != iconType) {
        _iconType = iconType;
        
        if(iconType == MenuItemsActionableIconNone) {
            
            self.iconView.image = nil;
            self.iconView.hidden = YES;
            
        }else {
            
            self.iconView.hidden = NO;
            self.iconView.image = [[UIImage imageNamed:[self iconNameForType:self.iconType]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        }
    }
}

#pragma mark - instance

- (void)setContentBackgroundColor:(UIColor *)contentBackgroundColor
{
    if(_contentBackgroundColor != contentBackgroundColor) {
        _contentBackgroundColor = [contentBackgroundColor copy];
        [self setNeedsDisplay];
    }
}

- (void)setIndentationLevel:(NSUInteger)indentationLevel
{
    if(_indentationLevel != indentationLevel) {
        _indentationLevel = indentationLevel;
        self.constraintForLeadingIndentation.constant = MenusDesignDefaultContentSpacing * indentationLevel;
    }
}

- (UIColor *)highlightedColor
{
    return [WPStyleGuide mediumBlue];
}

- (UIButton *)newButtonIconViewWithType:(MenuItemsActionableIconType)type
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.imageView.contentMode = UIViewContentModeScaleAspectFit;
    button.backgroundColor = [UIColor clearColor];
    
    if(type != MenuItemsActionableIconNone) {
        [button setImage:[[UIImage imageNamed:[self iconNameForType:type]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    }
    
    CGFloat buttonWidth = 25.0;
    CGFloat buttonHeight = 30.0;
    CGFloat iconSize = MenuItemsActionableViewIconSize;
    UIEdgeInsets imageInset = UIEdgeInsetsZero;
    imageInset.top = (buttonHeight - iconSize) / 2.0;
    imageInset.bottom = imageInset.top;
    imageInset.left = (buttonWidth - iconSize) / 2.0;
    imageInset.right = imageInset.right;
    button.imageEdgeInsets = imageInset;
    
    // width and height constraints are (less than or equal to) in case the view is hidden
    [button.widthAnchor constraintLessThanOrEqualToConstant:buttonWidth].active = YES;
    [button.heightAnchor constraintEqualToConstant:buttonHeight].active = YES;
    
    return button;
}

#pragma mark - private

- (NSString *)iconNameForType:(MenuItemsActionableIconType)type
{
    NSString *name;
    switch (type) {
        case MenuItemsActionableIconNone:
            name = nil;
            break;
        case MenuItemsActionableIconDefault:
            name = @"icon-menus-document";
            break;
        case MenuItemsActionableIconEdit:
            name = @"icon-menus-edit";
            break;
        case MenuItemsActionableIconAdd:
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
    
    if(self.drawsHighlighted) {
        [[self highlightedColor] set];
    }else {
        [self.contentBackgroundColor set];
    }
    
    CGContextFillRect(context, rect);
    
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
    self.drawsHighlighted = YES;
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    self.drawsHighlighted = NO;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    self.drawsHighlighted = NO;
}

@end
