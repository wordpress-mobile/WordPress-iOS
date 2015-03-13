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
        [self handleShouldDisplayMultifactorChanged:shouldDisplayMultifactor];
    }];
    
    [RACObserve(self, isUsernameEnabled) subscribeNext:^(NSNumber *isUsernameEnabled) {
        [self.delegate setUsernameEnabled:[isUsernameEnabled boolValue]];
    }];
    
    [RACObserve(self, isPasswordEnabled) subscribeNext:^(NSNumber *isPasswordEnabled) {
        [self.delegate setPasswordEnabled:[isPasswordEnabled boolValue]];
    }];
    
    [RACObserve(self, userIsDotCom) subscribeNext:^(NSNumber *userIsDotCom) {
        self.isSiteUrlEnabled = ![userIsDotCom boolValue];
    }];
    
    [RACObserve(self, isSiteUrlEnabled) subscribeNext:^(NSNumber *isSiteUrlEnabled) {
        [self handleSiteUrlEnabledChanged:isSiteUrlEnabled];
    }];
    
    [RACObserve(self, isMultifactorEnabled) subscribeNext:^(NSNumber *isMultifactorEnabled) {
        [self.delegate setMultifactorEnabled:[isMultifactorEnabled boolValue]];
    }];
}

- (void)handleShouldDisplayMultifactorChanged:(NSNumber *)shouldDisplayMultifactor {
    BOOL displayMultifactor = [shouldDisplayMultifactor boolValue];
    if (displayMultifactor) {
        [self.delegate setUsernameAlpha:LoginViewModelAlphaDisabled];
        [self.delegate setPasswordAlpha:LoginViewModelAlphaDisabled];
        [self.delegate setMultiFactorAlpha:LoginViewModelAlphaEnabled];
    } else {
        [self.delegate setUsernameAlpha:LoginViewModelAlphaEnabled];
        [self.delegate setPasswordAlpha:LoginViewModelAlphaEnabled];
        [self.delegate setMultiFactorAlpha:LoginViewModelAlphaHidden];
    }
    
    self.isUsernameEnabled = !displayMultifactor;
    self.isPasswordEnabled = !displayMultifactor;
    self.isMultifactorEnabled = displayMultifactor;
}

- (void)handleSiteUrlEnabledChanged:(NSNumber *)isSiteUrlEnabled
{
    BOOL siteUrlEnabled = [isSiteUrlEnabled boolValue];
    if (siteUrlEnabled) {
        if (self.shouldDisplayMultifactor) {
            [self.delegate setSiteAlpha:LoginViewModelAlphaDisabled];
        } else {
            [self.delegate setSiteAlpha:LoginViewModelAlphaEnabled];
        }
    } else {
        [self.delegate setSiteAlpha:LoginViewModelAlphaHidden];
    }
    [self.delegate setSiteUrlEnabled:siteUrlEnabled];
}

@end
