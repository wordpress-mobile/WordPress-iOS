#import <Foundation/Foundation.h>

@class WPAccount;
@protocol AccountCreationFacade

- (WPAccount *)createOrUpdateWordPressComAccountWithUsername:(NSString *)username
                                                   authToken:(NSString *)authToken;

- (WPAccount *)createOrUpdateSelfHostedAccountWithXmlrpc:(NSString *)xmlrpc
                                                username:(NSString *)username
                                             andPassword:(NSString *)password;

- (void)updateEmailAndDefaultBlogForWordPressComAccount:(WPAccount *)account;

@end

@interface AccountCreationFacade : NSObject<AccountCreationFacade>

@end
