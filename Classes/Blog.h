//
//  Blog.h
//  WordPress
//
//  Created by Gareth Townsend on 24/06/09.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import "AFXMLRPCClient.h"
#import "Reachability.h"

@interface Blog : NSManagedObject

@property (nonatomic, retain) NSNumber *blogID;
@property (nonatomic, retain) NSString *blogName, *username, *password, *xmlrpc, *apiKey;
@property (readonly) NSString *blavatarUrl;
@property (nonatomic, assign) NSNumber *isAdmin, *hasOlderPosts, *hasOlderPages;
@property (nonatomic, retain) NSSet *posts;
@property (nonatomic, retain) NSSet *categories;
@property (nonatomic, retain) NSSet *comments;
@property (nonatomic, assign) BOOL isSyncingPosts;
@property (nonatomic, assign) BOOL isSyncingPages;
@property (nonatomic, assign) BOOL isSyncingComments;
@property (nonatomic, retain) NSDate *lastPostsSync;
@property (nonatomic, retain) NSDate *lastPagesSync;
@property (nonatomic, retain) NSDate *lastCommentsSync;
@property (nonatomic, retain) NSDate *lastStatsSync;
@property (nonatomic, assign) BOOL geolocationEnabled;
@property (nonatomic, retain) NSDictionary *options; //we can store an NSArray or an NSDictionary as a transformable attribute... 
@property (nonatomic, retain) NSDictionary *postFormats;
@property (readonly, nonatomic, retain) AFXMLRPCClient *api;
@property (readonly) NSString *version;
@property (readonly) Reachability *reachability;
@property (readonly) BOOL reachable;

/**
 URL properties (example: http://wp.koke.me/sub/xmlrpc.php)
 */

// User to display the blog url to the user (IDN decoded, no http:)
// wp.koke.me/sub
@property (readonly) NSString *displayURL;
// alias of displayURL
// kept for compatibilty, used as a key to store passwords
@property (readonly) NSString *hostURL;
// http://wp.koke.me/sub
@property (nonatomic, retain) NSString *url;
// Used for reachability checks (IDN encoded)
// wp.koke.me
@property (readonly) NSString *hostname;


#pragma mark - Blog information
- (BOOL)isWPcom;
- (BOOL)isPrivate;
- (NSArray *)sortedCategories;
- (NSString *)getOptionValue:(NSString *) name;
- (NSString *)loginURL;
- (NSArray *)getXMLRPCArgsWithExtra:(id)extra;
- (NSString *)fetchPassword;

#pragma mark - 

- (void)dataSave;

#pragma mark -
#pragma mark Synchronization
- (NSArray *)syncedPosts;
- (void)syncPostsWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure loadMore:(BOOL)more;
- (void)syncPagesWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure loadMore:(BOOL)more;
- (void)syncCategoriesWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)syncOptionsWithWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)syncCommentsWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)syncPostFormatsWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)syncBlogWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;
// Called when manually refreshing PostsViewController
// Syncs posts, categories, options, and post formats
- (void)syncBlogPostsWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;

#pragma mark -
#pragma mark Class methods
+ (BOOL)blogExistsForURL:(NSString *)theURL withContext:(NSManagedObjectContext *)moc andUsername:(NSString *)username;
+ (Blog *)createFromDictionary:(NSDictionary *)blogInfo withContext:(NSManagedObjectContext *)moc;
+ (Blog *)findWithId:(int)blogId withContext:(NSManagedObjectContext *)moc;
+ (NSInteger)countWithContext:(NSManagedObjectContext *)moc;

@end
