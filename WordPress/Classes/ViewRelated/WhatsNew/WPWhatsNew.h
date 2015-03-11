#import <Foundation/Foundation.h>

#import "WPWhatsNewView.h"

/**
 *  @class      WPWhatsNew
 *  @brief      This class is a module that can be used to contain the logic to show the What's New
 *              popup.
 *  @details    This class was added to remove the What's New code from the app delegate by
 *              modularizing the componet.
 *  @todo       Analyze the possibility of making this a UIViewController subclass.  Right now it's
 *              difficult to tell if that's needed as this class has no use after showing the
 *              What's New dialog.
 */
@interface WPWhatsNew : NSObject

/**
 *  @brief      Shows the What's New popup.
 *  @details    If this version of the application does not have the required title and details
 *              glotpress strings, then nothing will be shown.
 *
 *  @param      dismissBlock    This block will be executed when the WPWhatsNewView is dismissed.
 *                              Can be nil.
 */
- (void)showWithDismissBlock:(WPWhatsNewDismissBlock)dismissBlock;

@end
