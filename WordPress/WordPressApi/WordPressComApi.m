#import "WordPressComApi.h"
#import "NSString+Helpers.h"
#import <UIDeviceIdentifier/UIDeviceHardware.h>
#import "UIDevice+Helpers.h"
#import "WordPressAppDelegate.h"
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
		
        NSString *userAgent = [[WordPressAppDelegate sharedInstance].userAgent wordPressUserAgent];
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
            NSArray *errors = (NSArray *)[operation.responseObject objectForKey:@"errors"];
            NSDictionary *errorDictionary = nil;
            if (errors) {
                errorDictionary = [errors firstObject];
            } else {
                errorDictionary = (NSDictionary *)operation.responseObject;
            }
            NSString *errorMessage = (NSString *)errorDictionary[@"message"];
            NSString *errorType = (NSString *)errorDictionary[@"error"];
            NSUInteger errorCode = WordPressComApiErrorJSON;
            if (errorType && errorMessage) {
                if ([errorType isEqualToString:@"invalid_token"]) {
                    errorCode = WordPressComApiErrorInvalidToken;
                } else if ([errorType isEqualToString:@"authorization_required"]) {
                    errorCode = WordPressComApiErrorAuthorizationRequired;
                } else if ([errorType isEqualToString:@"upload_error"]) {
                    errorCode = WordPressComApiErrorUploadFailed;
                    if (operation.response.statusCode == 400) {
                        errorCode = WordPressComApiErrorUploadFailedInvalidFileType;
                    } else if (operation.response.statusCode == 500) {
                        errorCode = WordPressComApiErrorUploadFailedNotEnoughDiskQuota;
                    }
                }
                newError = [NSError errorWithDomain:WordPressComApiErrorDomain code:errorCode userInfo:@{NSLocalizedDescriptionKey: errorMessage, WordPressComApiErrorCodeKey: errorType}];
            }
        }
        
        if (failure) {
            failure(operation, newError);
        }
        
    }];
	
    return operation;
}

- (AFHTTPRequestOperation *)POST:(NSString *)URLString
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
    NSAssert([URLString rangeOfString:@"/v1/"].length > 0
             || [URLString rangeOfString:@"v1.1"].length > 0
             || [URLString rangeOfString:@"v1.2"].length > 0,
             @"Unexpected API version in URL: %@", URLString);
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

        NSString *userAgent = [[WordPressAppDelegate sharedInstance].userAgent wordPressUserAgent];
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


#pragma mark - User Details

- (void)setAuthorizationHeaderWithToken:(NSString *)token {
	[self.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token]
				  forHTTPHeaderField:@"Authorization"];
}

@end
