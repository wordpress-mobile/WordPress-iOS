#import <QuartzCore/QuartzCore.h>
#import "WPToast.h"

const CGFloat WPToastAnimationZoomDuration = 0.15f;
const CGFloat WPToastAnimationFadeDuration = 0.25f;
const CGFloat WPToastAnimationVisibleDuration = 0.35f;

@interface WPToast ()
@property (nonatomic, strong) IBOutlet UIView *toastView;
@property (nonatomic, strong) IBOutlet UILabel *toastLabel;
@property (nonatomic, strong) IBOutlet UIImageView *toastIcon;
@end
@implementation WPToast

+ (void)showToastWithMessage:(NSString *)message andImage:(UIImage *)image
{
    [[[self alloc] init] showToastWithMessage:message andImage:image];
}

+ (void)showToastWithMessage:(NSString *)message andImageNamed:(NSString *)imageName
{
    [self showToastWithMessage:message andImage:[UIImage imageNamed:imageName]];
}

- (void)showToastWithMessage:(NSString *)message andImage:(UIImage *)image
{
    // Note: There might be more than one window (IE. AlertView is onscreen)
    UIWindow *firstWindow = [[[UIApplication sharedApplication] windows] firstObject];
    UIViewController *rootViewController = firstWindow.rootViewController;

    UIView *parentView = rootViewController.view;

    [[NSBundle mainBundle] loadNibNamed:@"ToastView" owner:self options:nil];
    [self.toastView setFrame:parentView.bounds];
    [self.toastView setAlpha:0.1f];
    [self.toastView setCenter:CGPointMake(CGRectGetMidX(parentView.bounds), CGRectGetMidY(parentView.bounds))];
    [self.toastView.layer setCornerRadius:20.0f];
    [rootViewController.view addSubview:self.toastView];

    self.toastLabel.text = message;
    self.toastLabel.alpha = 0.0f;

    self.toastIcon.image = image;
    self.toastIcon.alpha = 0.0f;

    [UIView beginAnimations:@"toast_zoom_in" context:(__bridge void *)(self.toastView)];
    [UIView setAnimationDuration:WPToastAnimationZoomDuration];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    self.toastView.alpha= 1.0f;
    CGFloat toastOffset = 95.0f;
    if (IS_IPHONE && UIInterfaceOrientationIsPortrait(rootViewController.interfaceOrientation)) {
        toastOffset = 125.0f;
    }
    self.toastView.frame = CGRectMake((rootViewController.view.bounds.size.width / 2) - 95.0f, (rootViewController.view.bounds.size.height / 2) - toastOffset, 190.0f, 190.0f);
    [UIView commitAnimations];
}

- (void)animationDidStop:(NSString*)animationID finished:(BOOL)finished context:(void *)context
{
    UIViewController *parentViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];

    UIView *toastView = (__bridge UIView *)context;
    if ([animationID isEqualToString:@"toast_zoom_in"]) {
        [UIView beginAnimations:@"content_fade_in" context:(__bridge void *)(toastView)];
        [UIView setAnimationDuration:WPToastAnimationFadeDuration];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
        self.toastLabel.alpha = 1.0f;
        self.toastIcon.alpha = 1.0f;
        [UIView commitAnimations];
    } else if ([animationID isEqualToString:@"content_fade_in"]) {
        [UIView beginAnimations:@"content_fade_out" context:(__bridge void *)(toastView)];
        [UIView setAnimationDelay:WPToastAnimationVisibleDuration];
        [UIView setAnimationDuration:WPToastAnimationFadeDuration];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
        self.toastLabel.alpha = 0.0f;
        self.toastIcon.alpha = 0.0f;
        [UIView commitAnimations];
    } else if ([animationID isEqualToString:@"content_fade_out"]) {
        [UIView beginAnimations:@"toast_zoom_out" context:(__bridge void *)(toastView)];
        [UIView setAnimationDuration:WPToastAnimationZoomDuration];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        toastView.frame = CGRectMake(parentViewController.view.bounds.size.width / 2, parentViewController.view.bounds.size.height / 2, 0.0f, 0.0f);
        toastView.alpha = 0.0f;
        [UIView commitAnimations];
    } else if ([animationID isEqualToString:@"toast_zoom_out"]) {
        [toastView removeFromSuperview];
    }
}

@end
