#import "MenuItemSourceLoadingView.h"
#import "MenuItemSourceCell.h"
#import "WPStyleGuide.h"

static NSTimeInterval const PulseAnimationDuration = 0.35;

@protocol MenuItemSourceLoadingDrawViewDelegate <NSObject>

- (void)drawViewDrawRect:(CGRect)rect;

@end

@interface MenuItemSourceLoadingDrawView : UIView

@property (nonatomic, weak) id <MenuItemSourceLoadingDrawViewDelegate> drawDelegate;

@end

@interface MenuItemSourceLoadingView () <MenuItemSourceLoadingDrawViewDelegate>

@property (nonatomic, strong) MenuItemSourceCell *sourceCell;
@property (nonatomic, strong) MenuItemSourceLoadingDrawView *drawView;
@property (nonatomic, strong) NSTimer *beginAnimationsTimer;
@property (nonatomic, strong) NSTimer *endAnimationsTimer;

@end

@implementation MenuItemSourceLoadingView

- (void)dealloc
{
    [self.beginAnimationsTimer invalidate];
    [self.endAnimationsTimer invalidate];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        MenuItemSourceCell *cell = [[MenuItemSourceCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        cell.frame = self.bounds;
        cell.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        cell.alpha = 0.0;
        [cell setTitle:@"Dummy Text For Sizing the Label"];
        [self addSubview:cell];
        self.sourceCell = cell;
        
        MenuItemSourceLoadingDrawView *drawView = [[MenuItemSourceLoadingDrawView alloc] initWithFrame:self.bounds];
        drawView.backgroundColor = [UIColor whiteColor];
        drawView.autoresizingMask = cell.autoresizingMask;
        drawView.drawDelegate = self;
        drawView.contentMode = UIViewContentModeRedraw;
        [self.sourceCell addSubview:drawView];
        self.drawView = drawView;
    }
    
    return self;
}

- (void)startAnimating
{
    if (self.isAnimating) {
        return;
    }
    
    [self.beginAnimationsTimer invalidate];
    [self.endAnimationsTimer invalidate];
    
    self.isAnimating = YES;
    self.sourceCell.hidden = NO;
    
    // Will begin animations on next runloop incase there are upcoming layout upates in-which the animation won't play.
    NSTimer *timer = [NSTimer timerWithTimeInterval:0.0 target:self selector:@selector(beginCellAnimations) userInfo:nil repeats:NO];
    self.beginAnimationsTimer = timer;
    // Add the timer to the runloop scheduling under common modes, to not pause for UIScrollView scrolling.
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

- (void)stopAnimating
{
    if (!self.isAnimating) {
        return;
    }
    
    [self.beginAnimationsTimer invalidate];
    [self.endAnimationsTimer invalidate];
    
    self.isAnimating = NO;
    // Let the animation play for just a bit before ending it. This avoids flickering.
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(endCellAnimations) userInfo:nil repeats:NO];
    self.endAnimationsTimer = timer;
    // Add the timer to the runloop scheduling under common modes, to not pause for UIScrollView scrolling.
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
    [self.sourceCell.layer removeAllAnimations];
    self.sourceCell.hidden = YES;
}

#pragma mark - MenuItemSourceLoadingDrawViewDelegate

- (void)drawViewDrawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [[WPStyleGuide lightGrey] CGColor]);
    CGContextFillEllipseInRect(context, self.sourceCell.drawingRectForRadioButton);
    
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
