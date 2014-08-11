#import "WPLoadingView.h"

@interface WPLoadingView ()

@property (nonatomic, assign) CGFloat side;

@end

@implementation WPLoadingView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    return self;
}

- (id)initWithSide:(CGFloat)sideLength
{
    self = [super init];
    if (self) {
        _side = sideLength;
        [self createLoadingView];
    }
    return self;
}

- (void)createLoadingView
{
    self.layer.cornerRadius = 10.0f;
    self.frame = CGRectMake(0, 0, _side, _side);
    self.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.8f];
    self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
    UIViewAutoresizingFlexibleBottomMargin |
    UIViewAutoresizingFlexibleTopMargin |
    UIViewAutoresizingFlexibleRightMargin;

    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    activityView.hidesWhenStopped = NO;
    activityView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
    UIViewAutoresizingFlexibleBottomMargin |
    UIViewAutoresizingFlexibleTopMargin |
    UIViewAutoresizingFlexibleRightMargin;
    [activityView startAnimating];

    CGRect frm = activityView.frame;
    frm.origin.x = (_side / 2.0f) - (frm.size.width / 2.0f);
    frm.origin.y = (_side / 2.0f) - (frm.size.height / 2.0f);
    activityView.frame = frm;
    [self addSubview:activityView];
}

- (void)show
{
    [UIView animateWithDuration:0.3f animations:^{
        [self setHidden:NO];
    } completion:^(BOOL finished) {
    }];
}

- (void)hide
{
    [UIView animateWithDuration:0.3f animations:^{
        [self setHidden:YES];
    } completion:^(BOOL finished) {
    }];

    [self setHidden:YES];
}

@end
