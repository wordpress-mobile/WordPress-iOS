#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import <CoreData/CoreData.h>
#import <WordPressApi/WordPressApi.h>

#import "Reachability.h"

@class WPAccount;
@class WordPressComApi;

@interface Blog : NSManagedObject

@property (weak, readonly) Reachability *reachability;
@property (readonly) BOOL reachable;
@property (nonatomic, strong, readwrite) NSNumber       *blogID;
@property (nonatomic, strong, readwrite) NSString       *blogName;
@property (nonatomic, strong, readwrite) NSString       *xmlrpc;
@property (nonatomic, strong, readwrite) NSString       *apiKey;
@property (nonatomic, strong, readwrite) NSNumber       *hasOlderPosts;
@property (nonatomic, strong, readwrite) NSNumber       *hasOlderPages;
@property (nonatomic, strong, readwrite) NSSet          *posts;
@property (nonatomic, strong, readwrite) NSSet          *categories;
@property (nonatomic, strong, readwrite) NSSet          *comments;
@property (nonatomic, strong, readwrite) NSSet          *themes;
@property (nonatomic, strong, readwrite) NSSet          *media;
@property (nonatomic, strong, readwrite) NSString       *currentThemeId;
@property (nonatomic, assign, readwrite) BOOL           isSyncingPosts;
@property (nonatomic, assign, readwrite) BOOL           isSyncingPages;
@property (nonatomic, assign, readwrite) BOOL           isSyncingComments;
@property (nonatomic, assign, readwrite) BOOL           isSyncingMedia;
@property (nonatomic, strong, readwrite) NSDate         *lastPostsSync;
@property (nonatomic, strong, readwrite) NSDate         *lastPagesSync;
@property (nonatomic, strong, readwrite) NSDate         *lastCommentsSync;
@property (nonatomic, strong, readwrite) NSDate         *lastStatsSync;
@property (nonatomic, strong, readwrite) NSString       *lastUpdateWarning;
@property (nonatomic, assign, readwrite) BOOL           geolocationEnabled;
@property (nonatomic, assign, readwrite) BOOL           visible;
@property (nonatomic,   weak, readwrite) NSNumber       *isActivated;
@property (nonatomic, strong, readwrite) NSDictionary   *options;
@property (nonatomic, strong, readwrite) NSDictionary   *postFormats;
@property (nonatomic, strong, readwrite) WPAccount      *account;
@property (nonatomic, strong, readwrite) WPAccount      *jetpackAccount;
@property (nonatomic, assign, readwrite) BOOL           videoPressEnabled;

// Readonly Properties
@property (nonatomic,   weak,  readonly) NSString       *blavatarUrl;
@property (nonatomic,   weak,  readonly) NSArray        *sortedPostFormatNames;
@property (nonatomic, strong,  readonly) WPXMLRPCClient *api;
@property (nonatomic,   weak,  readonly) NSString       *version;
@property (nonatomic, strong,  readonly) NSString       *username;
@property (nonatomic, strong,  readonly) NSString       *password;


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

/**
 Returns a REST API client if available
 
 If the blog is a WordPress.com one or it has Jetpack it will return a REST API
 client. Otherwise, the XML-RPC API should be used.
 
 @warning this method doesn't know if a Jetpack blog has the JSON API disabled
 
 @return a WordPressComApi object if available
 */
- (WordPressComApi *)restApi;
- (NSNumber *)dotComID;

#pragma mark -

// TODO - Remove these methods when persistence/network code removed from VCs
- (void)dataSave;
- (void)remove;

@end
