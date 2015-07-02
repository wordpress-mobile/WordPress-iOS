#import "WPAuthTokenIssueSolver.h"
#import "AccountService.h"
#import "BlogService.h"
#import "ContextManager.h"
#import "LoginViewController.h"
#import "UIAlertView+Blocks.h"
#import "WordPressAppDelegate.h"
#import "WPAccount.h"

@implementation WPAuthTokenIssueSolver

#pragma mark - Fixing the authToken issue.

- (void)fixAuthTokenIssueAndDo:(WPAuthTokenissueSolverCompletionBlock)onComplete
{
    NSParameterAssert(onComplete);
    
    if ([self hasAuthTokenIssues]) {
        LoginViewController *loginViewController = [[LoginViewController alloc] init];
        
        loginViewController.onlyDotComAllowed = YES;
        loginViewController.shouldReauthenticateDefaultAccount = YES;
        loginViewController.cancellable = ![self noSelfHostedBlogs];
        loginViewController.dismissBlock = ^(BOOL cancelled) {
            if (cancelled) {
                [self showCancelReAuthenticationAlertAndOnOK:^{
                    NSManagedObjectContext *mainContext = [[ContextManager sharedInstance] mainContext];
                    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:mainContext];
                    
                    [accountService removeDefaultWordPressComAccount];
                    onComplete();
                }];
            } else {
                onComplete();
            }
        };
        
        WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[UIApplication sharedApplication].delegate;
        appDelegate.window.rootViewController = loginViewController;
        
        [self showExplanationAlertForReAuthenticationDueToMissingAuthToken];
    } else {
        onComplete();
    }
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
 *  @brief      Shows the alert when the re-authentication is cancelled by the user.
 *
 *  @param      okBlock     The block that will be executed if the user confirms the operation.
 */
- (void)showCancelReAuthenticationAlertAndOnOK:(WPAuthTokenissueSolverCompletionBlock)okBlock
{
    NSParameterAssert(okBlock);
    
    NSString *alertTitle = NSLocalizedString(@"Careful!",
                                             @"Title for the warning shown to the user when he refuses to re-login when the authToken is missing.");
    NSString *alertMessage = NSLocalizedString(@"If you proceed, all your WP.com account data will be removed from this device.  This means any unsaved data such as locally stored posts will be deleted.  This will not affect data that has already been uploaded to your WP.com account.",
                                               @"Message for the warning shown to the user when he refuses to re-login when the authToken is missing.");
    NSString *cancelButtonTitle = NSLocalizedString(@"Cancel",
                                                    @"Cancel button title for the warning shown to the user when he refuses to re-login when the authToken is missing.");
    NSString *deleteButtonTitle = NSLocalizedString(@"Delete",
                                                    @"Delete button title for the warning shown to the user when he refuses to re-login when the authToken is missing.");
    
    [UIAlertView showWithTitle:alertTitle
                       message:alertMessage
             cancelButtonTitle:cancelButtonTitle
             otherButtonTitles:@[deleteButtonTitle]
                      tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                          if (buttonIndex == alertView.firstOtherButtonIndex) {
                              okBlock();
                          }
                      }];
}

/**
 *  @brief      Shows the alert explaining the authToken issue to the user.
 */
- (void)showExplanationAlertForReAuthenticationDueToMissingAuthToken
{
    NSString *alertTitle = NSLocalizedString(@"Oops!",
                                             @"Title for the warning shown to the user when the app realizes there should be an auth token but there isn't one.");
    NSString *alertMessage = NSLocalizedString(@"We have detected a synchronization problem with your locally stored WP.com credentials. You're going to be prompted to re-authenticate.",
                                               @"Message for the warning shown to the user when the app realizes there should be an auth token but there isn't one.");
    NSString *okButtonTitle = NSLocalizedString(@"OK",
                                                @"OK button title for the warning shown to the user when the app realizes there should be an auth token but there isn't one.");
    
    [UIAlertView showWithTitle:alertTitle
                       message:alertMessage
             cancelButtonTitle:nil
             otherButtonTitles:@[okButtonTitle]
                      tapBlock:nil];
}

@end
