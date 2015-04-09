#import <Specta/Specta.h>
#define EXP_SHORTHAND
#import <Expecta/Expecta.h>
#import <OCMock/OCMock.h>
#import "LoginViewModel.h"
#import "ReachabilityFacade.h"
#import "LoginFacade.h"
#import "WordPressComOAuthClientFacade.h"
#import "AccountCreationFacade.h"
#import "BlogSyncFacade.h"
#import "HelpshiftFacade.h"
#import "OnePasswordFacade.h"
#import <WPXMLRPC/WPXMLRPC.h>
#import "WPWalkthroughOverlayView.h"

SpecBegin(LoginViewModel)

__block LoginViewModel *viewModel;
__block id mockViewModelDelegate;
__block id mockReachabilityFacade;
__block id mockLoginFacade;
__block id mockLoginFacadeDelegate;
__block id mockOAuthFacade;
__block id mockAccountCreationFacade;
__block id mockBlogSyncFacade;
__block id mockHelpshiftFacade;
__block id mockOnePasswordFacade;

beforeEach(^{
    mockViewModelDelegate = [OCMockObject niceMockForProtocol:@protocol(LoginViewModelDelegate)];
    mockReachabilityFacade = [OCMockObject niceMockForProtocol:@protocol(ReachabilityFacade)];
    mockLoginFacade = [OCMockObject niceMockForProtocol:@protocol(LoginFacade)];
    mockLoginFacadeDelegate = [OCMockObject niceMockForProtocol:@protocol(LoginFacadeDelegate)];
    mockOAuthFacade = [OCMockObject niceMockForProtocol:@protocol(WordPressComOAuthClientFacade)];
    mockAccountCreationFacade = [OCMockObject niceMockForProtocol:@protocol(AccountCreationFacade)];
    mockBlogSyncFacade = [OCMockObject niceMockForProtocol:@protocol(BlogSyncFacade)];
    mockHelpshiftFacade = [OCMockObject niceMockForProtocol:@protocol(HelpshiftFacade)];
    mockOnePasswordFacade = [OCMockObject niceMockForProtocol:@protocol(OnePasswordFacade)];
    [OCMStub([mockLoginFacade wordpressComOAuthClientFacade]) andReturn:mockOAuthFacade];
    [OCMStub([mockLoginFacade delegate]) andReturn:mockLoginFacadeDelegate];
    
    viewModel = [LoginViewModel new];
    viewModel.loginFacade = mockLoginFacade;
    viewModel.reachabilityFacade = mockReachabilityFacade;
    viewModel.delegate = mockViewModelDelegate;
    viewModel.accountCreationFacade = mockAccountCreationFacade;
    viewModel.blogSyncFacade = mockBlogSyncFacade;
    viewModel.helpshiftFacade = mockHelpshiftFacade;
    viewModel.onePasswordFacade = mockOnePasswordFacade;
});

describe(@"authenticating", ^{
    
    it(@"should show the activity indicator when authenticating", ^{
        [[mockViewModelDelegate expect] showActivityIndicator:YES];
        
        viewModel.authenticating = YES;
        
        [mockViewModelDelegate verify];
    });
    
    it(@"should hide the activity indicator when not authenticating", ^{
        [[mockViewModelDelegate expect] showActivityIndicator:NO];
        
        viewModel.authenticating = NO;
        
        [mockViewModelDelegate verify];
    });
    
});

describe(@"shouldDisplayMultifactor", ^{
    
    context(@"when it's true", ^{
        
        it(@"should set the username's alpha to 0.5", ^{
            [[mockViewModelDelegate expect] setUsernameAlpha:0.5];
            
            viewModel.shouldDisplayMultifactor = YES;
            
            [mockViewModelDelegate verify];
        });
        
        it(@"should set the password's alpha to 0.5", ^{
            [[mockViewModelDelegate expect] setPasswordAlpha:0.5];
            
            viewModel.shouldDisplayMultifactor = YES;
            
            [mockViewModelDelegate verify];
        });
        
        it(@"should set multifactor's alpha to 1.0", ^{
            [[mockViewModelDelegate expect] setMultiFactorAlpha:1.0];
            
            viewModel.shouldDisplayMultifactor = YES;
            
            [mockViewModelDelegate verify];
        });
    });
    
    context(@"when it's false", ^{
        
        it(@"it should set the username's alpha to 1.0", ^{
            [[mockViewModelDelegate expect] setUsernameAlpha:1.0];
            
            viewModel.shouldDisplayMultifactor = NO;
            
            [mockViewModelDelegate verify];
        });
        
        it(@"should set the password's alpha to 1.0", ^{
            [[mockViewModelDelegate expect] setPasswordAlpha:1.0];
            
            viewModel.shouldDisplayMultifactor = NO;
            
            [mockViewModelDelegate verify];
        });
        
        it(@"should set multifactor's alpha to 0.0", ^{
            [[mockViewModelDelegate expect] setMultiFactorAlpha:0.0];
            
            viewModel.shouldDisplayMultifactor = NO;
            
            [mockViewModelDelegate verify];
        });
    });
});

describe(@"isUsernameEnabled", ^{
    
    context(@"when it's true", ^{
        
        it(@"should enable the username text field", ^{
            [[mockViewModelDelegate expect] setUsernameEnabled:YES];
            
            viewModel.isUsernameEnabled = YES;
            
            [mockViewModelDelegate verify];
        });
    });
    
    context(@"when it's false", ^{
        
        it(@"should disable the username text field" , ^{
            [[mockViewModelDelegate expect] setUsernameEnabled:NO];
            
            viewModel.isUsernameEnabled = NO;
            
            [mockViewModelDelegate verify];
        });
    });
    
    context(@"dependency on shouldDisplayMultifactor", ^{
        
        it(@"should result in the value being true when shouldDisplayMultifactor is false", ^{
            viewModel.shouldDisplayMultifactor = NO;
            expect(viewModel.isUsernameEnabled).to.beTruthy();
        });
        
        it(@"should result in the value being false when shouldDisplayMultifactor is true", ^{
            viewModel.shouldDisplayMultifactor = YES;
            expect(viewModel.isUsernameEnabled).to.beFalsy();
        });
    });
});

describe(@"isPasswordEnabled", ^{
    
    context(@"when it's true", ^{
        
        it(@"should enable the password text field", ^{
            [[mockViewModelDelegate expect] setPasswordEnabled:YES];
            
            viewModel.isPasswordEnabled = YES;
            
            [mockViewModelDelegate verify];
        });
    });
    
    context(@"when it's false", ^{
        
        it(@"should disable the password text field" , ^{
            [[mockViewModelDelegate expect] setPasswordEnabled:NO];
            
            viewModel.isPasswordEnabled = NO;
            
            [mockViewModelDelegate verify];
        });
    });
    
    context(@"dependency on shouldDisplayMultifactor", ^{
        
        it(@"should result in the value being true when shouldDisplayMultifactor is false", ^{
            viewModel.shouldDisplayMultifactor = NO;
            expect(viewModel.isPasswordEnabled).to.beTruthy();
        });
        
        it(@"should result in the value being false when shouldDisplayMultifactor is true", ^{
            viewModel.shouldDisplayMultifactor = YES;
            expect(viewModel.isPasswordEnabled).to.beFalsy();
        });
    });
});

describe(@"isSiteUrlEnabled", ^{
    
    it(@"when it's true it should enable the site url field", ^{
        [[mockViewModelDelegate expect] setSiteUrlEnabled:YES];
        
        viewModel.isSiteUrlEnabled = YES;
        
        [mockViewModelDelegate verify];
    });
    
    it(@"when it's false it should disable the site url field", ^{
        [[mockViewModelDelegate expect] setSiteUrlEnabled:NO];
        
        viewModel.isSiteUrlEnabled = NO;
        
        [mockViewModelDelegate verify];
    });
    
    context(@"depdendency on isUserDotCom", ^{
        
        it(@"should result in the value being false when isUserDotCom is true", ^{
            viewModel.userIsDotCom = YES;
            expect(viewModel.isSiteUrlEnabled).to.beFalsy();
        });
        
        it(@"should result in the value being true when isUserDotCom is false", ^{
            viewModel.userIsDotCom = NO;
            expect(viewModel.isSiteUrlEnabled).to.beTruthy();
        });
    });
});

describe(@"isMultifactorEnabled", ^{
    
    it(@"when it's true it should enable the multifactor text field", ^{
        [[mockViewModelDelegate expect] setMultifactorEnabled:YES];
        
        viewModel.isMultifactorEnabled = YES;
        
        [mockViewModelDelegate verify];
    });
    
    it(@"when it's false it should disable the multifactor text field", ^{
        [[mockViewModelDelegate expect] setMultifactorEnabled:NO];
        
        viewModel.isMultifactorEnabled = NO;
        
        [mockViewModelDelegate verify];
    });
    
    context(@"dependency on shouldDisplayMultifactor", ^{
        
        it(@"should result in the value being true when shouldDisplayMultifactor is true", ^{
            viewModel.shouldDisplayMultifactor = YES;
            expect(viewModel.isMultifactorEnabled).to.beTruthy();
        });
        
        it(@"should result in the value being false when shouldDisplayMultifactor is false", ^{
            viewModel.shouldDisplayMultifactor = NO;
            expect(viewModel.isMultifactorEnabled).to.beFalsy();
        });
    });
});

describe(@"cancellable", ^{
    
    it(@"when it's true it should display the cancel button", ^{
        [[mockViewModelDelegate expect] setCancelButtonHidden:NO];
        
        viewModel.cancellable = YES;
        
        [mockViewModelDelegate verify];
    });
    
    it(@"when it's false it should hide the cancel button", ^{
        [[mockViewModelDelegate expect] setCancelButtonHidden:YES];
        
        viewModel.cancellable = NO;
        
        [mockViewModelDelegate verify];
    });
});

describe(@"forgot password button's visibility", ^{
    
    context(@"for a .com user", ^{
        
        beforeEach(^{
            viewModel.userIsDotCom = YES;
        });
        
        context(@"who is authenticating", ^{
        
            it(@"should not be visible", ^{
                [[mockViewModelDelegate expect] setForgotPasswordHidden:YES];
                
                viewModel.authenticating = YES;
                
                [mockViewModelDelegate verify];
            });
        });
        
        context(@"who isn't authenticating", ^{
            
            it(@"should be visible", ^{
                [[mockViewModelDelegate expect] setForgotPasswordHidden:NO];
                
                viewModel.authenticating = NO;
                
                [mockViewModelDelegate verify];
            });
            
            it(@"should not be visibile if multifactor auth controls are visible", ^{
                [[mockViewModelDelegate expect] setForgotPasswordHidden:YES];
                
                viewModel.isMultifactorEnabled = YES;
                viewModel.authenticating = NO;
                
                [mockViewModelDelegate verify];
            });
        });
    });
    
    context(@"for a self hosted user", ^{
        
        context(@"who isn't authenticating", ^{
            
            beforeEach(^{
                viewModel.authenticating = NO;
            });
            
            it(@"should not be visible if a url is not present", ^{
                [[mockViewModelDelegate expect] setForgotPasswordHidden:YES];
                
                viewModel.siteUrl = @"";
                
                [mockViewModelDelegate verify];
            });
            
            
            it(@"should be visible if a url is present", ^{
                [[mockViewModelDelegate expect] setForgotPasswordHidden:NO];
                
                viewModel.siteUrl = @"http://www.selfhosted.com";
                
                [mockViewModelDelegate verify];
            });
            
            it(@"should not be visible if multifactor controls are visible", ^{
                [[mockViewModelDelegate expect] setForgotPasswordHidden:YES];
                
                viewModel.isMultifactorEnabled = YES;
                
                [mockViewModelDelegate verify];
            });
        });
        
        context(@"who is authenticating", ^{
            
            beforeEach(^{
                viewModel.authenticating = YES;
            });
            
            it(@"should not be visible if a url is present", ^{
                [[mockViewModelDelegate expect] setForgotPasswordHidden:YES];
                
                viewModel.siteUrl = @"http://www.selfhosted.com";
                
                [mockViewModelDelegate verify];
            });
        });
    });
});

describe(@"skipToCreateAccountButton visibility", ^{
    
    context(@"when authenticating", ^{
        
        it(@"should not be visible if the user has an account", ^{
            [[mockViewModelDelegate expect] setAccountCreationButtonHidden:YES];
            
            viewModel.authenticating = YES;
            viewModel.hasDefaultAccount = YES;
            
            [mockViewModelDelegate verify];
        });
        
        it(@"should not be visible if the user doesn't have an account", ^{
            [[mockViewModelDelegate expect] setAccountCreationButtonHidden:YES];
            
            viewModel.authenticating = YES;
            viewModel.hasDefaultAccount = NO;
            
            [mockViewModelDelegate verify];
        });
    });
    
    context(@"when not authenticating", ^{
        
        it(@"should not be visible if the user has an account", ^{
            [[mockViewModelDelegate expect] setAccountCreationButtonHidden:YES];
            
            viewModel.authenticating = NO;
            viewModel.hasDefaultAccount = YES;
            
            [mockViewModelDelegate verify];
        });
        
        it(@"should be visible if the user doesn't have an account", ^{
            [[mockViewModelDelegate expect] setAccountCreationButtonHidden:NO];
            
            viewModel.authenticating = NO;
            viewModel.hasDefaultAccount = NO;
            
            [mockViewModelDelegate verify];
        });
    });
});

describe(@"the sign in button title", ^{
    
    context(@"when multifactor controls are visible", ^{
        
        beforeEach(^{
            viewModel.shouldDisplayMultifactor = YES;
        });
        
        it(@"should set the sign in button title to 'Verify'", ^{
            [[mockViewModelDelegate expect] setSignInButtonTitle:@"Verify"];
            
            viewModel.shouldDisplayMultifactor = YES;
            
            [mockViewModelDelegate verify];
        });
        
        it(@"should set the sign in button title to 'Verify' even if the user is a .com user", ^{
            [[mockViewModelDelegate expect] setSignInButtonTitle:@"Verify"];
            
            viewModel.shouldDisplayMultifactor = YES;
            viewModel.userIsDotCom = YES;
            
            [mockViewModelDelegate verify];
        });
    });
    
    context(@"when multifactor controls aren't visible", ^{
        beforeEach(^{
            viewModel.shouldDisplayMultifactor = NO;
        });
        
        it(@"should set the sign in button title to 'Sign In' if user is a .com user", ^{
            [[mockViewModelDelegate expect] setSignInButtonTitle:@"Sign In"];
            
            viewModel.userIsDotCom = YES;
            
            [mockViewModelDelegate verify];
        });
        
        it(@"should set the sign in button title to 'Add Site' if user isn't a .com user", ^{
            [[mockViewModelDelegate expect] setSignInButtonTitle:@"Add Site"];
            
            viewModel.userIsDotCom = NO;
            
            [mockViewModelDelegate verify];
        });
    });
});

describe(@"signInButton", ^{
    
    context(@"for a .com user", ^{
        
        before(^{
            viewModel.userIsDotCom = YES;
        });
        
        context(@"when multifactor authentication controls are not visible", ^{
            before(^{
                viewModel.shouldDisplayMultifactor = NO;
            });
            
            it(@"should be disabled if username and password are blank", ^{
                [[mockViewModelDelegate expect] setSignInButtonEnabled:NO];
                
                viewModel.username = @"";
                viewModel.password = @"";
                
                [mockViewModelDelegate verify];
            });
            
            it(@"should be disabled if password is blank", ^{
                [[mockViewModelDelegate expect] setSignInButtonEnabled:NO];
                
                viewModel.username = @"username";
                viewModel.password = @"";
                
                [mockViewModelDelegate verify];
            });
            
            it(@"should be enabled if username and password are filled", ^{
                [[mockViewModelDelegate expect] setSignInButtonEnabled:YES];
                
                viewModel.username = @"username";
                viewModel.password = @"password";
                
                [mockViewModelDelegate verify];
            });
        });
        
        context(@"when multifactor authentication controls are visible", ^{
            
            before(^{
                viewModel.shouldDisplayMultifactor = YES;
                viewModel.username = @"username";
                viewModel.password = @"password";
            });
            
            it(@"should not be enabled if the multifactor code isn't entered", ^{
                [[mockViewModelDelegate expect] setSignInButtonEnabled:NO];
                
                viewModel.multifactorCode = @"";
                
                [mockViewModelDelegate verify];
            });
            
            it(@"should be enabled if the multifactor code is entered", ^{
                [[mockViewModelDelegate expect] setSignInButtonEnabled:YES];
                
                viewModel.multifactorCode = @"123456";
                
                [mockViewModelDelegate verify];
            });
        });
    });
    
    context(@"for a self hosted user", ^{
        
        before(^{
            viewModel.userIsDotCom = NO;
        });
        
        context(@"when multifactor authentication controls are not visible", ^{
            
            before(^{
                viewModel.shouldDisplayMultifactor = NO;
            });
            
            it(@"should be disabled if username, password and siteUrl are blank", ^{
                [[mockViewModelDelegate expect] setSignInButtonEnabled:NO];
                
                viewModel.username = @"";
                viewModel.password = @"";
                viewModel.siteUrl = @"";
                
                [mockViewModelDelegate verify];
            });
            
            it(@"should be disabled if password and siteUrl are blank", ^{
                [[mockViewModelDelegate expect] setSignInButtonEnabled:NO];
                
                viewModel.username = @"username";
                viewModel.password = @"";
                viewModel.siteUrl = @"";
                
                [mockViewModelDelegate verify];
            });
            
            it(@"should be disabled if siteUrl is blank", ^{
                [[mockViewModelDelegate expect] setSignInButtonEnabled:NO];
                
                viewModel.username = @"username";
                viewModel.password = @"password";
                viewModel.siteUrl = @"";
                
                [mockViewModelDelegate verify];
            });
            
            it(@"should be enabled if username, password and siteUrl are filled", ^{
                [[mockViewModelDelegate expect] setSignInButtonEnabled:YES];
                
                viewModel.username = @"username";
                viewModel.password = @"password";
                viewModel.siteUrl = @"http://www.selfhosted.com";
                
                [mockViewModelDelegate verify];
            });
        });
        
        context(@"when multifactor authentication controls are visible", ^{
            before(^{
                viewModel.shouldDisplayMultifactor = YES;
                viewModel.username = @"username";
                viewModel.password = @"password";
                viewModel.siteUrl = @"http://www.selfhosted.com";
            });
            
            it(@"should not be enabled if the multifactor code isn't entered", ^{
                [[mockViewModelDelegate expect] setSignInButtonEnabled:NO];
                
                viewModel.multifactorCode = @"";
                
                [mockViewModelDelegate verify];
            });
            
            it(@"should be enabled if the multifactor code is entered", ^{
                [[mockViewModelDelegate expect] setSignInButtonEnabled:YES];
                
                viewModel.multifactorCode = @"123456";
                
                [mockViewModelDelegate verify];
            });
        });
    });
});

describe(@"onePasswordButtonActionForViewController", ^{
    
    __block id mockViewController;
    before(^{
        mockViewController = [OCMockObject niceMockForClass:[UIViewController class]];
    });
    
    __block NSError *error;
    __block NSString *username;
    __block NSString *password;
    
    void (^forceOnePasswordExtensionCallbackToExecute)() = ^{
        [OCMStub([mockOnePasswordFacade findLoginForURLString:OCMOCK_ANY viewController:OCMOCK_ANY completion:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
            void (^ __unsafe_unretained callback)(NSString *, NSString *, NSError *);
            [invocation getArgument:&callback atIndex:4];
            
            callback(username, password, error);
        }];
    };
    
    NSString *sharedExamplesForABlankResponseOrAnError = @"the extension returning a blank response or an error";
    sharedExamplesFor(sharedExamplesForABlankResponseOrAnError, ^(NSDictionary *data) {
        
        beforeEach(^{
            forceOnePasswordExtensionCallbackToExecute();
        });
        
        context(@"there is no data", ^{
            
            beforeEach(^{
                username = nil;
                password = nil;
            });
            
            it(@"shouldn't attempt to set the username/password", ^{
                [[mockViewModelDelegate reject] setUsernameTextValue:OCMOCK_ANY];
                [[mockViewModelDelegate reject] setPasswordTextValue:OCMOCK_ANY];
                
                [viewModel onePasswordButtonActionForViewController:mockViewController];
                
                [mockViewModelDelegate verify];
            });
            
            it(@"shouldn't attempt to sign in", ^{
                [OCMStub([viewModel signInButtonAction]) andDo:^(NSInvocation *invocation) {
                    XCTFail(@"Shouldn't get here");
                }];
                
                [viewModel onePasswordButtonActionForViewController:mockViewController];
            });
        });
        
        
        context(@"there is an error", ^{
            
            beforeEach(^{
                error = [NSError errorWithDomain:@"com.wordpress" code:-1 userInfo:@{}];
            });
            
            it(@"shoudln't attempt to set username/password", ^{
                [[mockViewModelDelegate reject] setUsernameTextValue:OCMOCK_ANY];
                [[mockViewModelDelegate reject] setPasswordTextValue:OCMOCK_ANY];
                
                [viewModel onePasswordButtonActionForViewController:mockViewController];
                
                [mockViewModelDelegate verify];
            });
            
            it(@"shoudln't attempt to sign in", ^{
                [OCMStub([viewModel signInButtonAction]) andDo:^(NSInvocation *invocation) {
                    XCTFail(@"Shouldn't get here");
                }];
                
                [viewModel onePasswordButtonActionForViewController:mockViewController];
            });
        });
    });
    
    NSString *sharedExamplesForValidData = @"the extension returned valid data";
    sharedExamplesFor(sharedExamplesForValidData, ^(NSDictionary *data) {
        
        beforeEach(^{
            forceOnePasswordExtensionCallbackToExecute();
            viewModel.username = username =  @"username";
            viewModel.password = password = @"password";
            error = nil;
        });
        
        it(@"should set the username/password", ^{
            [[mockViewModelDelegate expect] setUsernameTextValue:viewModel.username];
            [[mockViewModelDelegate expect] setPasswordTextValue:viewModel.password];
            
            [viewModel onePasswordButtonActionForViewController:mockViewController];
            
            [mockViewModelDelegate verify];
        });
        
        it(@"should attempt to sign in", ^{
            __block BOOL signInAttempted = NO;
            [OCMStub([viewModel signInButtonAction]) andDo:^(NSInvocation *invocation) {
                signInAttempted = YES;
            }];
            
            [viewModel onePasswordButtonActionForViewController:mockViewController];
            
            expect(signInAttempted).to.beTruthy();
        });
    });
    
    NSString *sharedExamplesForBugWhereKeyboardWasntDismissedBeforeOpeningExtension = @"the dismissal of the keyboard before opening the extension";
    sharedExamplesFor(sharedExamplesForBugWhereKeyboardWasntDismissedBeforeOpeningExtension, ^(NSDictionary *data) {
        
        // https://github.com/wordpress-mobile/WordPress-iOS/issues/344
        it(@"should occur", ^{
            [[mockViewModelDelegate expect] endViewEditing];
            
            [viewModel onePasswordButtonActionForViewController:mockViewController];
            
            [mockViewModelDelegate verify];
        });
    });
    
    
    
    
    context(@"for a self hosted user", ^{
        
        beforeEach(^{
            viewModel.userIsDotCom = NO;
            viewModel.siteUrl = @"http://www.selfhosted.com";
        });
        
        it(@"if the user doesn't have a site url it should display an error", ^{
            viewModel.siteUrl = @"";
            [[mockViewModelDelegate expect] displayOnePasswordEmptySiteAlert];
            
            [viewModel onePasswordButtonActionForViewController:mockViewController];
            
            [mockViewModelDelegate verify];
        });
        
        it(@"if the user has a site url it should not display an error", ^{
            [[mockViewModelDelegate reject] displayOnePasswordEmptySiteAlert];
            
            [viewModel onePasswordButtonActionForViewController:mockViewController];
            
            [mockViewModelDelegate verify];
        });
        
        it(@"should use OnePassword to find the users credentials", ^{
            [[mockOnePasswordFacade expect] findLoginForURLString:viewModel.siteUrl viewController:mockViewController completion:OCMOCK_ANY];
            
            [viewModel onePasswordButtonActionForViewController:mockViewController];
            
            [mockOnePasswordFacade verify];
        });
        
        itShouldBehaveLike(sharedExamplesForABlankResponseOrAnError, nil);
        itShouldBehaveLike(sharedExamplesForValidData, nil);
        itShouldBehaveLike(sharedExamplesForBugWhereKeyboardWasntDismissedBeforeOpeningExtension, nil);
    });
    
    context(@"for a WordPress.com user", ^{
        
        beforeEach(^{
            viewModel.userIsDotCom = YES;
        });
        
        it(@"should use OnePassword to find the users credentials", ^{
            [[mockOnePasswordFacade expect] findLoginForURLString:@"wordpress.com" viewController:mockViewController completion:OCMOCK_ANY];
            
            [viewModel onePasswordButtonActionForViewController:mockViewController];
            
            [mockOnePasswordFacade verify];
        });
        
        itShouldBehaveLike(sharedExamplesForABlankResponseOrAnError, nil);
        itShouldBehaveLike(sharedExamplesForValidData, nil);
        itShouldBehaveLike(sharedExamplesForBugWhereKeyboardWasntDismissedBeforeOpeningExtension, nil);
    });
});

describe(@"displayRemoteError", ^{
    
    __block NSError *error;
    NSString *errorMessage = @"You have failed me yet again Starscream.";
    NSString *defaultFirstButtonText = NSLocalizedString(@"OK", nil);
    NSString *defaultSecondButtonText = NSLocalizedString(@"Need Help?", nil);
    __block id mockOverlayView;
    
    NSString *sharedExamplesForPrimaryButtonThatDismissesOverlay = @"a primary button that dismisses the overlay";
    sharedExamplesFor(sharedExamplesForPrimaryButtonThatDismissesOverlay, ^(NSDictionary *data) {
        
        context(@"when the primary button is pressed", ^{
            
            it(@"should dismiss the overlay", ^{
                [OCMStub([mockViewModelDelegate displayOverlayViewWithMessage:OCMOCK_ANY firstButtonText:OCMOCK_ANY firstButtonCallback:OCMOCK_ANY secondButtonText:OCMOCK_ANY secondButtonCallback:OCMOCK_ANY accessibilityIdentifier:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
                    void (^ __unsafe_unretained callback)(WPWalkthroughOverlayView *);
                    [invocation getArgument:&callback atIndex:4];
                    
                    callback(mockOverlayView);
                }];
                
                [[mockOverlayView expect] dismiss];
                
                [viewModel displayRemoteError:error];
                
                [mockOverlayView verify];
            });
        });
    });
    
    NSString *sharedExamplesForAnOverlayButtonThatShowsTheHelpViewController = @"an overlay button that shows the help view controller";
    sharedExamplesFor(sharedExamplesForAnOverlayButtonThatShowsTheHelpViewController, ^(NSDictionary *data) {
        
        it(@"should show the help view controller", ^{
            [[mockViewModelDelegate expect] displayHelpViewControllerWithAnimation:NO];
            
            [viewModel displayRemoteError:error];
            
            [mockViewModelDelegate verify];
        });
    });
    
    NSString *sharedExamplesForAnOverlayButtonThatDismissesTheOverlay = @"an overlay button that dismisses the overlay";
    sharedExamplesFor(sharedExamplesForAnOverlayButtonThatDismissesTheOverlay, ^(NSDictionary *data) {
        it(@"should dismiss the overlay view", ^{
            [[mockOverlayView expect] dismiss];
            
            [viewModel displayRemoteError:error];
            
            [mockOverlayView verify];
        });
    });
    
    NSString *sharedExamplesForAButtonThatOpensUpTheFAQ = @"a button that opens up the FAQ";
    sharedExamplesFor(sharedExamplesForAButtonThatOpensUpTheFAQ, ^(NSDictionary *data) {
        it(@"should open the FAQ on the website", ^{
            [[mockViewModelDelegate expect] displayWebViewForURL:[NSURL URLWithString:@"http://ios.wordpress.org/faq/#faq_3"] username:nil password:nil];
            
            [viewModel displayRemoteError:error];
            
            [mockViewModelDelegate verify];
        });
    });
    
    void (^overlayViewPrimaryButton)() = ^{
        [OCMStub([mockViewModelDelegate displayOverlayViewWithMessage:OCMOCK_ANY firstButtonText:OCMOCK_ANY firstButtonCallback:OCMOCK_ANY secondButtonText:OCMOCK_ANY secondButtonCallback:OCMOCK_ANY accessibilityIdentifier:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
            void (^ __unsafe_unretained callback)(WPWalkthroughOverlayView *);
            [invocation getArgument:&callback atIndex:4];
            
            callback(mockOverlayView);
        }];
    };
    
    void (^overlayViewSecondaryButton)() = ^{
        [OCMStub([mockViewModelDelegate displayOverlayViewWithMessage:OCMOCK_ANY firstButtonText:OCMOCK_ANY firstButtonCallback:OCMOCK_ANY secondButtonText:OCMOCK_ANY secondButtonCallback:OCMOCK_ANY accessibilityIdentifier:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
            void (^ __unsafe_unretained callback)(WPWalkthroughOverlayView *);
            [invocation getArgument:&callback atIndex:6];
            
            callback(mockOverlayView);
        }];
    };
    
    beforeEach(^{
        mockOverlayView = [OCMockObject niceMockForClass:[WPWalkthroughOverlayView class]];
    });
    
    it(@"should dismiss the login message", ^{
        [[mockViewModelDelegate expect] dismissLoginMessage];
        
        error = [NSError errorWithDomain:@"wordpress.com" code:3 userInfo:@{NSLocalizedDescriptionKey : errorMessage}];
        [viewModel displayRemoteError:error];
        
        [mockViewModelDelegate verify];
    });
   
    context(@"for non XMLRPC errors", ^{
        
        beforeEach(^{
            error = [NSError errorWithDomain:@"wordpress.com" code:3 userInfo:@{NSLocalizedDescriptionKey : errorMessage}];
        });
        
        context(@"when Helpshift is not enabled", ^{
            
            beforeEach(^{
                [[[mockHelpshiftFacade stub] andReturnValue:@(NO)] isHelpshiftEnabled];
            });
            
            it(@"should display an overlay with a generic error message with the default button labels", ^{
                [[mockViewModelDelegate expect] displayOverlayViewWithMessage:errorMessage firstButtonText:defaultFirstButtonText firstButtonCallback:OCMOCK_ANY secondButtonText:defaultSecondButtonText secondButtonCallback:OCMOCK_ANY accessibilityIdentifier:@"GenericErrorMessage"];
                
                [viewModel displayRemoteError:error];
                
                [mockViewModelDelegate verify];
            });
            
            itBehavesLike(sharedExamplesForPrimaryButtonThatDismissesOverlay, nil);
            
            context(@"when the overlay's secondary button is pressed", ^{
                
                beforeEach(^{
                    overlayViewSecondaryButton();
                });
                
                itShouldBehaveLike(sharedExamplesForAnOverlayButtonThatDismissesTheOverlay, nil);
                itShouldBehaveLike(sharedExamplesForAnOverlayButtonThatShowsTheHelpViewController, nil);
            });
        });
        
        context(@"when Helpshift is enabled", ^{
            
            beforeEach(^{
                [[[mockHelpshiftFacade stub] andReturnValue:@(YES)] isHelpshiftEnabled];
            });
            
            it(@"should display an overlay with a 'Contact Us' button", ^{
                [[mockViewModelDelegate expect] displayOverlayViewWithMessage:errorMessage firstButtonText:defaultFirstButtonText firstButtonCallback:OCMOCK_ANY secondButtonText:NSLocalizedString(@"Contact Us", nil) secondButtonCallback:OCMOCK_ANY accessibilityIdentifier:OCMOCK_ANY];
                
                [viewModel displayRemoteError:error];
                
                [mockViewModelDelegate verify];
            });
            
            itBehavesLike(sharedExamplesForPrimaryButtonThatDismissesOverlay, nil);
            
            context(@"when the overlay's secondary button is pressed", ^{
                
                beforeEach(^{
                    overlayViewSecondaryButton();
                });
                
                it(@"should bring up Helpshift", ^{
                    [[mockViewModelDelegate expect] displayHelpshiftConversationView];
                    
                    [viewModel displayRemoteError:error];
                    
                    [mockViewModelDelegate verify];
                });
            });
        });
    });
    
    context(@"for a bad URL", ^{
        
        beforeEach(^{
            error = [NSError errorWithDomain:@"wordpress.com" code:NSURLErrorBadURL userInfo:@{NSLocalizedDescriptionKey : errorMessage}];
        });
        
        it(@"should display an overlay with a 'Need Help?'", ^{
            [[[mockHelpshiftFacade stub] andReturnValue:@(YES)] isHelpshiftEnabled];
            [[mockViewModelDelegate expect] displayOverlayViewWithMessage:errorMessage firstButtonText:defaultFirstButtonText firstButtonCallback:OCMOCK_ANY secondButtonText:NSLocalizedString(@"Need Help?", nil) secondButtonCallback:OCMOCK_ANY accessibilityIdentifier:OCMOCK_ANY];
            
            [viewModel displayRemoteError:error];
            
            [mockViewModelDelegate verify];
        });
        
        itShouldBehaveLike(sharedExamplesForPrimaryButtonThatDismissesOverlay, nil);
        
        context(@"when the overlay's secondary button is pressed", ^{
            
            beforeEach(^{
                overlayViewSecondaryButton();
            });
            
            itShouldBehaveLike(sharedExamplesForAnOverlayButtonThatDismissesTheOverlay, nil);
            itShouldBehaveLike(sharedExamplesForAButtonThatOpensUpTheFAQ, nil);
        });
    });
    
    context(@"for XMLRPC errors", ^{
        
        context(@"when the error code is 403", ^{
            
            beforeEach(^{
                error = [NSError errorWithDomain:WPXMLRPCFaultErrorDomain code:403 userInfo:@{NSLocalizedDescriptionKey : errorMessage}];
            });
            
            it(@"should display an overlay with a message about re-entering login details", ^{
                [[mockViewModelDelegate expect] displayOverlayViewWithMessage:NSLocalizedString(@"Please try entering your login details again.", nil) firstButtonText:OCMOCK_ANY firstButtonCallback:OCMOCK_ANY secondButtonText:OCMOCK_ANY secondButtonCallback:OCMOCK_ANY accessibilityIdentifier:OCMOCK_ANY];
                
                [viewModel displayRemoteError:error];
                
                [mockViewModelDelegate verify];
            });
            
            itShouldBehaveLike(sharedExamplesForPrimaryButtonThatDismissesOverlay, nil);
            
            context(@"the overlay's secondary button is pushed", ^{
                
                beforeEach(^{
                    overlayViewSecondaryButton();
                });
                
                itShouldBehaveLike(sharedExamplesForAnOverlayButtonThatDismissesTheOverlay, nil);
                itShouldBehaveLike(sharedExamplesForAnOverlayButtonThatShowsTheHelpViewController, nil);
            });
        });
        
        context(@"when the error code is 405", ^{
            
            beforeEach(^{
                error = [NSError errorWithDomain:WPXMLRPCFaultErrorDomain code:405 userInfo:@{NSLocalizedDescriptionKey : errorMessage}];
            });
            
            it(@"should display an overlay with a button that will take the user to the page to enable XMLRPC", ^{
                [[mockViewModelDelegate expect] displayOverlayViewWithMessage:OCMOCK_ANY firstButtonText:NSLocalizedString(@"Enable Now", nil) firstButtonCallback:OCMOCK_ANY secondButtonText:OCMOCK_ANY secondButtonCallback:OCMOCK_ANY accessibilityIdentifier:OCMOCK_ANY];
                
                [viewModel displayRemoteError:error];
                
                [mockViewModelDelegate verify];
            });
            
            context(@"when the overlay's primary button is pressed", ^{
                
                beforeEach(^{
                    overlayViewPrimaryButton();
                });
                
                itShouldBehaveLike(sharedExamplesForAnOverlayButtonThatDismissesTheOverlay, nil);
                
                it(@"should open a web view to the writing options page to allow the user to enable XMLRPC", ^{
                    NSString *siteUrl = @"http://www.selfhosted.com";
                    NSString *writingOptionsUrl = @"http://www.selfhosted.com/wp-admin/options-writing.php";
                    viewModel.siteUrl = siteUrl;
                    [[mockViewModelDelegate expect] displayWebViewForURL:[NSURL URLWithString:writingOptionsUrl] username:viewModel.username password:viewModel.password];
                    
                    [viewModel displayRemoteError:error];
                    
                    [mockViewModelDelegate verify];
                });
            });
            
            context(@"when the overlay's secondary button is pressed", ^{
                
                beforeEach(^{
                    overlayViewSecondaryButton();
                });
                
                itShouldBehaveLike(sharedExamplesForAnOverlayButtonThatDismissesTheOverlay, nil);
                itShouldBehaveLike(sharedExamplesForAnOverlayButtonThatShowsTheHelpViewController, nil);
            });
        });
        
        context(@"the error code isn't 403, 405, a bad url and there is no error message", ^{
            
            beforeEach(^{
                error = [NSError errorWithDomain:WPXMLRPCFaultErrorDomain code:401 userInfo:@{NSLocalizedDescriptionKey : @"" }];;
            });
            
            it(@"should display an overlay with a message about sign in failed", ^{
                [[mockViewModelDelegate expect] displayOverlayViewWithMessage:NSLocalizedString(@"Sign in failed. Please try again.", nil) firstButtonText:OCMOCK_ANY firstButtonCallback:OCMOCK_ANY secondButtonText:OCMOCK_ANY secondButtonCallback:OCMOCK_ANY accessibilityIdentifier:OCMOCK_ANY];
                
                [viewModel displayRemoteError:error];
                
                [mockViewModelDelegate verify];
            });
            
            it(@"should display an overlay with the default button text", ^{
                [[mockViewModelDelegate expect] displayOverlayViewWithMessage:OCMOCK_ANY firstButtonText:defaultFirstButtonText firstButtonCallback:OCMOCK_ANY secondButtonText:defaultSecondButtonText secondButtonCallback:OCMOCK_ANY accessibilityIdentifier:OCMOCK_ANY];
                
                [viewModel displayRemoteError:error];
                
                [mockViewModelDelegate verify];
            });
            
            itShouldBehaveLike(sharedExamplesForPrimaryButtonThatDismissesOverlay, nil);
            
            context(@"when the overlay's secondary button is pressed", ^{
                beforeEach(^{
                    overlayViewSecondaryButton();
                });
                
                itShouldBehaveLike(sharedExamplesForAnOverlayButtonThatShowsTheHelpViewController, nil);
            });
        });
        
        context(@"when the url is bad", ^{
            
            it(@"should display an overlay with the default button text", ^{
                error = [NSError errorWithDomain:WPXMLRPCFaultErrorDomain code:NSURLErrorBadURL userInfo:@{NSLocalizedDescriptionKey : errorMessage}];
                [[mockViewModelDelegate expect] displayOverlayViewWithMessage:OCMOCK_ANY firstButtonText:defaultFirstButtonText firstButtonCallback:OCMOCK_ANY secondButtonText:defaultSecondButtonText secondButtonCallback:OCMOCK_ANY accessibilityIdentifier:OCMOCK_ANY];
                
                [viewModel displayRemoteError:error];
                
                [mockViewModelDelegate verify];
            });
            
            itShouldBehaveLike(sharedExamplesForPrimaryButtonThatDismissesOverlay, nil);
            
            context(@"when the overlay's secondary button is pressed", ^{
                
                beforeEach(^{
                    overlayViewSecondaryButton();
                });
                
                itShouldBehaveLike(sharedExamplesForAnOverlayButtonThatDismissesTheOverlay, nil);
                itShouldBehaveLike(sharedExamplesForAButtonThatOpensUpTheFAQ, nil);
            });
        });
    });
});

describe(@"toggleSignInButtonTitle", ^{
    
    it(@"should set the title to 'Add Self-Hosted Site' for a .com user", ^{
        [[mockViewModelDelegate expect] setToggleSignInButtonTitle:@"Add Self-Hosted Site"];
        
        viewModel.userIsDotCom = YES;
       
        [mockViewModelDelegate verify];
    });
    
    it(@"should set the title to 'Sign in to WordPress.com' for a self hosted user", ^{
        [[mockViewModelDelegate expect] setToggleSignInButtonTitle:@"Sign in to WordPress.com"];
        
        viewModel.userIsDotCom = NO;
       
        [mockViewModelDelegate verify];
    });
});

describe(@"toggleSignInButton visibility", ^{
    
    it(@"should be hidden if onlyDotComAllowed is true", ^{
        [[mockViewModelDelegate expect] setToggleSignInButtonHidden:YES];
        
        viewModel.onlyDotComAllowed = YES;
        
        [mockViewModelDelegate verify];
    });
    
    it(@"should be hidden if hasDefaultAccount is true", ^{
        [[mockViewModelDelegate expect] setToggleSignInButtonHidden:YES];
        
        viewModel.hasDefaultAccount = YES;
        
        [mockViewModelDelegate verify];
    });
    
    it(@"should be hidden during authentication", ^{
        [[mockViewModelDelegate expect] setToggleSignInButtonHidden:YES];
        
        viewModel.authenticating = YES;;
        
        [mockViewModelDelegate verify];
    });
    
    it(@"should be visible if onlyDotComAllowed, hasDefaultAccount, and authenticating are all false", ^{
        [[mockViewModelDelegate expect] setToggleSignInButtonHidden:NO];
        
        viewModel.onlyDotComAllowed = NO;
        viewModel.hasDefaultAccount = NO;
        viewModel.authenticating = NO;
        
        [mockViewModelDelegate verify];
    });
});

describe(@"signInButtonAction", ^{
    
    context(@"the checking of the user's internet connection", ^{
        
        it(@"should not show an error message about the internet connection if it's down", ^{
            [OCMStub([mockReachabilityFacade isInternetReachable]) andReturnValue:@(YES)];
            [[mockReachabilityFacade reject] showAlertNoInternetConnection];
            
            [viewModel signInButtonAction];
            
            [mockReachabilityFacade verify];
        });
        
        it(@"should show an error message about the internet connection if it's down", ^{
            [OCMStub([mockReachabilityFacade isInternetReachable]) andReturnValue:@(NO)];
            [[mockReachabilityFacade expect] showAlertNoInternetConnection];
            
            [viewModel signInButtonAction];
            
            [mockReachabilityFacade verify];
        });
    });
    
    context(@"user field validation", ^{
        
        beforeEach(^{
            [OCMStub([mockReachabilityFacade isInternetReachable]) andReturnValue:@(YES)];
            
            viewModel.username = @"username";
            viewModel.password = @"password";
            viewModel.siteUrl = @"http://www.selfhosted.com";
        });
        
        sharedExamplesFor(@"username and password validation", ^(NSDictionary *data) {
            
            it(@"should display an error message if the username and password are blank", ^{
                viewModel.username = @"";
                viewModel.password = @"";
                [[mockViewModelDelegate expect] displayErrorMessageForInvalidOrMissingFields];
                
                [viewModel signInButtonAction];
                
                [mockViewModelDelegate verify];
            });
            
            it(@"should display an error message if the username is blank", ^{
                viewModel.username = @"";
                [[mockViewModelDelegate expect] displayErrorMessageForInvalidOrMissingFields];
                
                [viewModel signInButtonAction];
                
                [mockViewModelDelegate verify];
            });
            
            it(@"should display an error message if the password is blank", ^{
                viewModel.password = @"";
                [[mockViewModelDelegate expect] displayErrorMessageForInvalidOrMissingFields];
                
                [viewModel signInButtonAction];
                
                [mockViewModelDelegate verify];
            });
            
            it(@"should not display an error message if the fields are filled", ^{
                [[mockViewModelDelegate reject] displayErrorMessageForInvalidOrMissingFields];
                
                [viewModel signInButtonAction];
                
                [mockViewModelDelegate verify];
            });
        });
        
        context(@"for a .com user", ^{
            
            beforeEach(^{
                viewModel.userIsDotCom = YES;
            });
            
            itShouldBehaveLike(@"username and password validation", @{});
        });
        
        context(@"for a self hosted user", ^{
            beforeEach(^{
                viewModel.userIsDotCom = NO;
            });
            
            itShouldBehaveLike(@"username and password validation", @{});
            
            it(@"should display an error if the username, password and siteUrl are blank", ^{
                viewModel.username = @"";
                viewModel.password = @"";
                viewModel.siteUrl = @"";
                [[mockViewModelDelegate expect] displayErrorMessageForInvalidOrMissingFields];
                
                [viewModel signInButtonAction];
                
                [mockViewModelDelegate verify];
            });
            
            it(@"should not display an error if the fields are filled", ^{
                [[mockViewModelDelegate reject] displayErrorMessageForInvalidOrMissingFields];
                
                [viewModel signInButtonAction];
                
                [mockViewModelDelegate verify];
            });
        });
    });
    
    context(@"verification of non reserved username", ^{
        
        beforeEach(^{
            [OCMStub([mockReachabilityFacade isInternetReachable]) andReturnValue:@(YES)];
            
            viewModel.username = @"username";
            viewModel.password = @"password";
            viewModel.siteUrl = @"http://www.selfhosted.com";
        });
       
        NSArray *reservedNames = @[@"admin", @"administrator", @"root"];
        for (NSString *reservedName in reservedNames) {
            context(@"for a .com user", ^{
                
                beforeEach(^{
                    viewModel.userIsDotCom = YES;
                    viewModel.username = reservedName;
                });
                
                NSString *testName = [NSString stringWithFormat:@"should display the error message if the username is '%@'", reservedName];
                it(testName, ^{
                    [[mockViewModelDelegate expect] displayReservedNameErrorMessage];
                    
                    [viewModel signInButtonAction];
                    
                    [mockViewModelDelegate verify];
                });
                
                testName = [NSString stringWithFormat:@"should bring focus to siteUrlText if the username is '%@'", reservedName];
                it(testName, ^{
                    [[mockViewModelDelegate expect] setFocusToSiteUrlText];
                    
                    [viewModel signInButtonAction];
                    
                    [mockViewModelDelegate verify];
                });
                
                testName = [NSString stringWithFormat:@"should adjust passwordText's return key type to UIReturnKeyNext"];
                it(testName, ^{
                    [mockViewModelDelegate setPasswordTextReturnKeyType:UIReturnKeyNext];
                    
                    [viewModel signInButtonAction];
                    
                    [mockViewModelDelegate verify];
                });
                
                testName = [NSString stringWithFormat:@"should reload the interface"];
                it(testName, ^{
                    [[mockViewModelDelegate expect] reloadInterfaceWithAnimation:YES];
                    
                    [viewModel signInButtonAction];
                    
                    [mockViewModelDelegate verify];
                });
                
            });
            
            context(@"for a self hosted user", ^{
                
                beforeEach(^{
                    viewModel.userIsDotCom = NO;
                    viewModel.username = reservedName;
                });
                
                NSString *testName = [NSString stringWithFormat:@"should not display the error message if the username is '%@'", reservedName];
                it(testName, ^{
                    viewModel.username = reservedName;
                    [[mockViewModelDelegate reject] displayReservedNameErrorMessage];
                    
                    [viewModel signInButtonAction];
                    
                    [mockViewModelDelegate verify];
                });
            });
        }
    });
    
    context(@"when all fields are valid", ^{
        
        beforeEach(^{
            [OCMStub([mockReachabilityFacade isInternetReachable]) andReturnValue:@(YES)];
            
            viewModel.username = @"username";
            viewModel.password = @"password";
            viewModel.siteUrl = @"http://www.selfhosted.com";
        });
        
        context(@"for a .com user", ^{
            
            beforeEach(^{
                viewModel.userIsDotCom = YES;
            });
            
            it(@"should login", ^{
                [[mockLoginFacade expect] signInWithLoginFields:OCMOCK_ANY];
                
                [viewModel signInButtonAction];
                
                [mockLoginFacade verify];
            });
        });
        
        context(@"for a self hosted user", ^{
            beforeEach(^{
                viewModel.userIsDotCom = NO;
            });
            
            it(@"should login", ^{
                [[mockLoginFacade expect] signInWithLoginFields:OCMOCK_ANY];
                
                [viewModel signInButtonAction];
                
                [mockLoginFacade verify];
            });
        });
    });
});

describe(@"baseSiteUrl", ^{
    
    it(@"should force https:// for a WordPress.com site that used http://", ^{
        NSString *baseUrl = @"testsite.wordpress.com";
        viewModel.siteUrl = [NSString stringWithFormat:@"http://%@", baseUrl];
        
        expect([viewModel baseSiteUrl]).to.equal([NSString stringWithFormat:@"https://%@", baseUrl]);
    });
    
    it(@"should force https:// for a WordPress.com site that didn't include a scheme", ^{
        NSString *baseUrl = @"testsite.wordpress.com";
        viewModel.siteUrl = baseUrl;
        
        expect([viewModel baseSiteUrl]).to.equal([NSString stringWithFormat:@"https://%@", baseUrl]);
    });
    
    it(@"should add http:// for a non WordPress.com site that forgot to include a scheme", ^{
        NSString *baseUrl = @"www.selfhostedsite.com";
        viewModel.siteUrl = baseUrl;
        
        expect([viewModel baseSiteUrl]).to.equal([NSString stringWithFormat:@"http://%@", baseUrl]);
    });
    
    it(@"should remove wp-login.php from the url", ^{
        NSString *baseUrl = @"www.selfhostedsite.com";
        viewModel.siteUrl = [NSString stringWithFormat:@"%@/wp-login.php", baseUrl];
        
        expect([viewModel baseSiteUrl]).to.equal([NSString stringWithFormat:@"http://%@", baseUrl]);
    });
    
    it(@"should remove /wp-admin from the url", ^{
        NSString *baseUrl = @"www.selfhostedsite.com";
        viewModel.siteUrl = [NSString stringWithFormat:@"%@/wp-admin", baseUrl];
        
        expect([viewModel baseSiteUrl]).to.equal([NSString stringWithFormat:@"http://%@", baseUrl]);
    });
    
    it(@"should remove /wp-admin/ from the url", ^{
        NSString *baseUrl = @"www.selfhostedsite.com";
        viewModel.siteUrl = [NSString stringWithFormat:@"%@/wp-admin/", baseUrl];
        
        expect([viewModel baseSiteUrl]).to.equal([NSString stringWithFormat:@"http://%@", baseUrl]);
    });
    
    it(@"should remove a trailing slash from the url", ^{
        NSString *baseUrl = @"www.selfhostedsite.com";
        viewModel.siteUrl = [NSString stringWithFormat:@"%@/", baseUrl];
        
        expect([viewModel baseSiteUrl]).to.equal([NSString stringWithFormat:@"http://%@", baseUrl]);
    });
});

describe(@"forgotPasswordButtonAction", ^{
    
    it(@"should open the correct forgot password url for WordPress.com", ^{
        viewModel.userIsDotCom = YES;
        [[mockViewModelDelegate expect] openURLInSafari:[NSURL URLWithString:@"https://wordpress.com/wp-login.php?action=lostpassword&redirect_to=wordpress%3A%2F%2F"]];
        
        [viewModel forgotPasswordButtonAction];
        
        [mockViewModelDelegate verify];
    });
    
    it(@"should open the correct forgot password url for a self hosted site", ^{
        viewModel.userIsDotCom = NO;
        viewModel.siteUrl = @"http://www.selfhosted.com";
        NSString *url = [NSString stringWithFormat:@"%@%@", viewModel.siteUrl, @"/wp-login.php?action=lostpassword&redirect_to=wordpress%3A%2F%2F"];
        [[mockViewModelDelegate expect] openURLInSafari:[NSURL URLWithString:url]];
        
        [viewModel forgotPasswordButtonAction];
        
        [mockViewModelDelegate verify];
    });
});

describe(@"LoginFacadeDelegate methods", ^{
    
    context(@"displayLoginMessage", ^{
        
        it(@"should be passed on to the LoginViewModelDelegate", ^{
            [[mockViewModelDelegate expect] displayLoginMessage:@"Test"];
            
            [viewModel displayLoginMessage:@"Test"];
            
            [mockViewModelDelegate verify];
        });
    });
    
    context(@"needsMultifactorCode", ^{
        
        it(@"should result in the multifactor field being displayed", ^{
            OCMExpect([viewModel displayMultifactorTextField]);
            
            [viewModel needsMultifactorCode];
            
            OCMVerify([viewModel displayMultifactorTextField]);
        });
        
        it(@"should dismiss the login message", ^{
            [[mockViewModelDelegate expect] dismissLoginMessage];
            
            [viewModel needsMultifactorCode];
            
            [mockViewModelDelegate verify];
        });
    });
    
    context(@"finishedLoginWithUsername:authToken:shouldDisplayMultifactor:", ^{
        
        __block NSString *username;
        __block NSString *authToken;
        __block BOOL shouldDisplayMultifactor;
        
        beforeEach(^{
            username = @"username";
            authToken = @"authtoken";
            shouldDisplayMultifactor = NO;
        });
        
        it(@"should dismiss the login message", ^{
            [[mockViewModelDelegate expect] dismissLoginMessage];
            
            [viewModel finishedLoginWithUsername:username authToken:authToken shouldDisplayMultifactor:shouldDisplayMultifactor];
            
            [mockViewModelDelegate verify];
        });
        
        it(@"should display a message about getting account information", ^{
            [[mockViewModelDelegate expect] displayLoginMessage:NSLocalizedString(@"Getting account information", nil)];
            
            [viewModel finishedLoginWithUsername:username authToken:authToken shouldDisplayMultifactor:shouldDisplayMultifactor];
            
            [mockViewModelDelegate verify];
        });
        
        it(@"should create a WPAccount for a .com site", ^{
            [[mockAccountCreationFacade expect] createOrUpdateWordPressComAccountWithUsername:username authToken:authToken];
            
            [viewModel finishedLoginWithUsername:username authToken:authToken shouldDisplayMultifactor:shouldDisplayMultifactor];
            
            [mockViewModelDelegate verify];
        });
        
        context(@"the syncing of the newly added blogs", ^{
            
            it(@"should occur", ^{
                [[mockBlogSyncFacade expect] syncBlogsForAccount:OCMOCK_ANY success:OCMOCK_ANY failure:OCMOCK_ANY];
                
                [viewModel finishedLoginWithUsername:username authToken:authToken shouldDisplayMultifactor:shouldDisplayMultifactor];
                
                [mockViewModelDelegate verify];
            });
            
            context(@"when successful", ^{
                
                beforeEach(^{
                    // Retrieve success block and execute it when appropriate
                    [OCMStub([mockBlogSyncFacade syncBlogsForAccount:OCMOCK_ANY success:OCMOCK_ANY failure:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
                        void (^ __unsafe_unretained successStub)(void);
                        [invocation getArgument:&successStub atIndex:3];
                        
                        successStub();
                    }];
                });
                
                it(@"should dismiss the login message", ^{
                    [[mockViewModelDelegate expect] dismissLoginMessage];
                    
                    [viewModel finishedLoginWithUsername:username authToken:authToken shouldDisplayMultifactor:shouldDisplayMultifactor];
                    
                    [mockViewModelDelegate verify];
                });
                
                it(@"should indicate dismiss the login view", ^{
                    [[mockViewModelDelegate expect] dismissLoginView];
                    
                    [viewModel finishedLoginWithUsername:username authToken:authToken shouldDisplayMultifactor:shouldDisplayMultifactor];
                    
                    [mockViewModelDelegate verify];
                });
                
                it(@"should update the email and default blog for the newly created account", ^{
                    [[mockAccountCreationFacade expect] updateEmailAndDefaultBlogForWordPressComAccount:OCMOCK_ANY];
                    
                    [viewModel finishedLoginWithUsername:username authToken:authToken shouldDisplayMultifactor:shouldDisplayMultifactor];
                    
                    [mockAccountCreationFacade verify];
                });
            });
            
            context(@"when not successful", ^{
                
                __block NSError *error;
                
                beforeEach(^{
                    // Retrieve failure block and execute it when appropriate
                    [OCMStub([mockBlogSyncFacade syncBlogsForAccount:OCMOCK_ANY success:OCMOCK_ANY failure:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
                        void (^ __unsafe_unretained failureStub)(NSError *);
                        [invocation getArgument:&failureStub atIndex:4];
                        
                        error = [NSError errorWithDomain:@"org.wordpress" code:-1 userInfo:@{ NSLocalizedDescriptionKey : @"You have failed me yet again starscream" }];
                        failureStub(error);
                    }];
                });
                
                it(@"should dismiss the login message", ^{
                    [[mockViewModelDelegate expect] dismissLoginMessage];
                    
                    [viewModel finishedLoginWithUsername:username authToken:authToken shouldDisplayMultifactor:shouldDisplayMultifactor];
                    
                    [mockViewModelDelegate verify];
                });
                
                it(@"should display the error", ^{
                    [[mockViewModelDelegate expect] displayOverlayViewWithMessage:OCMOCK_ANY firstButtonText:OCMOCK_ANY firstButtonCallback:OCMOCK_ANY secondButtonText:OCMOCK_ANY secondButtonCallback:OCMOCK_ANY accessibilityIdentifier:OCMOCK_ANY];
                    
                    [viewModel finishedLoginWithUsername:username authToken:authToken shouldDisplayMultifactor:shouldDisplayMultifactor];
                    
                    [mockViewModelDelegate verify];
                });
            });
        });
    });

    context(@"finishedLoginWithUsername:password:xmlrpc:options:", ^{
        
        __block NSString *username;
        __block NSString *password;
        __block NSString *xmlrpc;
        __block NSDictionary *options;
        
        beforeEach(^{
            username = @"username";
            password = @"password";
            xmlrpc = @"www.wordpress.com/xmlrpc.php";
            options = @{};
        });
        
        it(@"should dismiss the login message", ^{
            [[mockViewModelDelegate expect] dismissLoginMessage];
            
            [viewModel finishedLoginWithUsername:username password:password xmlrpc:xmlrpc options:options];
            
            [mockViewModelDelegate verify];
        });
        
        it(@"should create a WPAccount for a self hosted site", ^{
            [[mockAccountCreationFacade expect] createOrUpdateSelfHostedAccountWithXmlrpc:xmlrpc username:username andPassword:password];
            
            [viewModel finishedLoginWithUsername:username password:password xmlrpc:xmlrpc options:options];
            
            [mockAccountCreationFacade verify];
        });
        
        it(@"should sync the newly added site", ^{
            [[mockBlogSyncFacade expect] syncBlogForAccount:OCMOCK_ANY username:username password:password xmlrpc:xmlrpc options:options needsJetpack:OCMOCK_ANY finishedSync:OCMOCK_ANY];
            
            [viewModel finishedLoginWithUsername:username password:password xmlrpc:xmlrpc options:options];
            
            [mockBlogSyncFacade verify];
        });
        
        it(@"should show jetpack authentication when the blog syncing facade tells it to", ^{
            [[mockViewModelDelegate expect] showJetpackAuthentication:OCMOCK_ANY];
            
            // Retrieve jetpack block and execute it when appropriate
            [OCMStub([mockBlogSyncFacade syncBlogForAccount:OCMOCK_ANY username:username password:password xmlrpc:xmlrpc options:options needsJetpack:OCMOCK_ANY finishedSync:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
                void (^ __unsafe_unretained jetpackStub)(void);
                [invocation getArgument:&jetpackStub atIndex:7];
                
                jetpackStub();
            }];
            
            [viewModel finishedLoginWithUsername:username password:password xmlrpc:xmlrpc options:options];
            
            [mockViewModelDelegate verify];
        });
        
        it(@"should dismiss the login view", ^{
            [[mockViewModelDelegate expect] dismissLoginView];
            
            // Retrieve finishedSync block and execute it when appropriate
            [OCMStub([mockBlogSyncFacade syncBlogForAccount:OCMOCK_ANY username:username password:password xmlrpc:xmlrpc options:options needsJetpack:OCMOCK_ANY finishedSync:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
                void (^ __unsafe_unretained finishedSyncStub)(void);
                [invocation getArgument:&finishedSyncStub atIndex:8];
                
                finishedSyncStub();
            }];
            
            [viewModel finishedLoginWithUsername:username password:password xmlrpc:xmlrpc options:options];
            
            [mockViewModelDelegate verify];
        });
    });
    
});

describe(@"toggleSignInFormAction", ^{
    
    it(@"should flag shoulDisplayMultifactorToFalse", ^{
        viewModel.shouldDisplayMultifactor = YES;
        
        [viewModel toggleSignInFormAction];
        
        expect(viewModel.shouldDisplayMultifactor).to.equal(NO);
    });
    
    it(@"should toggle userIsDotCom", ^{
        viewModel.userIsDotCom = YES;
        
        [viewModel toggleSignInFormAction];
        expect(viewModel.userIsDotCom).to.equal(NO);
        
        [viewModel toggleSignInFormAction];
        expect(viewModel.userIsDotCom).to.equal(YES);
    });
    
    it(@"should set the returnKeyType of passwordText to UIReturnKeyDone when the user is a self hosted user", ^{
        viewModel.userIsDotCom = NO;
        [[mockViewModelDelegate expect] setPasswordTextReturnKeyType:UIReturnKeyDone];
        
        [viewModel toggleSignInFormAction];
        
        [mockViewModelDelegate verify];
    });
    
    it(@"should set the returnKeyType of passwordText to UIReturnKeyNext when the user is a .com user", ^{
        viewModel.userIsDotCom = YES;
        [[mockViewModelDelegate expect] setPasswordTextReturnKeyType:UIReturnKeyNext];
        
        [viewModel toggleSignInFormAction];
        
        [mockViewModelDelegate verify];
    });
    
    it(@"should tell the view to reload it's interface", ^{
        [[mockViewModelDelegate expect] reloadInterfaceWithAnimation:YES];
        
        [viewModel toggleSignInFormAction];
        
        [mockViewModelDelegate verify];
    });
    
});

describe(@"displayMultifactorTextField", ^{
    
    it(@"should set shouldDisplayMultifactor to true", ^{
        viewModel.shouldDisplayMultifactor = NO;
        
        [viewModel displayMultifactorTextField];
        
        expect(viewModel.shouldDisplayMultifactor).to.equal(YES);
    });
    
    it(@"should reload the interface", ^{
        [[mockViewModelDelegate expect] reloadInterfaceWithAnimation:YES];
        
        [viewModel displayMultifactorTextField];
        
        [mockViewModelDelegate verify];
    });
    
    it(@"should set the focus to the multifactor text field", ^{
        [[mockViewModelDelegate expect] setFocusToMultifactorText];
        
        [viewModel displayMultifactorTextField];
        
        [mockViewModelDelegate verify];
    });
});

describe(@"requestOneTimeCode", ^{
    
    it(@"should pass on the request to the oauth client facade", ^{
        [[mockLoginFacade expect] requestOneTimeCodeWithLoginFields:OCMOCK_ANY];
        
        [viewModel requestOneTimeCode];
        
        [mockLoginFacade verify];
    });
});

describe(@"sendVerificationCodeButton visibility", ^{
    
    context(@"when authenticating", ^{
        
        it(@"should not be visible if the multifactor controls enabled", ^{
            [[mockViewModelDelegate expect] setSendVerificationCodeButtonHidden:YES];
            
            viewModel.authenticating = YES;
            viewModel.shouldDisplayMultifactor = YES;
            
            [mockViewModelDelegate verify];
        });
        
        it(@"should not be visible if the multifactor controls aren't enabled", ^{
            [[mockViewModelDelegate expect] setSendVerificationCodeButtonHidden:YES];
            
            viewModel.authenticating = YES;
            viewModel.shouldDisplayMultifactor = NO;
            
            [mockViewModelDelegate verify];
        });
    });
    
    context(@"when not authenticating", ^{
        
        it(@"should be visible if multifactor controls are enabled", ^{
            [[mockViewModelDelegate expect] setSendVerificationCodeButtonHidden:NO];
            
            viewModel.authenticating = NO;
            viewModel.shouldDisplayMultifactor = YES;
            
            [mockViewModelDelegate verify];
        });
        
        it(@"should not be visible if multifactor controls aren't enabled", ^{
            [[mockViewModelDelegate expect] setSendVerificationCodeButtonHidden:YES];
            
            viewModel.authenticating = NO;
            viewModel.shouldDisplayMultifactor = NO;
            
            [mockViewModelDelegate verify];
        });
    });
    
});

SpecEnd
