#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import <CoreData/CoreData.h>
#import "JetpackState.h"

@class BlogSettings;
@class WPAccount;
@class WordPressComApi;
@class WPXMLRPCClient;

extern NSString * const PostFormatStandard;

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
    /// Does the blog support theme browsing?
    BlogFeatureThemeBrowsing,
    /// Does the blog support private visibility?
    BlogFeaturePrivate,
    /// Does the blog support sharing?
    BlogFeatureSharing,
    /// Does the blog support people management?
    BlogFeaturePeople,
    /// Can the blog's site be changed or deleted?
    BlogFeatureSiteManagement,
    /// Does the blog support different paid plans?
    BlogFeaturePlans
};

typedef NS_ENUM(NSInteger, SiteVisibility) {
    SiteVisibilityPrivate = -1,
    SiteVisibilityHidden = 0,
    SiteVisibilityPublic = 1,
    SiteVisibilityUnknown = NSIntegerMax
};

@interface Blog : NSManagedObject

@property (nonatomic, strong, readwrite) NSNumber *blogID __deprecated_msg("Use dotComID instead");
@property (nonatomic, strong, readwrite) NSNumber *dotComID;
@property (nonatomic, strong, readwrite) NSString *xmlrpc;
@property (nonatomic, strong, readwrite) NSString *apiKey;
@property (nonatomic, strong, readwrite) NSNumber *hasOlderPosts;
@property (nonatomic, strong, readwrite) NSNumber *hasOlderPages;
@property (nonatomic, strong, readwrite) NSSet *posts;
@property (nonatomic, strong, readwrite) NSSet *categories;
@property (nonatomic, strong, readwrite) NSSet *tags;
@property (nonatomic, strong, readwrite) NSSet *comments;
@property (nonatomic, strong, readwrite) NSSet *connections;
@property (nonatomic, strong, readwrite) NSSet *themes;
@property (nonatomic, strong, readwrite) NSSet *media;
@property (nonatomic, strong, readwrite) NSOrderedSet *menus;
@property (nonatomic, strong, readwrite) NSOrderedSet *menuLocations;
@property (nonatomic, strong, readwrite) NSString *currentThemeId;
@property (nonatomic, assign, readwrite) BOOL isSyncingPosts;
@property (nonatomic, assign, readwrite) BOOL isSyncingPages;
@property (nonatomic, assign, readwrite) BOOL isSyncingMedia;
@property (nonatomic, strong, readwrite) NSDate *lastPostsSync;
@property (nonatomic, strong, readwrite) NSDate *lastPagesSync;
@property (nonatomic, strong, readwrite) NSDate *lastCommentsSync;
@property (nonatomic, strong, readwrite) NSDate *lastStatsSync;
@property (nonatomic, strong, readwrite) NSString *lastUpdateWarning;
@property (nonatomic, assign, readwrite) BOOL visible;
@property (nonatomic, weak, readwrite) NSNumber *isActivated;
@property (nonatomic, strong, readwrite) NSDictionary *options;
@property (nonatomic, strong, readwrite) NSSet *postTypes;
@property (nonatomic, strong, readwrite) NSDictionary *postFormats;
@property (nonatomic, strong, readwrite) WPAccount *account;
@property (nonatomic, strong, readwrite) WPAccount *jetpackAccount;
@property (nonatomic, strong, readwrite) WPAccount *accountForDefaultBlog;
@property (nonatomic, assign, readwrite) BOOL videoPressEnabled;
@property (nonatomic, assign, readwrite) BOOL isMultiAuthor;
@property (nonatomic, assign, readwrite) BOOL isHostedAtWPcom;
@property (nonatomic, strong, readwrite) NSString *icon;
@property (nonatomic, assign, readwrite) SiteVisibility siteVisibility;
@property (nonatomic, strong, readwrite) NSNumber *planID;
@property (nonatomic, strong, readwrite) NSSet *sharingButtons;

/**
 *  @details    Maps to a BlogSettings instance, which contains a collection of the available preferences, 
 *              and their values.
 */
@property (nonatomic, strong, readwrite) BlogSettings *settings;

/**
 *  @details    Flags whether the current user is an admin on the blog.
 */
@property (nonatomic, assign, readwrite) BOOL isAdmin;

/**
 *  @details    Stores the username for self hosted sites
 *
 *  @warn       For WordPress.com or Jetpack Managed sites this will be nil. Use usernameForSite instead
 */
@property (nonatomic, strong, readwrite) NSString       *username;
@property (nonatomic, strong, readwrite) NSString       *password;


// Readonly Properties
@property (nonatomic,   weak,  readonly) NSArray *sortedPostFormatNames;
@property (nonatomic,   weak,  readonly) NSArray *sortedPostFormats;
@property (nonatomic, strong,  readonly) WPXMLRPCClient *api;
@property (nonatomic,   weak,  readonly) NSString       *version;
@property (nonatomic, strong,  readonly) NSString       *authToken;
@property (nonatomic, strong,  readonly) NSSet *allowedFileTypes;
@property (nonatomic, copy, readonly) NSString *usernameForSite;

/**
 *  @details    Contains the Jetpack state. Returns nil if the blog options haven't been downloaded yet
 */
@property (nonatomic, strong,  readonly) JetpackState *jetpack;


/**
 *  @details    URL properties (example: http://wp.koke.me/sub/xmlrpc.php)
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

@property (weak, readonly) NSString *defaultPostFormatText;

#pragma mark - Blog information
- (BOOL)isPrivate;
- (NSArray *)sortedCategories;
- (id)getOptionValue:(NSString *) name;
- (NSString *)loginUrl;
- (NSString *)urlWithPath:(NSString *)path;
- (NSString *)adminUrlWithPath:(NSString *)path;
- (NSUInteger)numberOfPendingComments;
- (NSDictionary *) getImageResizeDimensions;
- (BOOL)supportsFeaturedImages;
- (BOOL)supports:(BlogFeature)feature;
- (BOOL)supportsPublicize;
- (BOOL)supportsShareButtons;

/**
 *  Returnst the text description for a post format code
 *
 *  @param postFormatCode of the post format you want to display
 *
 *  @return a string with the post format description and if no description was found the postFormatCode sent.
 */
- (NSString *)postFormatTextFromSlug:(NSString *)postFormatSlug;
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

@end
