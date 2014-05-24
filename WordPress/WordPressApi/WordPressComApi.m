#import "WordPressComApi.h"
#import "WordPressComApiCredentials.h"
#import "NSString+Helpers.h"
#import <AFNetworking/AFNetworking.h>
#import <UIDeviceHardware.h>
#import "UIDevice+WordPressIdentifier.h"
#import "WordPressAppDelegate.h"
#import "NotificationsManager.h"

static NSString *const WordPressComApiClientEndpointURL = @"https://public-api.wordpress.com/rest/v1/";
static NSString *const WordPressComApiOauthBaseUrl = @"https://public-api.wordpress.com/oauth2";
NSString *const WordPressComApiNotificationFields = @"id,type,unread,body,subject,timestamp,meta";
static NSString *const WordPressComApiLoginUrl = @"https://wordpress.com/wp-login.php";
NSString *const WordPressComApiErrorDomain = @"com.wordpress.api";
NSString *const WordPressComApiErrorCodeKey = @"WordPressComApiErrorCodeKey";
NSString *const WordPressComApiErrorMessageKey = @"WordPressComApiErrorMessageKey";

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
@end
@implementation WPJSONRequestOperation

-(id)initWithRequest:(NSURLRequest *)urlRequest
{
	self = [super initWithRequest:urlRequest];
	
	if (self)
	{
		self.responseSerializer = [[AFJSONResponseSerializer alloc] init];
	}
	
	return self;
}

@end

@interface WordPressComApi ()
@property (readwrite, nonatomic, strong) NSString *username;
@property (readwrite, nonatomic, strong) NSString *password;
@property (readwrite, nonatomic, strong) NSString *authToken;
@property (readwrite, nonatomic, strong) AFHTTPRequestOperationManager *httpManager;
- (void)clearWpcomCookies;

@end

@implementation WordPressComApi

#pragma - Initializers
- (instancetype)initWithBaseURL:(NSURL *) baseURL{
    self = [super init];
    if (!self) {
        return nil;
    }
    _httpManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:baseURL];
    NSString* userAgent = [[WordPressAppDelegate sharedWordPressApplicationDelegate] applicationUserAgent];
    [_httpManager.requestSerializer setValue:userAgent forHTTPHeaderField:@"User-Agent"];
    return self;
}

- (instancetype)initWithOAuthToken:(NSString *)authToken
{
	NSParameterAssert([authToken isKindOfClass:[NSString class]]);
    NSURL* url = [NSURL URLWithString:WordPressComApiClientEndpointURL];
	self = [self initWithBaseURL:url];
	if (!self) {
        return nil;
	}
	_authToken = authToken;
    [self setAuthorizationHeaderWithToken:_authToken];
	return self;
}

- (AFHTTPRequestOperation *)HTTPRequestOperationWithRequest:(NSURLRequest *)request
                                                    success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                                    failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    WPJSONRequestOperation *operation = [[WPJSONRequestOperation alloc] initWithRequest:request];
	
    operation.shouldUseCredentialStorage = self.httpManager.shouldUseCredentialStorage;
    operation.credential = self.httpManager.credential;
    operation.securityPolicy = self.httpManager.securityPolicy;
	
    [operation setCompletionBlockWithSuccess:success failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSError *newError = error;
        if (operation.response.statusCode >= 400) {
            NSString *errorMessage = [operation.responseObject objectForKey:@"message"];
            NSUInteger errorCode = WordPressComApiErrorJSON;
            if ([operation.responseObject objectForKey:@"error"] && errorMessage) {
                NSString *errorString = [operation.responseObject objectForKey:@"error"];
                if ([errorString isEqualToString:@"invalid_token"]) {
                    errorCode = WordPressComApiErrorInvalidToken;
                } else if ([errorString isEqualToString:@"authorization_required"]) {
                    errorCode = WordPressComApiErrorAuthorizationRequired;
                }
                newError = [NSError errorWithDomain:WordPressComApiErrorDomain code:errorCode userInfo:@{NSLocalizedDescriptionKey: errorMessage, WordPressComApiErrorCodeKey: error}];
            }
        }
        
        if (failure) {
            failure(operation, newError);
        }
        
    }];
	
    return operation;
}

+ (WordPressComApi *)anonymousApi {
    static WordPressComApi *_anonymousApi = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        DDLogVerbose(@"Initializing anonymous API");
        _anonymousApi = [[self alloc] initWithBaseURL:[NSURL URLWithString:WordPressComApiClientEndpointURL] ];
    });

    return _anonymousApi;
}

#pragma mark - Account management

- (void)clearAuthorizationHeader
{
	[self.httpManager.requestSerializer setValue:nil forHTTPHeaderField:@"Authorization"];
}

- (void)reset {
    DDLogMethod();

    [self.httpManager.operationQueue cancelAllOperations];
    self.authToken = nil;
    self.username = nil;
    self.password = nil;
 
    [self clearWpcomCookies];
    [self clearAuthorizationHeader];
}

- (BOOL)hasCredentials {
    return self.authToken.length > 0;
}

- (void)invalidateOAuth2Token {
    [self setAuthToken:nil];
}

- (void)validateWPComAccountWithEmail:(NSString *)email andUsername:(NSString *)username andPassword:(NSString *)password success:(void (^)(id responseObject))success failure:(void (^)(NSError *error))failure
{
    [self createWPComAccountWithEmail:email andUsername:username andPassword:password validate:YES success:success failure:failure];
}

- (void)createWPComAccountWithEmail:(NSString *)email andUsername:(NSString *)username andPassword:(NSString *)password success:(void (^)(id responseObject))success failure:(void (^)(NSError *error))failure
{
    [self createWPComAccountWithEmail:email andUsername:username andPassword:password validate:NO success:success failure:failure];
}

- (void)createWPComAccountWithEmail:(NSString *)email andUsername:(NSString *)username andPassword:(NSString *)password validate:(BOOL)validate success:(void (^)(id responseObject))success failure:(void (^)(NSError *error))failure
{
    NSParameterAssert(email != nil);
    NSParameterAssert(username != nil);
    NSParameterAssert(password != nil);

    void (^successBlock)(AFHTTPRequestOperation *, id) = ^(AFHTTPRequestOperation *operation, id responseObject) {
        success(responseObject);
    };
    
    void (^failureBlock)(AFHTTPRequestOperation *, NSError *) = ^(AFHTTPRequestOperation *operation, NSError *error){
        NSError *errorWithLocalizedMessage;
        // This endpoint is throttled, so check if we've sent too many requests and fill that error in as
        // when too many requests occur the API just spits out an html page.
        if ([error.userInfo objectForKey:WordPressComApiErrorCodeKey] == nil) {
            NSString *responseString = [operation responseString];
            if (responseString != nil && [responseString rangeOfString:@"Limit reached"].location != NSNotFound) {
                NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] initWithDictionary:error.userInfo];
                [userInfo setValue:NSLocalizedString(@"Limit reached. You can try again in 1 minute. Trying again before that will only increase the time you have to wait before the ban is lifted. If you think this is in error, contact support.", @"") forKey:WordPressComApiErrorMessageKey];
                [userInfo setValue:@"too_many_requests" forKey:WordPressComApiErrorCodeKey];
                errorWithLocalizedMessage = [[NSError alloc] initWithDomain:error.domain code:error.code userInfo:userInfo];
            }
        } else {
            NSString *localizedErrorMessage = [self errorMessageForError:error];
            NSString *errorCode = [error.userInfo objectForKey:WordPressComApiErrorCodeKey];
            NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] initWithDictionary:error.userInfo];
            [userInfo setValue:errorCode forKey:WordPressComApiErrorCodeKey];
            [userInfo setValue:localizedErrorMessage forKey:WordPressComApiErrorMessageKey];
            errorWithLocalizedMessage = [[NSError alloc] initWithDomain:error.domain code:error.code userInfo:userInfo];
        }
        
        failure(errorWithLocalizedMessage);
    };
    
    NSDictionary *params = @{
                             @"email": email,
                             @"username" : username,
                             @"password" : password,
                             @"validate" : @(validate),
                             @"client_id" : [WordPressComApiCredentials client],
                             @"client_secret" : [WordPressComApiCredentials secret]
                             };
    
    [self.httpManager POST:@"users/new" parameters:params success:successBlock failure:failureBlock];

}

- (void)validateWPComBlogWithUrl:(NSString *)blogUrl andBlogTitle:(NSString *)blogTitle andLanguageId:(NSNumber *)languageId success:(void (^)(id))success failure:(void (^)(NSError *))failure
{
    [self createWPComBlogWithUrl:blogUrl andBlogTitle:blogTitle andLanguageId:languageId andBlogVisibility:WordPressComApiBlogVisibilityPublic validate:YES success:success failure:failure];
}

- (void)createWPComBlogWithUrl:(NSString *)blogUrl andBlogTitle:(NSString *)blogTitle andLanguageId:(NSNumber *)languageId andBlogVisibility:(WordPressComApiBlogVisibility)visibility success:(void (^)(id))success failure:(void (^)(NSError *))failure
{
    [self createWPComBlogWithUrl:blogUrl andBlogTitle:blogTitle andLanguageId:languageId andBlogVisibility:visibility validate:NO success:success failure:failure];
}

- (void)createWPComBlogWithUrl:(NSString *)blogUrl andBlogTitle:(NSString *)blogTitle andLanguageId:(NSNumber *)languageId andBlogVisibility:(WordPressComApiBlogVisibility)visibility validate:(BOOL)validate success:(void (^)(id))success failure:(void (^)(NSError *))failure
{
    NSParameterAssert(blogUrl != nil);
    NSParameterAssert(languageId != nil);
    
    void (^successBlock)(AFHTTPRequestOperation *, id) = ^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *response = responseObject;
        if ([response count] == 0) {
            // There was an error creating the blog as a successful call yields a dictionary back.
            NSString *localizedErrorMessage = NSLocalizedString(@"Unknown error", nil);
            NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
            [userInfo setValue:localizedErrorMessage forKey:WordPressComApiErrorMessageKey];
            NSError *errorWithLocalizedMessage = [[NSError alloc] initWithDomain:WordPressComApiErrorDomain code:0 userInfo:userInfo];

            failure(errorWithLocalizedMessage);
        } else {
            success(responseObject);
        }
    };
    
    void (^failureBlock)(AFHTTPRequestOperation *, NSError *) = ^(AFHTTPRequestOperation *operation, NSError *error){
        NSError *errorWithLocalizedMessage;
        
        if ([error.userInfo objectForKey:WordPressComApiErrorCodeKey] == nil) {
            NSString *responseString = [operation responseString];
            if (responseString != nil && [responseString rangeOfString:@"Limit reached"].location != NSNotFound) {
                NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] initWithDictionary:error.userInfo];
                [userInfo setValue:NSLocalizedString(@"Limit reached. You can try again in 1 minute. Trying again before that will only increase the time you have to wait before the ban is lifted. If you think this is in error, contact support.", @"") forKey:WordPressComApiErrorMessageKey];
                [userInfo setValue:@"too_many_requests" forKey:WordPressComApiErrorCodeKey];
                errorWithLocalizedMessage = [[NSError alloc] initWithDomain:error.domain code:error.code userInfo:userInfo];
            }
        }
        else {
            NSString *errorCode = [error.userInfo objectForKey:WordPressComApiErrorCodeKey];
            NSString *localizedErrorMessage = [self errorMessageForError:error];
            NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] initWithDictionary:error.userInfo];
            [userInfo setValue:errorCode forKey:WordPressComApiErrorCodeKey];
            [userInfo setValue:localizedErrorMessage forKey:WordPressComApiErrorMessageKey];
            errorWithLocalizedMessage = [[NSError alloc] initWithDomain:error.domain code:error.code userInfo:userInfo];            
        }
        failure(errorWithLocalizedMessage);
    };
    
    if (blogTitle == nil) {
        blogTitle = @"";
    }
    
    int blogVisibility = 1;
    if (visibility == WordPressComApiBlogVisibilityPublic) {
        blogVisibility = 1;
    } else if (visibility == WordPressComApiComBlogVisibilityPrivate) {
        blogVisibility = -1;
    } else {
        // Hidden
        blogVisibility = 0;
    }
    
    NSDictionary *params = @{
                             @"blog_name": blogUrl,
                             @"blog_title": blogTitle,
                             @"lang_id": languageId,
                             @"public": @(blogVisibility),
                             @"validate": @(validate),
                             @"client_id": [WordPressComApiCredentials client],
                             @"client_secret": [WordPressComApiCredentials secret]
                             };
    
    [self.httpManager POST:@"sites/new" parameters:params success:successBlock failure:failureBlock];
}

- (void)clearWpcomCookies {
    NSArray *wpcomCookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
    for (NSHTTPCookie *cookie in wpcomCookies) {
        if ([cookie.domain hasSuffix:@"wordpress.com"]) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
        }
    }
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

#pragma mark - Posts

- (void)fetchPost:(NSUInteger)postID
         fromSite:(NSUInteger)siteID
          success:(WordPressComApiRestSuccessResponseBlock)success
          failure:(WordPressComApiRestSuccessFailureBlock)failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%d/posts/%d", siteID, postID];
    [self.httpManager POST:path
        parameters:nil
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               if (!success) {
                   return;
               }
               success(operation, responseObject);
               
           } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               if (failure) {
                   failure(operation, error);
               }
           }];
}

- (void)fetchSiteMetaPost:(NSUInteger)postID
                 fromSite:(NSUInteger)siteID
                  success:(WordPressComApiRestSuccessResponseBlock)success
                  failure:(WordPressComApiRestSuccessFailureBlock)failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%d/posts/%d/?meta=site", siteID, postID];
    [self.httpManager POST:path
                parameters:nil
                   success:success
                   failure:failure];
}


- (void)likePost:(NSUInteger)postID
         forSite:(NSUInteger)siteID
         success:(WordPressComApiRestSuccessResponseBlock)success
         failure:(WordPressComApiRestSuccessFailureBlock)failure
{
    
    NSString *path = [NSString stringWithFormat:@"sites/%d/posts/%d/likes/new", siteID, postID];
    [self.httpManager POST:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(operation, responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(operation, error);
        }
    }];
}

- (void)unlikePost:(NSUInteger)postID
           forSite:(NSUInteger)siteID
           success:(WordPressComApiRestSuccessResponseBlock)success
           failure:(WordPressComApiRestSuccessFailureBlock)failure {
    NSString *path = [NSString stringWithFormat:@"sites/%d/posts/%d/likes/mine/delete", siteID, postID];
    [self.httpManager POST:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(operation, responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(operation, error);
        }
    }];
}

- (void)followSite:(NSUInteger)siteID
           success:(WordPressComApiRestSuccessResponseBlock)success
           failure:(WordPressComApiRestSuccessFailureBlock)failure {
    NSString *path = [NSString stringWithFormat:@"sites/%d/follows/new", siteID];
    [self.httpManager POST:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(operation, responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(operation, error);
        }
    }];
}

- (void)unfollowSite:(NSUInteger)siteID
             success:(WordPressComApiRestSuccessResponseBlock)success
             failure:(WordPressComApiRestSuccessFailureBlock)failure {
    NSString *path = [NSString stringWithFormat:@"sites/%d/follows/mine/delete", siteID];
    [self.httpManager POST:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(operation, responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(operation, error);
        }
    }];
}

- (void)followSiteAtURL:(NSString *)siteURL
                success:(WordPressComApiRestSuccessResponseBlock)success
                failure:(WordPressComApiRestSuccessFailureBlock)failure {
    NSString *path = @"read/following/mine/new";
    NSDictionary *params = @{@"url": siteURL};
    [self.httpManager POST:path parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(operation, responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(operation, error);
        }
    }];
}

- (void)unfollowSiteAtURL:(NSString *)siteURL
                  success:(WordPressComApiRestSuccessResponseBlock)success
                  failure:(WordPressComApiRestSuccessFailureBlock)failure {
    NSString *path = @"read/following/mine/delete";
    NSDictionary *params = @{@"url": siteURL};
    [self.httpManager POST:path parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(operation, responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(operation, error);
        }
    }];
}

- (void)reblogPost:(NSUInteger)postID
          fromSite:(NSUInteger)siteID
            toSite:(NSUInteger)targetSiteID
              note:(NSString *)note
           success:(WordPressComApiRestSuccessResponseBlock)success
           failure:(WordPressComApiRestSuccessFailureBlock)failure {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:@(targetSiteID) forKey:@"destination_site_id"];
    
    if ([note length] > 0) {
        [params setObject:note forKey:@"note"];
    }
    
    NSString *path = [NSString stringWithFormat:@"sites/%d/posts/%d/reblogs/new", siteID, postID];
    [self.httpManager POST:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(operation, responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(operation, error);
        }
    }];
}

/**
 Fetches the posts from the specified remote endpoint
 
 @param params A dictionary of parameters supported by the endpoint. Params are converted to the request's query string.
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)fetchPostsFromEndpoint:(NSURL *)endpoint
                withParameters:(NSDictionary *)params
                       success:(WordPressComApiRestSuccessResponseBlock)success
                       failure:(WordPressComApiRestSuccessFailureBlock)failure
{
    
    [self.httpManager GET:[endpoint absoluteString]
       parameters:params
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              if (!success) {
                  return;
              }
              
              success(operation, responseObject);
              
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              if (failure) {
                  failure(operation, error);
              }
          }];
}

#pragma mark - Stats

- (void)fetchStatsForUrls:(NSArray *) urls
    withCompletionHandler:(WordPressComApiRestSuccessResponseBlock)completionHandler
           failureHandler:(WordPressComApiRestSuccessFailureBlock)failureHandler
{
    
    [self.httpManager GET:@"batch"
               parameters:@{ @"urls" : urls}
                  success:^void (AFHTTPRequestOperation *operation, id responseObject){
                      if (completionHandler){
                          completionHandler(operation, responseObject);
                      }
                  }
                  failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                      if (failureHandler){
                          failureHandler(operation , error);
                      }
                  }
    ];
}

#pragma  mark - Menu

- (void)fetchReaderMenuWithSuccess:(WordPressComApiRestSuccessResponseBlock)success
                           failure:(WordPressComApiRestSuccessFailureBlock)failure
{
    NSString *path = @"read/menu";
    
    [self.httpManager GET:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if (!success) {
            return;
        }
        success(operation, responseObject);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(operation, error);
        }
    }];
    
}


#pragma mark - Notifications

- (void)saveNotificationSettings:(NSDictionary *)settings
                        deviceId:(NSString *)deviceId
                         success:(void(^)())success
                         failure:(void (^)(NSError *error))failure {
    
    if (deviceId.length == 0) {
        DDLogWarn(@"Unable to saveNotificationSettings - Device ID is empty!");
        return;
    }

    NSString *path = [NSString stringWithFormat:@"device/%@", deviceId];
    NSDictionary *parameters = @{@"settings": settings};
    [self.httpManager POST:path
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
    
    NSString *path = [NSString stringWithFormat:@"device/%@", deviceId];
    [self.httpManager GET:path
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

    NSString *path = [NSString stringWithFormat:@"devices/%@/delete", deviceId];
    [self.httpManager POST:path
        parameters:nil
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               DDLogInfo(@"Successfully unregistered device ID %@", deviceId);
               if (success) {
                   success();
               }
           }
           failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               DDLogError(@"Unable to unregister push for device ID %@: %@", deviceId, error);
               if (failure) {
                   failure(error);
               }
           }
     ];
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
                                 @"device_uuid"     : [[UIDevice currentDevice] wordpressIdentifier],
                                 };
    
    [self.httpManager POST:@"devices/new"
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

- (void)fetchNewUnseenNotificationsWithSuccess:(void (^)(NSArray *notes))success failure:(void (^)(NSError *error))failure {
    NSDictionary *params = @{@"unread": @"true",
                             @"number": @"20",
                             @"num_note_items": @"20",
                             @"fields": WordPressComApiNotificationFields};
    [self.httpManager GET:@"notifications" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSNumber *lastSeenTime = [responseObject objectForKey:@"last_seen_time"];
        NSArray *notes = [responseObject objectForKey:@"notes"];
        if ([notes count] > 0) {
            NSMutableArray *unseenNotes = [[NSMutableArray alloc] initWithCapacity:[notes count]];
            [notes enumerateObjectsUsingBlock:^(id noteData, NSUInteger idx, BOOL *stop) {
                NSNumber *timestamp = [noteData objectForKey:@"timestamp"];
                if ([timestamp compare:lastSeenTime] == NSOrderedDescending) {
                    [unseenNotes addObject:noteData];
                }
            }];
            
            if (success) {
                success([NSArray arrayWithArray:unseenNotes]);
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (void)fetchRecentNotificationsWithSuccess:(void (^)(NSArray *))success failure:(WordPressComApiRestSuccessFailureBlock)failure {
    [self fetchNotificationsWithParameters:nil success:success failure:failure];
}

- (void)fetchNotificationsSince:(NSNumber *)timestamp
                        success:(void (^)(NSArray *notes))success
                        failure:(WordPressComApiRestSuccessFailureBlock)failure {
    NSDictionary *parameters = nil;
    if (timestamp != nil) {
        parameters = @{@"since": timestamp};
    }
    [self fetchNotificationsWithParameters:parameters success:success failure:failure];
}

- (void)fetchNotificationsBefore:(NSNumber *)timestamp
                         success:(void (^)(NSArray *notes))success
                         failure:(WordPressComApiRestSuccessFailureBlock)failure {
    NSDictionary *parameters = nil;
    if (timestamp != nil) {
        parameters = @{@"before": timestamp};
    }
    [self fetchNotificationsWithParameters:parameters success:success failure:failure];
}

- (void)fetchNotificationsWithParameters:(NSDictionary *)parameters success:(void (^)(NSArray *notes))success failure:(WordPressComApiRestSuccessFailureBlock)failure {
    NSMutableDictionary *requestParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
    [requestParameters setObject:WordPressComApiNotificationFields forKey:@"fields"];
    [requestParameters setObject:[NSNumber numberWithInt:20] forKey:@"number"];
    [requestParameters setObject:[NSNumber numberWithInt:20] forKey:@"num_note_items"];
    
    [self.httpManager GET:@"notifications/" parameters:requestParameters success:^(AFHTTPRequestOperation *operation, id responseObject){
        if (success) {
            success(responseObject[@"notes"]);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(operation, error);
        }
    }];
}

- (void)refreshNotifications:(NSArray *)noteIDs fields:(NSString *)fields success:(void (^)(NSArray *notes))success failure:(WordPressComApiRestSuccessFailureBlock)failure {
    if ([noteIDs count] == 0) {
        return;
    }

    if (fields == nil) {
        fields = WordPressComApiNotificationFields;
    }
    
    NSDictionary *params = @{
        @"fields": fields,
        @"ids": noteIDs
    };
    [self.httpManager GET:@"notifications/" parameters:params success:^(AFHTTPRequestOperation *operation, id response){
        if (success) {
            success(response[@"notes"]);
        }
    } failure:failure];
}

- (void)markNoteAsRead:(NSString *)noteID success:(WordPressComApiRestSuccessResponseBlock)success failure:(WordPressComApiRestSuccessFailureBlock)failure {
    NSDictionary *params = @{ @"counts" : @{ noteID : @"1" } };
    [self.httpManager POST:@"notifications/read"
                   parameters:params
                      success:success
                      failure:failure];
}

- (void)updateNoteLastSeenTime:(NSNumber *)timestamp success:(WordPressComApiRestSuccessResponseBlock)success failure:(WordPressComApiRestSuccessFailureBlock)failure {
    [self.httpManager POST:@"notifications/seen" parameters:@{ @"time" : timestamp } success:success failure:failure];
}

- (void)followBlog:(NSUInteger)blogID isFollowing:(BOOL)following success:(WordPressComApiRestSuccessResponseBlock)success failure:(WordPressComApiRestSuccessFailureBlock)failure {
    NSString *followPath = [NSString stringWithFormat: @"sites/%d/follows/new", blogID];
    if (following) {
        followPath = [followPath stringByReplacingOccurrencesOfString:@"new" withString:@"mine/delete"];
    }
    [self.httpManager POST:followPath
        parameters:nil
           success:^(AFHTTPRequestOperation *operation, id responseObject){
               if (success != nil) success(operation, responseObject);
           }
           failure:failure];
}

#pragma mark - Comments

- (void)getCommentsForPost:(NSUInteger)postID
                  fromSite:(NSString *)siteID
            withParameters:(NSDictionary*)params
                   success:(WordPressComApiRestSuccessResponseBlock)success
                   failure:(WordPressComApiRestSuccessFailureBlock)failure
{
    
    NSString *path = [NSString stringWithFormat:@"sites/%@/posts/%i/replies", siteID, postID];
    
    [self.httpManager GET:path parameters:params success:success failure:failure];
    
}

- (void)getComment:(NSUInteger)commentID
          fromSite:(NSString *)siteID
           success:(WordPressComApiRestSuccessResponseBlock)success
           failure:(WordPressComApiRestSuccessFailureBlock)failure
{
    NSString *commentPath = [NSString stringWithFormat:@"sites/%@/comments/%@", siteID, commentID];

    [self.httpManager GET:commentPath parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success){
            success(operation, responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error){
        DDLogVerbose(@"[Rest API] ! %@", [error localizedDescription]);
        if (failure){
            failure(operation, error);
        }
    }];
}

- (void)postNoteToComment:(NSUInteger)commentID
             toSite:(NSString *)siteID
             params:(NSDictionary *) params
            success:(WordPressComApiRestSuccessResponseBlock)success
            failure:(WordPressComApiRestSuccessFailureBlock)failure
{
    
    NSString *path = [NSString stringWithFormat:@"sites/%@/comments/%@", commentID, siteID];
    
    [self.httpManager POST:path parameters:params success:success failure:failure];
    
}

// Attempt to publish the comment using the REST API
- (void)publishComment:(NSString *)commentText
                toPath:(NSString *) path
               success:(WordPressComApiRestSuccessResponseBlock)success
               failure:(WordPressComApiRestSuccessFailureBlock)failure
{
    NSString *str = [commentText trim];
	if ([str length] == 0) {
		return;
	}
    
	NSDictionary *params = @{@"content":str};
    
	[self.httpManager POST:path parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(operation, responseObject);
        }
        
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure){
            failure(operation, error);
        }
	}];
    
}
- (void)moderateComment:(NSUInteger)blogID forCommentID:(NSUInteger)commentID withStatus:(NSString *)commentStatus success:(WordPressComApiRestSuccessResponseBlock)success failure:(WordPressComApiRestSuccessFailureBlock)failure {
    NSString *commentPath = [NSString stringWithFormat: @"sites/%d/comments/%d", blogID, commentID];
    [self.httpManager POST:commentPath
        parameters:@{ @"status" : commentStatus }
           success:success
           failure:failure];
}

- (void)replyToComment:(NSUInteger)blogID forCommentID:(NSUInteger)commentID withReply:(NSString *)reply
               success:(WordPressComApiRestSuccessResponseBlock)success
               failure:(WordPressComApiRestSuccessFailureBlock)failure
{
    NSString *replyPath = [NSString stringWithFormat: @"sites/%d/comments/%d/replies/new", blogID, commentID];
    [self.httpManager POST:replyPath
        parameters:@{ @"content" : reply }
           success:success
           failure:failure];
}

- (void)replyToCommentInPath:(NSString *) path
                   withReply:(NSString *) reply
                     success:(WordPressComApiRestSuccessResponseBlock)success
                     failure:(WordPressComApiRestSuccessFailureBlock)failure
{
    NSString *replyPath = [NSString stringWithFormat:@"%@/replies/new", path];
    NSDictionary *params = @{@"content" : reply };
    [self.httpManager POST:replyPath parameters:params success:success failure:failure];
}

- (void)performCommentAction:(NSDictionary *)commentAction
                     success:(WordPressComApiRestSuccessResponseBlock)success
                     failure:(WordPressComApiRestSuccessFailureBlock)failure
{
    NSString *path = [NSString stringWithFormat:@"/rest/v1%@", commentAction[@"params.rest_path"]];
    
    [self.httpManager POST:path parameters:commentAction[@"params.rest_body"]
                   success:success
                   failure:failure];
    
}

- (void)approveCommentAction:(NSDictionary *)commentAction
                     success:(WordPressComApiRestSuccessResponseBlock)success
                     failure:(WordPressComApiRestSuccessFailureBlock)failure
{
    
    NSString *approvePath = [NSString stringWithFormat:@"/rest/v1%@", commentAction[@"params.rest_path"]];

    [self.httpManager POST:approvePath
                parameters:@{@"status" : @"approved"}
                   success:success
                   failure:failure];
}
#pragma mark - Blog Themes

- (void)fetchThemesForBlogId:(NSString *)blogId
                     success:(WordPressComApiRestSuccessResponseBlock)success failure:(WordPressComApiRestSuccessFailureBlock)failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%@/themes", blogId];
    [self.httpManager GET:path parameters:nil
          success:success failure:failure];
}

- (void)fetchCurrentThemeForBlogId:(NSString *)blogId
                           success:(WordPressComApiRestSuccessResponseBlock)success failure:(WordPressComApiRestSuccessFailureBlock)failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%@/themes/mine", blogId];
    [self.httpManager GET:path parameters:nil
          success:success failure:failure];
}

- (void)activateThemeForBlogId:(NSString *)blogId themeId:(NSString *)themeId
                       success:(WordPressComApiRestSuccessResponseBlock)success failure:(WordPressComApiRestSuccessFailureBlock)failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%@/themes/mine", blogId];
    [self.httpManager POST:path parameters:@{@"theme": themeId}
           success:success failure:failure];
}

- (void)fetchMeWithSuccess:(WordPressComApiRestSuccessResponseBlock)success
                   failure:(WordPressComApiRestSuccessFailureBlock)failure{
    [self.httpManager GET:@"me"
               parameters:nil
                  success:success
                  failure:failure];    
}

#pragma mark - OAuth info

- (void)setAuthorizationHeaderWithToken:(NSString *)token {
	[self.httpManager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token]
				  forHTTPHeaderField:@"Authorization"];
}

+ (NSString *)WordPressAppId {
    return [WordPressComApiCredentials client];
}

+ (NSString *)WordPressAppSecret {
    return [WordPressComApiCredentials secret];
}

#pragma mark - Error handling

- (NSString *)errorMessageForError:(NSError *)error
{
    NSString *errorCode = [error.userInfo objectForKey:WordPressComApiErrorCodeKey];
    NSString *errorMessage = [[error.userInfo objectForKey:NSLocalizedDescriptionKey] stringByStrippingHTML];
    
    if ([errorCode isEqualToString:@"username_only_lowercase_letters_and_numbers"]) {
        return NSLocalizedString(@"Sorry, usernames can only contain lowercase letters (a-z) and numbers.", nil);
    } else if ([errorCode isEqualToString:@"username_required"]) {
        return NSLocalizedString(@"Please enter a username.", nil);
    } else if ([errorCode isEqualToString:@"username_not_allowed"]) {
        return NSLocalizedString(@"That username is not allowed.", nil);
    } else if ([errorCode isEqualToString:@"email_cant_be_used_to_signup"]) {
        return NSLocalizedString(@"You cannot use that email address to signup. We are having problems with them blocking some of our email. Please use another email provider.", nil);
    } else if ([errorCode isEqualToString:@"username_must_be_at_least_four_characters"]) {
        return NSLocalizedString(@"Username must be at least 4 characters.", nil);
    } else if ([errorCode isEqualToString:@"username_contains_invalid_characters"]) {
        return NSLocalizedString(@"Sorry, usernames may not contain the character &#8220;_&#8221;!", nil);
    } else if ([errorCode isEqualToString:@"username_must_include_letters"]) {
        return NSLocalizedString(@"Sorry, usernames must have letters (a-z) too!", nil);
    } else if ([errorCode isEqualToString:@"email_not_allowed"]) {
        return NSLocalizedString(@"Sorry, that email address is not allowed!", nil);
    } else if ([errorCode isEqualToString:@"username_exists"]) {
        return NSLocalizedString(@"Sorry, that username already exists!", nil);
    } else if ([errorCode isEqualToString:@"email_exists"]) {
        return NSLocalizedString(@"Sorry, that email address is already being used!", nil);
    } else if ([errorCode isEqualToString:@"username_reserved_but_may_be_available"]) {
        return NSLocalizedString(@"That username is currently reserved but may be available in a couple of days.", nil);
    } else if ([errorCode isEqualToString:@"username_unavailable"]) {
        return NSLocalizedString(@"Sorry, that username is unavailable.", nil);
    } else if ([errorCode isEqualToString:@"email_reserved"]) {
        return NSLocalizedString(@"That email address has already been used. Please check your inbox for an activation email. If you don't activate you can try again in a few days.", nil);
    } else if ([errorCode isEqualToString:@"blog_name_required"]) {
        return NSLocalizedString(@"Please enter a site address.", nil);
    } else if ([errorCode isEqualToString:@"blog_name_not_allowed"]) {
        return NSLocalizedString(@"That site address is not allowed.", nil);
    } else if ([errorCode isEqualToString:@"blog_name_must_be_at_least_four_characters"]) {
        return NSLocalizedString(@"Site address must be at least 4 characters.", nil);
    } else if ([errorCode isEqualToString:@"blog_name_must_be_less_than_sixty_four_characters"]) {
        return NSLocalizedString(@"The site address must be shorter than 64 characters.", nil);
    } else if ([errorCode isEqualToString:@"blog_name_contains_invalid_characters"]) {
        return NSLocalizedString(@"Sorry, site addresses may not contain the character &#8220;_&#8221;!", nil);
    } else if ([errorCode isEqualToString:@"blog_name_cant_be_used"]) {
        return NSLocalizedString(@"Sorry, you may not use that site address.", nil);
    } else if ([errorCode isEqualToString:@"blog_name_only_lowercase_letters_and_numbers"]) {
        return NSLocalizedString(@"Sorry, site addresses can only contain lowercase letters (a-z) and numbers.", nil);
    } else if ([errorCode isEqualToString:@"blog_name_must_include_letters"]) {
        return NSLocalizedString(@"Sorry, site addresses must have letters too!", nil);
    } else if ([errorCode isEqualToString:@"blog_name_exists"]) {
        return NSLocalizedString(@"Sorry, that site already exists!", nil);
    } else if ([errorCode isEqualToString:@"blog_name_reserved"]) {
        return NSLocalizedString(@"Sorry, that site is reserved!", nil);
    } else if ([errorCode isEqualToString:@"blog_name_reserved_but_may_be_available"]) {
        return NSLocalizedString(@"That site is currently reserved but may be available in a couple days.", nil);
    } else if ([errorCode isEqualToString:@"password_invalid"]) {
        return NSLocalizedString(@"Your password is invalid because it does not meet our security guidelines. Please try a more complex password.", @"");
    } else if ([errorCode isEqualToString:@"blog_title_invalid"]) {
        return NSLocalizedString(@"Invalid Site Title", @"");
    } else if ([errorCode isEqualToString:@"username_illegal_wpcom"]) {
        // Try to extract the illegal phrase
        NSError *error;
        NSRegularExpression *regEx = [NSRegularExpression regularExpressionWithPattern:@"\"([^\"].*)\"" options:NSRegularExpressionCaseInsensitive error:&error];
        NSArray *matches = [regEx matchesInString:errorMessage options:0 range:NSMakeRange(0, [errorMessage length])];
        NSString *invalidPhrase = @"";
        for (NSTextCheckingResult *result in matches) {
            if ([result numberOfRanges] < 2)
                continue;
            NSRange invalidTextRange = [result rangeAtIndex:1];
            invalidPhrase = [NSString stringWithFormat:@" (\"%@\")", [errorMessage substringWithRange:invalidTextRange]];
        }
        
        return [NSString stringWithFormat:NSLocalizedString(@"Sorry, but your username contains an invalid phrase%@.", @"This error message occurs when a user tries to create a username that contains an invalid phrase for WordPress.com. The %@ may include the phrase in question if it was sent down by the API"), invalidPhrase];
    }

    // We have a few ambiguous errors that come back from the api, they sometimes have error messages included so
    // attempt to return that if possible. If not fall back to a generic error.
    NSDictionary *ambiguousErrors = @{
                                      @"email_invalid": NSLocalizedString(@"Please enter a valid email address.", nil),
                                      @"blog_name_invalid" : NSLocalizedString(@"Invalid Site Address", @""),
                                      @"username_invalid" : NSLocalizedString(@"Invalid username", @"")
                                      };
    if ([ambiguousErrors.allKeys containsObject:errorCode]) {
        if (errorMessage != nil) {
            return errorMessage;
        } else {
            return [ambiguousErrors objectForKey:errorCode];
        }
    }
    
    // Return an error message if there's one included rather than the unhelpful "Unknown Error"
    if (errorMessage != nil) {
        return errorMessage;
    } else {
        return NSLocalizedString(@"Unknown error", nil);
    }
}

@end
