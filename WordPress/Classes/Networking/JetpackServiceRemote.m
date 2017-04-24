#import "JetpackServiceRemote.h"

#import <AFNetworking/AFNetworking.h>
#import "WordPress-Swift.h"

NSString * const JetpackServiceRemoteErrorDomain = @"JetpackServiceRemoteError";
static NSString * const GetUsersBlogsApiPath = @"https://public-api.wordpress.com/get-user-blogs/1.0";

@implementation JetpackServiceRemote

- (void)validateJetpackUsername:(NSString *)username
                       password:(NSString *)password
                      forSiteID:(NSNumber *)siteID
                        success:(void (^)(NSArray *blogIDs))success
                        failure:(void (^)(NSError *error))failure
{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager.requestSerializer setAuthorizationHeaderFieldWithUsername:username password:password];
    NSDictionary *parameters = @{
                                 @"f": @"json"
                                 };
    
    [manager GET:GetUsersBlogsApiPath
      parameters:parameters
        progress:nil
         success:^(NSURLSessionDataTask *task, id responseObject) {
             NSArray *blogs = [responseObject arrayForKeyPath:@"userinfo.blog"];
             DDLogInfo(@"Available wp.com/jetpack sites for %@: %@", username, blogs);
             NSArray *foundBlogs = [blogs filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"id = %@", siteID]];
             if (foundBlogs.count > 0) {
                 DDLogInfo(@"Found blog: %@", foundBlogs);
                 NSArray *blogIDs = [blogs valueForKey:@"id"];
                 if (success) {
                     success(blogIDs);
                 }
             } else {
                 if (failure) {
                     NSError *error = [NSError errorWithDomain:JetpackServiceRemoteErrorDomain
                                                          code:JetpackServiceRemoteErrorNoRecordForBlog
                                                      userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"This site is not connected to that WordPress.com username", @"")}];
                     DDLogError(@"Error validating Jetpack user: %@", error);
                     failure(error);
                 }
             }
         } failure:^(NSURLSessionDataTask *task, NSError *error) {
             DDLogError(@"Error validating Jetpack user: %@", error);
             if (failure) {
                 NSError *jetpackError = error;
                 NSHTTPURLResponse *httpResponse = nil;
                 if ([task.response isKindOfClass:[NSHTTPURLResponse class]]) {
                     httpResponse = (NSHTTPURLResponse *)task.response;
                 }
                 if (httpResponse && httpResponse.statusCode == 401) {
                     jetpackError = [NSError errorWithDomain:JetpackServiceRemoteErrorDomain
                                                        code:JetpackServiceRemoteErrorInvalidCredentials
                                                    userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Invalid username or password", @""), NSUnderlyingErrorKey: error}];
                 }
                 failure(jetpackError);
             }
         }];
}

/**
    Check if the specified site is a Jetpack site.  The success block
    receives two arguements, a bool indicating if the site is Jetpack, and
    and optionally specifies a connection error for the site.
 */
- (void)checkSiteIsJetpack:(NSURL *)siteURL
                   success:(void (^)(BOOL isJetpack, NSError *error))success
                   failure:(void (^)(NSError *error))failure
{
    NSString *siteStr = [[NSString stringWithFormat:@"%@%@", siteURL.host, siteURL.path]
                         stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLHostAllowedCharacterSet];

    NSString *endpoint = [NSString stringWithFormat:@"sites/%@", siteStr];
    NSString *path = [self pathForEndpoint:endpoint withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];

    [self.wordPressComRestApi GET:path
                       parameters:nil
                          success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                              NSDictionary *dict = (NSDictionary *)responseObject;
                              BOOL isJetpack = [[dict numberForKey:@"jetpack"] boolValue];
                              success(isJetpack, nil);

                          } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {

                              if ([error.domain isEqualToString:WordPressComRestApiErrorDomain]) {
                                  NSDictionary *userInfo = error.userInfo;
                                  NSString *errorKey = [userInfo stringForKey:WordPressComRestApi.ErrorKeyErrorCode];
                                  BOOL isJetpack = NO;

                                  // Jetpack is installed and connected but there is some other error.
                                  // It could be a php error.  It could be that xmlrpc requests have been blocked
                                  // via .htaccess :
                                  // <Files xmlrpc.php>
                                  // order allow,deny
                                  // deny from all
                                  // </Files>
                                  // Or it could be due to some other unknown error that caues the site
                                  // to return ah HTTP 500 status code when queried by the REST API.
                                  // NOTE: IF XML-RPC is disabled via `add_filter( 'xmlrpc_enabled', '__return_false' );`
                                  // the REST API currently still treates it as working (system.listMethods still operates).
                                  if ([errorKey isEqualToString:@"jetpack_error"] && error.code == WordPressComRestApiErrorUnknown) {
                                      // Site is inaccessible. (500 error)
                                      isJetpack = YES;
                                      error = [NSError errorWithDomain:JetpackServiceRemoteErrorDomain
                                                                  code:JetpackServiceRemoteErrorSiteInaccessable
                                                              userInfo:error.userInfo];

                                  }

                                  // The unauthorized key is a special case here.
                                  // The API call does not require credentials and does not return a 403 itself.
                                  // This combination occurs when Jetpack is installed but not connected to wpcom.
                                  if ([errorKey isEqualToString:@"unauthorized"] && error.code == WordPressComRestApiErrorAuthorizationRequired) {
                                      // Jetpack is disabled/installed but not connected. (403 error)
                                      isJetpack = YES;
                                      error = [NSError errorWithDomain:JetpackServiceRemoteErrorDomain
                                                                  code:JetpackServiceRemoteErrorJetpackDisabled
                                                              userInfo:error.userInfo];


                                  }

                                  success(isJetpack, error);
                                  return;
                              }

                              failure(error);
                          }];
}


@end
