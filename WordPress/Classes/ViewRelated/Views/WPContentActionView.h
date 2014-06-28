#import <UIKit/UIKit.h>
#import "WPContentViewProvider.h"

/**
 A UIControl accepting a `WPContentViewProvider` and displaying a short
 date and accompaning icon, and an optional group of "action" buttons.
 The displayed date is incremented (if necessary) on a timed interval.
 */
@interface WPContentActionView : UIView

/**
 The object specifying the content (text, images, etc.) to display.
 */
@property (nonatomic, weak) id<WPContentViewProvider>contentProvider;

/**
 Adds the specified button to the group of "action" buttons.
 
 @param actionButton A `UIButton` to display.
 */
- (void)addActionButton:(UIButton *)actionButton;

/**
 Removes all the buttons previously added.
 */
- (void)removeAllActionButtons;

@end
