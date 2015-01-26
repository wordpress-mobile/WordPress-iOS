#import <UIKit/UIKit.h>

typedef void(^WPBackgroundDimmerCompletionBlock)(BOOL finished);

/**
 *  @class      Generic class to take care of dimming the background when you want to show 
 *              view that does not cover the entire screen.
 *  @details    After creating an instance of this class you can safely add it to a parent view.
 *              It will not be visible until you call showAnimated:.  It can be hidden by calling
 *              hideAnimated:.
 */
@interface WPBackgroundDimmerView : UIView

#pragma mark - Visual Customization

/**
 *  @brief      The alpha value used for creating the background dim effect.  Defaults to 0.4f.
 */
@property (nonatomic, assign, readwrite) CGFloat alphaWhenVisible;

#pragma mark - Showing and hiding

- (void)hideAnimated:(BOOL)animated
          completion:(WPBackgroundDimmerCompletionBlock)completion;

/**
 *  @brief      Shows the view.
 *  @details    The view must have been added to a superview before calling this, otherwise it won't
 *              really show anywhere.
 *
 *  @param      animated        YES means the transition should be animated.
 *                              NO means instantaneous.
 *  @param      completion      A block to execute when the transition completes.
 */
- (void)showAnimated:(BOOL)animated
          completion:(WPBackgroundDimmerCompletionBlock)completion;

@end
