#import "WPWhatsNewView.h"
#import <QuartzCore/QuartzCore.h>
#import "WPGUIConstants.h"

static const CGFloat WPWhatsNewCornerRadiusDefault = 7.0f;

@interface WPWhatsNewView ()
#pragma mark - Properties: Outlets

/**
 *  @brief      The details to show below the title.
 */
@property (nonatomic, copy, readwrite) IBOutlet UITextView* details;

/**
 *  @brief      The image to show on top of the view.
 */
@property (nonatomic, copy, readwrite) IBOutlet UIImageView* imageView;

/**
 *  @title      The title for the new features.
 */
@property (nonatomic, copy, readwrite) IBOutlet UITextView* title;
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
{
    [UIView animateWithDuration:WPAnimationDurationFast
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.transform = CGAffineTransformMakeScale(0.01, 0.01);
                         self.alpha = WPAlphaZero;
                     } completion:nil];
}

- (void)showAnimated:(BOOL)animated
{
    self.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.1, 1.1);
    self.alpha = WPAlphaZero;
    
    [UIView animateWithDuration:WPAnimationDurationFaster
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^void()
    {
        self.transform = CGAffineTransformIdentity;
        self.alpha = WPAlphaFull;
    } completion:nil];
}

@end
