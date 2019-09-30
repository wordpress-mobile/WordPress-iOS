#import "WPAnimatedBox.h"

@interface WPAnimatedBox () {
    UIImageView *_container;
    UIImageView *_containerBack;
}

@property (nonatomic, assign, readwrite) BOOL isAnimating;
@property (nonatomic, retain) UIImageView *page1;
@property (nonatomic, retain) UIImageView *page2;
@property (nonatomic, retain) UIImageView *page3;
@end

@implementation WPAnimatedBox

static CGFloat const WPAnimatedBoxSideLength = 86.0;
static CGFloat const WPAnimatedBoxAnimationTolerance = 5.0;
static CGFloat const WPAnimatedBoxXPosPage1 = 28;
static CGFloat const WPAnimatedBoxXPosPage2 = 17;
static CGFloat const WPAnimatedBoxXPosPage3 = 2;
static CGFloat const WPAnimatedBoxYPosPage1 = WPAnimatedBoxAnimationTolerance + 11;
static CGFloat const WPAnimatedBoxYPosPage2 = WPAnimatedBoxAnimationTolerance + 0;
static CGFloat const WPAnimatedBoxYPosPage3 = WPAnimatedBoxAnimationTolerance + 15;

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        [self setupView];
        
        _isAnimating = NO;
    }
    
    return self;
}

- (void)dealloc
{
    _isAnimating = NO;
}

- (void)setupView
{
    _container = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"animatedBox"]];
    [_container sizeToFit];

    _containerBack = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"animatedBoxBack"]];
    [_containerBack sizeToFit];

    _page1 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"animatedBoxPage1"]];
    [_page1 sizeToFit];

    _page2 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"animatedBoxPage2"]];
    [_page2 sizeToFit];

    _page3 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"animatedBoxPage3"]];
    [_page3 sizeToFit];

    // view's are laid out by pixels for accuracy
    self.frame = CGRectMake(0, 0, WPAnimatedBoxSideLength, WPAnimatedBoxSideLength);
    _container.frame = CGRectMake(0, CGRectGetHeight(self.frame) - CGRectGetHeight(_container.frame), CGRectGetWidth(_container.frame), CGRectGetHeight(_container.frame));
    _containerBack.frame = CGRectMake(0, CGRectGetHeight(self.frame) - CGRectGetHeight(_containerBack.frame), CGRectGetWidth(_containerBack.frame), CGRectGetHeight(_containerBack.frame));
    _page1.frame = CGRectMake(WPAnimatedBoxXPosPage1, WPAnimatedBoxYPosPage1, CGRectGetWidth(_page1.frame), CGRectGetHeight(_page1.frame));
    _page2.frame = CGRectMake(WPAnimatedBoxXPosPage2, WPAnimatedBoxYPosPage2, CGRectGetWidth(_page2.frame), CGRectGetHeight(_page2.frame));
    _page3.frame = CGRectMake(WPAnimatedBoxXPosPage3, WPAnimatedBoxYPosPage3, CGRectGetWidth(_page3.frame), CGRectGetHeight(_page3.frame));

    [self addSubview:_container];
    [self insertSubview:_page1 belowSubview:_container];
    [self insertSubview:_page2 belowSubview:_page1];
    [self insertSubview:_page3 belowSubview:_page2];
    [self insertSubview:_containerBack belowSubview:_page3];

    self.clipsToBounds = YES;
    
    [self moveAnimationToFirstFrame];
}

- (void)moveAnimationToFirstFrame
{
    NSArray *pages = @[_page1, _page2, _page3];
 
    for (UIView *view in pages) {
        
        // We're setting the transform to identity, because the following calculation of `yOrigin`
        // is relative to `view.frame.origin`, so we want the view to be positioned correctly
        // before the calculation is done.  The lack of this, was causing trouble when this method
        // was called twice in a row.
        //
        // https://github.com/wordpress-mobile/WordPress-iOS/pull/5295
        //
        view.transform = CGAffineTransformIdentity;
        CGFloat yOrigin = CGRectGetMinY(view.frame);
        view.transform = CGAffineTransformMakeTranslation(0, CGRectGetHeight(self.frame) - yOrigin);
    }
}

- (void)playAnimation
{
    self.isAnimating = YES;

    __weak __typeof(self) weakSelf = self;

    [UIView animateWithDuration:1.4 delay:0.1 usingSpringWithDamping:0.5 initialSpringVelocity:0.1 options:UIViewAnimationOptionCurveEaseOut animations:^{
        weakSelf.page1.transform = CGAffineTransformIdentity;
    } completion:nil];
    [UIView animateWithDuration:1 delay:0.0 usingSpringWithDamping:0.65 initialSpringVelocity:0.01 options:UIViewAnimationOptionCurveEaseOut animations:^{
        weakSelf.page2.transform = CGAffineTransformIdentity;
    } completion:nil];
    [UIView animateWithDuration:1.2 delay:0.2 usingSpringWithDamping:0.5 initialSpringVelocity:0.1 options:UIViewAnimationOptionCurveEaseOut animations:^{
        weakSelf.page3.transform = CGAffineTransformIdentity;
    } completion:^void(BOOL finished) {
        [UIView animateWithDuration:0.8 delay:2.0 usingSpringWithDamping:0.8 initialSpringVelocity:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            [weakSelf moveAnimationToFirstFrame];
        } completion:^(BOOL finished) {
            if (weakSelf.isAnimating && weakSelf.window != nil) {
                [weakSelf playAnimation];
            }
        }];
    }];
}

- (void)animate
{
    [self animateAfterDelay:0];
}

- (void)animateAfterDelay:(NSTimeInterval)delayInSeconds
{
    if (self.isAnimating) {
        return;
    }
    
    [self moveAnimationToFirstFrame];
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self playAnimation];
    });
}

- (void)suspendAnimation
{
    self.isAnimating = NO;
}

@end
