//
//  Blog.h
//  WordPress
//
//  Created by Gareth Townsend on 24/06/09.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import <CoreData/CoreData.h>
#import <WordPressApi/WordPressApi.h>

#import "Reachability.h"

@class WPAccount;

@interface Blog : NSManagedObject

@property (nonatomic, strong) NSNumber *blogID;
@property (nonatomic, strong) NSString *blogName, *xmlrpc, *apiKey;
@property (weak, readonly) NSString *blavatarUrl;
@property (nonatomic, strong) NSNumber *hasOlderPosts, *hasOlderPages;
@property (nonatomic, strong) NSSet *posts;
@property (nonatomic, strong) NSSet *categories;
@property (nonatomic, strong) NSSet *comments;
@property (nonatomic, strong) NSSet *themes;
@property (nonatomic, strong) NSSet *media;
@property (nonatomic, strong) NSString *currentThemeId;
@property (nonatomic, assign) BOOL isSyncingPosts;
@property (nonatomic, assign) BOOL isSyncingPages;
@property (nonatomic, assign) BOOL isSyncingComments;
@property (nonatomic, assign) BOOL isSyncingMedia;
@property (nonatomic, strong) NSDate *lastPostsSync;
@property (nonatomic, strong) NSDate *lastPagesSync;
@property (nonatomic, strong) NSDate *lastCommentsSync;
@property (nonatomic, strong) NSDate *lastStatsSync;
@property (nonatomic, strong) NSString *lastUpdateWarning;
@property (nonatomic, assign) BOOL geolocationEnabled;
@property (nonatomic, assign) BOOL visible;
@property (nonatomic, weak) NSNumber *isActivated;
@property (nonatomic, strong) NSDictionary *options; //we can store an NSArray or an NSDictionary as a transformable attribute...
@property (nonatomic, strong) NSDictionary *postFormats;
@property (nonatomic, strong) WPAccount *account;
@property (nonatomic, strong) WPAccount *jetpackAccount;
@property (weak, readonly) NSArray *sortedPostFormatNames;
@property (readonly, nonatomic, strong) WPXMLRPCClient *api;
@property (weak, readonly) NSString *version;
@property (nonatomic, readonly, strong) NSString *username;
@property (nonatomic, readonly, strong) NSString *password;
@property (weak, readonly) Reachability *reachability;
@property (readonly) BOOL reachable;
@property (nonatomic, assign) BOOL videoPressEnabled;

/**
 URL properties (example: http://wp.koke.me/sub/xmlrpc.php)
 */

// User to display the blog url to the user (IDN decoded, no http:)
// wp.koke.me/sub
@property (weak, readonly) NSString *displayURL;
// alias of displayURL
// kept for compatibilty, used as a key to store passwords
@property (weak, readonly) NSString *hostURL;
@property (weak, readonly) NSString *homeURL;
// http://wp.koke.me/sub
@property (nonatomic, strong) NSString *url;
// Used for reachability checks (IDN encoded)
// wp.koke.me
@property (weak, readonly) NSString *hostname;

/**
 Returns the blog currently flagged as the one last used, or the first blog in 
 an alphanumerically sorted list, if no blog is currently flagged as last used.
 */
+ (Blog *)lastUsedOrFirstBlog;

/**
 Returns the blog currently flaged as the one last used.
 */
+ (Blog *)lastUsedBlog;

/**
 Returns the first blog in an alphanumerically sorted list. 
 */
+ (Blog *)firstBlog;

#pragma mark - Blog information
- (void)flagAsLastUsed;
- (BOOL)isWPcom;
- (BOOL)isPrivate;
- (NSArray *)sortedCategories;
- (id)getOptionValue:(NSString *) name;
- (NSString *)loginUrl;
- (NSString *)urlWithPath:(NSString *)path;
- (NSString *)adminUrlWithPath:(NSString *)path;
- (NSArray *)getXMLRPCArgsWithExtra:(id)extra;
- (NSUInteger)numberOfPendingComments;
- (NSDictionary *) getImageResizeDimensions;
- (BOOL)supportsFeaturedImages;

#pragma mark - 

- (void)dataSave;
- (void)remove;

#pragma mark -
#pragma mark Synchronization
/*! Sync only blog posts, categories, options and post formats.
 *  Used for instances where comments and pages aren't necessarily needed to be updated.
 *
 *  \param success Completion block called if the operation was a success
 *  \param failure Completion block called if the operation was a failure
 */
- (void)syncPostsAndMetadataWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;

/*! Sync only blog posts (no metadata lists)
 *  Used for instances where comments and pages aren't necessarily needed to be updated.
 *
 *  \param success  Completion block called if the operation was a success
 *  \param failure  Completion block called if the operation was a failure
 *  \param more     If posts already exist then sync an additional batch
 */
- (void)syncPostsWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure loadMore:(BOOL)more;

- (void)syncPagesWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure loadMore:(BOOL)more;
- (void)syncCategoriesWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)syncOptionsWithWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)syncCommentsWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)syncMediaLibraryWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)syncPostFormatsWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;

/*! Syncs an entire blog include posts, pages, comments, options, post formats and categories.
 *  Used for instances where the entire blog should be refreshed or initially downloaded.
 *
 *  \param success Completion block called if the operation was a success
 *  \param failure Completion block called if the operation was a failure
 */
- (void)syncBlogWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;

- (void)checkVideoPressEnabledWithSuccess:(void (^)(BOOL enabled))success failure:(void (^)(NSError *error))failure;

#pragma mark -
#pragma mark Class methods
+ (NSInteger)countWithContext:(NSManagedObjectContext *)moc;
+ (NSInteger)countSelfHostedWithContext:(NSManagedObjectContext *)moc;
+ (NSInteger)countVisibleWithContext:(NSManagedObjectContext *)moc;

@end
