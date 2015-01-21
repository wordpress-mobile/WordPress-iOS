#import "WPWhatsNewView.h"
#import <QuartzCore/QuartzCore.h>
#import "WPGUIConstants.h"

static const CGFloat WPWhatsNewCornerRadiusDefault = 7.0f;
static const CGFloat WPWhatsNewShowAnimationMagnificationScale = 1.1;

@interface WPWhatsNewView ()
#pragma mark - Properties: Outlets

/**
 *  @brief      The details to show below the title.
 */
@property (nonatomic, weak, readwrite) IBOutlet UITextView* details;

/**
 *  @brief      The image to show on top of the view.
 */
@property (nonatomic, weak, readwrite) IBOutlet UIImageView* imageView;

/**
 *  @title      The title for the new features.
 */
@property (nonatomic, weak, readwrite) IBOutlet UITextView* title;
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
    __weak __typeof(self) weakSelf = self;
    
    [self hideAnimated:YES
            completion:^(BOOL finished)
    {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        
        [strongSelf removeFromSuperview];
        
        if (strongSelf.dismissBlock) {
            strongSelf.dismissBlock();
        }
    }];
}

@end
