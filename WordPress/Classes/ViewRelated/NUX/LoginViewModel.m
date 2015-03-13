#import <ReactiveCocoa/ReactiveCocoa.h>
#import "LoginViewModel.h"

@interface LoginViewModel()

@end


@implementation LoginViewModel

static CGFloat const LoginViewModelAlphaHidden              = 0.0f;
static CGFloat const LoginViewModelAlphaDisabled            = 0.5f;
static CGFloat const LoginViewModelAlphaEnabled             = 1.0f;

- (instancetype)init
{
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    [RACObserve(self, authenticating) subscribeNext:^(NSNumber *authenticating) {
        [self.delegate showActivityIndicator:[authenticating boolValue]];
    }];
    
    [RACObserve(self, shouldDisplayMultifactor) subscribeNext:^(NSNumber *shouldDisplayMultifactor) {
        [self handleShouldDisplayMultifactorChanging:shouldDisplayMultifactor];
    }];
}

- (void)handleShouldDisplayMultifactorChanging:(NSNumber *)shouldDisplayMultifactor {
    if ([shouldDisplayMultifactor boolValue]) {
        [self.delegate setUsernameAlpha:LoginViewModelAlphaDisabled];
        [self.delegate setPasswordAlpha:LoginViewModelAlphaDisabled];
        
        if (self.isSiteUrlEnabled) {
            [self.delegate setSiteAlpha:LoginViewModelAlphaDisabled];
        }
    } else {
        [self.delegate setUsernameAlpha:LoginViewModelAlphaEnabled];
        [self.delegate setPasswordAlpha:LoginViewModelAlphaEnabled];
        if (self.isSiteUrlEnabled) {
            [self.delegate setSiteAlpha:LoginViewModelAlphaEnabled];
        }
    }
    
    if (!self.isSiteUrlEnabled) {
        [self.delegate setSiteAlpha:LoginViewModelAlphaHidden];
    }
}

@end
