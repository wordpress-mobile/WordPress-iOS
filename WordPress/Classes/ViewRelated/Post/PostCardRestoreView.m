#import "PostCardRestoreView.h"
#import <QuartzCore/QuartzCore.h>

static CGFloat PostCardRestoreViewAnimationDuration = 0.2;

@interface PostCardRestoreView ()
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityView;
@property (nonatomic, strong) IBOutlet UIView *dialogView;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UIButton *button;
@end

@implementation PostCardRestoreView

#pragma mark - LifeCycle Methods

+ (instancetype)newPostCardRestoreView
{
    return [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil] firstObject];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self applyBorderRadius];
}


#pragma mark - Configuration Methods

- (void)applyBorderRadius
{
    self.dialogView.clipsToBounds = YES;
    self.dialogView.layer.cornerRadius = 5.0;
    self.dialogView.layer.borderWidth = 1.0;
}


#pragma mark - Public Methods

- (void)tintColorDidChange
{
    [super tintColorDidChange];
    self.dialogView.layer.borderColor = self.tintColor.CGColor;
    self.button.tintColor = self.tintColor;
    [self.button setTitleColor:self.tintColor forState:UIControlStateNormal];
    self.titleLabel.textColor = self.tintColor;
}

- (void)setMessage:(NSString *)message andButtonTitle:(NSString *)buttonTitle
{
    self.titleLabel.text = message;
    [self.button setTitle:buttonTitle forState:UIControlStateNormal];
    [self.button setTitle:buttonTitle forState:UIControlStateHighlighted];
}

- (void)showSpinner:(BOOL)show animated:(BOOL)animated
{
    if (show == self.activityView.isAnimating) {
        return;
    }

    CGFloat startingAlpha;
    CGFloat endingAlpha;
    if (show) {
        [self.activityView startAnimating];
        startingAlpha = 1.0;
        endingAlpha = 0.0;
    } else {
        [self.activityView stopAnimating];
        startingAlpha = 0.0;
        endingAlpha = 1.0;
    }

    CGFloat duration = animated ? PostCardRestoreViewAnimationDuration : 0.0;
    self.button.hidden = NO;
    self.titleLabel.hidden = NO;
    self.button.alpha = startingAlpha;
    self.titleLabel.alpha = startingAlpha;
    [UIView animateWithDuration:duration
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.button.alpha = endingAlpha;
                         self.titleLabel.alpha = endingAlpha;
                     } completion:^(BOOL finished) {
                         self.button.hidden = show;
                         self.titleLabel.hidden = show;
                     }];
}


#pragma mark - Actions

- (IBAction)didTapButton:(id)sender
{
    if (self.callback) {
        self.callback();
    }
}

@end
