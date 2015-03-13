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
        
        it(@"and isSiteText is enabled it should set the site's alpha to 0.5", ^{
            [[mockDelegate expect] setSiteAlpha:0.5];
            viewModel.isSiteUrlEnabled = YES;
            viewModel.shouldDisplayMultifactor = YES;
            [mockDelegate verify];
        });
        
        it(@"and isSiteText is disabled it should set the site's alpha to 0.0", ^{
            [[mockDelegate expect] setSiteAlpha:0.0];
            viewModel.isSiteUrlEnabled = NO;
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
        
        it(@"and isSiteText is enabled it should set the site's alpha to 1.0", ^{
            [[mockDelegate expect] setSiteAlpha:1.0];
            viewModel.isSiteUrlEnabled = YES;
            viewModel.shouldDisplayMultifactor = NO;
            [mockDelegate verify];
        });
        
        it(@"and isSiteText is disabled it should set the site's alpha to 0.0", ^{
            [[mockDelegate expect] setSiteAlpha:0.0];
            viewModel.isSiteUrlEnabled = NO;
            viewModel.shouldDisplayMultifactor = NO;
            [mockDelegate verify];
        });
    });
    
});

SpecEnd
