#import "WordPressComOAuthClient.h"
#import "WordPressComApiCredentials.h"

NSString * const WordPressComOAuthErrorDomain = @"WordPressComOAuthError";
NSString * const WordPressComOAuthKeychainServiceName = @"public-api.wordpress.com";
static NSString * const WordPressComOAuthBaseUrl = @"https://public-api.wordpress.com/oauth2";
static NSString * const WordPressComOAuthRedirectUrl = @"https://wordpress.com/";

@implementation WordPressComOAuthClient

#pragma mark - Convenience constructors

+ (WordPressComOAuthClient *)client {
    WordPressComOAuthClient *client = [[WordPressComOAuthClient alloc] initWithBaseURL:[NSURL URLWithString:WordPressComOAuthBaseUrl]];

	client.responseSerializer = [[AFJSONResponseSerializer alloc] init];
	[client.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
	
    return client;
}

#pragma mark - Misc

- (void)authenticateWithUsername:(NSString *)username password:(NSString *)password success:(void (^)(NSString *authToken))success failure:(void (^)(NSError *error))failure {
    NSDictionary *parameters = @{
                                 @"username": username,
                                 @"password": password,
                                 @"grant_type": @"password",
                                 @"client_id": [WordPressComApiCredentials client],
                                 @"client_secret": [WordPressComApiCredentials secret],
                                 };
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

- (NSError *)processError:(NSError *)error forOperation:(AFHTTPRequestOperation *)operation {
    if (operation.response.statusCode >= 400 && operation.response.statusCode < 500) {
        // Bad request, look for errors in the JSON response
		NSDictionary* response = operation.responseObject;

        if (response) {
            NSString *errorCode = [response stringForKey:@"error"];
            NSString *errorDescription = [response stringForKey:@"error_description"];

            NSInteger code = WordPressComOAuthErrorUnknown;
            /*
             Possible errors:
             - invalid_client: client_id is missing or wrong, it shouldn't happen
             - unsupported_grant_type: client_id doesn't support password grants
             - invalid_request: a required field is missing/malformed
             - invalid_request: authentication failed
             */
            if ([errorCode isEqualToString:@"invalid_client"]) {
                code = WordPressComOAuthErrorInvalidClient;
            } else if ([errorCode isEqualToString:@"unsupported_grant_type"]) {
                code = WordPressComOAuthErrorUnsupportedGrantType;
            } else if ([errorCode isEqualToString:@"invalid_request"]) {
                code = WordPressComOAuthErrorInvalidRequest;
            }
            return [NSError errorWithDomain:WordPressComOAuthErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
        }
    }
    return error;
}

@end
