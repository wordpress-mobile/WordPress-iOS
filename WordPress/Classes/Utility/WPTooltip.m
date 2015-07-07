#import "WPTooltip.h"
#import <AMPopTip/AMPopTip.h>

@implementation WPTooltip

+ (void)displayToolTipInView:(UIView *)view fromFrame:(CGRect)frame withText:(NSString *)text direction:(WPTooltipDirection)direction;
{
    NSParameterAssert([view isKindOfClass:[UIView class]]);
    NSParameterAssert([text isKindOfClass:[NSString class]]);
    NSParameterAssert([text length] > 0);
    
    AMPopTipDirection amDirection;
    switch (direction) {
        case WPTooltipDirectionDown:
            amDirection = AMPopTipDirectionDown;
            break;
        case WPTooltipDirectionUp:
            amDirection = AMPopTipDirectionUp;
            break;
        case WPTooltipDirectionRight:
            amDirection = AMPopTipDirectionRight;
            break;
        case WPTooltipDirectionLeft:
            amDirection = AMPopTipDirectionLeft;
            break;
        default:
            amDirection = AMPopTipDirectionNone;
            break;
    }
    
    AMPopTip *popTip = [AMPopTip popTip];
    [[AMPopTip appearance] setFont:[WPStyleGuide regularTextFont]];
    [[AMPopTip appearance] setTextColor:[UIColor whiteColor]];
    [[AMPopTip appearance] setPopoverColor:[WPStyleGuide littleEddieGrey]];
    [[AMPopTip appearance] setArrowSize:CGSizeMake(12.0, 8.0)];
    [[AMPopTip appearance] setEdgeMargin:5.0];
    [[AMPopTip appearance] setDelayIn:0.5];
    UIEdgeInsets insets = {6,5,6,5};
    [[AMPopTip appearance] setEdgeInsets:insets];
    popTip.shouldDismissOnTap = YES;
    popTip.shouldDismissOnTapOutside = YES;
    [popTip showText:text
           direction:amDirection
            maxWidth:200
              inView:view
           fromFrame:frame
            duration:3];
}

@end
