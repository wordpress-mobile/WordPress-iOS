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
NSString *const WordPressComApiUnseenNotesNotification = @"WordPressComUnseenNotes";
NSString *const WordPressComApiNotesUserInfoKey = @"notes";
NSString *const WordPressComApiUnseenNoteCountInfoKey = @"note_count";

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
        
        [_sharedApi checkForNewUnseenNotifications];
        
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


#pragma mark - Notifications REST API methods
/*
 * Queries the REST Api for unread notes and determines if the user has
 * seen them using the response's last_seen_time timestamp.
 *
 * If we have unseen notes we post a WordPressComApiUnseenNotesNotification 
 */
- (void)checkForNewUnseenNotifications {
    NSDictionary *params = @{ @"unread":@"true", @"number":@"20", @"fields" : WordPressComApiNotificationFields };
    [self.restClient getPath:@"notifications" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
    // TODO: Check for unread notifications and notify with the number of unread notifications

    [self.restClient getPath:@"notifications/" parameters:requestParameters success:^(AFHTTPRequestOperation *operation, id responseObject){
        // save the notes
        NSManagedObjectContext *context = [[WordPressAppDelegate sharedWordPressApplicationDelegate] managedObjectContext];
        [Note syncNotesWithResponse:[responseObject objectForKey:@"notes"] withManagedObjectContext:context];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"WordPressComUpdateNoteCount"
                                                            object:nil
                                                          userInfo:nil];
        if (success != nil ) success( operation, responseObject );
        
    } failure:failure];

    
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
    [self.restClient getPath:@"notifications/" parameters:params success:^(AFHTTPRequestOperation *operation, id response){
        NSError *error;
        NSArray *notesData = [response objectForKey:@"notes"];
        for (int i=0; i < [notes count]; i++) {
            Note *note = [notes objectAtIndex:i];
            [note syncAttributes:[notesData objectAtIndex:i]];
        }
        if(![context save:&error]){
            NSLog(@"Unable to update note: %@", error);
        }
        // Update sidebar unread count
        [[NSNotificationCenter defaultCenter] postNotificationName:@"WordPressComUpdateNoteCount"
                                                            object:nil
                                                          userInfo:nil];
        if (success != nil) success(operation, response);
    } failure:failure ];
}

- (void)markNoteAsRead:(Note *)note success:(WordPressComApiRestSuccessResponseBlock)success failure:(WordPressComApiRestSuccessFailureBlock)failure {
    
    NSDictionary *params = @{ @"counts" : @{ note.noteID : note.unread } };
    
    [self.restClient postPath:@"notifications/read"
                   parameters:params
                      success:success
                      failure:failure];
    
}

- (void)updateNoteLastSeenTime:(NSNumber *)timestamp success:(WordPressComApiRestSuccessResponseBlock)success failure:(WordPressComApiRestSuccessFailureBlock)failure {
    
    [self.restClient postPath:@"notifications/seen" parameters:@{ @"time" : timestamp } success:success failure:failure];
    
}

- (void)followBlog:(NSUInteger)blogID isFollowing:(bool)following success:(WordPressComApiRestSuccessResponseBlock)success failure:(WordPressComApiRestSuccessFailureBlock)failure {
    
    NSString *followPath = [NSString stringWithFormat: @"sites/%d/follows/new", blogID];
    if (following)
        followPath = [followPath stringByReplacingOccurrencesOfString:@"new" withString:@"mine/delete"];
    
    [self.restClient postPath:followPath
                   parameters:nil
                      success:success
                      failure:failure];
}

- (void)moderateComment:(NSUInteger)blogID forCommentID:(NSUInteger)commentID withStatus:(NSString *)commentStatus success:(WordPressComApiRestSuccessResponseBlock)success failure:(WordPressComApiRestSuccessFailureBlock)failure {
    
    NSString *commentPath = [NSString stringWithFormat: @"sites/%d/comments/%d", blogID, commentID];
    
    [self.restClient postPath:commentPath
                   parameters:@{ @"status" : commentStatus }
                      success:success
                      failure:failure];
}

- (void)replyToComment:(NSUInteger)blogID forCommentID:(NSUInteger)commentID withReply:(NSString *)reply success:(WordPressComApiRestSuccessResponseBlock)success failure:(WordPressComApiRestSuccessFailureBlock)failure {
    
    NSString *replyPath = [NSString stringWithFormat: @"sites/%d/comments/%d/replies/new", blogID, commentID];
    
    [self.restClient postPath:replyPath
                   parameters:@{ @"content" : reply }
                      success:success
                      failure:failure];
}

#pragma mark - Oauth methods

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


+ (NSString *)WordPressAppId {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"WPComAppID"];
}

+ (NSString *)WordPressAppSecret {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"WPComAppSecret"];
}


@end
