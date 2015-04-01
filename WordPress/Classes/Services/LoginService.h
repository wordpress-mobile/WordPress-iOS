#import <Foundation/Foundation.h>


@class LoginFields;
@protocol WordPressComOAuthClientService;
@protocol WordPressXMLRPCApiService;
@protocol LoginServiceDelegate;
@protocol LoginService

- (void)signInWithLoginFields:(LoginFields *)loginFields;
- (void)requestOneTimeCodeWithLoginFields:(LoginFields *)loginFields;

@property (nonatomic, weak) id<LoginServiceDelegate> delegate;
@property (nonatomic, strong) id<WordPressComOAuthClientService> wordpressComOAuthClientService;
@property (nonatomic, strong) id<WordPressXMLRPCApiService> wordpressXMLRPCApiService;

@end

@interface LoginService : NSObject <LoginService>

@end

@protocol LoginServiceDelegate

- (void)displayLoginMessage:(NSString *)message;
- (void)needsMultifactorCode;
- (void)displayRemoteError:(NSError *)error;
- (void)finishedLoginWithUsername:(NSString *)username password:(NSString *)password xmlrpc:(NSString *)xmlrpc options:(NSDictionary * )options;
- (void)finishedLoginWithUsername:(NSString *)username authToken:(NSString *)authToken shouldDisplayMultifactor:(BOOL)shouldDisplayMultifactor;

@end

