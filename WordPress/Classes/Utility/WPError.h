NS_ASSUME_NONNULL_BEGIN

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
+ (void)showNetworkingAlertWithError:(NSError *)error title:(nullable NSString *)title;

/**
 Show an alert that resulted from a network call,
 that is specifically related to an XML-RPC call
 
 @param error
 */
+ (void)showXMLRPCErrorAlert:(nullable NSError *)error;

/**
 * Create a suggested title and message based on the given `error`
 *
 * @param error Assumed to be an error from a networking call
 * @param desiredTitle If given, this will be the title that will be returned.
 *
 * @return A dictionary with keys "title" and "message". Both values are not null.
 */
+ (nonnull NSDictionary<NSString *, NSString *> *)titleAndMessageFromNetworkingError:(NSError *)error
                                                                        desiredTitle:(nullable NSString *)desiredTitle;

/**
 * Shows a sign-in page if the `error`'s cause requires an authentication or authorization.
 *
 * This is meant to be a helper method for the other methods in this class and is only publicly
 * exposed so it can be accessed in WPError.swift.
 *
 * @param error Assumed to be an error from a networking call.
 * @returns YES if a sign-in page was shown.
 */
+ (BOOL)showWPComSigninIfErrorIsInvalidAuth:(NSError *)error;

///---------------------
/// @name General alerts
///---------------------

/**
 Show a general alert with a custom title and message.
 
 @discussion The buttons provided are localized: "OK" and "Need help?"
             "Need help?" opens Support
             "OK" simply dismisses the alert.
 
 @param title for the alert
 @param message for the alert
 */
+ (void)showAlertWithTitle:(NSString *)title message:(NSString *)message;

/**
 Show a general alert with a custom title and message.
 
 @discussion The buttons provided are localized: "OK" and optionally "Need help?"
             "Need help?" opens Support
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
             "Need help?" opens Support
             "OK" simply dismisses the alert.
 
 @param title for the alert
 @param message for the alert
 @param showSupport YES shows the Need Help button and NO does not.
 @param okPressedBlock a block to execute if the OK button is pressed
 */
+ (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
         withSupportButton:(BOOL)showSupport
            okPressedBlock:(nullable void (^)(UIAlertController *alertView))okBlock;


@end

NS_ASSUME_NONNULL_END
