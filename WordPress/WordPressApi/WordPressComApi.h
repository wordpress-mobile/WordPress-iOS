//
//  WordPressComApi.h
//  WordPress
//
//  Created by Jorge Bernal on 6/4/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <AFHTTPClient.h>
#import <Availability.h>

#define WordPressComApiDidLoginNotification @"WordPressComApiDidLogin"
#define WordPressComApiDidLogoutNotification @"WordPressComApiDidLogout"

typedef void (^WordPressComApiRestSuccessResponseBlock)(AFHTTPRequestOperation *operation, id responseObject);
typedef void (^WordPressComApiRestSuccessFailureBlock)(AFHTTPRequestOperation *operation, NSError *error);

typedef NS_ENUM(NSUInteger, WordPressComApiError) {
    WordPressComApiErrorJSON,
    WordPressComApiErrorNoAccessToken,
    WordPressComApiErrorLoginFailed,
    WordPressComApiErrorInvalidToken,
    WordPressComApiErrorAuthorizationRequired,
};

extern NSString *const WordPressComApiErrorDomain;
extern NSString *const WordPressComApiErrorCodeKey;

@interface WordPressComApi : AFHTTPClient
@property (nonatomic,readonly,strong) NSString *username;
@property (nonatomic,readonly,strong) NSString *password;

+ (WordPressComApi *)sharedApi;

///-------------------------
/// @name Account management
///-------------------------

- (void)signInWithUsername:(NSString *)username password:(NSString *)password success:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)refreshTokenWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)signInWithToken:(NSString *)token DEPRECATED_ATTRIBUTE;
- (void)signOut;
- (BOOL)hasCredentials;

///---------------------------
/// @name Transitional methods
///---------------------------

/**
 Reloads `self.username` and `self.password` from the defaults dictionary and keychain
 
 Since WordPressComApi uses tokens now, this shouldn't be necessary and will be removed in the future
 */
- (void)updateCredentailsFromStore;

///--------------------
/// @name Notifications
///--------------------

- (void)saveNotificationSettings:(void (^)())success
                         failure:(void (^)(NSError *error))failure;

- (void)fetchNotificationSettings:(void (^)())success
                          failure:(void (^)(NSError *error))failure;

- (void)syncPushNotificationInfo;

/*
 * Queries the REST Api for unread notes and determines if the user has
 * seen them using the response's last_seen_time timestamp.
 *
 * If we have unseen notes we post a WordPressComApiUnseenNotesNotification
 */
- (void)checkForNewUnseenNotifications;

- (void)checkNotificationsSuccess:(WordPressComApiRestSuccessResponseBlock)success
                          failure:(WordPressComApiRestSuccessFailureBlock)failure;

- (void)getNotificationsBefore:(NSNumber *)timestamp
                       success:(WordPressComApiRestSuccessResponseBlock)success
                       failure:(WordPressComApiRestSuccessFailureBlock)failure;

- (void)getNotificationsSince:(NSNumber *)timestamp
                      success:(WordPressComApiRestSuccessResponseBlock)success
                      failure:(WordPressComApiRestSuccessFailureBlock)failure;

- (void)getNotificationsWithParameters:(NSDictionary *)parameters
                               success:(WordPressComApiRestSuccessResponseBlock)success
                               failure:(WordPressComApiRestSuccessFailureBlock)failure;

- (void)refreshNotifications:(NSArray *)notes
                     success:(WordPressComApiRestSuccessResponseBlock)success
                     failure:(WordPressComApiRestSuccessFailureBlock)failure;

- (void)markNoteAsRead:(NSString *)noteID
               success:(WordPressComApiRestSuccessResponseBlock)success
               failure:(WordPressComApiRestSuccessFailureBlock)failure;

- (void)updateNoteLastSeenTime:(NSNumber *)timestamp
                       success:(WordPressComApiRestSuccessResponseBlock)success
                       failure:(WordPressComApiRestSuccessFailureBlock)failure;

- (void)followBlog:(NSUInteger)blogID isFollowing:(bool)following
           success:(WordPressComApiRestSuccessResponseBlock)success
           failure:(WordPressComApiRestSuccessFailureBlock)failure;

- (void)moderateComment:(NSUInteger)blogID forCommentID:(NSUInteger)commentID withStatus:(NSString *)commentStatus
                success:(WordPressComApiRestSuccessResponseBlock)success
                failure:(WordPressComApiRestSuccessFailureBlock)failure;

- (void)replyToComment:(NSUInteger)blogID forCommentID:(NSUInteger)commentID withReply:(NSString *)reply
               success:(WordPressComApiRestSuccessResponseBlock)success
               failure:(WordPressComApiRestSuccessFailureBlock)failure;

///-----------------
/// @name OAuth info
///-----------------

- (NSString *)authToken;
+ (NSString *)WordPressAppId;
+ (NSString *)WordPressAppSecret;

@end
