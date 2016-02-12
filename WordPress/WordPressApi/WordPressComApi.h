#import <Availability.h>
#import <AFNetworking/AFNetworking.h>

typedef void (^WordPressComApiRestSuccessResponseBlock)(AFHTTPRequestOperation *operation, id responseObject);
typedef void (^WordPressComApiRestSuccessFailureBlock)(AFHTTPRequestOperation *operation, NSError *error);

typedef NS_ENUM(NSUInteger, WordPressComApiError) {
    WordPressComApiErrorJSON,
    WordPressComApiErrorNoAccessToken,
    WordPressComApiErrorLoginFailed,
    WordPressComApiErrorInvalidToken,
    WordPressComApiErrorAuthorizationRequired,
    WordPressComApiErrorUploadFailed,
    WordPressComApiErrorUploadFailedInvalidFileType,
    WordPressComApiErrorUploadFailedNotEnoughDiskQuota
};

extern NSString *const WordPressComApiErrorDomain;
extern NSString *const WordPressComApiErrorCodeKey;
extern NSString *const WordPressComApiErrorMessageKey;
extern NSString *const WordPressComApiPushAppId;

@interface WordPressComApi : AFHTTPRequestOperationManager
@property (nonatomic, readonly, strong) NSString *username;
@property (nonatomic, readonly, strong) NSString *password;
@property (nonatomic, readonly, strong) NSString *authToken;

/**
 Returns an API without an associated user
 
 Use this only for things that don't require an account, like signup or logged out reader
 */
+ (WordPressComApi *)anonymousApi;
- (instancetype)initWithOAuthToken:(NSString *)authToken;

/**
 Reset the API instance
 
 @discussion Clears cookies, and sets `authToken`, `username`, and `password` to nil.
 */
- (void)reset;


/**
 Returns a AFHTTPRequestOperation instance for a POST OP, with the specified paramteres.
 As an addition to the standard AFNetworking helpers, our kiddo allows for cancellable operations.
 */
- (AFHTTPRequestOperation *)POST:(NSString *)URLString
                      parameters:(id)parameters
                     cancellable:(BOOL)cancellable
                         success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;


///-------------------------
/// @name Account management
///-------------------------


- (BOOL)hasCredentials;

// Wipe the OAuth2 token
- (void)invalidateOAuth2Token;

@end
