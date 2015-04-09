#import <Foundation/Foundation.h>


@class LoginFields;
@protocol WordPressComOAuthClientFacade;
@protocol WordPressXMLRPCApiFacade;
@protocol LoginFacadeDelegate;
@protocol LoginFacade

- (void)signInWithLoginFields:(LoginFields *)loginFields;
- (void)requestOneTimeCodeWithLoginFields:(LoginFields *)loginFields;

@property (nonatomic, weak) id<LoginFacadeDelegate> delegate;
@property (nonatomic, strong) id<WordPressComOAuthClientFacade> wordpressComOAuthClientFacade;
@property (nonatomic, strong) id<WordPressXMLRPCApiFacade> wordpressXMLRPCApiFacade;

@end

@interface LoginFacade : NSObject <LoginFacade>

@end

@protocol LoginFacadeDelegate

- (void)displayLoginMessage:(NSString *)message;
- (void)needsMultifactorCode;
- (void)displayRemoteError:(NSError *)error;
- (void)finishedLoginWithUsername:(NSString *)username password:(NSString *)password xmlrpc:(NSString *)xmlrpc options:(NSDictionary * )options;
- (void)finishedLoginWithUsername:(NSString *)username authToken:(NSString *)authToken shouldDisplayMultifactor:(BOOL)shouldDisplayMultifactor;

@end

