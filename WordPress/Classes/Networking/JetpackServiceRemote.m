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
    receives a bool indicating if the site has Jetpack.
 */
- (void)checkSiteHasJetpack:(NSURL *)siteURL
                    success:(void (^)(BOOL isJetpack))success
                    failure:(void (^)(NSError *error))failure
{
    NSString *siteStr = [[NSString stringWithFormat:@"%@%@", siteURL.host, siteURL.path]
                         stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLHostAllowedCharacterSet];
    NSString *scheme = siteURL.scheme ?: @"http";

    NSString *endpoint = [NSString stringWithFormat:@"connect/site-info/%@/%@", scheme, siteStr];
    NSString *path = [self pathForEndpoint:endpoint withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];

    [self.wordPressComRestApi GET:path
                       parameters:nil
                          success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                              NSDictionary *dict = (NSDictionary *)responseObject;
                              BOOL hasJetpack = [[dict numberForKey:@"hasJetpack"] boolValue];
                              success(hasJetpack);
                          } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
                              failure(error);
                          }];
}


@end
