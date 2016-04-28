#import "WordPressComOAuthClient.h"
#import "ApiCredentials.h"
#import <AFNetworking/AFNetworking.h>

NSString * const WordPressComOAuthErrorDomain = @"WordPressComOAuthError";
NSString * const WordPressComOAuthKeychainServiceName = @"public-api.wordpress.com";
static NSString * const WordPressComOAuthBaseUrl = @"https://public-api.wordpress.com/oauth2";
static NSString * const WordPressComOAuthRedirectUrl = @"https://wordpress.com/";

@interface  WordPressComOAuthClient()

@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;

@end

@implementation WordPressComOAuthClient

#pragma mark - Convinience constructors

+ (WordPressComOAuthClient *)client
{
    WordPressComOAuthClient *client = [[WordPressComOAuthClient alloc] init];
    return client;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSURL *baseURL = [NSURL URLWithString:WordPressComOAuthBaseUrl];
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        _sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL sessionConfiguration:sessionConfiguration];
        _sessionManager.responseSerializer = [[AFJSONResponseSerializer alloc] init];
        [_sessionManager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    }
    return self;
}

#pragma mark - Misc

- (void)authenticateWithUsername:(NSString *)username
                        password:(NSString *)password
                 multifactorCode:(NSString *)multifactorCode
                         success:(void (^)(NSString *authToken))success
                         failure:(void (^)(NSError *error))failure
{
    NSMutableDictionary *parameters = [@{
        @"username": username,
        @"password": password,
        @"grant_type": @"password",
        @"client_id": [ApiCredentials client],
        @"client_secret": [ApiCredentials secret],
        @"wpcom_supports_2fa": @(YES)
    } mutableCopy];
    
    if (multifactorCode.length > 0) {
        [parameters setObject:multifactorCode forKey:@"wpcom_otp"];
    }
    
    [self.sessionManager POST:@"token"
                   parameters:parameters
                      success:^(NSURLSessionDataTask *task, id responseObject) {
                          DDLogVerbose(@"Received OAuth2 response: %@", [self cleanedUpResponseForLogging:responseObject]);
                          NSString *authToken = [responseObject stringForKey:@"access_token"];
                          if (success) {
                              success(authToken);
                          }
                      } failure:^(NSURLSessionDataTask *task, NSError *error) {
                          if ([task.response isKindOfClass:[NSHTTPURLResponse class]]) {
                              NSHTTPURLResponse *httpURLResponse = (NSHTTPURLResponse *)task.response;
                              error = [self processError:error forResponse:httpURLResponse];
                          }
                          DDLogError(@"Error receiving OAuth2 token: %@", error);
                          if (failure) {
                              failure(error);
                          }
                      }];
}

- (void)requestOneTimeCodeWithUsername:(NSString *)username
                              password:(NSString *)password
                               success:(void (^)(void))success
                               failure:(void (^)(NSError *error))failure
{
    NSDictionary *parameters = @{
        @"username": username,
        @"password": password,
        @"grant_type": @"password",
        @"client_id": [ApiCredentials client],
        @"client_secret": [ApiCredentials secret],
        @"wpcom_supports_2fa": @(YES),
        @"wpcom_resend_otp": @(YES)
    };
    
    [self.sessionManager POST:@"token"
                   parameters:parameters
                      success:^(NSURLSessionDataTask *task, id responseObject) {
                          if (success) {
                              success();
                          }
                      } failure:^(NSURLSessionDataTask *task, NSError *error) {
                          if ([task.response isKindOfClass:[NSHTTPURLResponse class]]) {
                              NSHTTPURLResponse *httpURLResponse = (NSHTTPURLResponse *)task.response;
                              error = [self processError:error forResponse:httpURLResponse];
                          }

                          // SORRY:
                          // SMS Requests will still return WordPressComOAuthErrorNeedsMultifactorCode. In which case,
                          // we should hit the success callback.
                          if (error.code == WordPressComOAuthErrorNeedsMultifactorCode) {
                              if (success) {
                                  success();
                              }
                          } else if (failure) {
                              failure(error);
                          }
                      }];
}

- (NSError *)processError:(NSError *)error forResponse:(NSHTTPURLResponse *)response {
    if (response.statusCode >= 400 && response.statusCode < 500) {
        // Bad request, look for errors in the JSON response

        NSData* responseData = nil;
        NSDictionary *responseDictionary = nil;
        if (error.domain == AFURLResponseSerializationErrorDomain) {
            responseData = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
            responseDictionary = [NSJSONSerialization JSONObjectWithData:responseData options:nil error:nil];

        }
        if (responseDictionary) {
            NSString *errorCode = [responseDictionary stringForKey:@"error"];
            NSString *errorDescription = [responseDictionary stringForKey:@"error_description"];

            /*
             Possible errors:
             - invalid_client: client_id is missing or wrong, it shouldn't happen
             - unsupported_grant_type: client_id doesn't support password grants
             - invalid_request: A required field is missing/malformed
             - invalid_request: Authentication failed
             - needs_2fa: Multifactor Authentication code is required
             */
            
            NSDictionary *errorsMap = @{
                @"invalid_client"           : @(WordPressComOAuthErrorInvalidClient),
                @"unsupported_grant_type"   : @(WordPressComOAuthErrorUnsupportedGrantType),
                @"invalid_request"          : @(WordPressComOAuthErrorInvalidRequest),
                @"needs_2fa"                : @(WordPressComOAuthErrorNeedsMultifactorCode)
            };

            NSNumber *mappedCode = errorsMap[errorCode] ?: @(WordPressComOAuthErrorUnknown);
            
            return [NSError errorWithDomain:WordPressComOAuthErrorDomain
                                       code:mappedCode.intValue
                                   userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
        }
    }
    return error;
}

- (id)cleanedUpResponseForLogging:(id)response {
    if (![response isKindOfClass:[NSDictionary class]]) {
        return response;
    }
    if ([(NSDictionary *)response objectForKey:@"access_token"] == nil) {
        return response;
    }
    NSMutableDictionary *dict = [(NSDictionary *)response mutableCopy];
    dict[@"access_token"] = @"*** REDACTED ***";
    return dict;
}

@end
