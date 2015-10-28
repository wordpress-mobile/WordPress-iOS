#import "UIAlertControllerProxy.h"
#import "WordPress-Swift.h"

@implementation UIAlertControllerProxy

- (UIAlertController *)showWithTitle:(NSString *)title
                             message:(NSString *)message
                   cancelButtonTitle:(NSString *)cancelButtonTitle
                   otherButtonTitles:(NSArray *)otherButtonTitles
                            tapBlock:(UIAlertControllerCompletionBlock)tapBlock
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];

    void (^handler)(UIAlertAction *) = ^(UIAlertAction *action) {
        if (!tapBlock) {
            return;
        }
        
        NSInteger buttonIndex = [alertController.actions indexOfObject:action];
        tapBlock(alertController, buttonIndex);
    };
    
    [alertController addCancelActionWithTitle:cancelButtonTitle handler:handler];
    
    for (NSString *buttonTitle in otherButtonTitles) {
        [alertController addDefaultActionWithTitle:buttonTitle handler:handler];
    }
    
    // Note: This viewController might not be visible anymore
    [alertController presentFromRootViewController];
    
    return alertController;
}

@end
