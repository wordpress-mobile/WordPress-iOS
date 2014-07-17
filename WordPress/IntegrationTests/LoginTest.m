#import <Subliminal/Subliminal.h>
#import "IntegrationTestsInfo.h"
#import "ContextManager.h"
#import "AccountService.h"
#import "WordPressAppDelegate.h"

@interface LoginTest : SLTest
@end

@implementation LoginTest {
    SLTextField *_usernameField;
    SLTextField *_passwordField;
    SLButton *_signInButton;
    
    AccountService *_accountService;
}

- (void)setUpTest {
    _usernameField = [SLTextField elementWithAccessibilityIdentifier:@"Username"];
    _passwordField = [SLTextField elementWithAccessibilityIdentifier:@"Password"];
    _signInButton = [SLButton elementWithAccessibilityIdentifier:@"Sign In"];

    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    _accountService = [[AccountService alloc] initWithManagedObjectContext:context];
}

- (void)tearDownTestCaseWithSelector:(SEL)testCaseSelector {
    if ([_accountService defaultWordPressComAccount]) {
        [[SLElement elementWithAccessibilityLabel:@"Me"] tap];
        [[SLElement elementWithAccessibilityLabel:@"Settings"] tap];
        [[SLElement elementWithAccessibilityIdentifier:@"wpcom-sign-out"] tap];
        [[SLElement elementWithAccessibilityLabel:@"Sign Out"] tap];
        
        [self wait:2.0];
    }
}

- (void)testLoginSucceedsWithUsernameAndPassword {
    [_usernameField setText:[IntegrationTestsInfo WPComUsername]];
    [_passwordField setText:[IntegrationTestsInfo WPComPassword]];
    [_signInButton tap];
    
    SLAssertTrueWithTimeout([[SLElement elementWithAccessibilityIdentifier:@"tabBar"] isValid],
                            5.0,
                            @"Sign in was not successful.");

    // wait for reader to finish up some stuff in the background before teardown
    [self wait:10.0];
}

- (void)testLoginFailsWithBadUsernameAndPassword {
    [_usernameField setText:@"baduser"];
    [_passwordField setText:@"badpass"];
    [_signInButton tap];
    
    SLElement *errorMessage = [SLElement elementWithAccessibilityLabel:@"Sorry, we can't log you in."];

    SLAssertTrueWithTimeout([errorMessage isValid],
                            5.0,
                            @"Sign in worked with an invalid user/pass.");
    
    [[SLElement elementWithAccessibilityLabel:@"OK"] tap];
}

- (void)tearDownTest {
}

@end
