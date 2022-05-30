#import "WPAuthTokenIssueSolver.h"
#import "AccountService.h"
#import "BlogService.h"
#import "ContextManager.h"
#import "WPAccount.h"
#import "WordPress-Swift.h"

@implementation WPAuthTokenIssueSolver

#pragma mark - Fixing the authToken issue.

- (BOOL)fixAuthTokenIssueAndDo:(WPAuthTokenissueSolverCompletionBlock)onComplete
{
    NSParameterAssert(onComplete);

    BOOL isFixingAuthTokenIssue = NO;

    if ([self hasAuthTokenIssues]) {
        UIViewController *controller = [WordPressAuthenticationManager signinForWPComFixingAuthToken:^(BOOL cancelled) {
            if (cancelled) {
                // We present asynchronously to prevent an issue where the Login VC would dismiss the
                // alert instead of itself.
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self showCancelReAuthenticationAlertAndOnOK:^{
                        NSManagedObjectContext *mainContext = [[ContextManager sharedInstance] mainContext];
                        AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:mainContext];

                        [accountService removeDefaultWordPressComAccount];
                        onComplete();
                    }];
                });
            } else {
                onComplete();
            }
        }];

        [UIApplication sharedApplication].mainWindow.rootViewController = controller;

        [self showExplanationAlertForReAuthenticationDueToMissingAuthToken];
        isFixingAuthTokenIssue = YES;
    } else {
        onComplete();
    }

    return isFixingAuthTokenIssue;
}

#pragma mark - Misc

/**
 *  @brief      Call this method to know if there are hosted blogs.
 *
 *  @returns    YES if there are hosted blogs, NO otherwise.
 */
- (BOOL)noSelfHostedBlogs
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];

    NSInteger blogCount = [blogService blogCountSelfHosted];
    return blogCount == 0;
}

/**
 *  @brief      Call this method to know if the local installation of WPiOS has the authToken issue
 *              this class was designed to solve.
 *
 *  @returns    YES if the local WPiOS installation needs to be fixed by this class.
 */
- (BOOL)hasAuthTokenIssues
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *account = [accountService defaultWordPressComAccount];

    BOOL hasAuthTokenIssues = account && ![account authToken];

    return hasAuthTokenIssues;
}

#pragma mark - Alerts

/**
 *  @brief      Shows the alert when the re-authentication is canceled by the user.
 *
 *  @param      okBlock     The block that will be executed if the user confirms the operation.
 */
- (void)showCancelReAuthenticationAlertAndOnOK:(WPAuthTokenissueSolverCompletionBlock)okBlock
{
    NSParameterAssert(okBlock);

    NSString *alertTitle = NSLocalizedString(@"Careful!",
                                             @"Title for the warning shown to the user when he refuses to re-login when the authToken is missing.");
    NSString *alertMessage = NSLocalizedString(@"Proceeding will remove all WordPress.com data from this device, and delete any locally saved drafts. You will not lose anything already saved to your WordPress.com blog(s).",
                                               @"Message for the warning shown to the user when he refuses to re-login when the authToken is missing.");
    NSString *cancelButtonTitle = NSLocalizedString(@"Cancel",
                                                    @"Cancel button title for the warning shown to the user when he refuses to re-login when the authToken is missing.");
    NSString *deleteButtonTitle = NSLocalizedString(@"Delete",
                                                    @"Delete button title for the warning shown to the user when he refuses to re-login when the authToken is missing.");

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:alertTitle
                                                                             message:alertMessage
                                                                      preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelButtonTitle
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction *action){}];

    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:deleteButtonTitle
                                                           style:UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction *action){
                                                             okBlock();
                                                         }];
    [alertController addAction:cancelAction];
    [alertController addAction:deleteAction];
    [[[UIApplication sharedApplication] mainWindow].rootViewController presentViewController:alertController
                                                                                   animated:YES
                                                                                 completion:nil];
}

/**
 *  @brief      Shows the alert explaining the authToken issue to the user.
 */
- (void)showExplanationAlertForReAuthenticationDueToMissingAuthToken
{
    UIWindow *alertWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    alertWindow.rootViewController = [UIViewController new];
    [alertWindow makeKeyAndVisible];

    NSString *alertTitle = NSLocalizedString(@"Oops!",
                                             @"Title for the warning shown to the user when the app realizes there should be an auth token but there isn't one.");
    NSString *alertMessage = NSLocalizedString(@"There was a problem connecting to WordPress.com. Please log in again.",
                                               @"Message for the warning shown to the user when the app realizes there should be an auth token but there isn't one.");
    NSString *okButtonTitle = NSLocalizedString(@"OK",
                                                @"OK button title for the warning shown to the user when the app realizes there should be an auth token but there isn't one.");

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:alertTitle
                                                                             message:alertMessage
                                                                      preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *okAction = [UIAlertAction actionWithTitle:okButtonTitle
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action){}];
    [alertController addAction:okAction];
    alertController.modalPresentationStyle = UIModalPresentationPopover;

    [alertWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
}

@end
