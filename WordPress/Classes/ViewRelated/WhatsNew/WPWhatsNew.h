#import <Foundation/Foundation.h>

/**
 *  @class      WPWhatsNew
 *  @brief      This class is a module that can be used to contain the logic to show the What's New
 *              popup.
 *  @details    This class was added to remove the What's New code from the app delegate by
 *              modularizing the componet.
 */
@interface WPWhatsNew : NSObject

/**
 *  @brief      Shows the What's New popup.
 *  @details    If this version of the application does not have the required title and details
 *              glotpress strings, then nothing will be shown.
 */
- (void)show;

@end
