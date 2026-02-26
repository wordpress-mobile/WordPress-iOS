#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import <CoreData/CoreData.h>

@import WordPressKit;

NS_ASSUME_NONNULL_BEGIN

@class AbstractPost;
@class BlogSettings;
@class WPAccount;
@class WordPressComRestApi;
@class WordPressOrgRestApi;
@class WordPressOrgXMLRPCApi;
@class Role;
@class UserSuggestion;
@class SiteSuggestion;
@class PageTemplateCategory;
@class PublicizeInfo;
@class PostCategory;
@class PostTag;
@class PublicizeConnection;
@class Comment;
@class InviteLinks;
@class ManagedDomain;
@class Theme;
@class Media;
@class Menu;
@class MenuLocation;
@class PostType;

typedef NS_ENUM(NSInteger, SiteVisibility) {
    SiteVisibilityPrivate = -1,
    SiteVisibilityHidden = 0,
    SiteVisibilityPublic = 1,
    SiteVisibilityUnknown = NSIntegerMax
};

@interface Blog : NSManagedObject

@property (nonatomic, strong, readwrite, nullable) NSNumber *blogID __deprecated_msg("Use dotComID instead");
/// WordPress.com site ID stored as signed 32-bit integer.
@property (nonatomic, strong, readwrite, nullable) NSNumber *dotComID;
@property (nonatomic, strong, readwrite, nullable) NSString *xmlrpc;
@property (nonatomic, strong, readwrite, nullable) NSString *restApiRootURL;
@property (nonatomic, strong, readwrite, nullable) NSString *apiKey;
@property (nonatomic, strong, readwrite, nonnull) NSNumber *organizationID;
@property (nonatomic, strong, readwrite, nullable) NSSet<AbstractPost *> *posts;
@property (nonatomic, strong, readwrite, nullable) NSSet<PostCategory *> *categories;
@property (nonatomic, strong, readwrite, nullable) NSSet<PostTag *> *tags;
@property (nonatomic, strong, readwrite, nullable) NSSet<Comment *> *comments;
@property (nonatomic, strong, readwrite, nullable) NSSet<PublicizeConnection *> *connections;
@property (nonatomic, strong, readwrite, nullable) NSSet<InviteLinks *> *inviteLinks;
@property (nonatomic, strong, readwrite, nullable) NSSet<ManagedDomain *> *domains;
@property (nonatomic, strong, readwrite, nullable) NSSet<Theme *> *themes;
@property (nonatomic, strong, readwrite, nullable) NSSet<Media *> *media;
@property (nonatomic, strong, readwrite, nullable) NSSet<UserSuggestion *> *userSuggestions;
@property (nonatomic, strong, readwrite, nullable) NSSet<SiteSuggestion *> *siteSuggestions;
@property (nonatomic, strong, readwrite, nullable) NSOrderedSet<Menu *> *menus;
@property (nonatomic, strong, readwrite, nullable) NSOrderedSet<MenuLocation *> *menuLocations;
@property (nonatomic, strong, readwrite, nullable) NSSet<Role *> *roles;
@property (nonatomic, strong, readwrite, nullable) NSString *currentThemeId;
@property (nonatomic, strong, readwrite, nullable) NSDate *lastCommentsSync;
@property (nonatomic, strong, readwrite, nullable) NSString *lastUpdateWarning;
@property (nonatomic, strong, readwrite, nullable) NSDictionary *options;
@property (nonatomic, strong, readwrite, nullable) NSSet<PostType *> *postTypes;
@property (nonatomic, strong, readwrite, nullable) NSDictionary *postFormats;
@property (nonatomic, strong, readwrite, nullable) WPAccount *account;
@property (nonatomic, strong, readwrite, nullable) WPAccount *accountForDefaultBlog;
@property (nonatomic, assign, readwrite) BOOL videoPressEnabled;
@property (nonatomic, assign, readwrite) BOOL isMultiAuthor;
@property (nonatomic, assign, readwrite) BOOL isHostedAtWPcom;
@property (nonatomic, assign, readwrite) BOOL hasDomainCredit;
@property (nonatomic, strong, readwrite, nullable) NSString *icon;
@property (nonatomic, strong, readwrite, nullable) NSNumber *planID;
@property (nonatomic, strong, readwrite, nullable) NSString *planTitle;
@property (nonatomic, strong, readwrite, nullable) NSArray<NSString *> *planActiveFeatures;
@property (nonatomic, assign, readwrite) BOOL hasPaidPlan;
@property (nonatomic, strong, readwrite, nullable) NSSet *sharingButtons;
@property (nonatomic, strong, readwrite, nullable) NSDictionary *capabilities;
/// The blog's user ID for the current user
@property (nonatomic, strong, readwrite, nullable) NSNumber *userID;
/// Disk quota for site, this is only available for WP.com sites
@property (nonatomic, strong, readwrite, nullable) NSNumber *quotaSpaceAllowed;
@property (nonatomic, strong, readwrite, nullable) NSNumber *quotaSpaceUsed;
@property (nullable, nonatomic, retain) NSSet<PageTemplateCategory *> *pageTemplateCategories;

@property (nullable, nonatomic, retain) NSData *rawTaxonomies;

/**
 *  @details    Maps to a BlogSettings instance, which contains a collection of the available preferences, 
 *              and their values.
 */
@property (nonatomic, strong, readwrite, nullable) BlogSettings *settings;

/**
 *  @details    Maps to a PublicizeInfo instance, which contains Jetpack Social auto-sharing information.
 */
@property (nonatomic, strong, readwrite, nullable) PublicizeInfo *publicizeInfo;

/**
 *  @details    Flags whether the current user is an admin on the blog.
 */
@property (nonatomic, assign, readwrite) BOOL isAdmin;

/**
 *  @details    Stores the username for self hosted sites
 *
 *  @warn       For WordPress.com or Jetpack Managed sites this will be nil. Use effectiveUsername instead
 */
@property (nonatomic, strong, readwrite, nullable) NSString *username;


// Readonly Properties
@property (nonatomic, strong, readonly, nullable) WordPressOrgXMLRPCApi *xmlrpcApi;
@property (nonatomic, strong, readonly, nullable) WordPressOrgRestApi *selfHostedSiteRestApi;

// http://wp.koke.me/sub
@property (nonatomic, strong, nullable) NSString *url;

@end

NS_ASSUME_NONNULL_END
