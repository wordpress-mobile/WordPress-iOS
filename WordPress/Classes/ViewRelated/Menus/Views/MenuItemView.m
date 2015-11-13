#import "MenuItemView.h"
#import "MenuItem.h"
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

@interface MenuItemView () <MenuItemDrawingViewDelegate>

@property (nonatomic, strong) MenuItemDrawingView *contentView;
@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, assign) BOOL drawsHighlighted;
@property (nonatomic, weak) NSLayoutConstraint *constraintForLeadingIndentation;

@end

@implementation MenuItemView

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
    
    [self addSubview:contentView];
    self.contentView = contentView;
    
    NSLayoutConstraint *leadingConstraint = [contentView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor];
    self.constraintForLeadingIndentation = leadingConstraint;
    leadingConstraint.active = YES;
    
    [contentView.topAnchor constraintEqualToAnchor:self.topAnchor].active = YES;
    [contentView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor].active = YES;
    [contentView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor].active = YES;
}

- (void)setDrawsHighlighted:(BOOL)drawsHighlighted
{
    if(_drawsHighlighted != drawsHighlighted) {
        _drawsHighlighted = drawsHighlighted;
        [self.contentView setNeedsDisplay];
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

- (UIColor *)highlightedColor
{
    return [WPStyleGuide mediumBlue];
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
    BOOL highlighted = self.drawsHighlighted;
    
    if(highlighted) {
        [[self highlightedColor] set];
    }else {
        [[UIColor whiteColor] set];
    }
    
    CGContextFillRect(context, rect);
    
    if(!highlighted) {
        
        // draw the line separator
        CGContextSetLineWidth(context, 1.0);
        
        if(self.nextItemView) {
            // draw a line on the bottom
            CGContextMoveToPoint(context, 0, rect.size.height);
            CGContextAddLineToPoint(context, rect.size.width, rect.size.height);
        }
        
        CGContextMoveToPoint(context, 0, 0);
        CGContextAddLineToPoint(context, 0, rect.size.height);
        
        CGContextSetStrokeColorWithColor(context, [[WPStyleGuide greyLighten30] CGColor]);
        CGContextStrokePath(context);
    }
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
