#import <Foundation/Foundation.h>

@protocol WordPressComOAuthClientFacade


- (void)authenticateWithUsername:(NSString *)username
                        password:(NSString *)password
                 multifactorCode:(NSString *)multifactorCode
                         success:(void (^)(NSString *authToken))success
                needsMultiFactor:(void (^)())needsMultifactor
                         failure:(void (^)(NSError *error))failure;

- (void)requestOneTimeCodeWithUsername:(NSString *)username
                              password:(NSString *)password
                               success:(void (^)(void))success
                               failure:(void (^)(NSError *error))failure;

@end

@interface WordPressComOAuthClientFacade : NSObject <WordPressComOAuthClientFacade>

@end
