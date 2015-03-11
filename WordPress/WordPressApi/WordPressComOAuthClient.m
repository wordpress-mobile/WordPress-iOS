#import "WordPressComOAuthClient.h"
#import "WordPressComApiCredentials.h"

NSString * const WordPressComOAuthErrorDomain = @"WordPressComOAuthError";
NSString * const WordPressComOAuthKeychainServiceName = @"public-api.wordpress.com";
static NSString * const WordPressComOAuthBaseUrl = @"https://public-api.wordpress.com/oauth2";
static NSString * const WordPressComOAuthRedirectUrl = @"https://wordpress.com/";

@implementation WordPressComOAuthClient

#pragma mark - Conveniece constructors

+ (WordPressComOAuthClient *)client {
    WordPressComOAuthClient *client = [[WordPressComOAuthClient alloc] initWithBaseURL:[NSURL URLWithString:WordPressComOAuthBaseUrl]];

	client.responseSerializer = [[AFJSONResponseSerializer alloc] init];
	[client.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
	
    return client;
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
        @"client_id": [WordPressComApiCredentials client],
        @"client_secret": [WordPressComApiCredentials secret],
        @"wpcom_supports_2fa": @(YES)
    } mutableCopy];
    
    if (multifactorCode.length > 0) {
        [parameters setObject:multifactorCode forKey:@"wpcom_otp"];
    }
    
    [self POST:@"token"
	parameters:parameters
	   success:^(AFHTTPRequestOperation *operation, id responseObject) {
               DDLogVerbose(@"Received OAuth2 response: %@", responseObject);
               NSString *authToken = [responseObject stringForKey:@"access_token"];
               if (success) {
                   success(authToken);
               }
           } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               error = [self processError:error forOperation:operation];
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
        @"client_id": [WordPressComApiCredentials client],
        @"client_secret": [WordPressComApiCredentials secret],
        @"wpcom_supports_2fa": @(YES),
        @"wpcom_resend_otp": @(YES)
    };
    
    [self POST:@"token"
    parameters:parameters
       success:^(AFHTTPRequestOperation *operation, id responseObject) {
           if (success) {
               success();
           }
       } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
           error = [self processError:error forOperation:operation];
           
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

- (NSError *)processError:(NSError *)error forOperation:(AFHTTPRequestOperation *)operation {
    if (operation.response.statusCode >= 400 && operation.response.statusCode < 500) {
        // Bad request, look for errors in the JSON response
		NSDictionary* response = operation.responseObject;

        if (response) {
            NSString *errorCode = [response stringForKey:@"error"];
            NSString *errorDescription = [response stringForKey:@"error_description"];

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

@end
