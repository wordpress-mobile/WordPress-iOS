#import <Foundation/Foundation.h>

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
 *  @param      view    The view which contains the tooltip.
 *  @param      frame   The frame to animate out of.
 *  @param      text    The text to display.
 */
+ (void)displayToolTipInView:(UIView *)view fromFrame:(CGRect)frame withText:(NSString *)text;

@end
