#import "WPAnimatedBox.h"

@interface WPAnimatedBox () {

    UIImageView *_container;
    UIImageView *_containerBack;
    UIImageView *_page1;
    UIImageView *_page2;
    UIImageView *_page3;
}

@property (nonatomic, assign, readwrite) BOOL isAnimating;

@end

@implementation WPAnimatedBox

static CGFloat const WPAnimatedBoxSideLength = 86.0;
static CGFloat const WPAnimatedBoxAnimationTolerance = 5.0;

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        [self setupView];
        
        _isAnimating = NO;
    }
    
    return self;
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
    _page1.frame = CGRectMake(28, WPAnimatedBoxAnimationTolerance + 11, CGRectGetWidth(_page1.frame), CGRectGetHeight(_page1.frame));
    _page2.frame = CGRectMake(17, WPAnimatedBoxAnimationTolerance + 0, CGRectGetWidth(_page2.frame), CGRectGetHeight(_page2.frame));
    _page3.frame = CGRectMake(2, WPAnimatedBoxAnimationTolerance + 15, CGRectGetWidth(_page3.frame), CGRectGetHeight(_page3.frame));

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
    // Transform pages all the way down
    NSArray *pages = @[_page1, _page2, _page3];
    for (UIView *view in pages) {
        CGFloat YOrigin = CGRectGetMinY(view.frame);
        view.transform = CGAffineTransformMakeTranslation(0, CGRectGetHeight(self.frame) - YOrigin);
    }
}

- (void)playAnimation
{
    self.isAnimating = YES;

    [UIView animateWithDuration:1.4 delay:0.1 usingSpringWithDamping:0.5 initialSpringVelocity:0.1 options:UIViewAnimationOptionCurveEaseOut animations:^{
        _page1.transform = CGAffineTransformIdentity;
    } completion:nil];
    [UIView animateWithDuration:1 delay:0.0 usingSpringWithDamping:0.65 initialSpringVelocity:0.01 options:UIViewAnimationOptionCurveEaseOut animations:^{
        _page2.transform = CGAffineTransformIdentity;
    } completion: ^void(BOOL finished) {
        self.isAnimating = NO;
    }];
    [UIView animateWithDuration:1.2 delay:0.2 usingSpringWithDamping:0.5 initialSpringVelocity:0.1 options:UIViewAnimationOptionCurveEaseOut animations:^{
        _page3.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)animate
{
    if (self.isAnimating) {
        return;
    }
    
    [self moveAnimationToFirstFrame];
    [self playAnimation];
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

@end
