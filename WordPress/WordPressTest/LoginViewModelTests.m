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
    
    it(@"should call the delegate's showActivityIndicatoer method when the value changes", ^{
        [[mockDelegate expect] showActivityIndicator:YES];
        viewModel.authenticating = YES;
        [mockDelegate verify];
        
        [[mockDelegate expect] showActivityIndicator:NO];
        viewModel.authenticating = NO;
        [mockDelegate verify];
    });
    
});

describe(@"shouldDisplayMultifactor", ^{
    
    it(@"when true it should set the username's alpha to 0.5", ^{
        [[mockDelegate expect] setUsernameAlpha:0.5];
        viewModel.shouldDisplayMultifactor = YES;
        [mockDelegate verify];
    });
    
    it(@"when false it should set the username's alpha to 1.0", ^{
        [[mockDelegate expect] setUsernameAlpha:1.0];
        viewModel.shouldDisplayMultifactor = NO;
        [mockDelegate verify];
    });
});

SpecEnd
