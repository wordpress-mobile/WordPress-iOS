#import "OnePasswordFacade.h"
#import <1PasswordExtension/OnePasswordExtension.h>

@implementation OnePasswordFacade

- (void)findLoginForURLString:(NSString *)loginUrl viewController:(UIViewController *)viewController completion:(OnePasswordFacadeCallback)completion;
{
    NSParameterAssert(viewController != nil);
    NSParameterAssert(completion != nil);
    
    [[OnePasswordExtension sharedExtension] findLoginForURLString:loginUrl forViewController:viewController sender:nil completion:^(NSDictionary *loginDict, NSError *error) {
        if (error != nil && error.code != AppExtensionErrorCodeCancelledByUser) {
            completion(nil, nil, error);
        } else {
            NSString *username = loginDict[AppExtensionUsernameKey];
            NSString *password = loginDict[AppExtensionPasswordKey];
            completion(username, password, error);
        }
    }];
}

- (BOOL)isOnePasswordEnabled
{
    return [[OnePasswordExtension sharedExtension] isAppExtensionAvailable];
}

@end
