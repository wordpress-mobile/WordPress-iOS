#import "JetpackServiceRemote.h"

#import <AFNetworking/AFNetworking.h>

NSString * const JetpackServiceRemoteErrorDomain = @"JetpackServiceRemoteError";
static NSString * const GetUsersBlogsApiPath = @"https://public-api.wordpress.com/get-user-blogs/1.0";

@implementation JetpackServiceRemote

- (void)validateJetpackUsername:(NSString *)username
                       password:(NSString *)password
                      forSiteID:(NSNumber *)siteID
                        success:(void (^)(NSArray *blogIDs))success
                        failure:(void (^)(NSError *error))failure
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager.requestSerializer setAuthorizationHeaderFieldWithUsername:username password:password];
    NSDictionary *parameters = @{
                                 @"f": @"json"
                                 };
    
    [manager GET:GetUsersBlogsApiPath
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             DDLogError(@"Error validating Jetpack user: %@", error);
             if (failure) {
                 NSError *jetpackError = error;
                 if (operation.response.statusCode == 401) {
                     jetpackError = [NSError errorWithDomain:JetpackServiceRemoteErrorDomain
                                                        code:JetpackServiceRemoteErrorInvalidCredentials
                                                    userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Invalid username or password", @""), NSUnderlyingErrorKey: error}];
                 }
                 failure(jetpackError);
             }
         }];
}

@end