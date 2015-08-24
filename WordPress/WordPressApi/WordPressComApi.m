#import "WordPressComApi.h"
#import "NSString+Helpers.h"
#import <UIDeviceHardware.h>
#import "UIDevice+Helpers.h"
#import "WordPressAppDelegate.h"
#import "NotificationsManager.h"
#import "WPUserAgent.h"

static NSString *const WordPressComApiClientEndpointURL = @"https://public-api.wordpress.com/rest/";
static NSString *const WordPressComApiOauthBaseUrl = @"https://public-api.wordpress.com/oauth2";
NSString *const WordPressComApiNotificationFields = @"id,type,unread,body,subject,timestamp,meta";
static NSString *const WordPressComApiLoginUrl = @"https://wordpress.com/wp-login.php";

#ifdef DEBUG
NSString *const WordPressComApiPushAppId = @"org.wordpress.appstore.dev";
#else
#ifdef INTERNAL_BUILD
NSString *const WordPressComApiPushAppId = @"org.wordpress.internal";
#else
NSString *const WordPressComApiPushAppId = @"org.wordpress.appstore";
#endif
#endif

#define UnfollowedBlogEvent @"UnfollowedBlogEvent"

// AFJSONRequestOperation requires that a URI end with .json in order to match
// This will match all public-api.wordpress.com/rest/v1/ URI's and parse them as JSON

@interface WPJSONRequestOperation : AFHTTPRequestOperation
@property (nonatomic, assign) BOOL disallowsCancellation;
@end

@implementation WPJSONRequestOperation

- (instancetype)initWithRequest:(NSURLRequest *)urlRequest
{
	self = [super initWithRequest:urlRequest];
	
	if (self) {
		self.responseSerializer = [[AFJSONResponseSerializer alloc] init];
	}
	
	return self;
}

- (void)cancel
{
    if (self.disallowsCancellation) {
        return;
    }
    
    [super cancel];
}

@end


@interface WordPressComApi ()
@property (readwrite, nonatomic, strong) NSString *username;
@property (readwrite, nonatomic, strong) NSString *password;
@property (readwrite, nonatomic, strong) NSString *authToken;

@end

@implementation WordPressComApi

#pragma - Initializers

- (instancetype)initWithOAuthToken:(NSString *)authToken
{
	NSParameterAssert([authToken isKindOfClass:[NSString class]]);
	
	NSURL* url = [NSURL URLWithString:WordPressComApiClientEndpointURL];
	
	self = [super initWithBaseURL:url];
	
    if (self) {
        _authToken = authToken;
        self.requestSerializer = [AFJSONRequestSerializer serializer];
		
        [self setAuthorizationHeaderWithToken:_authToken];
		
        NSString *userAgent = [[WordPressAppDelegate sharedInstance].userAgent currentUserAgent];
		[self.requestSerializer setValue:userAgent forHTTPHeaderField:@"User-Agent"];
	}
	
	return self;
}

- (AFHTTPRequestOperation *)HTTPRequestOperationWithRequest:(NSURLRequest *)request
                                                    success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                                    failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    WPJSONRequestOperation *operation = [[WPJSONRequestOperation alloc] initWithRequest:request];
	
    operation.shouldUseCredentialStorage = self.shouldUseCredentialStorage;
    operation.credential = self.credential;
    operation.securityPolicy = self.securityPolicy;
	
    [operation setCompletionBlockWithSuccess:success failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSError *newError = error;
        if (operation.response.statusCode >= 400) {
            NSString *errorMessage = [operation.responseObject stringForKey:@"message"];
            NSUInteger errorCode = WordPressComApiErrorJSON;
            if ([operation.responseObject objectForKey:@"error"] && errorMessage) {
                NSString *errorString = [operation.responseObject stringForKey:@"error"];
                if ([errorString isEqualToString:@"invalid_token"]) {
                    errorCode = WordPressComApiErrorInvalidToken;
                } else if ([errorString isEqualToString:@"authorization_required"]) {
                    errorCode = WordPressComApiErrorAuthorizationRequired;
                }
                if (errorString) {
                    errorMessage = [errorMessage stringByAppendingFormat:@" [%@]", errorString];
                }
                newError = [NSError errorWithDomain:WordPressComApiErrorDomain code:errorCode userInfo:@{NSLocalizedDescriptionKey: errorMessage, WordPressComApiErrorCodeKey: errorString}];
            }
        }
        
        if (failure) {
            failure(operation, newError);
        }
        
    }];
	
    return operation;
}

- (WPJSONRequestOperation *)POST:(NSString *)URLString
                      parameters:(id)parameters
                     cancellable:(BOOL)cancellable
                         success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    WPJSONRequestOperation *operation = (WPJSONRequestOperation *) [super POST:URLString parameters:parameters success:success failure:failure];
    NSParameterAssert([operation isKindOfClass:[WPJSONRequestOperation class]]);
    
    operation.disallowsCancellation = !cancellable;
    
    return operation;
}

#pragma mark - Only for debugging purposes
// The methods in this section are all temporary and should be removed once enough time has passed.
//

#if !defined(NS_BLOCK_ASSERTIONS)
- (void)assertApiVersion:(NSString *)URLString
{
    NSAssert([URLString rangeOfString:@"v1.1"].length > 0
             || [URLString rangeOfString:@"v1.2"].length > 0,
             @"Unexpected API version.");
}

- (AFHTTPRequestOperation *)DELETE:(NSString *)URLString
                        parameters:(id)parameters
                           success:(void (^)(AFHTTPRequestOperation *, id))success
                           failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure
{
    [self assertApiVersion:URLString];
    
    return [super DELETE:URLString parameters:parameters success:success failure:failure];
}

- (AFHTTPRequestOperation *)GET:(NSString *)URLString
                     parameters:(id)parameters
                        success:(void (^)(AFHTTPRequestOperation *, id))success
                        failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure
{
    [self assertApiVersion:URLString];
    
    return [super GET:URLString parameters:parameters success:success failure:failure];
}

- (AFHTTPRequestOperation *)HEAD:(NSString *)URLString
                      parameters:(id)parameters
                         success:(void (^)(AFHTTPRequestOperation *))success
                         failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure
{
    [self assertApiVersion:URLString];
    
    return [super HEAD:URLString parameters:parameters success:success failure:failure];
}

- (AFHTTPRequestOperation *)PATCH:(NSString *)URLString
                       parameters:(id)parameters
                          success:(void (^)(AFHTTPRequestOperation *, id))success
                          failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure
{
    [self assertApiVersion:URLString];
    
    return [super PATCH:URLString parameters:parameters success:success failure:failure];
}

- (AFHTTPRequestOperation *)POST:(NSString *)URLString
                      parameters:(id)parameters
                         success:(void (^)(AFHTTPRequestOperation *, id))success
                         failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure
{
    [self assertApiVersion:URLString];
    
    return [super POST:URLString parameters:parameters success:success failure:failure];
}

- (AFHTTPRequestOperation *)POST:(NSString *)URLString
                      parameters:(id)parameters
       constructingBodyWithBlock:(void (^)(id<AFMultipartFormData>))block
                         success:(void (^)(AFHTTPRequestOperation *, id))success
                         failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure
{
    [self assertApiVersion:URLString];
    
    return [super POST:URLString
            parameters:parameters
constructingBodyWithBlock:block
               success:success
               failure:failure];
}

- (AFHTTPRequestOperation *)PUT:(NSString *)URLString
                     parameters:(id)parameters
                        success:(void (^)(AFHTTPRequestOperation *, id))success
                        failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure
{
    [self assertApiVersion:URLString];
    
    return [super PUT:URLString parameters:parameters success:success failure:failure];
}

#endif

#pragma mark - Misc

+ (WordPressComApi *)anonymousApi {
    static WordPressComApi *_anonymousApi = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        DDLogVerbose(@"Initializing anonymous API");
        _anonymousApi = [[self alloc] initWithBaseURL:[NSURL URLWithString:WordPressComApiClientEndpointURL] ];

        NSString *userAgent = [[WordPressAppDelegate sharedInstance].userAgent currentUserAgent];
		[_anonymousApi.requestSerializer setValue:userAgent forHTTPHeaderField:@"User-Agent"];
    });

    return _anonymousApi;
}

#pragma mark - Account management

- (void)clearAuthorizationHeader
{
	[self.requestSerializer setValue:nil forHTTPHeaderField:@"Authorization"];
}

- (void)reset {
    DDLogMethod();

    self.authToken = nil;
    self.username = nil;
    self.password = nil;
 
    [self clearAuthorizationHeader];
}

- (BOOL)hasCredentials {
    return self.authToken.length > 0;
}

- (void)invalidateOAuth2Token {
    [self setAuthToken:nil];
}

#pragma mark - Notifications

- (void)saveNotificationSettings:(NSDictionary *)settings
                        deviceId:(NSString *)deviceId
                         success:(void (^)())success
                         failure:(void (^)(NSError *error))failure {
    
    if (deviceId.length == 0) {
        DDLogWarn(@"Unable to saveNotificationSettings - Device ID is empty!");
        return;
    }

    NSString *path = [NSString stringWithFormat:@"v1.1/device/%@", deviceId];
    NSDictionary *parameters = @{@"settings": settings};
    [self POST:path
	parameters:parameters
		success:^(AFHTTPRequestOperation *operation, id responseObject) {
               if (success) {
                   success();
               }
           }
	   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               if (failure) {
                   failure(error);
               }
           }];
    
}

- (void)fetchNotificationSettingsWithDeviceId:(NSString *)deviceId
                                      success:(void (^)(NSDictionary *settings))success
                                      failure:(void (^)(NSError *error))failure {
    if (deviceId.length == 0) {
        DDLogWarn(@"Unable to fetchNotificationSettings - Device ID is empty!");
        return;
    }
    
    if (![self hasCredentials]) {
        DDLogWarn(@"Unable to fetchNotificationSettings - not authenticated!");
        return;
    }
    
    NSString *path = [NSString stringWithFormat:@"v1.1/device/%@", deviceId];
    [self GET:path
       parameters:nil
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              if (success) {
                  NSDictionary *settings = responseObject[@"settings"];
                  success(settings);
              }
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              if (failure) {
                  failure(error);
              }
          }
     ];

}

- (void)unregisterForPushNotificationsWithDeviceId:(NSString *)deviceId
                                           success:(void (^)())success
                                           failure:(void (^)(NSError *error))failure {
    if (deviceId.length == 0) {
        DDLogWarn(@"Unable to fetchNotificationSettings - Device ID is empty!");
        return;
    }

    NSString *path = [NSString stringWithFormat:@"v1.1/devices/%@/delete", deviceId];
    WordPressComApiRestSuccessResponseBlock successBlock = ^(AFHTTPRequestOperation *operation, id responseObject) {
        DDLogInfo(@"Successfully unregistered device ID %@", deviceId);
        if (success) {
            success();
        }
    };
    
    WordPressComApiRestSuccessFailureBlock failureBlock = ^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogError(@"Unable to unregister push for device ID %@: %@", deviceId, error);
        if (failure) {
            failure(error);
        }
    };

    [self POST:path parameters:nil cancellable:NO success:successBlock failure:failureBlock];
}

- (void)syncPushNotificationInfoWithDeviceToken:(NSString *)token
                                        success:(void (^)(NSString *deviceId, NSDictionary *settings))success
                                        failure:(void (^)(NSError *error))failure {
    if (token.length == 0) {
        DDLogWarn(@"syncPushNotificationInfoWithDeviceToken called with no token!");
        return;
    }

    if (![self hasCredentials]) {
        DDLogWarn(@"syncPushNotificationInfoWithDeviceToken called with no credentials!");
        return;
    }
        
    NSDictionary *parameters = @{@"device_token"    : token,
                                 @"device_family"   : @"apple",
                                 @"app_secret_key"  : WordPressComApiPushAppId,
                                 @"device_name"     : [[UIDevice currentDevice] name],
                                 @"device_model"    : [UIDeviceHardware platform],
                                 @"os_version"      : [[UIDevice currentDevice] systemVersion],
                                 @"app_version"     : [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"],
                                 @"device_uuid"     : [[UIDevice currentDevice] wordPressIdentifier],
                                 };
    
    [self POST:@"v1.1/devices/new"
        parameters:parameters
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               NSAssert([responseObject isKindOfClass:[NSDictionary class]], @"Response should be a dictionary");
               
               if (success) {
                   NSString *deviceId = [responseObject stringForKey:@"ID"];
                   NSDictionary *settings = [responseObject dictionaryForKey:@"settings"];
                   
                   success(deviceId, settings);
               }
           }
           failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               if (failure) {
                   failure(error);
               }
           }
     ];
}

#pragma mark - User Details

- (void)setAuthorizationHeaderWithToken:(NSString *)token {
	[self.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token]
				  forHTTPHeaderField:@"Authorization"];
}

@end
