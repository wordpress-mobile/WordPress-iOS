#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "BasePost.h"
#import "WordPressComApi.h"

extern NSInteger const ReaderTopicEndpointIndex;
extern NSInteger const ReaderPostsToSync;
extern NSString *const ReaderLastSyncDateKey;
extern NSString *const ReaderCurrentTopicKey;
extern NSString *const ReaderTopicsArrayKey;
extern NSString *const ReaderListsArrayKey;


extern NSString * const ReaderPostStoredCommentIDKey;
extern NSString * const ReaderPostStoredCommentTextKey;


@interface ReaderPost : BasePost

@property (nonatomic, strong) NSString *authorAvatarURL;
@property (nonatomic, strong) NSString *authorDisplayName;
@property (nonatomic, strong) NSString *authorEmail;
@property (nonatomic, strong) NSString *authorURL;
@property (nonatomic, strong) NSString *blogName;
@property (nonatomic, strong) NSNumber *blogSiteID;
@property (nonatomic, strong) NSString *blogURL;
@property (nonatomic, strong) NSNumber *commentCount;
@property (nonatomic, strong) NSNumber *commentsOpen;
@property (nonatomic, strong) NSDate *dateSynced;
@property (nonatomic, strong) NSDate *dateCommentsSynced;
@property (nonatomic, strong) NSString *endpoint;
@property (nonatomic, strong) NSString *featuredImage;
@property (nonatomic, strong) NSNumber *isBlogPrivate;
@property (nonatomic, strong) NSNumber *isFollowing;
@property (nonatomic, strong) NSNumber *isLiked;
@property (nonatomic, strong) NSNumber *isReblogged;
@property (nonatomic, strong) NSNumber *isWPCom;
@property (nonatomic, strong) NSNumber *likeCount;
@property (nonatomic, strong) NSString *postAvatar;
@property (nonatomic, strong) NSNumber *siteID;
@property (nonatomic, strong) NSDate *sortDate;
@property (nonatomic, strong) NSString *storedComment; // Formatted as commentID,string
@property (nonatomic, strong) NSString *summary;
@property (nonatomic, strong) NSMutableSet *comments;
@property (nonatomic, readonly, strong) NSURL *featuredImageURL;
@property (nonatomic, retain) WPAccount *account;
@property (nonatomic, strong) NSString *primaryTagName;
@property (nonatomic, strong) NSString *primaryTagSlug;
@property (nonatomic, strong) NSString *tags;

/**
 An array of dictionaries representing available REST API endpoints to retrieve posts for the Reader.
 The dictionaries contain the endpoint title, API path fragment, and if the endpoint is one of the default topics.
 */
+ (NSArray *)readerEndpoints;

+ (NSDictionary *)currentTopic;

+ (NSString *)currentEndpoint;

/**
 Fetch posts for the specified endpoint. 
 
 @param endpoint REST endpoint that sourced the posts.
 @param context The managed object context to query.

 @return Returns an array of posts.
 */
+ (NSArray *)fetchPostsForEndpoint:(NSString *)endpoint withContext:(NSManagedObjectContext *)context;


/*
 Save or update posts for the specified endpoint.
 
 @param endpoint REST endpoint that sourced the posts.
 @param arr An array of dictionaries from which to build posts.
 @param success  A block to execute when the save has finished.
 
 @return Returns an array of posts.
 */
+ (void)syncPostsFromEndpoint:(NSString *)endpoint withArray:(NSArray *)arr success:(void (^)())success;


/*
 Delete posts that were synced before the specified date.
 
 @param syncedDate The date before which posts should be deleted.
 @param context The managed object context to query.
 
 */
+ (void)deletePostsSyncedEarlierThan:(NSDate *)syncedDate;


/**
 Create or update an existing ReaderPost with the specified dictionary. 
 
 @param dict A dictionary representing the ReaderPost
 @param endpoint The endpoint from which the ReaderPost was retrieved. 
 @param context The Managed Object Context to fetch from. 
 */
+ (void)createOrUpdateWithDictionary:(NSDictionary *)dict forEndpoint:(NSString *)endpoint withContext:(NSManagedObjectContext *)context;


- (void)toggleLikedWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;


- (void)toggleFollowingWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;


- (void)reblogPostToSite:(id)site note:(NSString *)note success:(void (^)())success failure:(void (^)(NSError *error))failure;


- (BOOL)isFollowable;

- (BOOL)isFreshlyPressed;

- (BOOL)isBlogsIFollow;

- (BOOL)isPrivate;

- (void)storeComment:(NSNumber *)commentID comment:(NSString *)comment;


- (NSDictionary *)getStoredComment;

- (NSString *)authorString;

- (NSString *)avatar;

- (UIImage *)cachedAvatarWithSize:(CGSize)size;

- (void)fetchAvatarWithSize:(CGSize)size success:(void (^)(UIImage *image))success;

- (NSString *)featuredImageForWidth:(NSUInteger)width height:(NSUInteger)height;

@end


@interface ReaderPost (WordPressComApi)

/**
 Gets the list of tags & lists for the Reader.
 
 @param success a block called if the REST API call is successful.
 @param failure a block called if there is any error. `error` can be any underlying network error
 */
+ (void)getReaderMenuItemsWithSuccess:(WordPressComApiRestSuccessResponseBlock)success
                              failure:(WordPressComApiRestSuccessFailureBlock)failure;

/**
 Gets the list of comments for the specified post, on the specified site.
 
 @param postID The ID of the post for the comments to retrieve.
 @param siteID The ID (as a string) or host name of the site.
 @param params A dictionary of modifiers to limit or modify the result set. Possible values include number, offset, page, order, order_by, before, after.
 Check the documentation for the desired endpoint for a full list. ( http://developer.wordpress.com/docs/api/1/ )
 @param success a block called if the REST API call is successful.
 @param failure a block called if there is any error. `error` can be any underlying network error
 */
+ (void)getCommentsForPost:(NSUInteger)postID
				  fromSite:(NSString *)siteID
			withParameters:(NSDictionary*)params
				   success:(WordPressComApiRestSuccessResponseBlock)success
				   failure:(WordPressComApiRestSuccessFailureBlock)failure;

/**
 Gets a list of posts from the specified REST endpoint.
 
 @param endpoint The path for the endpoint to qurey (see the docs). The path should already include any ID (siteID, topicID, etc) required for the request.
 @param params A dictionary of modifiers to limit or modify the result set. Possible values include number, offset, page, order, order_by, before, after.
 Check the documentation for the desired endpoint for a full list. ( http://developer.wordpress.com/docs/api/1/ )
 @param loadingMore True if the call is loading more posts. Fails if this is a regular sync.  Older posts are deleted from core data on regular syncs but not when loading more.
 @param success a block called if the REST API call is successful.
 @param failure a block called if there is any error. `error` can be any underlying network error
 */
+ (void)getPostsFromEndpoint:(NSString *)path
			  withParameters:(NSDictionary *)params
				 loadingMore:(BOOL)loadingMore
					 success:(WordPressComApiRestSuccessResponseBlock)success
					 failure:(WordPressComApiRestSuccessFailureBlock)failure;

/**
 Wrapper for getPostsFromEndPoint:withParameters:loadingMore:success:failure: that passes in the current endpoint and default params. 
 Anticipates future improvements to background syncing. 
 
 @param completionHandler a block called when the fetch completes successfully or unsuccessfully. `count` is the number of posts fetched. `error` can be any underlying network error
 */
+ (void)fetchPostsWithCompletionHandler:(void (^)(NSInteger count, NSError *error))completionHandler;

@end
