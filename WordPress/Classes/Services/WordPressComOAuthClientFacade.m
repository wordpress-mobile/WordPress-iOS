#import "WordPressComOAuthClientFacade.h"
#import "WordPress-Swift.h"

@interface WordPressComOAuthClientFacade(Internal)

@property (nonatomic, strong) WordPressComOAuthClient *client;

@end

@implementation WordPressComOAuthClientFacade

- (instancetype)initWithClient:(NSString *)client secret:(NSString *)secret
{
    NSParameterAssert(client);
    NSParameterAssert(secret);
    self = [super init];
    if (self) {
        self.client = [WordPressComOAuthClient clientWithClientID:client secret:secret];
    }

    return self;
}

- (instancetype)init {
    NSAssert(false, @"Please initializer WordPressComOAuthClientFacade with the ClientID and Secret!");
    return nil;
}

- (void)authenticateWithUsername:(NSString *)username
                        password:(NSString *)password
                 multifactorCode:(NSString *)multifactorCode
                         success:(void (^)(NSString *authToken))success
                needsMultiFactor:(void (^)(void))needsMultifactor
                         failure:(void (^)(NSError *error))failure
{
    [self.client authenticateWithUsername:username password:password multifactorCode:multifactorCode success:success failure:^(NSError *error) {
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
    [self.client requestOneTimeCodeWithUsername:username password:password success:success failure:failure];
}

- (void)requestSocial2FACodeWithUserID:(NSInteger)userID
                                nonce:(NSString *)nonce
                                 success:(void (^)(NSString *newNonce))success
                                 failure:(void (^)(NSError *error, NSString *newNonce))failure
{
    [self.client requestSocial2FACodeWithUserID:userID nonce:nonce success:success failure:failure];
}

- (void)authenticateWithGoogleIDToken:(NSString *)token
                              success:(void (^)(NSString *authToken))success
                     needsMultiFactor:(void (^)(NSInteger userID, SocialLogin2FANonceInfo *nonceInfo))needsMultifactor
          existingUserNeedsConnection:(void (^)(NSString *email))existingUserNeedsConnection
                              failure:(void (^)(NSError *error))failure
{
    [self.client authenticateWithIDToken:token success:success needsMultifactor:needsMultifactor existingUserNeedsConnection:existingUserNeedsConnection failure:failure];
}

- (void)authenticateSocialLoginUser:(NSInteger)userID
                           authType:(NSString *)authType
                        twoStepCode:(NSString *)twoStepCode
                       twoStepNonce:(NSString *)twoStepNonce
                            success:(void (^)(NSString *authToken))success
                            failure:(void (^)(NSError *error))failure
{
    [self.client authenticateSocialLoginUser:userID authType:authType twoStepCode:twoStepCode twoStepNonce:twoStepNonce success:success failure:failure];
}

@end
