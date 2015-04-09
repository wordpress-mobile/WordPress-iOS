#import <Foundation/Foundation.h>

@class WPAccount;
@protocol AccountServiceFacade

- (WPAccount *)createOrUpdateWordPressComAccountWithUsername:(NSString *)username
                                                   authToken:(NSString *)authToken;

- (WPAccount *)createOrUpdateSelfHostedAccountWithXmlrpc:(NSString *)xmlrpc
                                                username:(NSString *)username
                                             andPassword:(NSString *)password;

- (void)updateEmailAndDefaultBlogForWordPressComAccount:(WPAccount *)account;

-(void)removeLegacyAccount:(NSString *)newUsername;

@end

@interface AccountServiceFacade : NSObject<AccountServiceFacade>

@end
