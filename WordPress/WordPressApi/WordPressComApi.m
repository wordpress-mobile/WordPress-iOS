//
//  WordPressComApi.m
//  WordPress
//
//  Created by Jorge Bernal on 6/4/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "WordPressComApi.h"
#import "WordPressComApiCredentials.h"
#import "SFHFKeychainUtils.h"
#import "WordPressAppDelegate.h"
#import "Constants.h"
#import "Note.h"
#import "NSString+Helpers.h"
#import "WPToast.h"
#import <AFJSONRequestOperation.h>
#import <UIDeviceHardware.h>
#import "UIDevice+WordPressIdentifier.h"
#import "ContextManager.h"

NSString *const WordPressComApiClientEndpointURL = @"https://public-api.wordpress.com/rest/v1/";
NSString *const WordPressComApiOauthBaseUrl = @"https://public-api.wordpress.com/oauth2";
NSString *const WordPressComApiOauthServiceName = @"public-api.wordpress.com";
NSString *const WordPressComApiOauthRedirectUrl = @"http://wordpress.com/";
NSString *const WordPressComApiNotificationFields = @"id,type,unread,body,subject,timestamp";
NSString *const WordPressComApiUnseenNotesNotification = @"WordPressComUnseenNotes";
NSString *const WordPressComApiNotesUserInfoKey = @"notes";
NSString *const WordPressComApiUnseenNoteCountInfoKey = @"note_count";
NSString *const WordPressComApiLoginUrl = @"https://wordpress.com/wp-login.php";
NSString *const WordPressComApiErrorDomain = @"com.wordpress.api";
NSString *const WordPressComApiErrorCodeKey = @"WordPressComApiErrorCodeKey";
NSString *const WordPressComApiErrorMessageKey = @"WordPressComApiErrorMessageKey";


#define UnfollowedBlogEvent @"UnfollowedBlogEvent"


// AFJSONRequestOperation requires that a URI end with .json in order to match
// This will match all public-api.wordpress.com/rest/v1/ URI's and parse them as JSON
@interface WPJSONRequestOperation : AFJSONRequestOperation
@end
@implementation WPJSONRequestOperation
+(BOOL)canProcessRequest:(NSURLRequest *)urlRequest {
    NSURL *testURL = [NSURL URLWithString:WordPressComApiOauthBaseUrl];
    if ([urlRequest.URL.host isEqualToString:testURL.host] && [urlRequest.URL.path rangeOfString:testURL.path].location == 0)
        return YES;

    testURL = [NSURL URLWithString:WordPressComApiClientEndpointURL];
    if ([urlRequest.URL.host isEqualToString:testURL.host] && [urlRequest.URL.path rangeOfString:testURL.path].location == 0)
        return YES;

    return NO;
}

- (NSError *)error {
    if (self.response.statusCode >= 400) {
        NSString *errorMessage = [self.responseJSON objectForKey:@"message"];
        NSUInteger errorCode = WordPressComApiErrorJSON;
        if ([self.responseJSON objectForKey:@"error"] && errorMessage) {
            NSString *error = [self.responseJSON objectForKey:@"error"];
            if ([error isEqualToString:@"invalid_token"]) {
                errorCode = WordPressComApiErrorInvalidToken;
            } else if ([error isEqualToString:@"authorization_required"]) {
                errorCode = WordPressComApiErrorAuthorizationRequired;
            }
            return [NSError errorWithDomain:WordPressComApiErrorDomain code:errorCode userInfo:@{NSLocalizedDescriptionKey: errorMessage, WordPressComApiErrorCodeKey: error}];
        }
    }
    return [super error];
}
@end

@interface WordPressComApi ()
@property (readwrite, nonatomic, strong) NSString *username;
@property (readwrite, nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSString *authToken;

- (void)clearWpcomCookies;

@end

@implementation WordPressComApi {
    NSString *_authToken;
}

+ (WordPressComApi *)sharedApi {
    static WordPressComApi *_sharedApi = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_username_preference"];
        DDLogVerbose(@"Initializing API with username '%@'", username);
        NSString *password = nil;
        NSString *authToken = nil;
        if (username) {
            NSError *error = nil;
            password = [SFHFKeychainUtils getPasswordForUsername:username
                                                  andServiceName:kWPcomXMLRPCUrl
                                                           error:&error];
            if (error) {
                DDLogError(@"Error getting WordPress.com password: %@", error);
            } else {
                DDLogVerbose(@"Found password for API: %@", password ? @"YES" : @"NO");
            }
            authToken = [SFHFKeychainUtils getPasswordForUsername:username
                                                   andServiceName:WordPressComApiOauthServiceName
                                                            error:&error];
            if (error) {
                DDLogError(@"Error getting WordPress.com OAuth token: %@", error);
            } else {
                DDLogVerbose(@"Found token for API: %@", authToken ? @"YES" : @"NO");
            }
        }
        _sharedApi = [[self alloc] initWithBaseURL:[NSURL URLWithString:WordPressComApiClientEndpointURL] ];
        _sharedApi.username = username;
        _sharedApi.password = password;
        [_sharedApi registerHTTPOperationClass:[WPJSONRequestOperation class]];
        [_sharedApi setDefaultHeader:@"User-Agent" value:[[WordPressAppDelegate sharedWordPressApplicationDelegate] applicationUserAgent]];
        if (authToken) {
            _sharedApi.authToken = authToken;
        } else if (username && password) {
            [_sharedApi signInWithUsername:username password:password success:nil failure:nil];
        }

//        [_sharedApi checkForNewUnseenNotifications];
    });

    return _sharedApi;
}

#pragma mark - Account management

- (void)signInWithUsername:(NSString *)username password:(NSString *)password success:(void (^)())success failure:(void (^)(NSError *error))failure {
    NSAssert(username != nil, @"username is nil");
    NSAssert(password != nil, @"password is nil");
    if (self.username && ![username isEqualToString:self.username]) {
        [self signOut]; // Only one account supported for now
    }
    self.username = username;
    self.password = password;

    void (^successBlock)(AFHTTPRequestOperation *,id) = ^(AFHTTPRequestOperation *operation, id responseObject) {
        /*
         responseObject should look like:
         {
         "access_token": "YOUR_API_TOKEN",
         "blog_id": "blog id",
         "blog_url": "blog url",
         "token_type": "bearer"
         }
         */
        NSString *accessToken;
        if ([responseObject respondsToSelector:@selector(objectForKey:)]) {
            accessToken = [responseObject objectForKey:@"access_token"];
        }
        if (accessToken == nil) {
            WPFLog(@"No access token found on OAuth response: %@", responseObject);
            //FIXME: this error message is crappy. Understand the posible reasons why responseObject is not what we expected and return a proper error
            NSString *localizedDescription = NSLocalizedString(@"Error authenticating", @"");
            NSError *error = [NSError errorWithDomain:WordPressComApiErrorDomain code:WordPressComApiErrorNoAccessToken userInfo:@{NSLocalizedDescriptionKey: localizedDescription}];
            if (failure) {
                failure(error);
            }
            return;
        }
        self.authToken = accessToken;
        NSError *error = nil;
        [SFHFKeychainUtils storeUsername:self.username andPassword:self.password forServiceName:kWPcomXMLRPCUrl updateExisting:YES error:&error];
        if (error) {
            if (failure) {
                failure(error);
            }
        } else {
            WPFLog(@"Signed in as %@", self.username);
            [[NSUserDefaults standardUserDefaults] setObject:self.username forKey:@"wpcom_username_preference"];
            [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"wpcom_authenticated_flag"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [WordPressAppDelegate sharedWordPressApplicationDelegate].isWPcomAuthenticated = YES;
            [[WordPressAppDelegate sharedWordPressApplicationDelegate] registerForPushNotifications];
            [[NSNotificationCenter defaultCenter] postNotificationName:WordPressComApiDidLoginNotification object:self.username];
            if (success) success();
        }
    };
    AFHTTPClient *client = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:WordPressComApiOauthBaseUrl]];
    [client registerHTTPOperationClass:[WPJSONRequestOperation class]];
    [client setDefaultHeader:@"User-Agent" value:[[WordPressAppDelegate sharedWordPressApplicationDelegate] applicationUserAgent]];
    NSDictionary *params = @{
                             @"client_id": [WordPressComApi WordPressAppId],
                             @"redirect_uri": WordPressComApiOauthRedirectUrl,
                             @"client_secret": [WordPressComApi WordPressAppSecret],
                             @"grant_type": @"password",
                             @"username": username,
                             @"password": password
                             };

    [self postPath:@"/oauth2/token"
        parameters:params
           success:successBlock
           failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               WPFLog(@"Couldn't signin the user: %@", error);
               self.password = nil;
               if (operation.response.statusCode != 400) {
                   [WPError showAlertWithError:error];
               }
               if (failure) failure(error);
             }];
}

- (void)refreshTokenWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    if (self.username == nil || self.password == nil) {
        WPFLog(@"-[WordPressComApi refreshTokenWithSuccess:failure:] username or password are nil, don't even try");
        return;
    }
    [self signInWithUsername:self.username password:self.password success:success failure:failure];
}

- (void)signInWithToken:(NSString *)token {
    self.authToken = token;
}

- (void)signOut {
    WPFLogMethod();
    NSError *error = nil;

    [SFHFKeychainUtils deleteItemForUsername:self.username andServiceName:@"WordPress.com" error:&error];
    [SFHFKeychainUtils deleteItemForUsername:self.username andServiceName:kWPcomXMLRPCUrl error:&error];
    
    [[WordPressAppDelegate sharedWordPressApplicationDelegate] unregisterApnsToken];
    [WordPressAppDelegate sharedWordPressApplicationDelegate].isWPcomAuthenticated = NO;
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kApnsDeviceTokenPrefKey]; //Remove the token from Preferences, otherwise the token is never sent to the server on the next login
    [SFHFKeychainUtils deleteItemForUsername:self.username andServiceName:WordPressComApiOauthServiceName error:&error];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"wpcom_username_preference"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"wpcom_authenticated_flag"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    self.authToken = nil;
    self.username = nil;
    self.password = nil;
    [self clearAuthorizationHeader];

    // Remove all notes
    [Note removeAllNotesWithContext:[[ContextManager sharedInstance] mainContext]];

    [self clearWpcomCookies];

    // Notify the world
    [[NSNotificationCenter defaultCenter] postNotificationName:WordPressComApiDidLogoutNotification object:nil];
}

- (BOOL)hasCredentials {
    return _authToken != nil;
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
    
    [self postPath:@"users/new" parameters:params success:successBlock failure:failureBlock];

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
    
    [self postPath:@"sites/new" parameters:params success:successBlock failure:failureBlock];    
}


#pragma mark - Transitional methods

- (void)updateCredentailsFromStore {
    self.username = [[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_username_preference"];
    NSError *error = nil;
    self.password = [SFHFKeychainUtils getPasswordForUsername:self.username
                                          andServiceName:kWPcomXMLRPCUrl
                                                   error:&error];
    [self clearWpcomCookies];
    [[NSNotificationCenter defaultCenter] postNotificationName:WordPressComApiDidLogoutNotification object:nil];
    [WordPressAppDelegate sharedWordPressApplicationDelegate].isWPcomAuthenticated = YES;
    [[WordPressAppDelegate sharedWordPressApplicationDelegate] registerForPushNotifications];
    [[NSNotificationCenter defaultCenter] postNotificationName:WordPressComApiDidLoginNotification object:self.username];
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

#pragma mark - Notifications

- (void)saveNotificationSettings:(void (^)())success
                         failure:(void (^)(NSError *error))failure {
    
    NSString *token = [[NSUserDefaults standardUserDefaults] objectForKey:kApnsDeviceTokenPrefKey];
    if( nil == token ) return; //no apns token available
    
    if(![[WordPressComApi sharedApi] hasCredentials])
        return;
    
    NSDictionary *notificationPreferences = [[NSUserDefaults standardUserDefaults] objectForKey:@"notification_preferences"];
    if (!notificationPreferences)
        return;

    NSMutableArray *notificationPrefArray = [[notificationPreferences allKeys] mutableCopy];
    if ([notificationPrefArray indexOfObject:@"muted_blogs"] != NSNotFound)
        [notificationPrefArray removeObjectAtIndex:[notificationPrefArray indexOfObject:@"muted_blogs"]];
    
    // Build the dictionary to send in the API call
    NSMutableDictionary *updatedSettings = [[NSMutableDictionary alloc] init];
    for (int i = 0; i < [notificationPrefArray count]; i++) {
        NSDictionary *updatedSetting = [notificationPreferences objectForKey:[notificationPrefArray objectAtIndex:i]];
        [updatedSettings setValue:[updatedSetting objectForKey:@"value"] forKey:[notificationPrefArray objectAtIndex:i]];
    }

    //Check and send 'mute_until' value
    NSMutableDictionary *muteDictionary = [notificationPreferences objectForKey:@"mute_until"];
    if(muteDictionary != nil  && [muteDictionary objectForKey:@"value"] != nil) {
        [updatedSettings setValue:[muteDictionary objectForKey:@"value"] forKey:@"mute_until"];
    } else {
        [updatedSettings setValue:@"0" forKey:@"mute_until"];
    }
    
    NSArray *blogsArray = [[notificationPreferences objectForKey:@"muted_blogs"] objectForKey:@"value"];
    NSMutableArray *mutedBlogsArray = [[NSMutableArray alloc] init];
    for (int i=0; i < [blogsArray count]; i++) {
        NSDictionary *userBlog = [blogsArray objectAtIndex:i];
        if ([[userBlog objectForKey:@"value"] intValue] == 1) {
            [mutedBlogsArray addObject:userBlog];
        }
    }

    if ([mutedBlogsArray count] > 0)
        [updatedSettings setValue:mutedBlogsArray forKey:@"muted_blogs"];

    if ([updatedSettings count] == 0)
        return;

    WPXMLRPCClient *api = [[WPXMLRPCClient alloc] initWithXMLRPCEndpoint:[NSURL URLWithString:kWPcomXMLRPCUrl]];
    [api setAuthorizationHeaderWithToken:self.authToken];
    //Update supported notifications dictionary
    [api callMethod:@"wpcom.set_mobile_push_notification_settings"
         parameters:[NSArray arrayWithObjects:[self usernameForXmlrpc], [self passwordForXmlrpc], updatedSettings, token, @"apple", nil]
            success:^(AFHTTPRequestOperation *operation, id responseObject) {
                // Hooray!
                if (success)
                    success();
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                if (failure)
                    failure(error);
            }];
}

- (void)fetchNotificationSettings:(void (^)())success failure:(void (^)(NSError *error))failure {
    NSString *token = [[NSUserDefaults standardUserDefaults] objectForKey:kApnsDeviceTokenPrefKey];
    if( nil == token ) return; //no apns token available
    
    if(![[WordPressComApi sharedApi] hasCredentials])
        return;
    
    WPXMLRPCClient *api = [[WPXMLRPCClient alloc] initWithXMLRPCEndpoint:[NSURL URLWithString:kWPcomXMLRPCUrl]];
    [api setAuthorizationHeaderWithToken:self.authToken];
    [api callMethod:@"wpcom.get_mobile_push_notification_settings"
         parameters:[NSArray arrayWithObjects:[self usernameForXmlrpc], [self passwordForXmlrpc], token, @"apple", nil]
            success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSDictionary *supportedNotifications = (NSDictionary *)responseObject;
                [[NSUserDefaults standardUserDefaults] setObject:supportedNotifications forKey:@"notification_preferences"];
                if (success)
                    success();
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                if (failure)
                    failure(error);
            }];
}

- (void)syncPushNotificationInfo {
    NSString *token = [[NSUserDefaults standardUserDefaults] objectForKey:kApnsDeviceTokenPrefKey];
    if( nil == token ) return; //no apns token available
    
    if(![[WordPressComApi sharedApi] hasCredentials])
        return;
    
    NSString *authURL = kNotificationAuthURL;
    
    // Send a multicall for register the token and retrieval of push notification settings
    NSMutableArray *operations = [NSMutableArray arrayWithCapacity:2];
    WPXMLRPCClient *api = [[WPXMLRPCClient alloc] initWithXMLRPCEndpoint:[NSURL URLWithString:authURL]];
    
    [api setAuthorizationHeaderWithToken:self.authToken];
    
#ifdef DEBUG
    NSNumber *production = @NO;
#else
    NSNumber *production = @YES;
#endif

    NSDictionary *tokenOptions = @{
                                   @"device_family": @"apple",
                                   @"device_model": [UIDeviceHardware platform],
                                   @"device_name": [[UIDevice currentDevice] name],
                                   @"device_uuid": [[UIDevice currentDevice] wordpressIdentifier],
                                   @"production": production,
                                   @"app_version": [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"],
                                   @"os_version": [[UIDevice currentDevice] systemVersion],
                                   };
    WPXMLRPCRequest *tokenRequest = [api XMLRPCRequestWithMethod:@"wpcom.mobile_push_register_token" parameters:[NSArray arrayWithObjects:[self usernameForXmlrpc], [self passwordForXmlrpc], token, tokenOptions, nil]];
    WPXMLRPCRequestOperation *tokenOperation = [api XMLRPCRequestOperationWithRequest:tokenRequest success:^(AFHTTPRequestOperation *operation, id responseObject) {
        WPFLog(@"Registered token %@" , token);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        WPFLog(@"Couldn't register token: %@", [error localizedDescription]);
    }];
    
    [operations addObject:tokenOperation];
    
    NSArray *settingsParameters = [NSArray arrayWithObjects:[self usernameForXmlrpc], [self passwordForXmlrpc], token, @"apple", nil];
    WPXMLRPCRequest *settingsRequest = [api XMLRPCRequestWithMethod:@"wpcom.get_mobile_push_notification_settings" parameters:settingsParameters];
    WPXMLRPCRequestOperation *settingsOperation = [api XMLRPCRequestOperationWithRequest:settingsRequest success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *supportedNotifications = (NSDictionary *)responseObject;
        [[NSUserDefaults standardUserDefaults] setObject:supportedNotifications forKey:@"notification_preferences"];
        WPFLog(@"Notification settings loaded!");
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        WPFLog(@"Failed to receive supported notification list: %@", [error localizedDescription]);
    }];
    
    [operations addObject:settingsOperation];
    
    AFHTTPRequestOperation *combinedOperation = [api combinedHTTPRequestOperationWithOperations:operations success:^(AFHTTPRequestOperation *operation, id responseObject) {} failure:^(AFHTTPRequestOperation *operation, NSError *error) {}];
    [api enqueueHTTPRequestOperation:combinedOperation];
}

- (void)checkForNewUnseenNotifications {
    NSDictionary *params = @{ @"unread":@"true", @"number":@"20", @"num_note_items":@"20", @"fields" : WordPressComApiNotificationFields };
    [self getPath:@"notifications" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSNumber *last_seen_time = [responseObject objectForKey:@"last_seen_time"];
        NSArray *notes = [responseObject objectForKey:@"notes"];
        if ([notes count] > 0) {
            NSMutableArray *unseenNotes = [[NSMutableArray alloc] initWithCapacity:[notes count]];
            [notes enumerateObjectsUsingBlock:^(id noteData, NSUInteger idx, BOOL *stop) {
                NSNumber *timestamp = [noteData objectForKey:@"timestamp"];
                if ([timestamp compare:last_seen_time] == NSOrderedDescending) {
                    [unseenNotes addObject:noteData];
                }
            }];
            NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
            [nc postNotificationName:WordPressComApiUnseenNotesNotification
                              object:self
                            userInfo:@{
                WordPressComApiNotesUserInfoKey : unseenNotes,
                WordPressComApiUnseenNoteCountInfoKey : [NSNumber numberWithInteger:[unseenNotes count]]
             }];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
    }];
}

- (void)checkNotificationsSuccess:(WordPressComApiRestSuccessResponseBlock)success failure:(WordPressComApiRestSuccessFailureBlock)failure {
    [self getNotificationsBefore:nil success:success failure:failure];
}

- (void)getNotificationsSince:(NSNumber *)timestamp success:(WordPressComApiRestSuccessResponseBlock)success failure:(WordPressComApiRestSuccessFailureBlock)failure {
    NSDictionary *parameters;
    if (timestamp != nil) {
        parameters = @{ @"since" : timestamp };
    }
    [self getNotificationsWithParameters:parameters success:success failure:failure];
    
}

- (void)getNotificationsBefore:(NSNumber *)timestamp success:(WordPressComApiRestSuccessResponseBlock)success failure:(WordPressComApiRestSuccessFailureBlock)failure {
    NSDictionary *parameters;
    if (timestamp != nil) {
        parameters = @{ @"before" : timestamp };
    }
    [self getNotificationsWithParameters:parameters success:success failure:failure];
}

- (void)getNotificationsWithParameters:(NSDictionary *)parameters success:(WordPressComApiRestSuccessResponseBlock)success failure:(WordPressComApiRestSuccessFailureBlock)failure {
    NSMutableDictionary *requestParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
    
    [requestParameters setObject:WordPressComApiNotificationFields forKey:@"fields"];
    [requestParameters setObject:[NSNumber numberWithInt:20] forKey:@"number"];
    [requestParameters setObject:[NSNumber numberWithInt:20] forKey:@"num_note_items"];
    
    // TODO: Check for unread notifications and notify with the number of unread notifications

    [self getPath:@"notifications/" parameters:requestParameters success:^(AFHTTPRequestOperation *operation, id responseObject){
        // save the notes
        NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
        [Note syncNotesWithResponse:[responseObject objectForKey:@"notes"] withManagedObjectContext:context];
        if (success != nil ) success( operation, responseObject );
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) failure(operation, error);
    }];
}

- (void)refreshNotifications:(NSArray *)notes fields:(NSString *)fields success:(WordPressComApiRestSuccessResponseBlock)success failure:(WordPressComApiRestSuccessFailureBlock)failure {
    // No notes? Then there's nothing to sync
    if ([notes count] == 0) {
        return;
    }
    NSMutableArray *noteIDs = [[NSMutableArray alloc] initWithCapacity:[notes count]];
    [notes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [noteIDs addObject:[(Note *)obj noteID]];
    }];
    if (fields == nil) {
        fields = WordPressComApiNotificationFields;
    }
    NSDictionary *params = @{
        @"fields" : fields,
        @"ids" : noteIDs
    };
    NSManagedObjectContext *context = [(Note *)[notes objectAtIndex:0] managedObjectContext];
    [self getPath:@"notifications/" parameters:params success:^(AFHTTPRequestOperation *operation, id response){
        NSError *error;
        NSArray *notesData = [response objectForKey:@"notes"];
        for (int i=0; i < [notes count]; i++) {
            if ([notesData count] > i) {
                Note *note = [notes objectAtIndex:i];
                if (![note isDeleted] && [note managedObjectContext]) {
                    [note updateAttributes:[notesData objectAtIndex:i]];
                }
            }
        }
        if(![context save:&error]){
            NSLog(@"Unable to update note: %@", error);
        }
        if (success != nil) success(operation, response);
    } failure:failure ];
}

- (void)markNoteAsRead:(NSString *)noteID success:(WordPressComApiRestSuccessResponseBlock)success failure:(WordPressComApiRestSuccessFailureBlock)failure {
    
    NSDictionary *params = @{ @"counts" : @{ noteID : @"1" } };
    
    [self postPath:@"notifications/read"
                   parameters:params
                      success:success
                      failure:failure];
    
}

- (void)updateNoteLastSeenTime:(NSNumber *)timestamp success:(WordPressComApiRestSuccessResponseBlock)success failure:(WordPressComApiRestSuccessFailureBlock)failure {
    
    [self postPath:@"notifications/seen" parameters:@{ @"time" : timestamp } success:success failure:failure];
    
}

- (void)followBlog:(NSUInteger)blogID isFollowing:(bool)following success:(WordPressComApiRestSuccessResponseBlock)success failure:(WordPressComApiRestSuccessFailureBlock)failure {
    
    NSString *followPath = [NSString stringWithFormat: @"sites/%d/follows/new", blogID];
    if (following)
        followPath = [followPath stringByReplacingOccurrencesOfString:@"new" withString:@"mine/delete"];

    NSString *message = following ? NSLocalizedString(@"Unfollowed", @"User unfollowed a blog") : NSLocalizedString(@"Followed", @"User followed a blog");
    NSString *imageName = [NSString stringWithFormat:@"action_icon_%@", (following) ? @"unfollowed" : @"followed"];
    [WPToast showToastWithMessage:message andImage:[UIImage imageNamed:imageName]];
    
    [self postPath:followPath
        parameters:nil
           success:^(AFHTTPRequestOperation *operation, id responseObject){
               if (success != nil) success(operation, responseObject);
           }
           failure:failure];
}

- (void)moderateComment:(NSUInteger)blogID forCommentID:(NSUInteger)commentID withStatus:(NSString *)commentStatus success:(WordPressComApiRestSuccessResponseBlock)success failure:(WordPressComApiRestSuccessFailureBlock)failure {
    
    NSString *commentPath = [NSString stringWithFormat: @"sites/%d/comments/%d", blogID, commentID];
    
    [self postPath:commentPath
        parameters:@{ @"status" : commentStatus }
           success:success
           failure:failure];
}

- (void)replyToComment:(NSUInteger)blogID forCommentID:(NSUInteger)commentID withReply:(NSString *)reply success:(WordPressComApiRestSuccessResponseBlock)success failure:(WordPressComApiRestSuccessFailureBlock)failure {
    
    NSString *replyPath = [NSString stringWithFormat: @"sites/%d/comments/%d/replies/new", blogID, commentID];
    
    [self postPath:replyPath
        parameters:@{ @"content" : reply }
           success:success
           failure:failure];
}

/* HACK: temporary fix for cases where password is nil
 We believe jetpack settings might be causing this, but since we're actually doing authentication
 with the authToken, we don't care that much about username/password in this method
 */
- (NSString *)usernameForXmlrpc {
    NSString *username = self.username;
    if (!username)
        username = @"";
    return username;
}

- (NSString *)passwordForXmlrpc {
    NSString *password = self.password;
    if (!password)
        password = @"";
    return password;
}
/* HACK ENDS */

#pragma mark - Oauth methods

- (NSString *)authToken {
    return _authToken;
}

- (void)setAuthToken:(NSString *)authToken {
    _authToken = authToken;
    NSError *error;
    if (_authToken) {
        [self setAuthorizationHeaderWithToken:authToken];
        [SFHFKeychainUtils storeUsername:self.username
                             andPassword:authToken
                          forServiceName:WordPressComApiOauthServiceName
                          updateExisting:YES
                                   error:&error];
    } else {
        [self clearAuthorizationHeader];
        [SFHFKeychainUtils deleteItemForUsername:self.username
                                  andServiceName:WordPressComApiOauthServiceName
                                           error:&error];
    }
}

- (void)setAuthorizationHeaderWithToken:(NSString *)token {
    [self setDefaultHeader:@"Authorization" value:[NSString stringWithFormat:@"Bearer %@", token]];
}

+ (NSString *)WordPressAppId {
    return [WordPressComApiCredentials client];
}

+ (NSString *)WordPressAppSecret {
    return [WordPressComApiCredentials secret];
}

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
