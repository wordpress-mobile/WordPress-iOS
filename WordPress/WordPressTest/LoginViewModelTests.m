#import <Specta/Specta.h>
#define EXP_SHORTHAND
#import <Expecta/Expecta.h>
#import <OCMock/OCMock.h>
#import "LoginViewModel.h"

SpecBegin(LoginViewModelTests)

__block LoginViewModel *viewModel;
__block id mockDelegate;
beforeEach(^{
    mockDelegate = [OCMockObject niceMockForProtocol:@protocol(LoginViewModelDelegate)];
    viewModel = [LoginViewModel new];
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

SpecEnd
