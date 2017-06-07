#import "WordPressComOAuthClientFacade.h"
#import "WordPress-Swift.h"

@implementation WordPressComOAuthClientFacade

- (void)authenticateWithUsername:(NSString *)username
                        password:(NSString *)password
                 multifactorCode:(NSString *)multifactorCode
                         success:(void (^)(NSString *authToken))success
                needsMultiFactor:(void (^)())needsMultifactor
                         failure:(void (^)(NSError *error))failure
{
    WordPressComOAuthClient *client = [WordPressComOAuthClient clientWithClientID:ApiCredentials.client secret:ApiCredentials.secret];
    [client authenticateWithUsername:username password:password multifactorCode:multifactorCode success:success failure:^(NSError *error) {
        if (error.code == WordPressComOAuthErrorNeedsMultifactorCode) {
            if (needsMultifactor != nil) {
                needsMultifactor();
            }
        } else {
            if (failure != nil) {
                failure(error);
            }
        }
    }];
}

- (void)requestOneTimeCodeWithUsername:(NSString *)username
                              password:(NSString *)password
                               success:(void (^)(void))success
                               failure:(void (^)(NSError *error))failure
{
    WordPressComOAuthClient *client = [WordPressComOAuthClient clientWithClientID:ApiCredentials.client secret:ApiCredentials.secret];
    [client requestOneTimeCodeWithUsername:username password:password success:success failure:failure];
}

@end
