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


#pragma mark - Blog information
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

@end
