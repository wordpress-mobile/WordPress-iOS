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
 *  @brief      This class allows the implementer to display a simple, animated popover.
 *  @details    This class was added to simplify the creation & display of tooltips using
 *              designer-approved defaults.
 *  @todo       Currently, the tooltip only animates from the bottom of a frame. More display
 *              options should be added (as needed).
 */
@interface WPTooltip : NSObject

/**
 *  @brief      Shows the tooltip.
 *  @param      view        The view which contains the tooltip.
 *  @param      frame       The frame to animate out of.
 *  @param      text        The text to display.
 *  @param      direction   The direction of the popover.
 */
+ (void)displayToolTipInView:(UIView *)view fromFrame:(CGRect)frame withText:(NSString *)text direction:(WPTooltipDirection)direction;

@end
