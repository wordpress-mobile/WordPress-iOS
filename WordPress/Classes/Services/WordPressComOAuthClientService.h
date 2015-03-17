#import <Foundation/Foundation.h>

@protocol WordPressComOAuthClientService

- (void)authenticateWithUsername:(NSString *)username
                        password:(NSString *)password
                 multifactorCode:(NSString *)multifactorCode
                         success:(void (^)(NSString *authToken))success
                needsMultiFactor:(void (^)())needsMultifactor
                         failure:(void (^)(NSError *error))failure;

@end

@interface WordPressComOAuthClientService : NSObject <WordPressComOAuthClientService>

@end
