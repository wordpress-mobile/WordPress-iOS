#import "OnePasswordFacade.h"
#import <OnePasswordExtension/OnePasswordExtension.h>
#import "Constants.h"

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

- (void)createLoginForURLString:(NSString *)URLString
                       username:(NSString *)username
                       password:(NSString *)password
              forViewController:(UIViewController *)viewController
                         sender:(id)sender
                     completion:(void (^)(NSString * _Nullable username, NSString * _Nullable password, NSError * _Nullable error))completion
{
    NSParameterAssert(URLString != nil);
    NSParameterAssert(username != nil);
    NSParameterAssert(password != nil);
    NSParameterAssert(viewController != nil);
    NSParameterAssert(sender != nil);
    NSParameterAssert(completion != nil);

    NSDictionary *loginDetailsDictionary = @{
                                             AppExtensionTitleKey: WPOnePasswordWordPressTitle,
                                             AppExtensionUsernameKey: username,
                                             AppExtensionPasswordKey: password,
                                             };

    NSDictionary *passwordGenerationOptions = @{
                                                AppExtensionGeneratedPasswordMinLengthKey: @(WPOnePasswordGeneratedMinLength),
                                                AppExtensionGeneratedPasswordMaxLengthKey: @(WPOnePasswordGeneratedMaxLength),
                                                };

    [[OnePasswordExtension sharedExtension] storeLoginForURLString:URLString
                                                      loginDetails:loginDetailsDictionary
                                         passwordGenerationOptions:passwordGenerationOptions
                                                 forViewController:viewController
                                                            sender:sender
                                                        completion:^(NSDictionary *loginDict, NSError *error) {
                                                            if (error != nil && error.code != AppExtensionErrorCodeCancelledByUser) {
                                                                completion(nil, nil, error);
                                                                return;
                                                            }
                                                            NSString *username = loginDict[AppExtensionUsernameKey];
                                                            NSString *password = loginDict[AppExtensionPasswordKey];
                                                            completion(username, password, error);
                                                        }];


}

@end
