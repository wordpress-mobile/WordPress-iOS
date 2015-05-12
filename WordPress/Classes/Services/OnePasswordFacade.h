#import <Foundation/Foundation.h>

typedef void (^OnePasswordFacadeCallback)(NSString *username, NSString *password, NSError *);

/**
 *  This protocol is a Facade that hides some of the implementation details for interacting with 1Password.
 */
@protocol OnePasswordFacade

/**
 *  This method will pull up the 1Password extension and display any logins for the passed in `loginUrl`
 *
 *  @param loginUrl       the URL of the site in question.
 *  @param viewController the view controller of the class that needs the 1Password extension to appear. Note this can't be nil.
 *  @param sender         the control that triggered the action
 *  @param completion     block that is called when 1Password is done retrieving the password.
 */
- (void)findLoginForURLString:(NSString *)loginUrl viewController:(UIViewController *)viewController sender:(id)sender completion:(OnePasswordFacadeCallback)completion;

/**
 *  A method to check if the 1Password extension is enabled
 *
 *  @return whether the 1Password extension is enabled.
 */
- (BOOL)isOnePasswordEnabled;

@end

@interface OnePasswordFacade : NSObject <OnePasswordFacade>

@end
