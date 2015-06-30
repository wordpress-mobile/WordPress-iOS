#import <Foundation/Foundation.h>
#import "UIAlertView+Blocks.h"

/**
 *  This class acts as proxy for UIAlertView to make testing easier
 */
@interface UIAlertViewProxy : NSObject

- (UIAlertView *)showWithTitle:(NSString *)title
                      message:(NSString *)message
            cancelButtonTitle:(NSString *)cancelButtonTitle
            otherButtonTitles:(NSArray *)otherButtonTitles
                     tapBlock:(UIAlertViewCompletionBlock)tapBlock;

@end
