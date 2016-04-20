#import <Foundation/Foundation.h>


typedef void (^UIAlertControllerCompletionBlock) (UIAlertController *alertController, NSInteger buttonIndex);


/**
 *  This class acts as proxy for UIAlertController to make testing easier
 */
@interface UIAlertControllerProxy : NSObject

- (UIAlertController *)showWithTitle:(NSString *)title
                             message:(NSString *)message
                   cancelButtonTitle:(NSString *)cancelButtonTitle
                   otherButtonTitles:(NSArray *)otherButtonTitles
                            tapBlock:(UIAlertControllerCompletionBlock)tapBlock;

@end
