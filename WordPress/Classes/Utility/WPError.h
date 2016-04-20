@interface WPError : NSObject


///--------------------------------
/// @name Networking related errors
///--------------------------------

/**
 Show an alert that resulted from a network call
 
 @param error
 */
+ (void)showNetworkingAlertWithError:(NSError *)error;

/**
 Show an alert that resulted from a network call, with a defined title
 
 @param error
 @param title Custom title displayed on the alert
 */
+ (void)showNetworkingAlertWithError:(NSError *)error title:(NSString *)title;

/**
 Show an alert that resulted from a network call,
 that is specifically related to an XML-RPC call
 
 @param error
 */
+ (void)showXMLRPCErrorAlert:(NSError *)error;


///---------------------
/// @name General alerts
///---------------------

/**
 Show a general alert with a custom title and message.
 
 @discussion The buttons provided are localized: "OK" and "Need help?"
             "Need help?" opens the SupportViewController
             "OK" simply dismisses the alert.
 
 @param title for the alert
 @param message for the alert
 */
+ (void)showAlertWithTitle:(NSString *)title message:(NSString *)message;

/**
 Show a general alert with a custom title and message.
 
 @discussion The buttons provided are localized: "OK" and optionally "Need help?"
             "Need help?" opens the SupportViewController
             "OK" simply dismisses the alert.
 
 @param title for the alert
 @param message for the alert
 @param showSupport YES shows the Need Help button and NO does not.
 */
+ (void)showAlertWithTitle:(NSString *)title message:(NSString *)message withSupportButton:(BOOL)showSupport;

/**
 Show a general alert with a custom title and message.
 Supply a block to execute custom logic when the OK button is pressed
 
 @discussion The buttons provided are localized: "OK" and optionally "Need help?"
             "Need help?" opens the SupportViewController
             "OK" simply dismisses the alert.
 
 @param title for the alert
 @param message for the alert
 @param showSupport YES shows the Need Help button and NO does not.
 @param okPressedBlock a block to execute if the OK button is pressed
 */
+ (void)showAlertWithTitle:(NSString *)title message:(NSString *)message
         withSupportButton:(BOOL)showSupport okPressedBlock:(void (^)(UIAlertController *alertView))okBlock;


@end
