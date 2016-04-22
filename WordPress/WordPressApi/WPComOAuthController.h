#import <Foundation/Foundation.h>

extern NSString *const WPComOAuthErrorDomain;
typedef NS_ENUM(NSUInteger, WPComOAuthErrorCode) {
    WPComOAuthErrorCodeUnknown
};

@interface WPComOAuthController : UIViewController

+ (WPComOAuthController *)sharedController;

- (void)setWordPressComUsername:(NSString *)username;
- (void)setWordPressComAuthToken:(NSString *)authToken;

- (void)setClient:(NSString *)client;
- (void)setRedirectUrl:(NSString *)redirectUrl;
- (void)setSecret:(NSString *)secret;
- (void)setCompletionBlock:(void (^)(NSString *token, NSString *blogId, NSString *blogUrl, NSString *scope, NSError *error))completionBlock;

- (void)present;
- (void)presentWithScope:(NSString *)scope blogId:(NSString *)blogId;
- (void)getTokenWithCode:(NSString *)code secret:(NSString *)secret;
- (BOOL)handleOpenURL:(NSURL *)URL;

@end
