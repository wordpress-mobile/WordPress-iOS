#import "WPWhatsNewView.h"

// System & libraries
#import <QuartzCore/QuartzCore.h>
#import <WordPress-iOS-Shared/WPFontManager.h>

// Internal
#import "WPGUIConstants.h"

static const CGFloat WPWhatsNewCornerRadiusDefault = 7.0f;
static const CGFloat WPWhatsNewShowAnimationMagnificationScale = 1.1;

@interface WPWhatsNewView () <UITextViewDelegate>
#pragma mark - Properties: Outlets
@property (nonatomic, weak, readwrite) IBOutlet UITextView* details;
@property (nonatomic, weak, readwrite) IBOutlet NSLayoutConstraint *detailsHeightConstraint;
@property (nonatomic, weak, readwrite) IBOutlet UIImageView* imageView;
@property (nonatomic, weak, readwrite) IBOutlet UITextView* title;
@property (nonatomic, weak, readwrite) IBOutlet UIButton* acceptButton;
@end

@implementation WPWhatsNewView

#pragma mark - Initializers

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{    
    self = [super initWithCoder:aDecoder];

    if (self) {
        self.layer.cornerRadius = WPWhatsNewCornerRadiusDefault;
        self.layer.masksToBounds = YES;
    }

    return self;
}

#pragma mark - NSObject

- (void)awakeFromNib
{
    NSAssert([_details isKindOfClass:[UITextView class]],
             @"Details outlet not wired.");
    NSAssert([_imageView isKindOfClass:[UIImageView class]],
             @"ImageView outlet not wired.");
    NSAssert([_title isKindOfClass:[UITextView class]],
             @"Title outlet not wired.");
    NSAssert([_acceptButton isKindOfClass:[UIButton class]],
             @"Button outlet not wired.");
    
    self.details.scrollEnabled = NO;
    [self setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    UIFont *titleFont = [WPFontManager openSansBoldFontOfSize:18.0f];
    UIFont *detailsFont = [WPFontManager openSansLightFontOfSize:15.0f];
    UIFont *buttonFont = [WPFontManager openSansLightFontOfSize:16.0f];
    
    self.title.font = titleFont;
    self.details.font = detailsFont;
    self.acceptButton.titleLabel.font = buttonFont;

    NSString *acceptButtonTitle = NSLocalizedString(@"Great, thanks!", @"Displayed as the 'close' button label on the What's New dialog. A short acknowledgement that the user is aware of the new features. Tapping dismisses the dialog.");
    [self.acceptButton setTitle:acceptButtonTitle forState:UIControlStateNormal];
}

#pragma mark - Showing & hiding

- (void)hideAnimated:(BOOL)animated
          completion:(WPWhatsNewAnimationCompleteBlock)completion
{
    [UIView animateWithDuration:WPAnimationDurationFast
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.alpha = WPAlphaZero;
                     } completion:completion];
}

- (void)showAnimated:(BOOL)animated
          completion:(WPWhatsNewAnimationCompleteBlock)completion
{
    self.transform = CGAffineTransformScale(CGAffineTransformIdentity,
                                            WPWhatsNewShowAnimationMagnificationScale,
                                            WPWhatsNewShowAnimationMagnificationScale);
    self.alpha = WPAlphaZero;
    
    [UIView animateWithDuration:WPAnimationDurationFaster
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^void()
    {
        self.transform = CGAffineTransformIdentity;
        self.alpha = WPAlphaFull;
    } completion:completion];
}

#pragma mark - IBActions

/**
 *  @brief      Action to dismiss the popup.
 *
 *  @param      sender      The outlet that called this action.
 */
- (IBAction)dismissPopup:(id)sender
{
    if (self.willDismissBlock) {
        self.willDismissBlock();
    }
    
    __weak __typeof(self) weakSelf = self;
    
    [self hideAnimated:YES
            completion:^(BOOL finished)
    {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        
        [strongSelf removeFromSuperview];
        
        if (strongSelf.didDismissBlock) {
            strongSelf.didDismissBlock();
        }
    }];
}

#pragma mark - Constraints

- (void)updateConstraints
{
    [super updateConstraints];
    
    [self updateDetailsHeightConstraint];
    [self updateSize];
}

- (void)updateDetailsHeightConstraint
{
    CGSize maxSize = CGSizeMake(self.details.frame.size.width, CGFLOAT_MAX);
    
    CGSize size = [self.details sizeThatFits:maxSize];

    self.detailsHeightConstraint.constant = size.height;
}

#pragma mark - Sizing

- (void)updateSize
{
    CGRect frame = self.frame;
    frame.size = [self systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    self.frame = frame;
}

@end
