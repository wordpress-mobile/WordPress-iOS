#import "WPHTTPAuthenticationAlertController.h"

@interface WPHTTPAuthenticationAlertController ()
@property (nonatomic, strong) NSURLAuthenticationChallenge *challenge;
@end

@implementation WPHTTPAuthenticationAlertController

+ (void)presentWithChallenge:(NSURLAuthenticationChallenge *)challenge {
    UIAlertController *controller;
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        controller = [self controllerForServerTrustChallenge:challenge];
    } else {
        controller = [self controllerForUserAuthenticationChallenge:challenge];
    }
    UIViewController *presentingController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    if (presentingController.presentedViewController) {
        presentingController = presentingController.presentedViewController;
    }

    [presentingController presentViewController:controller animated:YES completion:nil];
}

+ (UIAlertController *)controllerForServerTrustChallenge:(NSURLAuthenticationChallenge *)challenge {
    NSString *title = NSLocalizedString(@"Certificate error", @"Popup title for wrong SSL certificate.");
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"The certificate for this server is invalid. You might be connecting to a server that is pretending to be “%@” which could put your confidential information at risk.\n\nWould you like to trust the certificate anyway?", @""), challenge.protectionSpace.host];
    UIAlertController *controller =  [UIAlertController alertControllerWithTitle:title
                                                                         message:message
                                                                  preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel button label")
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             [challenge.sender cancelAuthenticationChallenge:challenge];
                                                         }];
    [controller addAction:cancelAction];

    UIAlertAction *trustAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Trust", @"Connect when the SSL certificate is invalid")
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * _Nonnull action) {
                                                            NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];

                                                            [[NSURLCredentialStorage sharedCredentialStorage] setDefaultCredential:credential forProtectionSpace:challenge.protectionSpace];
                                                            [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
                                                        }];
    [controller addAction:trustAction];
    return controller;
}

+ (UIAlertController *)controllerForUserAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    NSString *title = NSLocalizedString(@"Authentication required", @"Popup title to ask for user credentials.");
    NSString *message = NSLocalizedString(@"Please enter your credentials", @"Popup message to ask for user credentials (fields shown below).");
    UIAlertController *controller =  [UIAlertController alertControllerWithTitle:title
                                                                         message:message
                                                                  preferredStyle:UIAlertControllerStyleAlert];

    [controller addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = NSLocalizedString(@"Username", @"Login dialog username placeholder");
    }];

    [controller addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = NSLocalizedString(@"Password", @"Login dialog password placeholder");
        textField.secureTextEntry = YES;
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel button label")
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             [challenge.sender cancelAuthenticationChallenge:challenge];
                                                         }];
    [controller addAction:cancelAction];

    UIAlertAction *loginAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Log In", @"Log In button label.")
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * _Nonnull action) {
                                                            NSString *username = controller.textFields.firstObject.text;
                                                            NSString *password = controller.textFields.lastObject.text;
                                                            NSURLCredential *credential = [NSURLCredential credentialWithUser:username password:password persistence:NSURLCredentialPersistencePermanent];

                                                            [[NSURLCredentialStorage sharedCredentialStorage] setDefaultCredential:credential forProtectionSpace:challenge.protectionSpace];
                                                            [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
                                                        }];
    [controller addAction:loginAction];
    return controller;
}

@end
