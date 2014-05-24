#import <Availability.h>

typedef void (^WordPressComApiRestSuccessResponseBlock)(AFHTTPRequestOperation *operation, id responseObject);
typedef void (^WordPressComApiRestSuccessFailureBlock)(AFHTTPRequestOperation *operation, NSError *error);

typedef NS_ENUM(NSUInteger, WordPressComApiError) {
    WordPressComApiErrorJSON,
    WordPressComApiErrorNoAccessToken,
    WordPressComApiErrorLoginFailed,
    WordPressComApiErrorInvalidToken,
    WordPressComApiErrorAuthorizationRequired,
};

typedef NS_ENUM(NSUInteger, WordPressComApiBlogVisibility) {
    WordPressComApiBlogVisibilityPublic = 0,
    WordPressComApiComBlogVisibilityPrivate = 1,
    WordPressComApiBlogVisibilityHidden = 2,
};

extern NSString *const WordPressComApiErrorDomain;
extern NSString *const WordPressComApiErrorCodeKey;
extern NSString *const WordPressComApiErrorMessageKey;
extern NSString *const WordPressComApiPushAppId;

@interface WordPressComApi : NSObject
@property (nonatomic, readonly, strong) NSString *username;
@property (nonatomic, readonly, strong) NSString *password;
@property (nonatomic, readonly, strong) NSString *authToken;

/**
 Returns an API without an associated user
 
 Use this only for things that don't require an account, like signup or logged out reader
 */
+ (WordPressComApi *)anonymousApi;
- (id)initWithOAuthToken:(NSString *)authToken;

/**
 Reset the API instance
 
 @discussion Clears cookies, and sets `authToken`, `username`, and `password` to nil.
 */
- (void)reset;

///-------------------------
/// @name Account management
///-------------------------


- (BOOL)hasCredentials;

// Wipe the OAuth2 token
- (void)invalidateOAuth2Token;
- (void)validateWPComAccountWithEmail:(NSString *)email andUsername:(NSString *)username andPassword:(NSString *)password success:(void (^)(id responseObject))success failure:(void (^)(NSError *error))failure;
- (void)createWPComAccountWithEmail:(NSString *)email andUsername:(NSString *)username andPassword:(NSString *)password success:(void (^)(id responseObject))success failure:(void (^)(NSError *error))failure;
- (void)validateWPComBlogWithUrl:(NSString *)blogUrl andBlogTitle:(NSString *)blogTitle andLanguageId:(NSNumber *)languageId success:(void (^)(id))success failure:(void (^)(NSError *))failure;
- (void)createWPComBlogWithUrl:(NSString *)blogUrl andBlogTitle:(NSString *)blogTitle andLanguageId:(NSNumber *)languageId andBlogVisibility:(WordPressComApiBlogVisibility)visibility success:(void (^)(id))success failure:(void (^)(NSError *))failure;

///--------------------
/// @name Posts
///--------------------

- (void)fetchPost:(NSUInteger)postID
         fromSite:(NSUInteger)siteID
          success:(WordPressComApiRestSuccessResponseBlock)success
          failure:(WordPressComApiRestSuccessFailureBlock)failure;

- (void)fetchSiteMetaPost:(NSUInteger)postID
                 fromSite:(NSUInteger)siteID
                  success:(WordPressComApiRestSuccessResponseBlock)success
                  failure:(WordPressComApiRestSuccessFailureBlock)failure;

- (void)likePost:(NSUInteger)postID
         forSite:(NSUInteger)siteID
         success:(WordPressComApiRestSuccessResponseBlock)success
         failure:(WordPressComApiRestSuccessFailureBlock)failure;

- (void)unlikePost:(NSUInteger)postID
           forSite:(NSUInteger)siteID
           success:(WordPressComApiRestSuccessResponseBlock)success
           failure:(WordPressComApiRestSuccessFailureBlock)failure;

- (void)followSite:(NSUInteger)siteID
           success:(WordPressComApiRestSuccessResponseBlock)success
           failure:(WordPressComApiRestSuccessFailureBlock)failure;

- (void)unfollowSite:(NSUInteger)siteID
             success:(WordPressComApiRestSuccessResponseBlock)success
             failure:(WordPressComApiRestSuccessFailureBlock)failure;

- (void)followSiteAtURL:(NSString *)siteURL
                success:(WordPressComApiRestSuccessResponseBlock)success
                failure:(WordPressComApiRestSuccessFailureBlock)failure;

- (void)unfollowSiteAtURL:(NSString *)siteURL
                  success:(WordPressComApiRestSuccessResponseBlock)success
                  failure:(WordPressComApiRestSuccessFailureBlock)failure;

- (void)reblogPost:(NSUInteger)postID
          fromSite:(NSUInteger)siteID
            toSite:(NSUInteger)targetSiteID
              note:(NSString *)note
           success:(WordPressComApiRestSuccessResponseBlock)success
           failure:(WordPressComApiRestSuccessFailureBlock)failure;

- (void)fetchPostsFromEndpoint:(NSURL *)endpoint
                withParameters:(NSDictionary *)params
                       success:(WordPressComApiRestSuccessResponseBlock)success
                       failure:(WordPressComApiRestSuccessFailureBlock)failure;
///--------------------
/// @name Notifications
///--------------------

- (void)saveNotificationSettings:(NSDictionary *)settings
                        deviceId:(NSString *)deviceId
                         success:(void (^)())success
                         failure:(void (^)(NSError *error))failure;

- (void)fetchNotificationSettingsWithDeviceId:(NSString *)deviceId
                                      success:(void (^)(NSDictionary *settings))success
                                      failure:(void (^)(NSError *error))failure;

- (void)unregisterForPushNotificationsWithDeviceId:(NSString *)deviceId
                                           success:(void (^)())success
                                           failure:(void (^)(NSError *error))failure;

- (void)syncPushNotificationInfoWithDeviceToken:(NSString *)token
                                        success:(void (^)(NSString *deviceId, NSDictionary *settings))success
                                        failure:(void (^)(NSError *error))failure;
/*
 * Queries the REST Api for unread notes and determines if the user has
 * seen them using the response's last_seen_time timestamp.
 *
 */
- (void)fetchNewUnseenNotificationsWithSuccess:(void (^)(NSArray *notes))success
                                      failure:(void (^)(NSError *error))failure;

- (void)fetchRecentNotificationsWithSuccess:(void (^)(NSArray *notes))success
                          failure:(WordPressComApiRestSuccessFailureBlock)failure;

- (void)fetchNotificationsBefore:(NSNumber *)timestamp
                       success:(void (^)(NSArray *notes))success
                       failure:(WordPressComApiRestSuccessFailureBlock)failure;

- (void)fetchNotificationsSince:(NSNumber *)timestamp
                      success:(void (^)(NSArray *notes))success
                      failure:(WordPressComApiRestSuccessFailureBlock)failure;

- (void)fetchNotificationsWithParameters:(NSDictionary *)parameters
                               success:(void (^)(NSArray *notes))success
                               failure:(WordPressComApiRestSuccessFailureBlock)failure;

- (void)refreshNotifications:(NSArray *)noteIDs
                      fields:(NSString *)fields
                     success:(void (^)(NSArray *notes))success
                     failure:(WordPressComApiRestSuccessFailureBlock)failure;

- (void)markNoteAsRead:(NSString *)noteID
               success:(WordPressComApiRestSuccessResponseBlock)success
               failure:(WordPressComApiRestSuccessFailureBlock)failure;

- (void)updateNoteLastSeenTime:(NSNumber *)timestamp
                       success:(WordPressComApiRestSuccessResponseBlock)success
                       failure:(WordPressComApiRestSuccessFailureBlock)failure;

///-------------
/// @name Reader
///-------------

- (void)followBlog:(NSUInteger)blogID isFollowing:(BOOL)following
           success:(WordPressComApiRestSuccessResponseBlock)success
           failure:(WordPressComApiRestSuccessFailureBlock)failure;


///---------------
/// @name Comments
///---------------

- (void)getCommentsForPost:(NSUInteger)postID
                  fromSite:(NSString *)siteID
            withParameters:(NSDictionary*)params
                   success:(WordPressComApiRestSuccessResponseBlock)success
                   failure:(WordPressComApiRestSuccessFailureBlock)failure;

- (void)getComment:(NSUInteger)commentID
          fromSite:(NSString *)siteID
           success:(WordPressComApiRestSuccessResponseBlock)success
           failure:(WordPressComApiRestSuccessFailureBlock)failure;

- (void)postNoteToComment:(NSUInteger)commentID
                   toSite:(NSString *)siteID
                   params:(NSDictionary *) params
                  success:(WordPressComApiRestSuccessResponseBlock)success
                  failure:(WordPressComApiRestSuccessFailureBlock)failure;

- (void)publishComment:(NSString *)commentText
                toPath:(NSString *) path
               success:(WordPressComApiRestSuccessResponseBlock)success
               failure:(WordPressComApiRestSuccessFailureBlock)failure;

- (void)moderateComment:(NSUInteger)blogID
           forCommentID:(NSUInteger)commentID
             withStatus:(NSString *)commentStatus
                success:(WordPressComApiRestSuccessResponseBlock)success
                failure:(WordPressComApiRestSuccessFailureBlock)failure;

- (void)replyToComment:(NSUInteger)blogID
          forCommentID:(NSUInteger)commentID
             withReply:(NSString *)reply
               success:(WordPressComApiRestSuccessResponseBlock)success
               failure:(WordPressComApiRestSuccessFailureBlock)failure;

- (void)replyToCommentInPath:(NSString *) path
                   withReply:(NSString *) reply
                     success:(WordPressComApiRestSuccessResponseBlock)success
                     failure:(WordPressComApiRestSuccessFailureBlock)failure;

- (void)performCommentAction:(NSDictionary *)commentAction
                     success:(WordPressComApiRestSuccessResponseBlock)success
                     failure:(WordPressComApiRestSuccessFailureBlock)failure;

- (void)approveCommentAction:(NSDictionary *)commentAction
                     success:(WordPressComApiRestSuccessResponseBlock)success
                     failure:(WordPressComApiRestSuccessFailureBlock)failure;


///------------------
/// @name Blog Themes
///------------------

- (void)fetchThemesForBlogId:(NSString*)blogId
                     success:(WordPressComApiRestSuccessResponseBlock)success
                     failure:(WordPressComApiRestSuccessFailureBlock)failure;

- (void)fetchCurrentThemeForBlogId:(NSString*)blogId
                           success:(WordPressComApiRestSuccessResponseBlock)success
                           failure:(WordPressComApiRestSuccessFailureBlock)failure;

- (void)activateThemeForBlogId:(NSString*)blogId themeId:(NSString*)themeId
                       success:(WordPressComApiRestSuccessResponseBlock)success
                       failure:(WordPressComApiRestSuccessFailureBlock)failure;

///-----------------
/// @name OAuth info
///-----------------

+ (NSString *)WordPressAppId;
+ (NSString *)WordPressAppSecret;

///-----------------
/// @name Stats
///-----------------

- (void)fetchStatsForUrls:(NSArray *) urls
    withCompletionHandler:(WordPressComApiRestSuccessResponseBlock)completionHandler
           failureHandler:(WordPressComApiRestSuccessFailureBlock)failureHandler;

///-----------------
/// @name Menu
///-----------------

- (void)fetchReaderMenuWithSuccess:(WordPressComApiRestSuccessResponseBlock)success
                           failure:(WordPressComApiRestSuccessFailureBlock)failure;


- (void)fetchMeWithSuccess:(WordPressComApiRestSuccessResponseBlock)success
                   failure:(WordPressComApiRestSuccessFailureBlock)failure;
@end
