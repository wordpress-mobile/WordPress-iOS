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
#import <AFJSONRequestOperation.h>

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

NSString *const WordPressComApiFollowedBlogEvent = @"FollowedBlogEvent";
NSString *const WordPressComApiUnfollowedBlogEvent = @"UnfollowedBlogEvent";

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
@end

@implementation WordPressComApi {
    NSString *_authToken;
}

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
        _sharedApi = [[self alloc] initWithBaseURL:[NSURL URLWithString:WordPressComApiClientEndpointURL] ];
        _sharedApi.username = username;
        _sharedApi.password = password;
        [_sharedApi registerHTTPOperationClass:[WPJSONRequestOperation class]];
        [_sharedApi setDefaultHeader:@"User-Agent" value:[[WordPressAppDelegate sharedWordPressApplicationDelegate] applicationUserAgent]];
        if (authToken) {
            _sharedApi.authToken = authToken;
        } else {
            [_sharedApi signInWithUsername:username password:password success:nil failure:nil];
        }

//        [_sharedApi checkForNewUnseenNotifications];
    });

    return _sharedApi;
}

#pragma mark - Account management

- (void)signInWithUsername:(NSString *)username password:(NSString *)password success:(void (^)())success failure:(void (^)(NSError *error))failure {
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
                 self.username = nil;
                 self.password = nil;
                 if (failure) failure(error);
             }];
}

- (void)refreshTokenWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    [self signInWithUsername:self.username password:self.password success:success failure:failure];
}

- (void)signInWithToken:(NSString *)token {
    self.authToken = token;
}

- (void)signOut {
    NSError *error = nil;
#if FALSE
    // Until we have accounts, don't delete the password or any blog with that username will stop working
    [SFHFKeychainUtils deleteItemForUsername:self.username andServiceName:@"WordPress.com" error:&error];
#endif
    [[WordPressAppDelegate sharedWordPressApplicationDelegate] unregisterApnsToken];
    [WordPressAppDelegate sharedWordPressApplicationDelegate].isWPcomAuthenticated = NO;
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"apnsDeviceToken"]; //Remove the token from Preferences, otherwise the token is never sent to the server on the next login
    [SFHFKeychainUtils deleteItemForUsername:self.username andServiceName:WordPressComApiOauthServiceName error:&error];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"wpcom_username_preference"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"wpcom_authenticated_flag"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    self.authToken = nil;
    self.username = nil;
    self.password = nil;
    [self clearAuthorizationHeader];

    // Remove all notes
    [Note removeAllNotesWithContext:[[WordPressAppDelegate sharedWordPressApplicationDelegate] managedObjectContext]];

    [self clearReaderCookies];

    // Notify the world
    [[NSNotificationCenter defaultCenter] postNotificationName:WordPressComApiDidLogoutNotification object:nil];
}

- (BOOL)hasCredentials {
    return _authToken != nil;
}

#pragma mark - Transitional methods

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

#pragma mark - Notifications

- (void)saveNotificationSettings:(void (^)())success
                         failure:(void (^)(NSError *error))failure {
    NSDictionary *notificationPreferences = [[NSUserDefaults standardUserDefaults] objectForKey:@"notification_preferences"];
    if (!notificationPreferences)
        return;

    NSMutableArray *notificationPrefArray = [[notificationPreferences allKeys] mutableCopy];
    if ([notificationPrefArray indexOfObject:@"muted_blogs"] != NSNotFound)
        [notificationPrefArray removeObjectAtIndex:[notificationPrefArray indexOfObject:@"muted_blogs"]];
    NSString *token = [[NSUserDefaults standardUserDefaults] objectForKey:@"apnsDeviceToken"];

    // Build the dictionary to send in the API call
    NSMutableDictionary *updatedSettings = [[NSMutableDictionary alloc] init];
    for (int i = 0; i < [notificationPrefArray count]; i++) {
        NSDictionary *updatedSetting = [notificationPreferences objectForKey:[notificationPrefArray objectAtIndex:i]];
        [updatedSettings setValue:[updatedSetting objectForKey:@"value"] forKey:[notificationPrefArray objectAtIndex:i]];
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

    AFXMLRPCClient *api = [[AFXMLRPCClient alloc] initWithXMLRPCEndpoint:[NSURL URLWithString:kWPcomXMLRPCUrl]];
    //Update supported notifications dictionary
    [api callMethod:@"wpcom.set_mobile_push_notification_settings"
         parameters:[NSArray arrayWithObjects:self.username, self.password, updatedSettings, token, @"apple", nil]
            success:^(AFHTTPRequestOperation *operation, id responseObject) {
                // Hooray!
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

            }];
}

- (void)fetchNotificationSettings:(void (^)())success failure:(void (^)(NSError *error))failure {
    NSString *token = [[NSUserDefaults standardUserDefaults] objectForKey:@"apnsDeviceToken"];
    AFXMLRPCClient *api = [[AFXMLRPCClient alloc] initWithXMLRPCEndpoint:[NSURL URLWithString:kWPcomXMLRPCUrl]];
    [api setAuthorizationHeaderWithToken:self.authToken];
    [api callMethod:@"wpcom.get_mobile_push_notification_settings"
         parameters:[NSArray arrayWithObjects:self.username, self.password, token, @"apple", nil]
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
    NSString *token = [[NSUserDefaults standardUserDefaults] objectForKey:@"apnsDeviceToken"];
    if( nil == token ) return; //no apns token available

    NSString *authURL = kNotificationAuthURL;
    NSError *error;
    NSManagedObjectContext *context = [[WordPressAppDelegate sharedWordPressApplicationDelegate] managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Blog" inManagedObjectContext:context]];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"blogName" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];
    NSArray *blogs = [context executeFetchRequest:fetchRequest error:&error];

    NSMutableArray *blogsID = [NSMutableArray array];

    //get a references to media files linked in a post
    for (Blog *blog in blogs) {
        if( [blog isWPcom] ) {
            [blogsID addObject:[blog blogID] ];
        } else {
            if ( [blog getOptionValue:@"jetpack_client_id"] )
                [blogsID addObject:[blog getOptionValue:@"jetpack_client_id"] ];
        }
    }

    // Send a multicall for the blogs list and retrieval of push notification settings
    NSMutableArray *operations = [NSMutableArray arrayWithCapacity:2];
    AFXMLRPCClient *api = [[AFXMLRPCClient alloc] initWithXMLRPCEndpoint:[NSURL URLWithString:authURL]];
    ;
    [api setAuthorizationHeaderWithToken:self.authToken];
    NSArray *blogsListParameters = [NSArray arrayWithObjects:self.username, self.password, token, blogsID, @"apple", nil];
    AFXMLRPCRequest *blogsListRequest = [api XMLRPCRequestWithMethod:@"wpcom.mobile_push_set_blogs_list" parameters:blogsListParameters];
    AFXMLRPCRequestOperation *blogsListOperation = [api XMLRPCRequestOperationWithRequest:blogsListRequest success:^(AFHTTPRequestOperation *operation, id responseObject) {
        WPFLog(@"Sent blogs list (%d blogs)", [blogsID count]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        WPFLog(@"Failed registering blogs list: %@", [error localizedDescription]);
    }];

    [operations addObject:blogsListOperation];

    NSArray *settingsParameters = [NSArray arrayWithObjects:self.username, self.password, token, @"apple", nil];
    AFXMLRPCRequest *settingsRequest = [api XMLRPCRequestWithMethod:@"wpcom.get_mobile_push_notification_settings" parameters:settingsParameters];
    AFXMLRPCRequestOperation *settingsOperation = [api XMLRPCRequestOperationWithRequest:settingsRequest success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *supportedNotifications = (NSDictionary *)responseObject;
        [[NSUserDefaults standardUserDefaults] setObject:supportedNotifications forKey:@"notification_preferences"];
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
        NSManagedObjectContext *context = [[WordPressAppDelegate sharedWordPressApplicationDelegate] managedObjectContext];
        [Note syncNotesWithResponse:[responseObject objectForKey:@"notes"] withManagedObjectContext:context];
        if (success != nil ) success( operation, responseObject );
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) failure(operation, error);
    }];
}

- (void)refreshNotifications:(NSArray *)notes success:(WordPressComApiRestSuccessResponseBlock)success failure:(WordPressComApiRestSuccessFailureBlock)failure {
    // No notes? Then there's nothing to sync
    if ([notes count] == 0) {
        return;
    }
    NSMutableArray *noteIDs = [[NSMutableArray alloc] initWithCapacity:[notes count]];
    [notes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [noteIDs addObject:[(Note *)obj noteID]];
    }];
    NSDictionary *params = @{
        @"fields" : WordPressComApiNotificationFields,
        @"ids" : noteIDs
    };
    NSManagedObjectContext *context = [(Note *)[notes objectAtIndex:0] managedObjectContext];
    [self getPath:@"notifications/" parameters:params success:^(AFHTTPRequestOperation *operation, id response){
        NSError *error;
        NSArray *notesData = [response objectForKey:@"notes"];
        for (int i=0; i < [notes count]; i++) {
            if ([notesData count] > i) {
                Note *note = [notes objectAtIndex:i];
                [note syncAttributes:[notesData objectAtIndex:i]];
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

    // post the notification
    NSString *notificationName = following ? WordPressComApiUnfollowedBlogEvent : WordPressComApiFollowedBlogEvent;
    [[NSNotificationCenter defaultCenter]
     postNotificationName:notificationName
     object:self
     userInfo:@{ @"siteID":[NSNumber numberWithInt:blogID] }];
    
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

@end
