#import "WordPressComOAuthClientFacade.h"
#import "WordPress-Swift.h"

@implementation WordPressComOAuthClientFacade

- (void)authenticateWithUsername:(NSString *)username
                        password:(NSString *)password
                 multifactorCode:(NSString *)multifactorCode
                         success:(void (^)(NSString *authToken))success
                needsMultiFactor:(void (^)(void))needsMultifactor
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

- (void)requestSocial2FACodeWithUserID:(NSInteger)userID
                                nonce:(NSString *)nonce
                                 success:(void (^)(NSString *newNonce))success
                                 failure:(void (^)(NSError *error, NSString *newNonce))failure
{
    WordPressComOAuthClient *client = [WordPressComOAuthClient clientWithClientID:ApiCredentials.client secret:ApiCredentials.secret];
    [client requestSocial2FACodeWithUserID:userID nonce:nonce success:success failure:failure];
}

- (void)authenticateWithGoogleIDToken:(NSString *)token
                              success:(void (^)(NSString *authToken))success
                     needsMultiFactor:(void (^)(NSInteger userID, SocialLogin2FANonceInfo *nonceInfo))needsMultifactor
          existingUserNeedsConnection:(void (^)(NSString *email))existingUserNeedsConnection
                              failure:(void (^)(NSError *error))failure
{
    WordPressComOAuthClient *client = [WordPressComOAuthClient clientWithClientID:ApiCredentials.client secret:ApiCredentials.secret];
    [client authenticateWithIDToken:token success:success needsMultifactor:needsMultifactor existingUserNeedsConnection:existingUserNeedsConnection failure:failure];
}

- (void)authenticateSocialLoginUser:(NSInteger)userID
                           authType:(NSString *)authType
                        twoStepCode:(NSString *)twoStepCode
                       twoStepNonce:(NSString *)twoStepNonce
                            success:(void (^)(NSString *authToken))success
                            failure:(void (^)(NSError *error))failure
{
    WordPressComOAuthClient *client = [WordPressComOAuthClient clientWithClientID:ApiCredentials.client secret:ApiCredentials.secret];
    [client authenticateSocialLoginUser:userID authType:authType twoStepCode:twoStepCode twoStepNonce:twoStepNonce success:success failure:failure];
}

@end
