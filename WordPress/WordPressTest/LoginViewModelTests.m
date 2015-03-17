#import <Specta/Specta.h>
#define EXP_SHORTHAND
#import <Expecta/Expecta.h>
#import <OCMock/OCMock.h>
#import "LoginViewModel.h"
#import "ReachabilityService.h"
#import "LoginService.h"
#import "WordPressComOAuthClientService.h"

SpecBegin(LoginViewModelTests)

__block LoginViewModel *viewModel;
__block id mockDelegate;
__block id mockReachabilityService;
__block id mockLoginService;
__block id mockLoginServiceDelegate;
__block id mockOAuthService;
beforeEach(^{
    mockDelegate = [OCMockObject niceMockForProtocol:@protocol(LoginViewModelDelegate)];
    mockReachabilityService = [OCMockObject niceMockForProtocol:@protocol(ReachabilityService)];
    mockLoginService = [OCMockObject niceMockForProtocol:@protocol(LoginService)];
    mockLoginServiceDelegate = [OCMockObject niceMockForProtocol:@protocol(LoginServiceDelegate)];
    mockOAuthService = [OCMockObject niceMockForProtocol:@protocol(WordPressComOAuthClientService)];
    [OCMStub([mockLoginService wordpressComOAuthClientService]) andReturn:mockOAuthService];
    [OCMStub([mockLoginService delegate]) andReturn:mockLoginServiceDelegate];
    
    viewModel = [LoginViewModel new];
    viewModel.loginService = mockLoginService;
    viewModel.reachabilityService = mockReachabilityService;
    viewModel.delegate = mockDelegate;
});

describe(@"authenticating", ^{
    
    it(@"should call the delegate's showActivityIndicator method when the value changes", ^{
        [[mockDelegate expect] showActivityIndicator:YES];
        viewModel.authenticating = YES;
        [mockDelegate verify];
        
        [[mockDelegate expect] showActivityIndicator:NO];
        viewModel.authenticating = NO;
        [mockDelegate verify];
    });
    
});

describe(@"shouldDisplayMultifactor", ^{
    
    context(@"when it's true", ^{
        
        it(@"should set the username's alpha to 0.5", ^{
            [[mockDelegate expect] setUsernameAlpha:0.5];
            viewModel.shouldDisplayMultifactor = YES;
            [mockDelegate verify];
        });
        
        it(@"should set the password's alpha to 0.5", ^{
            [[mockDelegate expect] setPasswordAlpha:0.5];
            viewModel.shouldDisplayMultifactor = YES;
            [mockDelegate verify];
        });
        
        it(@"should set multifactor's alpha to 1.0", ^{
            [[mockDelegate expect] setMultiFactorAlpha:1.0];
            viewModel.shouldDisplayMultifactor = YES;
            [mockDelegate verify];
        });
    });
    
    context(@"when it's false", ^{
        
        it(@"it should set the username's alpha to 1.0", ^{
            [[mockDelegate expect] setUsernameAlpha:1.0];
            viewModel.shouldDisplayMultifactor = NO;
            [mockDelegate verify];
        });
        
        it(@"should set the password's alpha to 1.0", ^{
            [[mockDelegate expect] setPasswordAlpha:1.0];
            viewModel.shouldDisplayMultifactor = NO;
            [mockDelegate verify];
        });
        
        it(@"should set multifactor's alpha to 0.0", ^{
            [[mockDelegate expect] setMultiFactorAlpha:0.0];
            viewModel.shouldDisplayMultifactor = NO;
            [mockDelegate verify];
        });
    });
});

describe(@"isUsernameEnabled", ^{
    
    context(@"when it's true", ^{
        it(@"should enable the username text field", ^{
            [[mockDelegate expect] setUsernameEnabled:YES];
            viewModel.isUsernameEnabled = YES;
            [mockDelegate verify];
        });
    });
    
    context(@"when it's false", ^{
        it(@"should disable the username text field" , ^{
            [[mockDelegate expect] setUsernameEnabled:NO];
            viewModel.isUsernameEnabled = NO;
            [mockDelegate verify];
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
            [[mockDelegate expect] setPasswordEnabled:YES];
            viewModel.isPasswordEnabled = YES;
            [mockDelegate verify];
        });
    });
    
    context(@"when it's false", ^{
        
        it(@"should disable the password text field" , ^{
            [[mockDelegate expect] setPasswordEnabled:NO];
            viewModel.isPasswordEnabled = NO;
            [mockDelegate verify];
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
        [[mockDelegate expect] setSiteUrlEnabled:YES];
        viewModel.isSiteUrlEnabled = YES;
        [mockDelegate verify];
    });
    
    it(@"when it's false it should disable the site url field", ^{
        [[mockDelegate expect] setSiteUrlEnabled:NO];
        viewModel.isSiteUrlEnabled = NO;
        [mockDelegate verify];
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
        [[mockDelegate expect] setMultifactorEnabled:YES];
        viewModel.isMultifactorEnabled = YES;
        [mockDelegate verify];
    });
    
    it(@"when it's false it should disable the multifactor text field", ^{
        [[mockDelegate expect] setMultifactorEnabled:NO];
        viewModel.isMultifactorEnabled = NO;
        [mockDelegate verify];
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
        [[mockDelegate expect] setCancelButtonHidden:NO];
        viewModel.cancellable = YES;
        [mockDelegate verify];
    });
    
    it(@"when it's false it should hide the cancel button", ^{
        [[mockDelegate expect] setCancelButtonHidden:YES];
        viewModel.cancellable = NO;
        [mockDelegate verify];
    });
});

describe(@"forgot password button's visibility", ^{
    
    context(@"for a .com user", ^{
        
        beforeEach(^{
            viewModel.userIsDotCom = YES;
        });
        
        context(@"who is authenticating", ^{
        
            it(@"should not be visible", ^{
                [[mockDelegate expect] setForgotPasswordHidden:YES];
                viewModel.authenticating = YES;
                [mockDelegate verify];
            });
        });
        
        context(@"who isn't authenticating", ^{
            
            it(@"should be visible", ^{
                [[mockDelegate expect] setForgotPasswordHidden:NO];
                viewModel.authenticating = NO;
                [mockDelegate verify];
            });
            
            it(@"should not be visibile if multifactor auth controls are visible", ^{
                [[mockDelegate expect] setForgotPasswordHidden:YES];
                viewModel.isMultifactorEnabled = YES;
                viewModel.authenticating = NO;
                [mockDelegate verify];
            });
        });
    });
    
    context(@"for a self hosted user", ^{
        
        context(@"who isn't authenticating", ^{
            
            beforeEach(^{
                viewModel.authenticating = NO;
            });
            
            it(@"should not be visible if a url is not present", ^{
                [[mockDelegate expect] setForgotPasswordHidden:YES];
                viewModel.siteUrl = @"";
                [mockDelegate verify];
            });
            
            
            it(@"should be visible if a url is present", ^{
                [[mockDelegate expect] setForgotPasswordHidden:NO];
                viewModel.siteUrl = @"http://www.selfhosted.com";
                [mockDelegate verify];
            });
            
            it(@"should not be visible if multifactor controls are visible", ^{
                [[mockDelegate expect] setForgotPasswordHidden:YES];
                viewModel.isMultifactorEnabled = YES;
                [mockDelegate verify];
            });
        });
        
        context(@"who is authenticating", ^{
            
            beforeEach(^{
                viewModel.authenticating = YES;
            });
            
            it(@"should not be visible if a url is present", ^{
                [[mockDelegate expect] setForgotPasswordHidden:YES];
                viewModel.siteUrl = @"http://www.selfhosted.com";
                [mockDelegate verify];
            });
        });
    });
});

describe(@"skipToCreateAccountButton visibility", ^{
    
    context(@"when authenticating", ^{
        
        it(@"should not be visible if the user has an account", ^{
            [[mockDelegate expect] setAccountCreationButtonHidden:YES];
            viewModel.authenticating = YES;
            viewModel.hasDefaultAccount = YES;
            [mockDelegate verify];
        });
        
        it(@"should not be visible if the user doesn't have an account", ^{
            [[mockDelegate expect] setAccountCreationButtonHidden:YES];
            viewModel.authenticating = YES;
            viewModel.hasDefaultAccount = NO;
            [mockDelegate verify];
        });
    });
    
    context(@"when not authenticating", ^{
        
        it(@"should not be visible if the user has an account", ^{
            [[mockDelegate expect] setAccountCreationButtonHidden:YES];
            viewModel.authenticating = NO;
            viewModel.hasDefaultAccount = YES;
            [mockDelegate verify];
        });
        
        it(@"should be visible if the user doesn't have an account", ^{
            [[mockDelegate expect] setAccountCreationButtonHidden:NO];
            viewModel.authenticating = NO;
            viewModel.hasDefaultAccount = NO;
            [mockDelegate verify];
        });
    });
});

describe(@"signInButtonTitle", ^{
    
    context(@"when multifactor controls are visible", ^{
        
        beforeEach(^{
            viewModel.shouldDisplayMultifactor = YES;
        });
        
        it(@"should be 'Verify'", ^{
            expect(viewModel.signInButtonTitle).to.equal(@"Verify");
        });
        
        it(@"should set the sign in button title to 'Verify'", ^{
            [[mockDelegate expect] setSignInButtonTitle:@"Verify"];
            
            viewModel.shouldDisplayMultifactor = YES;
            
            [mockDelegate verify];
        });
        
        it(@"should be 'Verify' even if user is a .com user", ^{
            viewModel.userIsDotCom = YES;
            expect(viewModel.signInButtonTitle).to.equal(@"Verify");
        });
        
        it(@"should set the sign in button title to 'Verify' even if the user is a .com user", ^{
            [[mockDelegate expect] setSignInButtonTitle:@"Verify"];
            
            viewModel.shouldDisplayMultifactor = YES;
            viewModel.userIsDotCom = YES;
            
            [mockDelegate verify];
        });
    });
    
    context(@"when multifactor controls aren't visible", ^{
        beforeEach(^{
            viewModel.shouldDisplayMultifactor = NO;
        });
        
        it(@"should be 'Sign In' if user is a .com user", ^{
            viewModel.userIsDotCom = YES;
            expect(viewModel.signInButtonTitle).to.equal(@"Sign In");
        });
        
        it(@"should set the sign in button title to 'Sign In' if user is a .com user", ^{
            [[mockDelegate expect] setSignInButtonTitle:@"Sign In"];
            
            viewModel.userIsDotCom = YES;
            
            [mockDelegate verify];
        });
        
        it(@"should be 'Add Site' if user isn't a .com user", ^{
            viewModel.userIsDotCom = NO;
            expect(viewModel.signInButtonTitle).to.equal(@"Add Site");
        });
        
        it(@"should set the sign in button title to 'Add Site' if user isn't a .com user", ^{
            [[mockDelegate expect] setSignInButtonTitle:@"Add Site"];
            
            viewModel.userIsDotCom = NO;
            
            [mockDelegate verify];
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
                [[mockDelegate expect] setSignInButtonEnabled:NO];
                
                viewModel.username = @"";
                viewModel.password = @"";
                
                [mockDelegate verify];
            });
            
            it(@"should be disabled if password is blank", ^{
                [[mockDelegate expect] setSignInButtonEnabled:NO];
                
                viewModel.username = @"username";
                viewModel.password = @"";
                
                [mockDelegate verify];
            });
            
            it(@"should be enabled if username and password are filled", ^{
                [[mockDelegate expect] setSignInButtonEnabled:YES];
                
                viewModel.username = @"username";
                viewModel.password = @"password";
                
                [mockDelegate verify];
            });
        });
        
        context(@"when multifactor authentication controls are visible", ^{
            before(^{
                viewModel.shouldDisplayMultifactor = YES;
                viewModel.username = @"username";
                viewModel.password = @"password";
            });
            
            it(@"should not be enabled if the multifactor code isn't entered", ^{
                [[mockDelegate expect] setSignInButtonEnabled:NO];
                
                viewModel.multifactorCode = @"";
                
                [mockDelegate verify];
            });
            
            it(@"should be enabled if the multifactor code is entered", ^{
                [[mockDelegate expect] setSignInButtonEnabled:YES];
                
                viewModel.multifactorCode = @"123456";
                
                [mockDelegate verify];
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
                [[mockDelegate expect] setSignInButtonEnabled:NO];
                
                viewModel.username = @"";
                viewModel.password = @"";
                viewModel.siteUrl = @"";
                
                [mockDelegate verify];
            });
            
            it(@"should be disabled if password and siteUrl are blank", ^{
                [[mockDelegate expect] setSignInButtonEnabled:NO];
                
                viewModel.username = @"username";
                viewModel.password = @"";
                viewModel.siteUrl = @"";
                
                [mockDelegate verify];
            });
            
            it(@"should be disabled if siteUrl is blank", ^{
                [[mockDelegate expect] setSignInButtonEnabled:NO];
                
                viewModel.username = @"username";
                viewModel.password = @"password";
                viewModel.siteUrl = @"";
                
                [mockDelegate verify];
            });
            
            it(@"should be enabled if username, password and siteUrl are filled", ^{
                [[mockDelegate expect] setSignInButtonEnabled:YES];
                
                viewModel.username = @"username";
                viewModel.password = @"password";
                viewModel.siteUrl = @"http://www.selfhosted.com";
                
                [mockDelegate verify];
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
                [[mockDelegate expect] setSignInButtonEnabled:NO];
                
                viewModel.multifactorCode = @"";
                
                [mockDelegate verify];
            });
            
            it(@"should be enabled if the multifactor code is entered", ^{
                [[mockDelegate expect] setSignInButtonEnabled:YES];
                
                viewModel.multifactorCode = @"123456";
                
                [mockDelegate verify];
            });
        });
    });
});

describe(@"toggleSignInButtonTitle", ^{
    
    it(@"should set the title to 'Add Self-Hosted Site' for a .com user", ^{
        [[mockDelegate expect] setToggleSignInButtonTitle:@"Add Self-Hosted Site"];
        
        viewModel.userIsDotCom = YES;
       
        [mockDelegate verify];
    });
    
    it(@"should set the title to 'Sign in to WordPress.com' for a self hosted user", ^{
        [[mockDelegate expect] setToggleSignInButtonTitle:@"Sign in to WordPress.com"];
        
        viewModel.userIsDotCom = NO;
       
        [mockDelegate verify];
    });
});

describe(@"toggleSignInButton visibility", ^{
    
    it(@"should be hidden if onlyDotComAllowed is true", ^{
        [[mockDelegate expect] setToggleSignInButtonHidden:YES];
        
        viewModel.onlyDotComAllowed = YES;
        
        [mockDelegate verify];
    });
    
    it(@"should be hidden if hasDefaultAccount is true", ^{
        [[mockDelegate expect] setToggleSignInButtonHidden:YES];
        
        viewModel.hasDefaultAccount = YES;
        
        [mockDelegate verify];
    });
    
    it(@"should be hidden during authentication", ^{
        [[mockDelegate expect] setToggleSignInButtonHidden:YES];
        
        viewModel.authenticating = YES;;
        
        [mockDelegate verify];
    });
    
    it(@"should be visible if onlyDotComAllowed, hasDefaultAccount, and authenticating are all false", ^{
        [[mockDelegate expect] setToggleSignInButtonHidden:NO];
        
        viewModel.onlyDotComAllowed = NO;
        viewModel.hasDefaultAccount = NO;
        viewModel.authenticating = NO;
        
        [mockDelegate verify];
    });
});

describe(@"signInButtonAction", ^{
    
    context(@"the checking of the user's internet connection", ^{
        
        it(@"should not show an error message about the internet connection if it's down", ^{
            [OCMStub([mockReachabilityService isInternetReachable]) andReturnValue:@(YES)];
            [[mockReachabilityService reject] showAlertNoInternetConnection];
            
            [viewModel signInButtonAction];
            
            [mockReachabilityService verify];
        });
        
        it(@"should show an error message about the internet connection if it's down", ^{
            [OCMStub([mockReachabilityService isInternetReachable]) andReturnValue:@(NO)];
            [[mockReachabilityService expect] showAlertNoInternetConnection];
            
            [viewModel signInButtonAction];
            
            [mockReachabilityService verify];
        });
    });
    
    context(@"user field validation", ^{
        
        beforeEach(^{
            [OCMStub([mockReachabilityService isInternetReachable]) andReturnValue:@(YES)];
            
            viewModel.username = @"username";
            viewModel.password = @"password";
            viewModel.siteUrl = @"http://www.selfhosted.com";
        });
        
        sharedExamplesFor(@"username and password validation", ^(NSDictionary *data) {
            
            it(@"should display an error message if the username and password are blank", ^{
                viewModel.username = @"";
                viewModel.password = @"";
                [[mockDelegate expect] displayErrorMessageForInvalidOrMissingFields];
                
                [viewModel signInButtonAction];
                
                [mockDelegate verify];
            });
            
            it(@"should display an error message if the username is blank", ^{
                viewModel.username = @"";
                [[mockDelegate expect] displayErrorMessageForInvalidOrMissingFields];
                
                [viewModel signInButtonAction];
                
                [mockDelegate verify];
            });
            
            it(@"should display an error message if the password is blank", ^{
                viewModel.password = @"";
                [[mockDelegate expect] displayErrorMessageForInvalidOrMissingFields];
                
                [viewModel signInButtonAction];
                
                [mockDelegate verify];
            });
            
            it(@"should not display an error message if the fields are filled", ^{
                [[mockDelegate reject] displayErrorMessageForInvalidOrMissingFields];
                
                [viewModel signInButtonAction];
                
                [mockDelegate verify];
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
                [[mockDelegate expect] displayErrorMessageForInvalidOrMissingFields];
                
                [viewModel signInButtonAction];
                
                [mockDelegate verify];
            });
            
            it(@"should not display an error if the fields are filled", ^{
                [[mockDelegate reject] displayErrorMessageForInvalidOrMissingFields];
                
                [viewModel signInButtonAction];
                
                [mockDelegate verify];
            });
        });
    });
    
    context(@"verification of non reserved username", ^{
        
        beforeEach(^{
            [OCMStub([mockReachabilityService isInternetReachable]) andReturnValue:@(YES)];
            
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
                    [[mockDelegate expect] displayReservedNameErrorMessage];
                    
                    [viewModel signInButtonAction];
                    
                    [mockDelegate verify];
                });
                
                testName = [NSString stringWithFormat:@"should bring focus to siteUrlText if the username is '%@'", reservedName];
                it(testName, ^{
                    [[mockDelegate expect] setFocusToSiteUrlText];
                    
                    [viewModel signInButtonAction];
                    
                    [mockDelegate verify];
                });
                
                testName = [NSString stringWithFormat:@"should adjust passwordText's return key type to UIReturnKeyNext"];
                it(testName, ^{
                    [mockDelegate setPasswordTextReturnKeyType:UIReturnKeyNext];
                    
                    [viewModel signInButtonAction];
                    
                    [mockDelegate verify];
                });
                
                testName = [NSString stringWithFormat:@"should reload the interface"];
                it(testName, ^{
                    [[mockDelegate expect] reloadInterfaceWithAnimation:YES];
                    
                    [viewModel signInButtonAction];
                    
                    [mockDelegate verify];
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
                    [[mockDelegate reject] displayReservedNameErrorMessage];
                    
                    [viewModel signInButtonAction];
                    
                    [mockDelegate verify];
                });
            });
            
        }
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
        [[mockDelegate expect] setPasswordTextReturnKeyType:UIReturnKeyDone];
        
        [viewModel toggleSignInFormAction];
        
        [mockDelegate verify];
    });
    
    it(@"should set the returnKeyType of passwordText to UIReturnKeyNext when the user is a .com user", ^{
        viewModel.userIsDotCom = YES;
        [[mockDelegate expect] setPasswordTextReturnKeyType:UIReturnKeyNext];
        
        [viewModel toggleSignInFormAction];
        
        [mockDelegate verify];
    });
    
    it(@"should tell the view to reload it's interface", ^{
        [[mockDelegate expect] reloadInterfaceWithAnimation:YES];
        
        [viewModel toggleSignInFormAction];
        
        [mockDelegate verify];
    });
    
});

describe(@"displayMultifactorTextField", ^{
    
    it(@"should set shouldDisplayMultifactor to true", ^{
        viewModel.shouldDisplayMultifactor = NO;
        
        [viewModel displayMultifactorTextField];
        
        expect(viewModel.shouldDisplayMultifactor).to.equal(YES);
    });
    
    it(@"should reload the interface", ^{
        [[mockDelegate expect] reloadInterfaceWithAnimation:YES];
        
        [viewModel displayMultifactorTextField];
        
        [mockDelegate verify];
    });
    
    it(@"should set the focus to the multifactor text field", ^{
        [[mockDelegate expect] setFocusToMultifactorText];
        
        [viewModel displayMultifactorTextField];
        
        [mockDelegate verify];
    });
});

describe(@"sendVerificationCodeButton visibility", ^{
    
    context(@"when authenticating", ^{
        
        it(@"should not be visible if the multifactor controls enabled", ^{
            [[mockDelegate expect] setSendVerificationCodeButtonHidden:YES];
            viewModel.authenticating = YES;
            viewModel.shouldDisplayMultifactor = YES;
            [mockDelegate verify];
        });
        
        it(@"should not be visible if the multifactor controls aren't enabled", ^{
            [[mockDelegate expect] setSendVerificationCodeButtonHidden:YES];
            viewModel.authenticating = YES;
            viewModel.shouldDisplayMultifactor = NO;
            [mockDelegate verify];
        });
    });
    
    context(@"when not authenticating", ^{
        
        it(@"should be visible if multifactor controls are enabled", ^{
            [[mockDelegate expect] setSendVerificationCodeButtonHidden:NO];
            viewModel.authenticating = NO;
            viewModel.shouldDisplayMultifactor = YES;
            [mockDelegate verify];
        });
        
        it(@"should not be visible if multifactor controls aren't enabled", ^{
            [[mockDelegate expect] setSendVerificationCodeButtonHidden:YES];
            viewModel.authenticating = NO;
            viewModel.shouldDisplayMultifactor = NO;
            [mockDelegate verify];
        });
    });
    
});

SpecEnd
