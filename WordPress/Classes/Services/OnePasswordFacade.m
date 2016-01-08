#import "OnePasswordFacade.h"
#import <OnePasswordExtension/OnePasswordExtension.h>

@implementation OnePasswordFacade

- (void)findLoginForURLString:(NSString *)loginUrl viewController:(UIViewController *)viewController sender:(id)sender completion:(OnePasswordFacadeCallback)completion
{
    NSParameterAssert(viewController != nil);
    NSParameterAssert(sender != nil);
    NSParameterAssert(completion != nil);
    
    [[OnePasswordExtension sharedExtension] findLoginForURLString:loginUrl forViewController:viewController sender:sender completion:^(NSDictionary *loginDict, NSError *error) {
        if (error != nil && error.code != AppExtensionErrorCodeCancelledByUser) {
            completion(nil, nil, nil, error);
        } else {
            NSString *username = loginDict[AppExtensionUsernameKey];
            NSString *password = loginDict[AppExtensionPasswordKey];
            NSString *oneTimePassword = loginDict[AppExtensionTOTPKey];
            
            completion(username, password, oneTimePassword, error);
        }
    }];
}

- (BOOL)isOnePasswordEnabled
{
    return [[OnePasswordExtension sharedExtension] isAppExtensionAvailable];
}

@end
