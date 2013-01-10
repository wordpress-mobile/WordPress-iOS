//
//  Blog.h
//  WordPress
//
//  Created by Gareth Townsend on 24/06/09.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import <CoreData/CoreData.h>
#import "AFXMLRPCClient.h"
#import "Reachability.h"

@interface Blog : NSManagedObject

@property (nonatomic, strong) NSNumber *blogID;
@property (nonatomic, strong) NSString *blogName, *username, *password, *xmlrpc, *apiKey;
@property (weak, readonly) NSString *blavatarUrl;
@property (nonatomic, strong) NSNumber *isAdmin, *hasOlderPosts, *hasOlderPages;
@property (nonatomic, strong) NSSet *posts;
@property (nonatomic, strong) NSSet *categories;
@property (nonatomic, strong) NSSet *comments;
@property (nonatomic, assign) BOOL isSyncingPosts;
@property (nonatomic, assign) BOOL isSyncingPages;
@property (nonatomic, assign) BOOL isSyncingComments;
@property (nonatomic, strong) NSDate *lastPostsSync;
@property (nonatomic, strong) NSDate *lastPagesSync;
@property (nonatomic, strong) NSDate *lastCommentsSync;
@property (nonatomic, strong) NSDate *lastStatsSync;
@property (nonatomic, strong) NSString *lastUpdateWarning;
@property (nonatomic, assign) BOOL geolocationEnabled;
@property (nonatomic, weak) NSNumber *isActivated;
@property (nonatomic, strong) NSDictionary *options; //we can store an NSArray or an NSDictionary as a transformable attribute... 
@property (nonatomic, strong) NSDictionary *postFormats;
@property (weak, readonly) NSArray *sortedPostFormatNames;
@property (readonly, nonatomic, strong) AFXMLRPCClient *api;
@property (weak, readonly) NSString *version;
@property (weak, readonly) Reachability *reachability;
@property (readonly) BOOL reachable;

/**
 URL properties (example: http://wp.koke.me/sub/xmlrpc.php)
 */

// User to display the blog url to the user (IDN decoded, no http:)
// wp.koke.me/sub
@property (weak, readonly) NSString *displayURL;
// alias of displayURL
// kept for compatibilty, used as a key to store passwords
@property (weak, readonly) NSString *hostURL;
// http://wp.koke.me/sub
@property (nonatomic, strong) NSString *url;
// Used for reachability checks (IDN encoded)
// wp.koke.me
@property (weak, readonly) NSString *hostname;


#pragma mark - Blog information
- (BOOL)isWPcom;
- (BOOL)isPrivate;
- (NSArray *)sortedCategories;
- (id)getOptionValue:(NSString *) name;
- (NSString *)loginURL;
- (NSArray *)getXMLRPCArgsWithExtra:(id)extra;
- (NSString *)fetchPassword;
- (int)numberOfPendingComments;
- (NSDictionary *) getImageResizeDimensions;
- (BOOL)hasJetpack;
- (NSNumber *)jetpackClientID;

#pragma mark - 

- (void)dataSave;
- (void)remove;

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
- (void)checkActivationStatusWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)checkVideoPressEnabledWithSuccess:(void (^)(BOOL enabled))success failure:(void (^)(NSError *error))failure;

#pragma mark -
#pragma mark Class methods
+ (BOOL)blogExistsForURL:(NSString *)theURL withContext:(NSManagedObjectContext *)moc andUsername:(NSString *)username;
+ (Blog *)createFromDictionary:(NSDictionary *)blogInfo withContext:(NSManagedObjectContext *)moc;
+ (Blog *)findWithId:(int)blogId withContext:(NSManagedObjectContext *)moc;
+ (NSInteger)countWithContext:(NSManagedObjectContext *)moc;

@end
