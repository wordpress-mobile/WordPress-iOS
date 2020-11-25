#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@class AbstractPost;
@class BlogSettings;
@class WPAccount;
@class WordPressComRestApi;
@class WordPressOrgRestApi;
@class WordPressOrgXMLRPCApi;
@class Role;
@class QuickStartTourState;
@class UserSuggestion;
@class SiteSuggestion;
@class PageTemplateCategory;

extern NSString * const BlogEntityName;
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
    /// Can we show activity for the blog?
    BlogFeatureActivity,
    /// Does the blog support mentions?
    BlogFeatureMentions,
    /// Does the blog support push notifications?
    BlogFeaturePushNotifications,
    /// Does the blog support theme browsing?
    BlogFeatureThemeBrowsing,
    /// Does the blog support custom themes?
    BlogFeatureCustomThemes,
    /// Does the blog support premium themes?
    BlogFeaturePremiumThemes,
    /// Does the blog support Menus management?
    BlogFeatureMenus,
    /// Does the blog support private visibility?
    BlogFeaturePrivate,
    /// Does the blog support sharing?
    BlogFeatureSharing,
    /// Does the blog support people management?
    BlogFeaturePeople,
    /// Can the blog's site be changed or deleted?
    BlogFeatureSiteManagement,
    /// Does the blog support different paid plans?
    BlogFeaturePlans,
    /// Does the blog support plugins?
    BlogFeaturePluginManagement,
    /// Does the blog support Jetpack image settings?
    BlogFeatureJetpackImageSettings,
    /// Does the blog support Jetpack settings
    BlogFeatureJetpackSettings,
    /// Does the blog support custom domains?
    BlogFeatureDomains,
    /// Does the blog support frame-nonce to authenticate previews?
    BlogFeatureNoncePreviews,
    /// Does the blog support editing media metadata?
    BlogFeatureMediaMetadataEditing,
    /// Does the blog support deleting media?
    BlogFeatureMediaDeletion,
    /// Does the blog support Stock Photos feature (free photos library)
    BlogFeatureStockPhotos,
    /// Does the blog support setting the homepage type and pages?
    BlogFeatureHomepageSettings,
    /// Does the blog support stories?
    BlogFeatureStories
};

typedef NS_ENUM(NSInteger, SiteVisibility) {
    SiteVisibilityPrivate = -1,
    SiteVisibilityHidden = 0,
    SiteVisibilityPublic = 1,
    SiteVisibilityUnknown = NSIntegerMax
};

@interface Blog : NSManagedObject

@property (nonatomic, strong, readwrite, nullable) NSNumber *blogID __deprecated_msg("Use dotComID instead");
@property (nonatomic, strong, readwrite, nullable) NSNumber *dotComID;
@property (nonatomic, strong, readwrite, nullable) NSString *xmlrpc;
@property (nonatomic, strong, readwrite, nullable) NSString *apiKey;
@property (nonatomic, strong, readwrite, nullable) NSNumber *hasOlderPosts;
@property (nonatomic, strong, readwrite, nullable) NSNumber *hasOlderPages;
@property (nonatomic, strong, readwrite, nullable) NSSet<AbstractPost *> *posts;
@property (nonatomic, strong, readwrite, nullable) NSSet *categories;
@property (nonatomic, strong, readwrite, nullable) NSSet *tags;
@property (nonatomic, strong, readwrite, nullable) NSSet *comments;
@property (nonatomic, strong, readwrite, nullable) NSSet *connections;
@property (nonatomic, strong, readwrite, nullable) NSSet *domains;
@property (nonatomic, strong, readwrite, nullable) NSSet *themes;
@property (nonatomic, strong, readwrite, nullable) NSSet *media;
@property (nonatomic, strong, readwrite, nullable) NSSet<UserSuggestion *> *userSuggestions;
@property (nonatomic, strong, readwrite, nullable) NSSet<SiteSuggestion *> *siteSuggestions;
@property (nonatomic, strong, readwrite, nullable) NSOrderedSet *menus;
@property (nonatomic, strong, readwrite, nullable) NSOrderedSet *menuLocations;
@property (nonatomic, strong, readwrite, nullable) NSSet<Role *> *roles;
@property (nonatomic, strong, readwrite, nullable) NSString *currentThemeId;
@property (nonatomic, assign, readwrite) BOOL isSyncingPosts;
@property (nonatomic, assign, readwrite) BOOL isSyncingPages;
@property (nonatomic, assign, readwrite) BOOL isSyncingMedia;
@property (nonatomic, strong, readwrite, nullable) NSDate *lastPostsSync;
@property (nonatomic, strong, readwrite, nullable) NSDate *lastPagesSync;
@property (nonatomic, strong, readwrite, nullable) NSDate *lastCommentsSync;
@property (nonatomic, strong, readwrite, nullable) NSDate *lastStatsSync;
@property (nonatomic, strong, readwrite, nullable) NSString *lastUpdateWarning;
@property (nonatomic, assign, readwrite) BOOL visible;
@property (nonatomic, weak, readwrite, nullable) NSNumber *isActivated;
@property (nonatomic, strong, readwrite, nullable) NSDictionary *options;
@property (nonatomic, strong, readwrite, nullable) NSSet *postTypes;
@property (nonatomic, strong, readwrite, nullable) NSDictionary *postFormats;
@property (nonatomic, strong, readwrite, nullable) WPAccount *account;
@property (nonatomic, strong, readwrite, nullable) WPAccount *accountForDefaultBlog;
@property (nonatomic, assign, readwrite) BOOL videoPressEnabled;
@property (nonatomic, assign, readwrite) BOOL isMultiAuthor;
@property (nonatomic, assign, readwrite) BOOL isHostedAtWPcom;
@property (nonatomic, assign, readwrite) BOOL hasDomainCredit;
@property (nonatomic, strong, readwrite, nullable) NSString *icon;
@property (nonatomic, assign, readwrite) SiteVisibility siteVisibility;
@property (nonatomic, strong, readwrite, nullable) NSNumber *planID;
@property (nonatomic, strong, readwrite, nullable) NSString *planTitle;
@property (nonatomic, assign, readwrite) BOOL hasPaidPlan;
@property (nonatomic, strong, readwrite, nullable) NSSet *sharingButtons;
@property (nonatomic, strong, readwrite, nullable) NSDictionary *capabilities;
@property (nonatomic, strong, readwrite, nullable) NSSet<QuickStartTourState *> *quickStartTours;
/// The blog's user ID for the current user
@property (nonatomic, strong, readwrite, nullable) NSNumber *userID;
/// Disk quota for site, this is only available for WP.com sites
@property (nonatomic, strong, readwrite, nullable) NSNumber *quotaSpaceAllowed;
@property (nonatomic, strong, readwrite, nullable) NSNumber *quotaSpaceUsed;
@property (nullable, nonatomic, retain) NSSet<PageTemplateCategory *> *pageTemplateCategories;

/**
 *  @details    Maps to a BlogSettings instance, which contains a collection of the available preferences, 
 *              and their values.
 */
@property (nonatomic, strong, readwrite, nullable) BlogSettings *settings;

/**
 *  @details    Flags whether the current user is an admin on the blog.
 */
@property (nonatomic, assign, readwrite) BOOL isAdmin;

/**
 *  @details    Stores the username for self hosted sites
 *
 *  @warn       For WordPress.com or Jetpack Managed sites this will be nil. Use usernameForSite instead
 */
@property (nonatomic, strong, readwrite, nullable) NSString       *username;
@property (nonatomic, strong, readwrite, nullable) NSString       *password;


// Readonly Properties
@property (nonatomic,   weak,  readonly, nullable) NSArray *sortedPostFormatNames;
@property (nonatomic,   weak,  readonly, nullable) NSArray *sortedPostFormats;
@property (nonatomic,   weak,  readonly, nullable) NSArray *sortedConnections;
@property (nonatomic, readonly, nullable) NSArray<Role *> *sortedRoles;
@property (nonatomic, strong,  readonly, nullable) WordPressOrgXMLRPCApi *xmlrpcApi;
@property (nonatomic, strong,  readonly, nullable) WordPressOrgRestApi *wordPressOrgRestApi;
@property (nonatomic,   weak,  readonly, nullable) NSString       *version;
@property (nonatomic, strong,  readonly, nullable) NSString       *authToken;
@property (nonatomic, strong,  readonly, nullable) NSSet *allowedFileTypes;
@property (nonatomic, copy, readonly, nullable) NSString *usernameForSite;

/**
 *  @details    URL properties (example: http://wp.koke.me/sub/xmlrpc.php)
 */

// User to display the blog url to the user (IDN decoded, no http:)
// wp.koke.me/sub
@property (weak, readonly, nullable) NSString *displayURL;
// alias of displayURL
// kept for compatibilty, used as a key to store passwords
@property (weak, readonly, nullable) NSString *hostURL;
@property (weak, readonly, nullable) NSString *homeURL;
// http://wp.koke.me/sub
@property (nonatomic, strong, nullable) NSString *url;
// Used for reachability checks (IDN encoded)
// wp.koke.me
@property (weak, readonly, nullable) NSString *hostname;

@property (weak, readonly, nullable) NSString *defaultPostFormatText;
// Used to check if the blog has an icon set up
@property (readonly) BOOL hasIcon;

#pragma mark - Blog information

- (BOOL)isAtomic;
- (BOOL)isWPForTeams;
- (BOOL)isAutomatedTransfer;
- (BOOL)isPrivate;
- (BOOL)isPrivateAtWPCom;
- (nullable NSArray *)sortedCategories;
- (nullable id)getOptionValue:(NSString *) name;
- (void)setValue:(id)value forOption:(NSString *)name;
- (NSString *)loginUrl;
- (NSString *)urlWithPath:(NSString *)path;
- (NSString *)adminUrlWithPath:(NSString *)path;
- (NSUInteger)numberOfPendingComments;
- (NSDictionary *) getImageResizeDimensions;
- (BOOL)supportsFeaturedImages;
- (BOOL)supports:(BlogFeature)feature;
- (BOOL)supportsPublicize;
- (BOOL)supportsShareButtons;
- (BOOL)hasMappedDomain;

/**
 *  Returnst the text description for a post format code
 *
 *  @param postFormatCode of the post format you want to display
 *
 *  @return a string with the post format description and if no description was found the postFormatCode sent.
 */
- (nullable NSString *)postFormatTextFromSlug:(nullable NSString *)postFormatSlug;
/**
 Returns a human readable description for logging
 
 Instead of inspecting the core data object, this returns select information, more
 useful for support.
 */
- (NSString *)logDescription;

/**
 Returns formatted Blog information to send to Support when user creates a new ticket.
 */
- (NSString *)supportDescription;

/**
 Returns formatted Blog State information to send to Support when user creates a new ticket.
 */
- (NSString *)stateDescription;

/**
 Returns a REST API client if available

 If the blog is a WordPress.com one or it has Jetpack it will return a REST API
 client. Otherwise, the XML-RPC API should be used.

 @warning this method doesn't know if a Jetpack blog has the JSON API disabled

 @return a WordPressComRestApi object if available
 */
- (nullable WordPressComRestApi *)wordPressComRestApi;

/**
 Call this method to know if the blog is hosted at WPcom or accessed through Jetpack.
 
 @return YES if the blog is hosted at WPcom or if it's connected through Jetpack.
    NO otherwise.
 */
- (BOOL)isAccessibleThroughWPCom;

/**
 Check if there is already a basic auth credential stored for this blog/site.

 @return YES if there is a credential
 */
- (BOOL)isBasicAuthCredentialStored;

@end

NS_ASSUME_NONNULL_END
