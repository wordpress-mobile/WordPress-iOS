#import "WPError.h"
#import "WordPressAppDelegate.h"
#import "WPAccount.h"
#import "SupportViewController.h"
#import <WordPressShared/NSString+XMLExtensions.h>
#import <WordPressUI/WordPressUI.h>
#import <wpxmlrpc/WPXMLRPC.h>
#import "WordPress-Swift.h"



NSInteger const SupportButtonIndex = 0;
NSString * const WordPressAppErrorDomain = @"org.wordpress.iphone";
NSString * const WPErrorSupportSourceKey = @"helpshift-support-source";

@interface WPError ()

@property (nonatomic, assign) BOOL alertShowing;

@end

@implementation WPError

+ (instancetype)internalInstance
{
    static WPError *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[WPError alloc] init];
    });
    return instance;
}

+ (void)showNetworkingAlertWithError:(NSError *)error
{
    [self showNetworkingAlertWithError:error title:nil];
}

+ (void)showNetworkingAlertWithError:(NSError *)error title:(NSString *)title
{
    NSString *message = nil;
    NSString *customTitle = nil;

    if ([error.domain isEqual:AFURLRequestSerializationErrorDomain] ||
        [error.domain isEqual:AFURLResponseSerializationErrorDomain])
    {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)[error.userInfo objectForKey:AFNetworkingOperationFailingURLResponseErrorKey];
        switch (error.code) {
            case NSURLErrorBadServerResponse:
                if (response) {
                    switch (response.statusCode) {
                        case 400:
                        case 405:
                        case 406:
                        case 411:
                        case 412:
                        case 413:
                        case 414:
                        case 415:
                        case 416:
                        case 417:
                            customTitle = NSLocalizedString(@"Incompatible site", @"Error message shown in the set up process if the WP install was unable to be added to the app due to an error being returned from the site.");
                            message = [NSString stringWithFormat:NSLocalizedString(@"Your site returned a %d error.\nThis is usually due to an incompatible server configuration.\nPlease contact your hosting provider, or reach out to us using our in-app support.", @"Error message shown in the set up process if the WP install was unable to be added to the app due to an error being returned from the site."), response.statusCode];
                            break;
                        case 403:
                            customTitle = NSLocalizedString(@"Forbidden Access", @"Error message shown in the set up process if the WP install was unable to be added to the app due to an error accessing the site.");
                            message = NSLocalizedString(@"Received 'Forbidden Access'.\nIt seems there is a problem with your WordPress site", @"Error message shown in the set up process if the WP install was unable to be added to the app due to an error accessing the site.");
                            break;
                        case 500:
                        case 501:
                            customTitle = NSLocalizedString(@"Internal Server Error", @"Error message shown in the set up process if the WP install was unable to be added to the app due to an error accessing the site, most likely due to an error with the server hosting the WP install.");
                            message = NSLocalizedString(@"Received 'Internal Server Error'.\nIt seems there is a problem with your WordPress site", @"Error message shown in the set up process if the WP install was unable to be added to the app due to an error accessing the site, most likely due to an error with the server hosting the WP install.");
                            break;
                        case 502:
                        case 503:
                        case 504:
                            customTitle = NSLocalizedString(@"Temporary Server Error", @"Error message shown in the set up process if the WP install was unable to be added to the app due to an error accessing the site, most likely due to an error with the server hosting the WP install, but may be a temporary issue.");
                            message = NSLocalizedString(@"It seems your WordPress site is not accessible at this time, please try again later", @"Error message shown in the set up process if the WP install was unable to be added to the app due to an error accessing the site, most likely due to an error with the server hosting the WP install, but may be a temporary issue.");
                            break;
                        default:
                            break;
                    }
                }
                break;

            default:
                break;
        }
    } else if ([error.domain isEqualToString:WordPressComRestApiErrorDomain]) {
        DDLogError(@"wp.com API error: %@: %@", error.userInfo[WordPressComRestApi.ErrorKeyErrorCode],
                   [error localizedDescription]);
        if (error.code == WordPressComRestApiErrorInvalidToken || error.code == WordPressComRestApiErrorAuthorizationRequired) {
            [WordPressAuthenticationManager showSigninForWPComFixingAuthToken];
            return;
        }
    }

    if (message == nil) {
        message = [error localizedDescription];
        message = [NSString decodeXMLCharactersIn:message];
    }

    if (title == nil) {
        if (customTitle == nil) {
            title = NSLocalizedString(@"Error", @"Generic error alert title");
        } else {
            title = customTitle;
        }
    }
    
    NSString *sourceTag = [error.userInfo stringForKey:WPErrorSupportSourceKey];

    [self showAlertWithTitle:title message:message withSupportButton:YES fromSource:sourceTag okPressedBlock:nil];
}

+ (void)showXMLRPCErrorAlert:(NSError *)error
{
    NSString *cleanedErrorMsg = [error localizedDescription];

    if ([error.domain isEqualToString:WPXMLRPCFaultErrorDomain] && error.code == 401) {
        cleanedErrorMsg = NSLocalizedString(@"Sorry, you cannot access this feature. Please check your User Role on this site.", @"");
    }

    // ignore HTTP auth canceled errors
    if ([error.domain isEqual:NSURLErrorDomain] && error.code == NSURLErrorUserCancelledAuthentication) {
        [WPError internalInstance].alertShowing = NO;
        return;
    }

    if ([cleanedErrorMsg rangeOfString:@"NSXMLParserErrorDomain"].location != NSNotFound) {
        cleanedErrorMsg = NSLocalizedString(@"The app can't recognize the server response. Please, check the configuration of your site.", @"");
    }

    [self showAlertWithTitle:NSLocalizedString(@"Error", @"Generic popup title for any type of error.") message:cleanedErrorMsg];
}

+ (void)showAlertWithTitle:(NSString *)title message:(NSString *)message
{
    [self showAlertWithTitle:title message:message withSupportButton:YES okPressedBlock:nil];
}

+ (void)showAlertWithTitle:(NSString *)title message:(NSString *)message withSupportButton:(BOOL)showSupport
{
    [self showAlertWithTitle:title message:message withSupportButton:showSupport okPressedBlock:nil];
}

+ (void)showAlertWithTitle:(NSString *)title message:(NSString *)message withSupportButton:(BOOL)showSupport okPressedBlock:(void (^)(UIAlertController *))okBlock
{
    [self showAlertWithTitle:title message:message withSupportButton:showSupport fromSource:nil okPressedBlock:okBlock];
}

+ (void)showAlertWithTitle:(NSString *)title message:(NSString *)message withSupportButton:(BOOL)showSupport fromSource:(NSString *)sourceTag okPressedBlock:(void (^)(UIAlertController *))okBlock
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([WPError internalInstance].alertShowing) {
            return;
        }
        [WPError internalInstance].alertShowing = YES;

        DDLogInfo(@"Showing alert with title: %@ and message %@", title, message);
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                                 message:[message stringByStrippingHTML]
                                                                          preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                         style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                                                             if (okBlock) {
                                                                 okBlock(alertController);
                                                             }
                                                             [WPError internalInstance].alertShowing = NO;
                                                         }];
        [alertController addAction:action];
        if (showSupport) {
            NSString *supportText = NSLocalizedString(@"Need Help?", @"'Need help?' button label, links off to the WP for iOS FAQ.");
            UIAlertAction *action = [UIAlertAction actionWithTitle:supportText
                                                             style:UIAlertActionStyleCancel
                                                           handler:^(UIAlertAction * _Nonnull action) {
                                                               
                                                               if ([Feature enabled:FeatureFlagZendeskMobile]) {
                                                                   SupportTableViewController *supportVC = [SupportTableViewController new];
                                                                   [supportVC updateSourceTagWith:sourceTag];
                                                                   [supportVC showFromTabBar];
                                                               }
                                                               else {
                                                                   SupportViewController *supportVC = [SupportViewController new];
                                                                   supportVC.sourceTag = sourceTag;
                                                                   [supportVC showFromTabBar];
                                                               }
                                                               
                                                               [WPError internalInstance].alertShowing = NO;
                                                           }];
            [alertController addAction:action];
        }
        [alertController presentFromRootViewController];
    });
}

@end
