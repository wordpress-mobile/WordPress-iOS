#import <Specta/Specta.h>
#define EXP_SHORTHAND
#import <Expecta/Expecta.h>
#import <OCMock/OCMock.h>
#import "LoginViewModel.h"
#import "ReachabilityFacade.h"
#import "LoginFacade.h"
#import "WordPressComOAuthClientFacade.h"
#import "WordPressXMLRPCAPIFacade.h"
#import "AccountServiceFacade.h"
#import "BlogSyncFacade.h"
#import "HelpshiftEnabledFacade.h"
#import "OnePasswordFacade.h"
#import <WPXMLRPC/WPXMLRPC.h>
#import "WPWalkthroughOverlayView.h"

SpecBegin(LoginViewModel)

__block LoginViewModel *viewModel;
__block id mockViewModelPresenter;
__block id mockReachabilityFacade;
__block id mockLoginFacade;
__block id mockLoginFacadeDelegate;
__block id mockOAuthFacade;
__block id mockXMLRPCFacade;
__block id mockAccountServiceFacade;
__block id mockBlogSyncFacade;
__block id mockHelpshiftEnabledFacade;
__block id mockOnePasswordFacade;

beforeEach(^{
    mockViewModelPresenter = [OCMockObject niceMockForProtocol:@protocol(LoginViewModelPresenter)];
    mockReachabilityFacade = [OCMockObject niceMockForProtocol:@protocol(ReachabilityFacade)];
    mockLoginFacade = [OCMockObject niceMockForProtocol:@protocol(LoginFacade)];
    mockLoginFacadeDelegate = [OCMockObject niceMockForProtocol:@protocol(LoginFacadeDelegate)];
    mockOAuthFacade = [OCMockObject niceMockForProtocol:@protocol(WordPressComOAuthClientFacade)];
    mockXMLRPCFacade = [OCMockObject niceMockForProtocol:@protocol(WordPressXMLRPCAPIFacade)];
    mockAccountServiceFacade = [OCMockObject niceMockForProtocol:@protocol(AccountServiceFacade)];
    mockBlogSyncFacade = [OCMockObject niceMockForProtocol:@protocol(BlogSyncFacade)];
    mockHelpshiftEnabledFacade = [OCMockObject niceMockForProtocol:@protocol(HelpshiftEnabledFacade)];
    mockOnePasswordFacade = [OCMockObject niceMockForProtocol:@protocol(OnePasswordFacade)];
    [OCMStub([mockLoginFacade wordpressComOAuthClientFacade]) andReturn:mockOAuthFacade];
    [OCMStub([mockLoginFacade wordpressXMLRPCAPIFacade]) andReturn:mockXMLRPCFacade];
    [OCMStub([mockLoginFacade delegate]) andReturn:mockLoginFacadeDelegate];
    
    viewModel = [LoginViewModel new];
    viewModel.loginFacade = mockLoginFacade;
    viewModel.reachabilityFacade = mockReachabilityFacade;
    viewModel.presenter = mockViewModelPresenter;
    viewModel.accountServiceFacade = mockAccountServiceFacade;
    viewModel.blogSyncFacade = mockBlogSyncFacade;
    viewModel.helpshiftEnabledFacade = mockHelpshiftEnabledFacade;
    viewModel.onePasswordFacade = mockOnePasswordFacade;
});

describe(@"authenticating", ^{
    
    it(@"should show the activity indicator when authenticating", ^{
        [[mockViewModelPresenter expect] showActivityIndicator:YES];
        
        viewModel.authenticating = YES;
        
        [mockViewModelPresenter verify];
    });
    
    it(@"should hide the activity indicator when not authenticating", ^{
        [[mockViewModelPresenter expect] showActivityIndicator:NO];
        
        viewModel.authenticating = NO;
        
        [mockViewModelPresenter verify];
    });
    
});

describe(@"shouldDisplayMultifactor", ^{
    
    context(@"when it's true", ^{
        
        it(@"should set the username's alpha to 0.5", ^{
            [[mockViewModelPresenter expect] setUsernameAlpha:0.5];
            
            viewModel.shouldDisplayMultifactor = YES;
            
            [mockViewModelPresenter verify];
        });
        
        it(@"should set the password's alpha to 0.5", ^{
            [[mockViewModelPresenter expect] setPasswordAlpha:0.5];
            
            viewModel.shouldDisplayMultifactor = YES;
            
            [mockViewModelPresenter verify];
        });
        
        it(@"should set multifactor's alpha to 1.0", ^{
            [[mockViewModelPresenter expect] setMultiFactorAlpha:1.0];
            
            viewModel.shouldDisplayMultifactor = YES;
            
            [mockViewModelPresenter verify];
        });
    });
    
    context(@"when it's false", ^{
        
        it(@"it should set the username's alpha to 1.0", ^{
            [[mockViewModelPresenter expect] setUsernameAlpha:1.0];
            
            viewModel.shouldDisplayMultifactor = NO;
            
            [mockViewModelPresenter verify];
        });
        
        it(@"should set the password's alpha to 1.0", ^{
            [[mockViewModelPresenter expect] setPasswordAlpha:1.0];
            
            viewModel.shouldDisplayMultifactor = NO;
            
            [mockViewModelPresenter verify];
        });
        
        it(@"should set multifactor's alpha to 0.0", ^{
            [[mockViewModelPresenter expect] setMultiFactorAlpha:0.0];
            
            viewModel.shouldDisplayMultifactor = NO;
            
            [mockViewModelPresenter verify];
        });
    });
});

describe(@"isUsernameEnabled", ^{
    
    context(@"when it's true", ^{
        
        it(@"should enable the username text field", ^{
            [[mockViewModelPresenter expect] setUsernameEnabled:YES];
            
            viewModel.isUsernameEnabled = YES;
            
            [mockViewModelPresenter verify];
        });
    });
    
    context(@"when it's false", ^{
        
        it(@"should disable the username text field" , ^{
            [[mockViewModelPresenter expect] setUsernameEnabled:NO];
            
            viewModel.isUsernameEnabled = NO;
            
            [mockViewModelPresenter verify];
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
            [[mockViewModelPresenter expect] setPasswordEnabled:YES];
            
            viewModel.isPasswordEnabled = YES;
            
            [mockViewModelPresenter verify];
        });
    });
    
    context(@"when it's false", ^{
        
        it(@"should disable the password text field" , ^{
            [[mockViewModelPresenter expect] setPasswordEnabled:NO];
            
            viewModel.isPasswordEnabled = NO;
            
            [mockViewModelPresenter verify];
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
        [[mockViewModelPresenter expect] setSiteUrlEnabled:YES];
        
        viewModel.isSiteUrlEnabled = YES;
        
        [mockViewModelPresenter verify];
    });
    
    it(@"when it's false it should disable the site url field", ^{
        [[mockViewModelPresenter expect] setSiteUrlEnabled:NO];
        
        viewModel.isSiteUrlEnabled = NO;
        
        [mockViewModelPresenter verify];
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
        [[mockViewModelPresenter expect] setMultifactorEnabled:YES];
        
        viewModel.isMultifactorEnabled = YES;
        
        [mockViewModelPresenter verify];
    });
    
    it(@"when it's false it should disable the multifactor text field", ^{
        [[mockViewModelPresenter expect] setMultifactorEnabled:NO];
        
        viewModel.isMultifactorEnabled = NO;
        
        [mockViewModelPresenter verify];
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
        [[mockViewModelPresenter expect] setCancelButtonHidden:NO];
        
        viewModel.cancellable = YES;
        
        [mockViewModelPresenter verify];
    });
    
    it(@"when it's false it should hide the cancel button", ^{
        [[mockViewModelPresenter expect] setCancelButtonHidden:YES];
        
        viewModel.cancellable = NO;
        
        [mockViewModelPresenter verify];
    });
});

describe(@"forgot password button's visibility", ^{
    
    context(@"for a .com user", ^{
        
        beforeEach(^{
            viewModel.userIsDotCom = YES;
        });
        
        context(@"who is authenticating", ^{
        
            it(@"should not be visible", ^{
                [[mockViewModelPresenter expect] setForgotPasswordHidden:YES];
                
                viewModel.authenticating = YES;
                
                [mockViewModelPresenter verify];
            });
        });
        
        context(@"who isn't authenticating", ^{
            
            it(@"should be visible", ^{
                [[mockViewModelPresenter expect] setForgotPasswordHidden:NO];
                
                viewModel.authenticating = NO;
                
                [mockViewModelPresenter verify];
            });
            
            it(@"should not be visibile if multifactor auth controls are visible", ^{
                [[mockViewModelPresenter expect] setForgotPasswordHidden:YES];
                
                viewModel.isMultifactorEnabled = YES;
                viewModel.authenticating = NO;
                
                [mockViewModelPresenter verify];
            });
        });
    });
    
    context(@"for a self hosted user", ^{
        
        context(@"who isn't authenticating", ^{
            
            beforeEach(^{
                viewModel.authenticating = NO;
            });
            
            it(@"should not be visible if a url is not present", ^{
                [[mockViewModelPresenter expect] setForgotPasswordHidden:YES];
                
                viewModel.siteUrl = @"";
                
                [mockViewModelPresenter verify];
            });
            
            
            it(@"should be visible if a url is present", ^{
                [[mockViewModelPresenter expect] setForgotPasswordHidden:NO];
                
                viewModel.siteUrl = @"http://www.selfhosted.com";
                
                [mockViewModelPresenter verify];
            });
            
            it(@"should not be visible if multifactor controls are visible", ^{
                [[mockViewModelPresenter expect] setForgotPasswordHidden:YES];
                
                viewModel.isMultifactorEnabled = YES;
                
                [mockViewModelPresenter verify];
            });
        });
        
        context(@"who is authenticating", ^{
            
            beforeEach(^{
                viewModel.authenticating = YES;
            });
            
            it(@"should not be visible if a url is present", ^{
                [[mockViewModelPresenter expect] setForgotPasswordHidden:YES];
                
                viewModel.siteUrl = @"http://www.selfhosted.com";
                
                [mockViewModelPresenter verify];
            });
        });
    });
});

describe(@"skipToCreateAccountButton visibility", ^{
    
    context(@"when authenticating", ^{
        
        it(@"should not be visible if the user has an account", ^{
            [[mockViewModelPresenter expect] setAccountCreationButtonHidden:YES];
            
            viewModel.authenticating = YES;
            viewModel.hasDefaultAccount = YES;
            
            [mockViewModelPresenter verify];
        });
        
        it(@"should not be visible if the user doesn't have an account", ^{
            [[mockViewModelPresenter expect] setAccountCreationButtonHidden:YES];
            
            viewModel.authenticating = YES;
            viewModel.hasDefaultAccount = NO;
            
            [mockViewModelPresenter verify];
        });
    });
    
    context(@"when not authenticating", ^{
        
        it(@"should not be visible if the user has an account", ^{
            [[mockViewModelPresenter expect] setAccountCreationButtonHidden:YES];
            
            viewModel.authenticating = NO;
            viewModel.hasDefaultAccount = YES;
            
            [mockViewModelPresenter verify];
        });
        
        it(@"should be visible if the user doesn't have an account", ^{
            [[mockViewModelPresenter expect] setAccountCreationButtonHidden:NO];
            
            viewModel.authenticating = NO;
            viewModel.hasDefaultAccount = NO;
            
            [mockViewModelPresenter verify];
        });
    });
});

describe(@"the sign in button title", ^{
    
    context(@"when multifactor controls are visible", ^{
        
        beforeEach(^{
            viewModel.shouldDisplayMultifactor = YES;
        });
        
        it(@"should set the sign in button title to 'Verify'", ^{
            [[mockViewModelPresenter expect] setSignInButtonTitle:@"Verify"];
            
            viewModel.shouldDisplayMultifactor = YES;
            
            [mockViewModelPresenter verify];
        });
        
        it(@"should set the sign in button title to 'Verify' even if the user is a .com user", ^{
            [[mockViewModelPresenter expect] setSignInButtonTitle:@"Verify"];
            
            viewModel.shouldDisplayMultifactor = YES;
            viewModel.userIsDotCom = YES;
            
            [mockViewModelPresenter verify];
        });
    });
    
    context(@"when multifactor controls aren't visible", ^{
        beforeEach(^{
            viewModel.shouldDisplayMultifactor = NO;
        });
        
        it(@"should set the sign in button title to 'Sign In' if user is a .com user", ^{
            [[mockViewModelPresenter expect] setSignInButtonTitle:@"Sign In"];
            
            viewModel.userIsDotCom = YES;
            
            [mockViewModelPresenter verify];
        });
        
        it(@"should set the sign in button title to 'Add Site' if user isn't a .com user", ^{
            [[mockViewModelPresenter expect] setSignInButtonTitle:@"Add Site"];
            
            viewModel.userIsDotCom = NO;
            
            [mockViewModelPresenter verify];
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
                [[mockViewModelPresenter expect] setSignInButtonEnabled:NO];
                
                viewModel.username = @"";
                viewModel.password = @"";
                
                [mockViewModelPresenter verify];
            });
            
            it(@"should be disabled if password is blank", ^{
                [[mockViewModelPresenter expect] setSignInButtonEnabled:NO];
                
                viewModel.username = @"username";
                viewModel.password = @"";
                
                [mockViewModelPresenter verify];
            });
            
            it(@"should be enabled if username and password are filled", ^{
                [[mockViewModelPresenter expect] setSignInButtonEnabled:YES];
                
                viewModel.username = @"username";
                viewModel.password = @"password";
                
                [mockViewModelPresenter verify];
            });
        });
        
        context(@"when multifactor authentication controls are visible", ^{
            
            before(^{
                viewModel.shouldDisplayMultifactor = YES;
                viewModel.username = @"username";
                viewModel.password = @"password";
            });
            
            it(@"should not be enabled if the multifactor code isn't entered", ^{
                [[mockViewModelPresenter expect] setSignInButtonEnabled:NO];
                
                viewModel.multifactorCode = @"";
                
                [mockViewModelPresenter verify];
            });
            
            it(@"should be enabled if the multifactor code is entered", ^{
                [[mockViewModelPresenter expect] setSignInButtonEnabled:YES];
                
                viewModel.multifactorCode = @"123456";
                
                [mockViewModelPresenter verify];
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
                [[mockViewModelPresenter expect] setSignInButtonEnabled:NO];
                
                viewModel.username = @"";
                viewModel.password = @"";
                viewModel.siteUrl = @"";
                
                [mockViewModelPresenter verify];
            });
            
            it(@"should be disabled if password and siteUrl are blank", ^{
                [[mockViewModelPresenter expect] setSignInButtonEnabled:NO];
                
                viewModel.username = @"username";
                viewModel.password = @"";
                viewModel.siteUrl = @"";
                
                [mockViewModelPresenter verify];
            });
            
            it(@"should be disabled if siteUrl is blank", ^{
                [[mockViewModelPresenter expect] setSignInButtonEnabled:NO];
                
                viewModel.username = @"username";
                viewModel.password = @"password";
                viewModel.siteUrl = @"";
                
                [mockViewModelPresenter verify];
            });
            
            it(@"should be enabled if username, password and siteUrl are filled", ^{
                [[mockViewModelPresenter expect] setSignInButtonEnabled:YES];
                
                viewModel.username = @"username";
                viewModel.password = @"password";
                viewModel.siteUrl = @"http://www.selfhosted.com";
                
                [mockViewModelPresenter verify];
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
                [[mockViewModelPresenter expect] setSignInButtonEnabled:NO];
                
                viewModel.multifactorCode = @"";
                
                [mockViewModelPresenter verify];
            });
            
            it(@"should be enabled if the multifactor code is entered", ^{
                [[mockViewModelPresenter expect] setSignInButtonEnabled:YES];
                
                viewModel.multifactorCode = @"123456";
                
                [mockViewModelPresenter verify];
            });
        });
    });
});

describe(@"onePasswordButtonActionForViewController", ^{
    
    __block id mockViewController;
    __block id mockSender;
    before(^{
        mockViewController = [OCMockObject niceMockForClass:[UIViewController class]];
        mockSender = [OCMockObject niceMockForClass:[UIButton class]];
    });
    
    __block NSError *error;
    __block NSString *username;
    __block NSString *password;
    
    void (^forceOnePasswordExtensionCallbackToExecute)() = ^{
        [OCMStub([mockOnePasswordFacade findLoginForURLString:OCMOCK_ANY viewController:OCMOCK_ANY sender:OCMOCK_ANY completion:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
            void (^ __unsafe_unretained callback)(NSString *, NSString *, NSError *);
            [invocation getArgument:&callback atIndex:5];
            
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
                [[mockViewModelPresenter reject] setUsernameTextValue:OCMOCK_ANY];
                [[mockViewModelPresenter reject] setPasswordTextValue:OCMOCK_ANY];
                
                [viewModel onePasswordButtonActionForViewController:mockViewController sender:mockSender];
                
                [mockViewModelPresenter verify];
            });
            
            it(@"shouldn't attempt to sign in", ^{
                [OCMStub([viewModel signInButtonAction]) andDo:^(NSInvocation *invocation) {
                    XCTFail(@"Shouldn't get here");
                }];
                
                [viewModel onePasswordButtonActionForViewController:mockViewController sender:mockSender];
            });
        });
        
        
        context(@"there is an error", ^{
            
            beforeEach(^{
                error = [NSError errorWithDomain:@"com.wordpress" code:-1 userInfo:@{}];
            });
            
            it(@"shoudln't attempt to set username/password", ^{
                [[mockViewModelPresenter reject] setUsernameTextValue:OCMOCK_ANY];
                [[mockViewModelPresenter reject] setPasswordTextValue:OCMOCK_ANY];
                
                [viewModel onePasswordButtonActionForViewController:mockViewController sender:mockSender];
                
                [mockViewModelPresenter verify];
            });
            
            it(@"shoudln't attempt to sign in", ^{
                [OCMStub([viewModel signInButtonAction]) andDo:^(NSInvocation *invocation) {
                    XCTFail(@"Shouldn't get here");
                }];
                
                [viewModel onePasswordButtonActionForViewController:mockViewController sender:mockSender];
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
            [[mockViewModelPresenter expect] setUsernameTextValue:viewModel.username];
            [[mockViewModelPresenter expect] setPasswordTextValue:viewModel.password];
            
            [viewModel onePasswordButtonActionForViewController:mockViewController sender:mockSender];
            
            [mockViewModelPresenter verify];
        });
        
        it(@"should attempt to sign in", ^{
            __block BOOL signInAttempted = NO;
            [OCMStub([viewModel signInButtonAction]) andDo:^(NSInvocation *invocation) {
                signInAttempted = YES;
            }];
            
            [viewModel onePasswordButtonActionForViewController:mockViewController sender:mockSender];
            
            expect(signInAttempted).to.beTruthy();
        });
    });
    
    NSString *sharedExamplesForBugWhereKeyboardWasntDismissedBeforeOpeningExtension = @"the dismissal of the keyboard before opening the extension";
    sharedExamplesFor(sharedExamplesForBugWhereKeyboardWasntDismissedBeforeOpeningExtension, ^(NSDictionary *data) {
        
        // https://github.com/wordpress-mobile/WordPress-iOS/issues/344
        it(@"should occur", ^{
            [[mockViewModelPresenter expect] endViewEditing];
            
            [viewModel onePasswordButtonActionForViewController:mockViewController sender:mockSender];
            
            [mockViewModelPresenter verify];
        });
    });
    
    
    
    
    context(@"for a self hosted user", ^{
        
        beforeEach(^{
            viewModel.userIsDotCom = NO;
            viewModel.siteUrl = @"http://www.selfhosted.com";
        });
        
        it(@"if the user doesn't have a site url it should display an error", ^{
            viewModel.siteUrl = @"";
            [[mockViewModelPresenter expect] displayOnePasswordEmptySiteAlert];
            
            [viewModel onePasswordButtonActionForViewController:mockViewController sender:mockSender];
            
            [mockViewModelPresenter verify];
        });
        
        it(@"if the user has a site url it should not display an error", ^{
            [[mockViewModelPresenter reject] displayOnePasswordEmptySiteAlert];
            
            [viewModel onePasswordButtonActionForViewController:mockViewController sender:mockSender];
            
            [mockViewModelPresenter verify];
        });
        
        it(@"should use OnePassword to find the users credentials", ^{
            [[mockOnePasswordFacade expect] findLoginForURLString:viewModel.siteUrl viewController:mockViewController sender:OCMOCK_ANY completion:OCMOCK_ANY];
            
            [viewModel onePasswordButtonActionForViewController:mockViewController sender:mockSender];
            
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
            [[mockOnePasswordFacade expect] findLoginForURLString:@"wordpress.com" viewController:mockViewController sender:OCMOCK_ANY completion:OCMOCK_ANY];
            
            [viewModel onePasswordButtonActionForViewController:mockViewController sender:mockSender];
            
            [mockOnePasswordFacade verify];
        });
        
        itShouldBehaveLike(sharedExamplesForABlankResponseOrAnError, nil);
        itShouldBehaveLike(sharedExamplesForValidData, nil);
        itShouldBehaveLike(sharedExamplesForBugWhereKeyboardWasntDismissedBeforeOpeningExtension, nil);
    });
});

describe(@"displayRemoteError", ^{
    
    __block NSError *error;
    NSString *errorMessage = @"Error";
    NSString *defaultFirstButtonText = NSLocalizedString(@"OK", nil);
    NSString *defaultSecondButtonText = NSLocalizedString(@"Need Help?", nil);
    __block id mockOverlayView;
    
    NSString *sharedExamplesForPrimaryButtonThatDismissesOverlay = @"a primary button that dismisses the overlay";
    sharedExamplesFor(sharedExamplesForPrimaryButtonThatDismissesOverlay, ^(NSDictionary *data) {
        
        context(@"when the primary button is pressed", ^{
            
            it(@"should dismiss the overlay", ^{
                [OCMStub([mockViewModelPresenter displayOverlayViewWithMessage:OCMOCK_ANY firstButtonText:OCMOCK_ANY firstButtonCallback:OCMOCK_ANY secondButtonText:OCMOCK_ANY secondButtonCallback:OCMOCK_ANY accessibilityIdentifier:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
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
            [[mockViewModelPresenter expect] displayHelpViewControllerWithAnimation:NO];
            
            [viewModel displayRemoteError:error];
            
            [mockViewModelPresenter verify];
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
            [[mockViewModelPresenter expect] displayWebViewForURL:[NSURL URLWithString:@"https://apps.wordpress.org/support/#faq-ios-3"] username:nil password:nil];
            
            [viewModel displayRemoteError:error];
            
            [mockViewModelPresenter verify];
        });
    });
    
    void (^overlayViewPrimaryButton)() = ^{
        [OCMStub([mockViewModelPresenter displayOverlayViewWithMessage:OCMOCK_ANY firstButtonText:OCMOCK_ANY firstButtonCallback:OCMOCK_ANY secondButtonText:OCMOCK_ANY secondButtonCallback:OCMOCK_ANY accessibilityIdentifier:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
            void (^ __unsafe_unretained callback)(WPWalkthroughOverlayView *);
            [invocation getArgument:&callback atIndex:4];
            
            callback(mockOverlayView);
        }];
    };
    
    void (^overlayViewSecondaryButton)() = ^{
        [OCMStub([mockViewModelPresenter displayOverlayViewWithMessage:OCMOCK_ANY firstButtonText:OCMOCK_ANY firstButtonCallback:OCMOCK_ANY secondButtonText:OCMOCK_ANY secondButtonCallback:OCMOCK_ANY accessibilityIdentifier:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
            void (^ __unsafe_unretained callback)(WPWalkthroughOverlayView *);
            [invocation getArgument:&callback atIndex:6];
            
            callback(mockOverlayView);
        }];
    };
    
    beforeEach(^{
        mockOverlayView = [OCMockObject niceMockForClass:[WPWalkthroughOverlayView class]];
    });
    
    it(@"should dismiss the login message", ^{
        [[mockViewModelPresenter expect] dismissLoginMessage];
        
        error = [NSError errorWithDomain:@"wordpress.com" code:3 userInfo:@{NSLocalizedDescriptionKey : errorMessage}];
        [viewModel displayRemoteError:error];
        
        [mockViewModelPresenter verify];
    });
   
    context(@"for non XMLRPC errors", ^{
        
        beforeEach(^{
            error = [NSError errorWithDomain:@"wordpress.com" code:3 userInfo:@{NSLocalizedDescriptionKey : errorMessage}];
        });
        
        context(@"when Helpshift is not enabled", ^{
            
            beforeEach(^{
                [[[mockHelpshiftEnabledFacade stub] andReturnValue:@(NO)] isHelpshiftEnabled];
            });
            
            it(@"should display an overlay with a generic error message with the default button labels", ^{
                [[mockViewModelPresenter expect] displayOverlayViewWithMessage:errorMessage firstButtonText:defaultFirstButtonText firstButtonCallback:OCMOCK_ANY secondButtonText:defaultSecondButtonText secondButtonCallback:OCMOCK_ANY accessibilityIdentifier:@"GenericErrorMessage"];
                
                [viewModel displayRemoteError:error];
                
                [mockViewModelPresenter verify];
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
                [[[mockHelpshiftEnabledFacade stub] andReturnValue:@(YES)] isHelpshiftEnabled];
            });
            
            it(@"should display an overlay with a 'Contact Us' button", ^{
                [[mockViewModelPresenter expect] displayOverlayViewWithMessage:errorMessage firstButtonText:defaultFirstButtonText firstButtonCallback:OCMOCK_ANY secondButtonText:NSLocalizedString(@"Contact Us", nil) secondButtonCallback:OCMOCK_ANY accessibilityIdentifier:OCMOCK_ANY];
                
                [viewModel displayRemoteError:error];
                
                [mockViewModelPresenter verify];
            });
            
            itBehavesLike(sharedExamplesForPrimaryButtonThatDismissesOverlay, nil);
            
            context(@"when the overlay's secondary button is pressed", ^{
                
                beforeEach(^{
                    overlayViewSecondaryButton();
                });
                
                it(@"should bring up Helpshift", ^{
                    [[mockViewModelPresenter expect] displayHelpshiftConversationView];
                    
                    [viewModel displayRemoteError:error];
                    
                    [mockViewModelPresenter verify];
                });
            });
        });
    });
    
    context(@"for a bad URL", ^{
        
        beforeEach(^{
            error = [NSError errorWithDomain:@"wordpress.com" code:NSURLErrorBadURL userInfo:@{NSLocalizedDescriptionKey : errorMessage}];
        });
        
        it(@"should display an overlay with a 'Need Help?'", ^{
            [[[mockHelpshiftEnabledFacade stub] andReturnValue:@(YES)] isHelpshiftEnabled];
            [[mockViewModelPresenter expect] displayOverlayViewWithMessage:errorMessage firstButtonText:defaultFirstButtonText firstButtonCallback:OCMOCK_ANY secondButtonText:NSLocalizedString(@"Need Help?", nil) secondButtonCallback:OCMOCK_ANY accessibilityIdentifier:OCMOCK_ANY];
            
            [viewModel displayRemoteError:error];
            
            [mockViewModelPresenter verify];
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
                [[mockViewModelPresenter expect] displayOverlayViewWithMessage:NSLocalizedString(@"Please try entering your login details again.", nil) firstButtonText:OCMOCK_ANY firstButtonCallback:OCMOCK_ANY secondButtonText:OCMOCK_ANY secondButtonCallback:OCMOCK_ANY accessibilityIdentifier:OCMOCK_ANY];
                
                [viewModel displayRemoteError:error];
                
                [mockViewModelPresenter verify];
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
                [[mockViewModelPresenter expect] displayOverlayViewWithMessage:OCMOCK_ANY firstButtonText:NSLocalizedString(@"Enable Now", nil) firstButtonCallback:OCMOCK_ANY secondButtonText:OCMOCK_ANY secondButtonCallback:OCMOCK_ANY accessibilityIdentifier:OCMOCK_ANY];
                
                [viewModel displayRemoteError:error];
                
                [mockViewModelPresenter verify];
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
                    [[mockViewModelPresenter expect] displayWebViewForURL:[NSURL URLWithString:writingOptionsUrl] username:viewModel.username password:viewModel.password];
                    
                    [viewModel displayRemoteError:error];
                    
                    [mockViewModelPresenter verify];
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
                [[mockViewModelPresenter expect] displayOverlayViewWithMessage:NSLocalizedString(@"Sign in failed. Please try again.", nil) firstButtonText:OCMOCK_ANY firstButtonCallback:OCMOCK_ANY secondButtonText:OCMOCK_ANY secondButtonCallback:OCMOCK_ANY accessibilityIdentifier:OCMOCK_ANY];
                
                [viewModel displayRemoteError:error];
                
                [mockViewModelPresenter verify];
            });
            
            it(@"should display an overlay with the default button text", ^{
                [[mockViewModelPresenter expect] displayOverlayViewWithMessage:OCMOCK_ANY firstButtonText:defaultFirstButtonText firstButtonCallback:OCMOCK_ANY secondButtonText:defaultSecondButtonText secondButtonCallback:OCMOCK_ANY accessibilityIdentifier:OCMOCK_ANY];
                
                [viewModel displayRemoteError:error];
                
                [mockViewModelPresenter verify];
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
            
            beforeEach(^{
                error = [NSError errorWithDomain:WPXMLRPCFaultErrorDomain code:NSURLErrorBadURL userInfo:@{NSLocalizedDescriptionKey : errorMessage}];
            });
            
            it(@"should display an overlay with the default button text", ^{
                [[mockViewModelPresenter expect] displayOverlayViewWithMessage:OCMOCK_ANY firstButtonText:defaultFirstButtonText firstButtonCallback:OCMOCK_ANY secondButtonText:defaultSecondButtonText secondButtonCallback:OCMOCK_ANY accessibilityIdentifier:OCMOCK_ANY];
                
                [viewModel displayRemoteError:error];
                
                [mockViewModelPresenter verify];
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
        [[mockViewModelPresenter expect] setToggleSignInButtonTitle:@"Add Self-Hosted Site"];
        
        viewModel.userIsDotCom = YES;
       
        [mockViewModelPresenter verify];
    });
    
    it(@"should set the title to 'Sign in to WordPress.com' for a self hosted user", ^{
        [[mockViewModelPresenter expect] setToggleSignInButtonTitle:@"Sign in to WordPress.com"];
        
        viewModel.userIsDotCom = NO;
       
        [mockViewModelPresenter verify];
    });
});

describe(@"toggleSignInButton visibility", ^{
    
    it(@"should be hidden if onlyDotComAllowed is true", ^{
        [[mockViewModelPresenter expect] setToggleSignInButtonHidden:YES];
        
        viewModel.onlyDotComAllowed = YES;
        
        [mockViewModelPresenter verify];
    });
    
    it(@"should be hidden if hasDefaultAccount is true", ^{
        [[mockViewModelPresenter expect] setToggleSignInButtonHidden:YES];
        
        viewModel.hasDefaultAccount = YES;
        
        [mockViewModelPresenter verify];
    });
    
    it(@"should be hidden during authentication", ^{
        [[mockViewModelPresenter expect] setToggleSignInButtonHidden:YES];
        
        viewModel.authenticating = YES;;
        
        [mockViewModelPresenter verify];
    });
    
    it(@"should be visible if onlyDotComAllowed, hasDefaultAccount, and authenticating are all false", ^{
        [[mockViewModelPresenter expect] setToggleSignInButtonHidden:NO];
        
        viewModel.onlyDotComAllowed = NO;
        viewModel.hasDefaultAccount = NO;
        viewModel.authenticating = NO;
        
        [mockViewModelPresenter verify];
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
                [[mockViewModelPresenter expect] displayErrorMessageForInvalidOrMissingFields];
                
                [viewModel signInButtonAction];
                
                [mockViewModelPresenter verify];
            });
            
            it(@"should display an error message if the username is blank", ^{
                viewModel.username = @"";
                [[mockViewModelPresenter expect] displayErrorMessageForInvalidOrMissingFields];
                
                [viewModel signInButtonAction];
                
                [mockViewModelPresenter verify];
            });
            
            it(@"should display an error message if the password is blank", ^{
                viewModel.password = @"";
                [[mockViewModelPresenter expect] displayErrorMessageForInvalidOrMissingFields];
                
                [viewModel signInButtonAction];
                
                [mockViewModelPresenter verify];
            });
            
            it(@"should not display an error message if the fields are filled", ^{
                [[mockViewModelPresenter reject] displayErrorMessageForInvalidOrMissingFields];
                
                [viewModel signInButtonAction];
                
                [mockViewModelPresenter verify];
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
                [[mockViewModelPresenter expect] displayErrorMessageForInvalidOrMissingFields];
                
                [viewModel signInButtonAction];
                
                [mockViewModelPresenter verify];
            });
            
            it(@"should not display an error if the fields are filled", ^{
                [[mockViewModelPresenter reject] displayErrorMessageForInvalidOrMissingFields];
                
                [viewModel signInButtonAction];
                
                [mockViewModelPresenter verify];
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
                    [[mockViewModelPresenter expect] displayReservedNameErrorMessage];
                    
                    [viewModel signInButtonAction];
                    
                    [mockViewModelPresenter verify];
                });
                
                testName = [NSString stringWithFormat:@"should bring focus to siteUrlText if the username is '%@'", reservedName];
                it(testName, ^{
                    [[mockViewModelPresenter expect] setFocusToSiteUrlText];
                    
                    [viewModel signInButtonAction];
                    
                    [mockViewModelPresenter verify];
                });
                
                testName = [NSString stringWithFormat:@"should adjust passwordText's return key type to UIReturnKeyNext"];
                it(testName, ^{
                    [mockViewModelPresenter setPasswordTextReturnKeyType:UIReturnKeyNext];
                    
                    [viewModel signInButtonAction];
                    
                    [mockViewModelPresenter verify];
                });
                
                testName = [NSString stringWithFormat:@"should reload the interface"];
                it(testName, ^{
                    [[mockViewModelPresenter expect] reloadInterfaceWithAnimation:YES];
                    
                    [viewModel signInButtonAction];
                    
                    [mockViewModelPresenter verify];
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
                    [[mockViewModelPresenter reject] displayReservedNameErrorMessage];
                    
                    [viewModel signInButtonAction];
                    
                    [mockViewModelPresenter verify];
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
        [[mockViewModelPresenter expect] openURLInSafari:[NSURL URLWithString:@"https://wordpress.com/wp-login.php?action=lostpassword&redirect_to=wordpress%3A%2F%2F"]];
        
        [viewModel forgotPasswordButtonAction];
        
        [mockViewModelPresenter verify];
    });
    
    it(@"should open the correct forgot password url for a self hosted site", ^{
        viewModel.userIsDotCom = NO;
        viewModel.siteUrl = @"http://www.selfhosted.com";
        NSString *url = [NSString stringWithFormat:@"%@%@", viewModel.siteUrl, @"/wp-login.php?action=lostpassword&redirect_to=wordpress%3A%2F%2F"];
        [[mockViewModelPresenter expect] openURLInSafari:[NSURL URLWithString:url]];
        
        [viewModel forgotPasswordButtonAction];
        
        [mockViewModelPresenter verify];
    });
});

describe(@"LoginFacadeDelegate methods", ^{
    
    context(@"displayLoginMessage", ^{
        
        it(@"should be passed on to the LoginViewModelDelegate", ^{
            [[mockViewModelPresenter expect] displayLoginMessage:@"Test"];
            
            [viewModel displayLoginMessage:@"Test"];
            
            [mockViewModelPresenter verify];
        });
    });
    
    context(@"needsMultifactorCode", ^{
        
        it(@"should result in the multifactor field being displayed", ^{
            expect(viewModel.shouldDisplayMultifactor).to.beFalsy();
            [[mockViewModelPresenter expect] setFocusToMultifactorText];
            [[mockViewModelPresenter expect] reloadInterfaceWithAnimation:YES];
            
            [viewModel needsMultifactorCode];
            
            expect(viewModel.shouldDisplayMultifactor).to.beTruthy();
            [mockViewModelPresenter verify];
        });
        
        it(@"should dismiss the login message", ^{
            [[mockViewModelPresenter expect] dismissLoginMessage];
            
            [viewModel needsMultifactorCode];
            
            [mockViewModelPresenter verify];
        });
    });
    
    context(@"finishedLoginWithUsername:authToken:requiredMultifactorCode:", ^{
        
        __block NSString *username;
        __block NSString *authToken;
        __block BOOL requiredMultifactorCode;
        
        beforeEach(^{
            username = @"username";
            authToken = @"authtoken";
            requiredMultifactorCode = NO;
        });
        
        it(@"should dismiss the login message", ^{
            [[mockViewModelPresenter expect] dismissLoginMessage];
            
            [viewModel finishedLoginWithUsername:username authToken:authToken requiredMultifactorCode:requiredMultifactorCode];
            
            [mockViewModelPresenter verify];
        });
        
        it(@"should display a message about getting account information", ^{
            [[mockViewModelPresenter expect] displayLoginMessage:NSLocalizedString(@"Getting account information", nil)];
            
            [viewModel finishedLoginWithUsername:username authToken:authToken requiredMultifactorCode:requiredMultifactorCode];
            
            [mockViewModelPresenter verify];
        });
        
        it(@"should create a WPAccount for a .com site", ^{
            [[mockAccountServiceFacade expect] createOrUpdateWordPressComAccountWithUsername:username authToken:authToken];
            
            [viewModel finishedLoginWithUsername:username authToken:authToken requiredMultifactorCode:requiredMultifactorCode];
            
            [mockViewModelPresenter verify];
        });
        
        // https://github.com/wordpress-mobile/WordPress-iOS/issues/3401
        context(@"the removal of the old legacy account", ^{
            
            it(@"should occur if shouldReauthenticateDefaultAccount is true", ^{
                viewModel.shouldReauthenticateDefaultAccount = YES;
                [[mockAccountServiceFacade expect] removeLegacyAccount:username];
                
                [viewModel finishedLoginWithUsername:username authToken:authToken requiredMultifactorCode:requiredMultifactorCode];
                
                [mockAccountServiceFacade verify];
            });
            
            it(@"should not occur if shouldReauthenticateDefaultAccount is false", ^{
                viewModel.shouldReauthenticateDefaultAccount = NO;
                [[mockAccountServiceFacade reject] removeLegacyAccount:username];
                
                [viewModel finishedLoginWithUsername:username authToken:authToken requiredMultifactorCode:requiredMultifactorCode];
                
                [mockAccountServiceFacade verify];
            });
        });
        
        context(@"the syncing of the newly added blogs", ^{
            
            it(@"should occur", ^{
                [[mockBlogSyncFacade expect] syncBlogsForAccount:OCMOCK_ANY success:OCMOCK_ANY failure:OCMOCK_ANY];
                
                [viewModel finishedLoginWithUsername:username authToken:authToken requiredMultifactorCode:requiredMultifactorCode];
                
                [mockViewModelPresenter verify];
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
                    [[mockViewModelPresenter expect] dismissLoginMessage];
                    
                    [viewModel finishedLoginWithUsername:username authToken:authToken requiredMultifactorCode:requiredMultifactorCode];
                    
                    [mockViewModelPresenter verify];
                });
                
                it(@"should indicate dismiss the login view", ^{
                    [[mockViewModelPresenter expect] dismissLoginView];
                    
                    [viewModel finishedLoginWithUsername:username authToken:authToken requiredMultifactorCode:requiredMultifactorCode];
                    
                    [mockViewModelPresenter verify];
                });
                
                it(@"should update the user details for the newly created account", ^{
                    [[mockAccountServiceFacade expect] updateUserDetailsForAccount:OCMOCK_ANY success:OCMOCK_ANY failure:OCMOCK_ANY];
                    
                    [viewModel finishedLoginWithUsername:username authToken:authToken requiredMultifactorCode:requiredMultifactorCode];
                    
                    [mockAccountServiceFacade verify];
                });
            });
            
            context(@"when not successful", ^{
                
                __block NSError *error;
                
                beforeEach(^{
                    // Retrieve failure block and execute it when appropriate
                    [OCMStub([mockBlogSyncFacade syncBlogsForAccount:OCMOCK_ANY success:OCMOCK_ANY failure:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
                        void (^ __unsafe_unretained failureStub)(NSError *);
                        [invocation getArgument:&failureStub atIndex:4];
                        
                        error = [NSError errorWithDomain:@"org.wordpress" code:-1 userInfo:@{ NSLocalizedDescriptionKey : @"Error" }];
                        failureStub(error);
                    }];
                });
                
                it(@"should dismiss the login message", ^{
                    [[mockViewModelPresenter expect] dismissLoginMessage];
                    
                    [viewModel finishedLoginWithUsername:username authToken:authToken requiredMultifactorCode:requiredMultifactorCode];
                    
                    [mockViewModelPresenter verify];
                });
                
                it(@"should display the error", ^{
                    [[mockViewModelPresenter expect] displayOverlayViewWithMessage:OCMOCK_ANY firstButtonText:OCMOCK_ANY firstButtonCallback:OCMOCK_ANY secondButtonText:OCMOCK_ANY secondButtonCallback:OCMOCK_ANY accessibilityIdentifier:OCMOCK_ANY];
                    
                    [viewModel finishedLoginWithUsername:username authToken:authToken requiredMultifactorCode:requiredMultifactorCode];
                    
                    [mockViewModelPresenter verify];
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
            [[mockViewModelPresenter expect] dismissLoginMessage];
            
            [viewModel finishedLoginWithUsername:username password:password xmlrpc:xmlrpc options:options];
            
            [mockViewModelPresenter verify];
        });
        
        it(@"should create a WPAccount for a self hosted site", ^{
            [[mockAccountServiceFacade expect] createOrUpdateSelfHostedAccountWithXmlrpc:xmlrpc username:username andPassword:password];
            
            [viewModel finishedLoginWithUsername:username password:password xmlrpc:xmlrpc options:options];
            
            [mockAccountServiceFacade verify];
        });
        
        it(@"should sync the newly added site", ^{
            [[mockBlogSyncFacade expect] syncBlogForAccount:OCMOCK_ANY username:username password:password xmlrpc:xmlrpc options:options finishedSync:OCMOCK_ANY];
            
            [viewModel finishedLoginWithUsername:username password:password xmlrpc:xmlrpc options:options];
            
            [mockBlogSyncFacade verify];
        });
                
        it(@"should dismiss the login view", ^{
            [[mockViewModelPresenter expect] dismissLoginView];
            
            // Retrieve finishedSync block and execute it when appropriate
            [OCMStub([mockBlogSyncFacade syncBlogForAccount:OCMOCK_ANY username:username password:password xmlrpc:xmlrpc options:options finishedSync:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
                void (^ __unsafe_unretained finishedSyncStub)(void);
                [invocation getArgument:&finishedSyncStub atIndex:7];
                
                finishedSyncStub();
            }];
            
            [viewModel finishedLoginWithUsername:username password:password xmlrpc:xmlrpc options:options];
            
            [mockViewModelPresenter verify];
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
        [[mockViewModelPresenter expect] setPasswordTextReturnKeyType:UIReturnKeyDone];
        
        [viewModel toggleSignInFormAction];
        
        [mockViewModelPresenter verify];
    });
    
    it(@"should set the returnKeyType of passwordText to UIReturnKeyNext when the user is a .com user", ^{
        viewModel.userIsDotCom = YES;
        [[mockViewModelPresenter expect] setPasswordTextReturnKeyType:UIReturnKeyNext];
        
        [viewModel toggleSignInFormAction];
        
        [mockViewModelPresenter verify];
    });
    
    it(@"should tell the view to reload it's interface", ^{
        [[mockViewModelPresenter expect] reloadInterfaceWithAnimation:YES];
        
        [viewModel toggleSignInFormAction];
        
        [mockViewModelPresenter verify];
    });
    
});

describe(@"requestOneTimeCode", ^{
    
    it(@"should pass on the request to the oauth client facade", ^{
        [[mockLoginFacade expect] requestOneTimeCodeWithLoginFields:OCMOCK_ANY];
        [[mockViewModelPresenter expect] showAlertWithMessage:OCMOCK_ANY];
        
        [viewModel requestOneTimeCode];
        
        [mockLoginFacade verify];
    });
});

describe(@"sendVerificationCodeButton visibility", ^{
    
    context(@"when authenticating", ^{
        
        it(@"should not be visible if the multifactor controls enabled", ^{
            [[mockViewModelPresenter expect] setSendVerificationCodeButtonHidden:YES];
            
            viewModel.authenticating = YES;
            viewModel.shouldDisplayMultifactor = YES;
            
            [mockViewModelPresenter verify];
        });
        
        it(@"should not be visible if the multifactor controls aren't enabled", ^{
            [[mockViewModelPresenter expect] setSendVerificationCodeButtonHidden:YES];
            
            viewModel.authenticating = YES;
            viewModel.shouldDisplayMultifactor = NO;
            
            [mockViewModelPresenter verify];
        });
    });
    
    context(@"when not authenticating", ^{
        
        it(@"should be visible if multifactor controls are enabled", ^{
            [[mockViewModelPresenter expect] setSendVerificationCodeButtonHidden:NO];
            
            viewModel.authenticating = NO;
            viewModel.shouldDisplayMultifactor = YES;
            
            [mockViewModelPresenter verify];
        });
        
        it(@"should not be visible if multifactor controls aren't enabled", ^{
            [[mockViewModelPresenter expect] setSendVerificationCodeButtonHidden:YES];
            
            viewModel.authenticating = NO;
            viewModel.shouldDisplayMultifactor = NO;
            
            [mockViewModelPresenter verify];
        });
    });
    
});

SpecEnd
