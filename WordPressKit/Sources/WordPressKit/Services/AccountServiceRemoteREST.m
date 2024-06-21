#import "AccountServiceRemoteREST.h"
#import "WPKit-Swift.h"
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

MagicLinkParameter const MagicLinkParameterFlow = @"flow";
MagicLinkParameter const MagicLinkParameterSource = @"source";

MagicLinkSource const MagicLinkSourceDefault = @"default";
MagicLinkSource const MagicLinkSourceJetpackConnect = @"jetpack";

MagicLinkFlow const MagicLinkFlowLogin = @"login";
MagicLinkFlow const MagicLinkFlowSignup = @"signup";

@interface AccountServiceRemoteREST ()

@end

@implementation AccountServiceRemoteREST

- (void)getBlogs:(BOOL)filterJetpackSites
         success:(void (^)(NSArray *))success
         failure:(void (^)(NSError *))failure
{
    if (filterJetpackSites) {
        [self getBlogsWithParameters:@{@"filters": @"jetpack"} success:success failure:failure];
    } else {
        [self getBlogsWithSuccess:success failure:failure];
    }
}

- (void)getBlogsWithSuccess:(void (^)(NSArray *))success
                    failure:(void (^)(NSError *))failure
{
    [self getBlogsWithParameters:nil success:success failure:failure];
}

- (void)getVisibleBlogsWithSuccess:(void (^)(NSArray *))success
                           failure:(void (^)(NSError *))failure
{
    [self getBlogsWithParameters:@{@"site_visibility": @"visible"} success:success failure:failure];
}

- (void)getAccountDetailsWithSuccess:(void (^)(RemoteUser *remoteUser))success
                             failure:(void (^)(NSError *error))failure
{
    NSString *requestUrl = [self pathForEndpoint:@"me"
                                     withVersion:WordPressComRESTAPIVersion_1_1];
    
    [self.wordPressComRESTAPI get:requestUrl
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
                      success:(void (^)(void))success
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
                               withVersion:WordPressComRESTAPIVersion_1_1];
    [self.wordPressComRESTAPI post:path
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

- (void)isPasswordlessAccount:(NSString *)identifier success:(void (^)(BOOL passwordless))success failure:(void (^)(NSError *error))failure
{
    NSString *encodedIdentifier = [identifier stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLPathRFC3986AllowedCharacterSet];

    NSString *path = [self pathForEndpoint:[NSString stringWithFormat:@"users/%@/auth-options", encodedIdentifier]
                               withVersion:WordPressComRESTAPIVersion_1_1];
    [self.wordPressComRESTAPI get:path
                       parameters:nil
                          success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                              if (!success) {
                                  return;
                              }
                              NSDictionary *dict = (NSDictionary *)responseObject;
                              BOOL passwordless = [[dict numberForKey:@"passwordless"] boolValue];
                              success(passwordless);
                              
                          } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
                              if (failure) {
                                  failure(error);
                              }
                          }];
}

- (void)isEmailAvailable:(NSString *)email success:(void (^)(BOOL available))success failure:(void (^)(NSError *error))failure
{
    static NSString * const errorEmailAddressInvalid = @"invalid";
    static NSString * const errorEmailAddressTaken = @"taken";
    
    [self.wordPressComRESTAPI get:@"is-available/email"
                       parameters:@{ @"q": email, @"format": @"json"}
                          success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSString *error = [responseObject objectForKey:@"error"];
            NSString *message = [responseObject objectForKey:@"message"];
            
            if (error != NULL) {
                if ([error isEqualToString:errorEmailAddressTaken]) {
                    // While this is informed as an error by the endpoint, for the purpose of this method
                    // it's a success case.  We just need to inform the caller that the email is not
                    // available.
                    success(false);
                } else if ([error isEqualToString:errorEmailAddressInvalid]) {
                    NSError* error = [[NSError alloc] initWithDomain:AccountServiceRemoteErrorDomain
                                                                code:AccountServiceRemoteEmailAddressInvalid
                                                            userInfo:@{
                                                                @"response": responseObject,
                                                                NSLocalizedDescriptionKey: message,
                                                            }];
                    if (failure) {
                        failure(error);
                    }
                } else {
                    NSError* error = [[NSError alloc] initWithDomain:AccountServiceRemoteErrorDomain
                                                                code:AccountServiceRemoteEmailAddressCheckError
                                                            userInfo:@{
                                                                @"response": responseObject,
                                                                NSLocalizedDescriptionKey: message,
                                                            }];
                    if (failure) {
                        failure(error);
                    }
                }
                
                return;
            }
            
            if (success) {
                BOOL available = [[responseObject numberForKey:@"available"] boolValue];
                success(available);
            }
        } else {
            NSError* error = [[NSError alloc] initWithDomain:AccountServiceRemoteErrorDomain
                                                        code:AccountServiceRemoteCantReadServerResponse
                                                    userInfo:@{@"response": responseObject}];

            if (failure) {
                failure(error);
            }
        }
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
    [self.wordPressComRESTAPI get:@"is-available/username"
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
                              source:(MagicLinkSource)source
                         wpcomScheme:(NSString *)scheme
                             success:(void (^)(void))success
                             failure:(void (^)(NSError *error))failure
{
    NSString *path = [self pathForEndpoint:@"auth/send-login-email"
                               withVersion:WordPressComRESTAPIVersion_1_3];
    
    NSDictionary *extraParams = @{
        MagicLinkParameterFlow: MagicLinkFlowLogin,
        MagicLinkParameterSource: source
    };
    
    [self requestWPComMagicLinkForEmail:email
                                   path:path
                               clientID:clientID
                           clientSecret:clientSecret
                            extraParams:extraParams
                            wpcomScheme:scheme
                                success:success
                                failure:failure];
}

- (void)requestWPComSignupLinkForEmail:(NSString *)email
                              clientID:(NSString *)clientID
                          clientSecret:(NSString *)clientSecret
                           wpcomScheme:(NSString *)scheme
                               success:(void (^)(void))success
                               failure:(void (^)(NSError *error))failure
{
    
    NSString *path = [self pathForEndpoint:@"auth/send-signup-email"
                               withVersion:WordPressComRESTAPIVersion_1_1];
    
    NSDictionary *extraParams = @{
        @"signup_flow_name": @"mobile-ios",
        MagicLinkParameterFlow: MagicLinkFlowSignup
    };

    [self requestWPComMagicLinkForEmail:email
                                   path:path
                               clientID:clientID
                           clientSecret:clientSecret
                            extraParams:extraParams
                            wpcomScheme:scheme
                                success:success
                                failure:failure];
}

- (void)requestWPComMagicLinkForEmail:(NSString *)email
                                 path:(NSString *)path
                             clientID:(NSString *)clientID
                         clientSecret:(NSString *)clientSecret
                          extraParams:(nullable NSDictionary *)extraParams
                          wpcomScheme:(NSString *)scheme
                              success:(void (^)(void))success
                              failure:(void (^)(NSError *error))failure
{
    NSAssert([email length] > 0, @"Needs an email address.");
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                  @"email": email,
                                                                                  @"client_id": clientID,
                                                                                  @"client_secret": clientSecret
    }];

    if (![@"wordpress" isEqualToString:scheme]) {
        [params setObject:scheme forKey:@"scheme"];
    }
    
    if (extraParams != nil) {
        [params addEntriesFromDictionary:extraParams];
    }

    [self.wordPressComRESTAPI post:path
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

- (void)requestVerificationEmailWithSucccess:(void (^)(void))success
                                    failure:(void (^)(NSError *))failure
{
    NSString *path = [self pathForEndpoint:@"me/send-verification-email"
                               withVersion:WordPressComRESTAPIVersion_1_1];

    [self.wordPressComRESTAPI post:path parameters:nil success:^(id _Nonnull responseObject, NSHTTPURLResponse * _Nullable httpResponse) {
        if (success) {
            success();
        }
    } failure:^(NSError * _Nonnull error, NSHTTPURLResponse * _Nullable response) {
        if (failure) {
            failure(error);
        }
    }];
}

#pragma mark - Private Methods

- (void)getBlogsWithParameters:(NSDictionary *)parameters
                       success:(void (^)(NSArray *))success
                       failure:(void (^)(NSError *))failure
{
    NSString *requestUrl = [self pathForEndpoint:@"me/sites"
                                     withVersion:WordPressComRESTAPIVersion_1_2];
    [self.wordPressComRESTAPI get:requestUrl
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

- (RemoteUser *)remoteUserFromDictionary:(NSDictionary *)dictionary
{
    RemoteUser *remoteUser = [RemoteUser new];
    remoteUser.userID = [dictionary numberForKey:UserDictionaryIDKey];
    remoteUser.username = [dictionary stringForKey:UserDictionaryUsernameKey];
    remoteUser.email = [dictionary stringForKey:UserDictionaryEmailKey];
    remoteUser.displayName = [dictionary stringForKey:UserDictionaryDisplaynameKey];
    remoteUser.primaryBlogID = [dictionary numberForKey:UserDictionaryPrimaryBlogKey];
    remoteUser.avatarURL = [dictionary stringForKey:UserDictionaryAvatarURLKey];
    remoteUser.dateCreated = [NSDate dateWithISO8601String:[dictionary stringForKey:UserDictionaryDateKey]];
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
