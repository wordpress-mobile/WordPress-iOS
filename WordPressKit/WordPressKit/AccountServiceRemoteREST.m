#import "AccountServiceRemoteREST.h"
#import "RemoteBlog.h"
#import "RemoteBlogOptionsHelper.h"
#import <WordPressKit/WordPressKit-Swift.h>
@import NSObject_SafeExpectations;
@import WordPressShared;

static NSString * const UserDictionaryIDKey = @"ID";
static NSString * const UserDictionaryUsernameKey = @"username";
static NSString * const UserDictionaryEmailKey = @"email";
static NSString * const UserDictionaryDisplaynameKey = @"display_name";
static NSString * const UserDictionaryPrimaryBlogKey = @"primary_blog";
static NSString * const UserDictionaryAvatarURLKey = @"avatar_URL";
static NSString * const UserDictionaryDateKey = @"date";
static NSString * const UserDictionaryEmailVerifiedKey = @"email_verified";

@interface AccountServiceRemoteREST ()

@end

@implementation AccountServiceRemoteREST

- (void)getBlogsWithSuccess:(void (^)(NSArray *))success
                    failure:(void (^)(NSError *))failure
{
    NSString *requestUrl = [self pathForEndpoint:@"me/sites"
                                     withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];

    NSString *locale = [[WordPressComLanguageDatabase new] deviceLanguageSlug];
    NSDictionary *parameters = @{
                                 @"locale": locale
                                 };
    [self.wordPressComRestApi GET:requestUrl
       parameters:parameters
                    success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
              if (success) {
                  success([self remoteBlogsFromJSONArray:responseObject[@"sites"]]);
              }
          } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
              if (failure) {
                  failure(error);
              }
          }];
}

- (void)getAccountDetailsWithSuccess:(void (^)(RemoteUser *remoteUser))success
                             failure:(void (^)(NSError *error))failure
{
    NSString *requestUrl = [self pathForEndpoint:@"me"
                                     withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];
    
    [self.wordPressComRestApi GET:requestUrl
       parameters:nil
          success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
              if (!success) {
                  return;
              }
              RemoteUser *remoteUser = [self remoteUserFromDictionary:responseObject];
              success(remoteUser);
          }
          failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
              if (failure) {
                  failure(error);
              }
          }];
}

- (void)updateBlogsVisibility:(NSDictionary *)blogs
                      success:(void (^)())success
                      failure:(void (^)(NSError *))failure
{
    NSParameterAssert([blogs isKindOfClass:[NSDictionary class]]);

    /*
     The `POST me/sites` endpoint expects it's input in a format like:
     @{
       @"sites": @[
         @"1234": {
           @"visible": @YES
         },
         @"2345": {
           @"visible": @NO
         },
       ]
     }
     */
    NSMutableDictionary *sites = [NSMutableDictionary dictionaryWithCapacity:blogs.count];
    [blogs enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSParameterAssert([key isKindOfClass:[NSNumber class]]);
        NSParameterAssert([obj isKindOfClass:[NSNumber class]]);
        /*
         Blog IDs are pased as strings because JSON dictionaries can't take
         non-string keys. If you try, you get a NSInvalidArgumentException
         */
        NSString *blogID = [key stringValue];
        sites[blogID] = @{ @"visible": obj };
    }];

    NSDictionary *parameters = @{
                                 @"sites": sites
                                 };
    NSString *path = [self pathForEndpoint:@"me/sites"
                               withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];
    [self.wordPressComRestApi POST:path
        parameters:parameters
           success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
               if (success) {
                   success();
               }
           } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
               if (failure) {
                   failure(error);
               }
           }];
}

- (void)isEmailAvailable:(NSString *)email success:(void (^)(BOOL available))success failure:(void (^)(NSError *error))failure
{
    NSString *path = @"https://public-api.wordpress.com/is-available/email";
    [self.wordPressComRestApi GET:path
       parameters:@{ @"q": email, @"format": @"json"}
          success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
              if (!success) {
                  return;
              }

              // If the email address is not available (has already been used)
              // the endpoint will reply with a 200 status code and an JSON
              // object describing an error.
              // The error is that the queried email address is not available,
              // which is our failure case. Test the error response for the
              // "taken" reason to confirm the email address exists.
              BOOL available = NO;
              if ([responseObject isKindOfClass:[NSDictionary class]]) {
                  NSDictionary *dict = (NSDictionary *)responseObject;
                  available = [[dict numberForKey:@"available"] boolValue];
              }
              success(available);

          } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
              if (failure) {
                  failure(error);
              }
          }];
}

- (void)isUsernameAvailable:(NSString *)username
                    success:(void (^)(BOOL available))success
                    failure:(void (^)(NSError *error))failure
{
    NSString *path = @"https://public-api.wordpress.com/is-available/username";
    [self.wordPressComRestApi GET:path
                       parameters:@{ @"q": username, @"format": @"json"}
                          success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                              if (!success) {
                                  return;
                              }

                              // currently the endpoint will not respond with available=false
                              // but it could one day, and this should still work in that case
                              BOOL available = NO;
                              if ([responseObject isKindOfClass:[NSDictionary class]]) {
                                  NSDictionary *dict = (NSDictionary *)responseObject;
                                  available = [[dict numberForKey:@"available"] boolValue];
                              }
                              success(available);
                          } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
                              // If the username is not available (has already been used)
                              // the endpoint will reply with a 200 status code but describe
                              // an error. This causes a JSON error, which we can test for here.
                              if (httpResponse.statusCode == 200 && [error.description containsString:@"JSON"]) {
                                  if (success) {
                                      success(true);
                                  }
                              } else if (failure) {
                                  failure(error);
                              }
                          }];
}

- (void)requestWPComAuthLinkForEmail:(NSString *)email
                            clientID:(NSString *)clientID
                        clientSecret:(NSString *)clientSecret
                         wpcomScheme:(NSString *)scheme
                             success:(void (^)())success failure:(void (^)(NSError *error))failure
{
    NSAssert([email length] > 0, @"Needs an email address.");

    NSString *path = [self pathForEndpoint:@"auth/send-login-email"
                                     withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];

    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                  @"email": email,
                                                                                  @"client_id": clientID,
                                                                                  @"client_secret": clientSecret,
                                                                                  }];
    if (![@"wordpress" isEqualToString:scheme]) {
        [params setObject:scheme forKey:@"scheme"];
    }

    [self.wordPressComRestApi POST:path
        parameters:[NSDictionary dictionaryWithDictionary:params]
           success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
               if (success) {
                   success();
               }
           } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
               if (failure) {
                   failure(error);
               }
           }];
}


#pragma mark - Private Methods

- (RemoteUser *)remoteUserFromDictionary:(NSDictionary *)dictionary
{
    RemoteUser *remoteUser = [RemoteUser new];
    remoteUser.userID = [dictionary numberForKey:UserDictionaryIDKey];
    remoteUser.username = [dictionary stringForKey:UserDictionaryUsernameKey];
    remoteUser.email = [dictionary stringForKey:UserDictionaryEmailKey];
    remoteUser.displayName = [dictionary stringForKey:UserDictionaryDisplaynameKey];
    remoteUser.primaryBlogID = [dictionary numberForKey:UserDictionaryPrimaryBlogKey];
    remoteUser.avatarURL = [dictionary stringForKey:UserDictionaryAvatarURLKey];
    // TODO: Import dateWithISO8601String
    // remoteUser.dateCreated = [NSDate dateWithISO8601String:[dictionary stringForKey:UserDictionaryDateKey]];
    remoteUser.emailVerified = [[dictionary numberForKey:UserDictionaryEmailVerifiedKey] boolValue];
    
    return remoteUser;
}

- (NSArray *)remoteBlogsFromJSONArray:(NSArray *)jsonBlogs
{
    NSArray *blogs = jsonBlogs;
    return [blogs wp_map:^id(NSDictionary *jsonBlog) {
        return [[RemoteBlog alloc] initWithJSONDictionary:jsonBlog];
    }];
    return blogs;
}

@end
