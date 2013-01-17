//
//  WordPressComApi.m
//  WordPress
//
//  Created by Jorge Bernal on 6/4/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "WordPressComApi.h"
#import "SFHFKeychainUtils.h"
#import "WordPressAppDelegate.h"
#import "Constants.h"

NSString *const WordPressComApiOauthServiceName = @"public-api.wordpress.com";
NSString *const WordPressComApiNotificationFields = @"id,type,unread,body,subject,timestamp";

@interface WordPressComApi () <WordPressComRestClientDelegate>
@property (readwrite, nonatomic, strong) NSString *username;
@property (readwrite, nonatomic, strong) NSString *password;
@property (readwrite, nonatomic, strong) WordPressComRestClient *restClient;
@end

@implementation WordPressComApi 
@dynamic username;
@dynamic password;

+ (WordPressComApi *)sharedApi {
    static WordPressComApi *_sharedApi = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_username_preference"];
        NSString *password = nil;
        NSString *authToken = nil;
        if (username) {
            NSError *error = nil;
            password = [SFHFKeychainUtils getPasswordForUsername:username
                                                  andServiceName:@"WordPress.com"
                                                           error:&error];
            authToken = [SFHFKeychainUtils getPasswordForUsername:username
                                                   andServiceName:WordPressComApiOauthServiceName
                                                            error:nil];
        }
        _sharedApi = [[self alloc] initWithXMLRPCEndpoint:[NSURL URLWithString:kWPcomXMLRPCUrl] username:username password:password];
        _sharedApi.restClient = [[WordPressComRestClient alloc] initWithBaseURL:[NSURL URLWithString:WordPressComRestClientEndpointURL] ];
        _sharedApi.restClient.authToken = authToken;
        _sharedApi.restClient.delegate = _sharedApi;
        
        [_sharedApi checkNotifications];
        
    });
    
    
    return _sharedApi;

}

- (void)dealloc {
    self.restClient.delegate = nil;
}

- (void)setUsername:(NSString *)username password:(NSString *)password success:(void (^)())success failure:(void (^)(NSError *error))failure {
    if (self.username && ![username isEqualToString:self.username]) {
        [self signOut]; // Only one account supported for now
    }
    self.username = username;
    self.password = password;
    [self authenticateWithSuccess:^{
        NSError *error = nil;
        [SFHFKeychainUtils storeUsername:self.username andPassword:self.password forServiceName:@"WordPress.com" updateExisting:YES error:&error];
        if (error) {
            if (failure) {
                failure(error);
            }
        } else {
            [[NSUserDefaults standardUserDefaults] setObject:self.username forKey:@"wpcom_username_preference"];
            [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"wpcom_authenticated_flag"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [WordPressAppDelegate sharedWordPressApplicationDelegate].isWPcomAuthenticated = YES;
            [[WordPressAppDelegate sharedWordPressApplicationDelegate] registerForPushNotifications];
            [[NSNotificationCenter defaultCenter] postNotificationName:WordPressComApiDidLoginNotification object:self.username];
            if (success) success();
        }
    } failure:^(NSError *error) {
        self.username = nil;
        self.password = nil;
        if (failure) failure(error);
    }];
}

- (void)signOut {
#if FALSE
    // Until we have accounts, don't delete the password or any blog with that username will stop working
    NSError *error = nil;
    [SFHFKeychainUtils deleteItemForUsername:self.username andServiceName:@"WordPress.com" error:&error];
#endif
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"wpcom_username_preference"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"wpcom_authenticated_flag"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [WordPressAppDelegate sharedWordPressApplicationDelegate].isWPcomAuthenticated = NO;
    [[WordPressAppDelegate sharedWordPressApplicationDelegate] unregisterApnsToken];
    self.username = nil;
    self.password = nil;

    [self clearReaderCookies];

    // Notify the world
    [[NSNotificationCenter defaultCenter] postNotificationName:WordPressComApiDidLogoutNotification object:nil];
}

- (void)updateCredentailsFromStore {
    self.username = [[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_username_preference"];
    NSError *error = nil;
    self.password = [SFHFKeychainUtils getPasswordForUsername:self.username
                                          andServiceName:@"WordPress.com"
                                                   error:&error];
    [self clearReaderCookies];
    [[NSNotificationCenter defaultCenter] postNotificationName:WordPressComApiDidLogoutNotification object:nil];
    [WordPressAppDelegate sharedWordPressApplicationDelegate].isWPcomAuthenticated = YES;
    [[WordPressAppDelegate sharedWordPressApplicationDelegate] registerForPushNotifications];
    [[NSNotificationCenter defaultCenter] postNotificationName:WordPressComApiDidLoginNotification object:self.username];
}

- (void)clearReaderCookies {
    NSArray *readerCookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
    for (NSHTTPCookie *cookie in readerCookies) {
        if ([cookie.domain hasSuffix:@"wordpress.com"]) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
        }
    }
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

- (void)checkNotifications {
    [self checkNotificationsSuccess:nil failure:nil];
}

- (void)checkNotificationsSuccess:(WordPressComApiRestSuccessResponseBlock)success failure:(WordPressComApiRestSuccessFailureBlock)failure {
    NSDictionary *parameters = @{ @"fields" : WordPressComApiNotificationFields };
    [self.restClient getPath:@"notifications/" parameters:parameters success:success failure:failure];
}

- (void)getNotificationsBefore:(NSNumber *)timestamp success:(WordPressComApiRestSuccessResponseBlock)success failure:(WordPressComApiRestSuccessFailureBlock)failure {
    NSDictionary *parameters= @{ @"before": timestamp };
    [self.restClient getPath:@"notifications/" parameters:parameters success:success failure:failure];
}

- (BOOL)hasAuthorizationToken {
    return self.authToken != nil;
}

- (NSString *)authToken {
    return self.restClient.authToken;
}

- (void)setAuthToken:(NSString *)authToken {
    NSError *error;
    [SFHFKeychainUtils storeUsername:self.username
                         andPassword:authToken
                      forServiceName:WordPressComApiOauthServiceName
                      updateExisting:YES
                               error:&error];
    self.restClient.authToken = authToken;
}

- (void)restClientDidFailAuthorization:(WordPressComRestClient *)client {
    // let the world know we need an auth token
    [[NSNotificationCenter defaultCenter] postNotificationName:WordPressComApiNeedsAuthTokenNotification object:self];
}

@end
