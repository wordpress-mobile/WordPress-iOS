#import <Foundation/Foundation.h>

@class SocialLogin2FANonceInfo;
@protocol WordPressComOAuthClientFacade


- (void)authenticateWithUsername:(NSString *)username
                        password:(NSString *)password
                 multifactorCode:(NSString *)multifactorCode
                         success:(void (^)(NSString *authToken))success
                needsMultiFactor:(void (^)(void))needsMultifactor
                         failure:(void (^)(NSError *error))failure;

- (void)requestOneTimeCodeWithUsername:(NSString *)username
                              password:(NSString *)password
                               success:(void (^)(void))success
                               failure:(void (^)(NSError *error))failure;

- (void)requestSocial2FACodeWithUserID:(NSInteger)userID
                                 nonce:(NSString *)nonce
                               success:(void (^)(NSString *newNonce))success
                               failure:(void (^)(NSError *error, NSString *newNonce))failure;

- (void)authenticateWithGoogleIDToken:(NSString *)token
                              success:(void (^)(NSString *authToken))success
                     needsMultiFactor:(void (^)(NSInteger userID, SocialLogin2FANonceInfo *nonceInfo))needsMultifactor
          existingUserNeedsConnection:(void (^)(NSString *email))existingUserNeedsConnection
                              failure:(void (^)(NSError *error))failure;

- (void)authenticateSocialLoginUser:(NSInteger)userID
                           authType:(NSString *)authType
                        twoStepCode:(NSString *)twoStepCode
                       twoStepNonce:(NSString *)twoStepNonce
                            success:(void (^)(NSString *authToken))success
                            failure:(void (^)(NSError *error))failure;
@end

@interface WordPressComOAuthClientFacade : NSObject <WordPressComOAuthClientFacade>

@end
