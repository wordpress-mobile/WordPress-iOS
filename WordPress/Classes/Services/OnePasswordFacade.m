#import "OnePasswordFacade.h"
#import <OnePasswordExtension/OnePasswordExtension.h>

// Proxy these contants. OnePassword defines them with a #define macro which hides them from Swift.
NSString * const WPOnePasswordTitleKey = AppExtensionTitleKey;
NSString * const WPOnePasswordUsernameKey = AppExtensionUsernameKey;
NSString * const WPOnePasswordPasswordKey = AppExtensionPasswordKey;
NSString * const WPOnePasswordGeneratedPasswordMinLengthKey = AppExtensionGeneratedPasswordMinLengthKey;
NSString * const WPOnePasswordGeneratedPasswordMaxLengthKey = AppExtensionGeneratedPasswordMaxLengthKey;
NSInteger WPOnePasswordErrorCodeCancelledByUser = AppExtensionErrorCodeCancelledByUser;

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


- (void)storeLoginForURLString:(NSString *)URLString
                  loginDetails:(NSDictionary *)loginDetailsDictionary
     passwordGenerationOptions:(NSDictionary *)passwordGenerationOptions
             forViewController:(UIViewController *)viewController
                        sender:(id)sender
                    completion:(void (^)(NSDictionary * _Nullable loginDictionary, NSError * _Nullable error))completion
{
    NSParameterAssert(URLString != nil);
    NSParameterAssert(loginDetailsDictionary != nil);
    NSParameterAssert(passwordGenerationOptions != nil);
    NSParameterAssert(viewController != nil);
    NSParameterAssert(completion != nil);

    [[OnePasswordExtension sharedExtension] storeLoginForURLString:URLString
                                                      loginDetails:loginDetailsDictionary
                                         passwordGenerationOptions:passwordGenerationOptions
                                                 forViewController:viewController
                                                            sender:sender
                                                        completion:completion];
}

@end
