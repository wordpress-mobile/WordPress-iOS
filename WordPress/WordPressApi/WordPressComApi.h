//
//  WordPressComApi.h
//  WordPress
//
//  Created by Jorge Bernal on 6/4/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <AFHTTPClient.h>
#import <Availability.h>
#import "ReaderPost.h"

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

///--------------------
/// @name Reader
///--------------------

typedef NS_ENUM(NSUInteger, RESTPostEndpoint) {
	RESTPostEndpointFreshly,
	RESTPostEndpointFollowing,
	RESTPostEndpointLiked,
	RESTPostEndpointTopic,
	RESTPostEndpointSite
};


/*
 Returns the API path for a particular RESTPostEndpoint.
 */
- (NSString *)getEndpointPath:(RESTPostEndpoint)endpoint;

/**
 Gets the list of recommended topics for the Reader.
 */
- (void)getReaderTopicsWithSuccess:(WordPressComApiRestSuccessResponseBlock)success
						   failure:(WordPressComApiRestSuccessFailureBlock)failure;

/**
 Gets the list of comments for the specified post, on the specified site.
 
 @param postID The ID of the post for the comments to retrieve.
 @param siteID The ID (as a string) or host name of the site.
 @param success a block called if the REST API call is successful.
 @param failure a block called if there is any error. `error` can be any underlying network error
 */
- (void)getCommentsForPost:(NSUInteger)postID
				  fromSite:(NSString *)siteID
				   success:(WordPressComApiRestSuccessResponseBlock)success
				   failure:(WordPressComApiRestSuccessFailureBlock)failure;

/**
 Gets a list of posts from the specified REST endpoint.
 
 @param endpoint The path for the endpoint to qurey. The path should already include any ID (siteID, topicID, etc) required for the request.
 @param params A dictionary of modifiers to limit or modify the result set. Possible values include number, offset, page, order, order_by, before, after. 
 Check the documentation for the desired endpoint for a full list. ( http://developer.wordpress.com/docs/api/1/ )
 @param success a block called if the REST API call is successful.
 @param failure a block called if there is any error. `error` can be any underlying network error
 */
- (void)getPostsFromEndpoint:(NSString *)path
			withParameters:(NSDictionary *)params
				   success:(WordPressComApiRestSuccessResponseBlock)success
				   failure:(WordPressComApiRestSuccessFailureBlock)failure;

@end
