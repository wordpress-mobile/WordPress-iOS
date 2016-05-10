#import "MenusSelectionItemView.h"
#import "MenusSelectionView.h"
#import "WPStyleGuide.h"
#import "Menu+ViewDesign.h"

@interface MenusSelectionItemView ()

@property (nonatomic, strong, readonly) UILabel *label;
@property (nonatomic, assign) BOOL drawsDesignLineSeparator;
@property (nonatomic, assign) BOOL drawsHighlighted;

@end

@implementation MenusSelectionItemView

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)init
{
    self = [super init];
    if (self) {
        
        self.backgroundColor = [UIColor clearColor];
        self.translatesAutoresizingMaskIntoConstraints = NO;
        
        UILabel *label = [[UILabel alloc] init];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.backgroundColor = [UIColor clearColor];
        label.font = [[WPStyleGuide regularTextFont] fontWithSize:14];
        label.textColor = [WPStyleGuide darkGrey];
        [self addSubview:label];
        _label = label;
        
        UIEdgeInsets insets = [Menu viewDefaultDesignInsets];
        insets.left = MenusDesignDefaultContentSpacing;
        insets.right = MenusDesignDefaultContentSpacing;
        
        [label.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:insets.left].active = YES;
        [label.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:insets.right].active = YES;
        [label.topAnchor constraintEqualToAnchor:self.topAnchor constant:0].active = YES;
        [label.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:0].active = YES;
        
        _drawsDesignLineSeparator = YES; // defaults to YES
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemSelectionChanged:) name:MenusSelectionViewItemChangedSelectedNotification object:nil];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tellDelegateViewWasSelected)];
        [self addGestureRecognizer:tap];
    }
    
    return self;
}

- (void)setItem:(MenusSelectionItem *)item
{
    if (_item != item) {
        _item = item;
    }
    self.label.text = item.displayName;
}

- (void)setDrawsDesignLineSeparator:(BOOL)drawsDesignLineSeparator
{
    if (_drawsDesignLineSeparator != drawsDesignLineSeparator) {
        _drawsDesignLineSeparator = drawsDesignLineSeparator;
        [self setNeedsDisplay];
    }
}

- (void)setDrawsHighlighted:(BOOL)drawsHighlighted
{
    if (_drawsHighlighted != drawsHighlighted) {
        _drawsHighlighted = drawsHighlighted;
        
        [self.previousItemView setNeedsDisplay];
        [self.nextItemView setNeedsDisplay];
        self.drawsDesignLineSeparator = !drawsHighlighted;
        [self setNeedsDisplay];
    }
}

- (void)setHidden:(BOOL)hidden
{
    [super setHidden:hidden];
    [self setNeedsDisplay];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (self.drawsHighlighted) {
        
        [[WPStyleGuide greyLighten30] set];
        CGContextFillRect(context, rect);
        
    } else  if (self.drawsDesignLineSeparator) {
        
        // draw the line separator
        CGContextSetLineWidth(context, MenusDesignStrokeWidth);
        
        if (self.nextItemView && !self.nextItemView.drawsHighlighted) {
            // draw a line on the bottom
            CGContextMoveToPoint(context, MenusDesignDefaultContentSpacing, rect.size.height - (MenusDesignStrokeWidth / 2.0));
            CGContextAddLineToPoint(context, rect.size.width, rect.size.height - (MenusDesignStrokeWidth / 2.0));
        }
        
        CGContextSetStrokeColorWithColor(context, [[WPStyleGuide greyLighten20] CGColor]);
        CGContextStrokePath(context);
    }
    
    if (self.item.selected) {
        // draw a checkmark
        CGFloat checkStepLength = 10.0;
        CGPoint checkOrigin = CGPointZero;
        checkOrigin.x = rect.size.width - MenusDesignDefaultContentSpacing;
        checkOrigin.x -= checkStepLength;
        checkOrigin.y = rect.size.height / 2.0;
        checkOrigin.y += checkStepLength / 2.0;
        
        CGContextSetLineWidth(context, 1.0);
        CGContextMoveToPoint(context, checkOrigin.x, checkOrigin.y);
        CGContextAddLineToPoint(context, checkOrigin.x + checkStepLength, checkOrigin.y - checkStepLength);
        CGContextMoveToPoint(context, checkOrigin.x - (checkStepLength / 2.0), checkOrigin.y - (checkStepLength / 2.0));
        CGContextAddLineToPoint(context, checkOrigin.x, checkOrigin.y);
        CGContextSetStrokeColorWithColor(context, [[WPStyleGuide greyDarken10] CGColor]);
        CGContextStrokePath(context);
    }
}

#pragma mark - delegate helpers

- (void)tellDelegateViewWasSelected
{
    [self.delegate selectionItemViewWasSelected:self];
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

#pragma mark - notifications

- (void)itemSelectionChanged:(NSNotification *)notification
{
    [self setNeedsDisplay];
}

@end
