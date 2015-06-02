#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import <CoreData/CoreData.h>
#import <WordPressApi/WordPressApi.h>

#import "JetpackState.h"

@class WPAccount;
@class WordPressComApi;

typedef NS_ENUM(NSUInteger, BlogFeature) {
    /// Can the blog be removed?
    BlogFeatureRemovable,
    /// Can the blog be hidden?
    BlogFeatureVisibility,
    /// Can the blog use the WordPress.com REST API?
    BlogFeatureWPComRESTAPI,
    /// Can we use an OAuth2 token with wp-login.php?
    BlogFeatureOAuth2Login,
    /// Does the blog support reblogs?
    BlogFeatureReblog,
    /// Does the blog support comment likes?
    BlogFeatureCommentLikes,
    /// Can we show stats for the blog?
    BlogFeatureStats,
    /// Does the blog support mentions?
    BlogFeatureMentions,
    /// Does the blog support push notifications?
    BlogFeaturePushNotifications,
};

@interface Blog : NSManagedObject

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
@property (nonatomic, assign, readwrite) BOOL           isMultiAuthor;
@property (nonatomic, assign, readwrite) BOOL           isJetpack;

// Readonly Properties
@property (nonatomic,   weak,  readonly) NSString       *blavatarUrl;
@property (nonatomic,   weak,  readonly) NSArray        *sortedPostFormatNames;
@property (nonatomic, strong,  readonly) WPXMLRPCClient *api;
@property (nonatomic,   weak,  readonly) NSString       *version;
@property (nonatomic, strong,  readonly) NSString       *username;
@property (nonatomic, strong,  readonly) NSString       *password;
@property (nonatomic, strong,  readonly) NSString       *authToken;
@property (nonatomic, strong,  readonly) NSSet *allowedFileTypes;
/**
 Contains the Jetpack state. Returns nil if the blog options haven't been downloaded yet
 */
@property (nonatomic, strong,  readonly) JetpackState *jetpack;


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
- (BOOL)isHostedAtWPcom;
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
- (BOOL)supports:(BlogFeature)feature;
/**
 Returns a human readable description for logging
 
 Instead of inspecting the core data object, this returns select information, more
 useful for support.
 */
- (NSString *)logDescription;

/**
 Returns a REST API client if available
 
 If the blog is a WordPress.com one or it has Jetpack it will return a REST API
 client. Otherwise, the XML-RPC API should be used.
 
 @warning this method doesn't know if a Jetpack blog has the JSON API disabled
 
 @return a WordPressComApi object if available
 */
- (WordPressComApi *)restApi;
- (NSNumber *)dotComID;

@end
