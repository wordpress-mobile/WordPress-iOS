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
@property (nonatomic, strong) NSTimer *delayedStopTimer;

@end

@implementation MenuItemSourceLoadingView

- (void)dealloc
{
    [self.delayedStopTimer invalidate];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self) {
        
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
    [self.delayedStopTimer invalidate];
    self.isAnimating = YES;
    self.sourceCell.hidden = NO;
    
    CABasicAnimation *animation = [CABasicAnimation new];
    animation.fromValue = @(0.0);
    animation.toValue = @(1.0);
    animation.keyPath = @"opacity";
    animation.autoreverses = YES;
    animation.repeatCount = HUGE_VALF;
    animation.duration = PulseAnimationDuration;
    [self.sourceCell.layer addAnimation:animation forKey:@"pulse"];
}

- (void)stopAnimating
{
    self.isAnimating = NO;
    self.delayedStopTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(hideCellAndRemoveAnimation) userInfo:nil repeats:NO];
}

- (void)hideCellAndRemoveAnimation
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
