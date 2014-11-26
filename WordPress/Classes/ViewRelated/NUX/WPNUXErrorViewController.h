#import <UIKit/UIKit.h>

@class WPWalkthroughOverlayView;

/**
 Presents a login error to the user and offers next steps
 
 This controller will display errors encountered in the login proccess and it
 will try to calculate the best way to help the user fix that error.
 
 This might be just the generic Support view, specific FAQ URLs, or even live chat if enabled.
 */
@interface WPNUXErrorViewController : UIViewController

- (instancetype)initWithRemoteError:(NSError *)error NS_DESIGNATED_INITIALIZER;

/**
 This block will be called when the user presses a button that should dismiss the controller.
 
 The helpController parameter is a new view controller that contains useful next steps to fix the error, and that the caller should present next.
 */
@property (nonatomic, copy) void (^dismissCompletionBlock)(UIViewController *helpController);

/**
 This block will be called when the user presses the 'Contact Us' button.

 The caller should then dismiss this controller and present live chat help.
 */
@property (nonatomic, copy) void (^contactCompletionBlock)();

/**
 Whether live chat is enabled or not
 */
@property (nonatomic, assign) BOOL liveChatEnabled;

@end
