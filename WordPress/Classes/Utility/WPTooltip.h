#import <Foundation/Foundation.h>


typedef NS_ENUM(NSInteger, WPTooltipDirection) {
    WPTooltipDirectionUp,
    WPTooltipDirectionDown,
    WPTooltipDirectionLeft,
    WPTooltipDirectionRight,
    WPTooltipDirectionNone
};

/**
 *  @class      WPTooltip
 *
 *  @brief      This class allows the implementer to display a simple, animated popover.
 *
 *  @details    This class was added to simplify the creation & display of tooltips using
 *              designer-approved defaults.
 */
@interface WPTooltip : NSObject

/**
 *  @brief      Shows the tooltip.
 *
 *  @param      view        The view which contains the tooltip.
 *  @param      frame       The frame to animate out of.
 *  @param      text        The text to display.
 *  @param      direction   The direction of the popover.
 *
 *  @return     WPTooltip   New instance of WPTooltip.
 */
+ (instancetype)displayTooltipInView:(UIView *)view fromFrame:(CGRect)frame withText:(NSString *)text direction:(WPTooltipDirection)direction;


/**
 *  @brief      Cancel the currently displayed tooltip
 *
 *  @detail     When called, this method will cancel the currently displayed tooltip
 *              associated with this WPTooltip instance.
 */
- (void)cancelCurrentTooltip;

@end
