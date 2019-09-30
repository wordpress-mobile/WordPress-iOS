#import "MenuItemSourceFooterView.h"
#import "MenuItemSourceCell.h"
#import "Menu+ViewDesign.h"
#import <WordPressShared/WPStyleGuide.h>
#import "WordPress-Swift.h"

static NSTimeInterval const PulseAnimationDuration = 0.35;

@protocol MenuItemSourceLoadingDrawViewDelegate <NSObject>

- (void)drawViewDrawRect:(CGRect)rect;

@end

@interface MenuItemSourceLoadingDrawView : UIView

@property (nonatomic, weak) id <MenuItemSourceLoadingDrawViewDelegate> drawDelegate;

@end

@interface MenuItemSourceFooterView () <MenuItemSourceLoadingDrawViewDelegate>

@property (nonatomic, copy) NSString *labelText;
@property (nonatomic, assign) BOOL drawsLabelTextIfNeeded;
@property (nonatomic, strong) MenuItemSourceCell *sourceCell;
@property (nonatomic, strong) MenuItemSourceLoadingDrawView *drawView;
@property (nonatomic, strong) NSTimer *beginLoadingAnimationsTimer;
@property (nonatomic, strong) NSTimer *endLoadingAnimationsTimer;

@end

@implementation MenuItemSourceFooterView

- (void)dealloc
{
    [self.beginLoadingAnimationsTimer invalidate];
    [self.endLoadingAnimationsTimer invalidate];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {

        self.backgroundColor = [UIColor murielListBackground];

        [self setupSourceCell];
        [self setupDrawView];
    }

    return self;
}

- (void)setupSourceCell
{
    MenuItemSourceCell *cell = [[MenuItemSourceCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.frame = self.bounds;
    cell.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    cell.alpha = 0.0;
    [cell setTitle:@"Dummy Text For Sizing the Label"];
    [self addSubview:cell];
    self.sourceCell = cell;
}

- (void)setupDrawView
{
    MenuItemSourceLoadingDrawView *drawView = [[MenuItemSourceLoadingDrawView alloc] initWithFrame:self.bounds];
    drawView.backgroundColor = [UIColor murielListBackground];
    drawView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    drawView.drawDelegate = self;
    drawView.contentMode = UIViewContentModeRedraw;
    [self.sourceCell addSubview:drawView];
    self.drawView = drawView;
}

- (void)toggleMessageWithText:(NSString *)text
{
    self.labelText = text;
    if (!self.beginLoadingAnimationsTimer && !self.endLoadingAnimationsTimer) {
        self.drawsLabelTextIfNeeded = YES;
    }
}

- (void)startLoadingIndicatorAnimation
{
    if (self.isAnimating) {
        return;
    }

    self.drawsLabelTextIfNeeded = NO;

    [self.beginLoadingAnimationsTimer invalidate];
    self.beginLoadingAnimationsTimer = nil;
    [self.endLoadingAnimationsTimer invalidate];
    self.endLoadingAnimationsTimer = nil;

    self.isAnimating = YES;
    self.sourceCell.hidden = NO;

    // Will begin animations on next runloop incase there are upcoming layout upates in-which the animation won't play.
    NSTimer *timer = [NSTimer timerWithTimeInterval:0.0 target:self selector:@selector(beginCellAnimations) userInfo:nil repeats:NO];
    self.beginLoadingAnimationsTimer = timer;
    // Add the timer to the runloop scheduling under common modes, to not pause for UIScrollView scrolling.
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

- (void)stopLoadingIndicatorAnimation
{
    if (!self.isAnimating) {
        return;
    }

    [self.beginLoadingAnimationsTimer invalidate];
    self.beginLoadingAnimationsTimer = nil;
    [self.endLoadingAnimationsTimer invalidate];
    self.endLoadingAnimationsTimer = nil;

    self.isAnimating = NO;
    // Let the animation play for just a bit before ending it. This avoids flickering.
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(endCellAnimations) userInfo:nil repeats:NO];
    self.endLoadingAnimationsTimer = timer;
    // Add the timer to the runloop scheduling under common modes so it does not pause while a UIScrollView scrolls.
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

- (void)beginCellAnimations
{
    CABasicAnimation *animation = [CABasicAnimation new];
    animation.fromValue = @(0.0);
    animation.toValue = @(1.0);
    animation.keyPath = @"opacity";
    animation.autoreverses = YES;
    animation.repeatCount = HUGE_VALF;
    animation.duration = PulseAnimationDuration;
    [self.sourceCell.layer addAnimation:animation forKey:@"pulse"];
}

- (void)endCellAnimations
{
    self.drawsLabelTextIfNeeded = YES;

    [self.sourceCell.layer removeAllAnimations];
    self.sourceCell.hidden = YES;
}

- (void)setLabelText:(NSString *)labelText
{
    if (_labelText != labelText) {
        _labelText = labelText;
        [self setNeedsDisplay];
    }
}

- (void)setDrawsLabelTextIfNeeded:(BOOL)drawsLabelTextIfNeeded
{
    if (_drawsLabelTextIfNeeded != drawsLabelTextIfNeeded) {
        _drawsLabelTextIfNeeded = drawsLabelTextIfNeeded;
        [self setNeedsDisplay];
    }
}

- (void)drawRect:(CGRect)rect
{
    if (self.labelText && self.drawsLabelTextIfNeeded) {
        const CGFloat textVerticalInsetPadding = 4.0;
        CGRect textRect = CGRectInset(rect, MenusDesignDefaultContentSpacing + textVerticalInsetPadding, 0);
        textRect.origin.y = MenusDesignDefaultContentSpacing / 2.0;;
        textRect.size.height -= textRect.origin.y;
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        NSDictionary *attributes = @{
                                     NSFontAttributeName: [WPStyleGuide regularTextFont],
                                     NSForegroundColorAttributeName: [UIColor murielNeutral40],
                                     NSParagraphStyleAttributeName: style
                                     };
        [self.labelText drawInRect:textRect withAttributes:attributes];
    }
}

#pragma mark - MenuItemSourceLoadingDrawViewDelegate

- (void)drawViewDrawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [[UIColor murielNeutral0] CGColor]);
    CGRect labelRect = self.sourceCell.drawingRectForLabel;
    CGContextFillRect(context, labelRect);
}

@end

@implementation MenuItemSourceLoadingDrawView

- (void)drawRect:(CGRect)rect
{
    [self.drawDelegate drawViewDrawRect:rect];
}

@end
