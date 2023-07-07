#import "Blog.h"
#import "WPAccount.h"
#import "AccountService.h"
#import "NSURL+IDN.h"
#import "CoreDataStack.h"
#import "Constants.h"
#import "WPUserAgent.h"
#import "WordPress-Swift.h"

@class Comment;

static NSInteger const ImageSizeSmallWidth = 240;
static NSInteger const ImageSizeSmallHeight = 180;
static NSInteger const ImageSizeMediumWidth = 480;
static NSInteger const ImageSizeMediumHeight = 360;
static NSInteger const ImageSizeLargeWidth = 640;
static NSInteger const ImageSizeLargeHeight = 480;
static NSInteger const JetpackProfessionalYearlyPlanId = 2004;
static NSInteger const JetpackProfessionalMonthlyPlanId = 2001;

NSString * const BlogEntityName = @"Blog";
NSString * const PostFormatStandard = @"standard";
NSString * const ActiveModulesKeyStats = @"stats";
NSString * const ActiveModulesKeyPublicize = @"publicize";
NSString * const ActiveModulesKeySharingButtons = @"sharedaddy";
NSString * const OptionsKeyActiveModules = @"active_modules";
NSString * const OptionsKeyPublicizeDisabled = @"publicize_permanently_disabled";
NSString * const OptionsKeyIsAutomatedTransfer = @"is_automated_transfer";
NSString * const OptionsKeyIsAtomic = @"is_wpcom_atomic";
NSString * const OptionsKeyIsWPForTeams = @"is_wpforteams_site";

@interface Blog ()

@property (nonatomic, strong, readwrite) WordPressOrgXMLRPCApi *xmlrpcApi;
@property (nonatomic, strong, readwrite) WordPressOrgRestApi *wordPressOrgRestApi;

@end

@implementation Blog

@dynamic accountForDefaultBlog;
@dynamic blogID;
@dynamic url;
@dynamic xmlrpc;
@dynamic apiKey;
@dynamic organizationID;
@dynamic hasOlderPosts;
@dynamic hasOlderPages;
@dynamic hasDomainCredit;
@dynamic posts;
@dynamic categories;
@dynamic tags;
@dynamic comments;
@dynamic connections;
@dynamic domains;
@dynamic inviteLinks;
@dynamic themes;
@dynamic media;
@dynamic userSuggestions;
@dynamic siteSuggestions;
@dynamic menus;
@dynamic menuLocations;
@dynamic roles;
@dynamic currentThemeId;
@dynamic lastPostsSync;
@dynamic lastStatsSync;
@dynamic lastPagesSync;
@dynamic lastCommentsSync;
@dynamic lastUpdateWarning;
@dynamic options;
@dynamic postTypes;
@dynamic postFormats;
@dynamic isActivated;
@dynamic visible;
@dynamic account;
@dynamic isAdmin;
@dynamic isMultiAuthor;
@dynamic isHostedAtWPcom;
@dynamic icon;
@dynamic username;
@dynamic settings;
@dynamic planID;
@dynamic planTitle;
@dynamic planActiveFeatures;
@dynamic hasPaidPlan;
@dynamic sharingButtons;
@dynamic capabilities;
@dynamic quickStartTours;
@dynamic quickStartTypeValue;
@dynamic userID;
@dynamic quotaSpaceAllowed;
@dynamic quotaSpaceUsed;
@dynamic pageTemplateCategories;
@dynamic publicizeInfo;

@synthesize isSyncingPosts;
@synthesize isSyncingPages;
@synthesize videoPressEnabled;
@synthesize isSyncingMedia;
@synthesize xmlrpcApi = _xmlrpcApi;
@synthesize wordPressOrgRestApi = _wordPressOrgRestApi;

#pragma mark - NSManagedObject subclass methods

- (void)prepareForDeletion
{
    [super prepareForDeletion];

    // delete stored password in the keychain for self-hosted sites.
    if ([self.username length] > 0 && [self.xmlrpc length] > 0) {
        self.password = nil;
    }

    [_xmlrpcApi invalidateAndCancelTasks];
    [_wordPressOrgRestApi invalidateAndCancelTasks];
}

- (void)didTurnIntoFault
{
    [super didTurnIntoFault];

    // Clean up instance variables
    self.xmlrpcApi = nil;
    self.wordPressOrgRestApi = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -
#pragma mark Custom methods

- (NSNumber *)organizationID {
    NSNumber *organizationID = [self primitiveValueForKey:@"organizationID"];
    
    if (organizationID == nil) {
        return @0;
    } else {
        return organizationID;
    }
}

- (BOOL)isAtomic
{
    NSNumber *value = (NSNumber *)[self getOptionValue:OptionsKeyIsAtomic];
    return [value boolValue];
}

- (BOOL)isWPForTeams
{
    NSNumber *value = (NSNumber *)[self getOptionValue:OptionsKeyIsWPForTeams];
    return [value boolValue];
}

- (BOOL)isAutomatedTransfer
{
    NSNumber *value = (NSNumber *)[self getOptionValue:OptionsKeyIsAutomatedTransfer];
    return [value boolValue];
}

// Used as a key to store passwords, if you change the algorithm, logins will break
- (NSString *)displayURL
{
    if (self.url == nil) {
        DDLogInfo(@"Blog display URL is nil");
        return nil;
    }
    
    NSError *error = nil;
    NSRegularExpression *protocol = [NSRegularExpression regularExpressionWithPattern:@"http(s?)://" options:NSRegularExpressionCaseInsensitive error:&error];
    NSString *result = [NSString stringWithFormat:@"%@", [protocol stringByReplacingMatchesInString:self.url options:0 range:NSMakeRange(0, [self.url length]) withTemplate:@""]];

    if ([result hasSuffix:@"/"]) {
        result = [result substringToIndex:[result length] - 1];
    }

    NSString *decodedResult = [NSURL IDNDecodedHostname:result];
    NSAssert(decodedResult != nil, @"Decoded url shouldn't be nil");
    if (decodedResult == nil) {
        DDLogInfo(@"displayURL: decoded url is nil: %@", self.url);
        return result;
    }

    return decodedResult;
}

- (NSString *)hostURL
{
    return [self displayURL];
}

- (NSString *)homeURL
{
    NSString *homeURL = [self getOptionValue:@"home_url"];
    if (!homeURL) {
        homeURL = self.url;
    }
    return homeURL;
}

- (NSString *)hostname
{
    NSString *hostname = [[NSURL URLWithString:self.xmlrpc] host];
    if (hostname == nil) {
        NSError *error = nil;
        NSRegularExpression *protocol = [NSRegularExpression regularExpressionWithPattern:@"^.*://" options:NSRegularExpressionCaseInsensitive error:&error];
        hostname = [protocol stringByReplacingMatchesInString:self.url options:0 range:NSMakeRange(0, [self.url length]) withTemplate:@""];
    }

    // NSURL seems to not recongnize some TLDs like .me and .it, which results in hostname returning a full path.
    // This can break reachibility (among other things) for the blog.
    // As a saftey net, make sure we drop any path component before returning the hostname.
    NSArray *parts = [hostname componentsSeparatedByString:@"/"];
    if (parts.count) {
        hostname = [parts firstObject];
    }

    return hostname;
}

- (NSString *)loginUrl
{
    NSString *loginUrl = [self getOptionValue:@"login_url"];
    if (!loginUrl) {
        loginUrl = [self urlWithPath:@"wp-login.php"];
    }
    return loginUrl;
}

- (NSString *)urlWithPath:(NSString *)path
{
    if (!path || !self.xmlrpc) {
        DDLogError(@"Blog: Error creating urlWithPath.");
        return nil;
    }

    NSError *error = nil;
    NSRegularExpression *xmlrpc = [NSRegularExpression regularExpressionWithPattern:@"xmlrpc.php$" options:NSRegularExpressionCaseInsensitive error:&error];
    return [xmlrpc stringByReplacingMatchesInString:self.xmlrpc options:0 range:NSMakeRange(0, [self.xmlrpc length]) withTemplate:path];
}

- (NSString *)adminUrlWithPath:(NSString *)path
{
    NSString *adminBaseUrl = [self getOptionValue:@"admin_url"];
    if (!adminBaseUrl) {
        adminBaseUrl = [self urlWithPath:@"wp-admin/"];
    }
    if (![adminBaseUrl hasSuffix:@"/"]) {
        adminBaseUrl = [adminBaseUrl stringByAppendingString:@"/"];
    }
    return [NSString stringWithFormat:@"%@%@", adminBaseUrl, path];
}

- (NSArray *)sortedCategories
{
    NSSortDescriptor *sortNameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"categoryName"
                                                                        ascending:YES
                                                                         selector:@selector(caseInsensitiveCompare:)];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortNameDescriptor, nil];

    return [[self.categories allObjects] sortedArrayUsingDescriptors:sortDescriptors];
}

- (NSArray *)sortedPostFormats
{
    if ([self.postFormats count] == 0) {
        return @[];
    }

    NSMutableArray *sortedFormats = [NSMutableArray arrayWithCapacity:[self.postFormats count]];

    if (self.postFormats[PostFormatStandard]) {
        [sortedFormats addObject:PostFormatStandard];
    }

    NSArray *sortedNonStandardFormats = [[self.postFormats keysSortedByValueUsingSelector:@selector(localizedCaseInsensitiveCompare:)] wp_filter:^BOOL(id obj) {
        return ![obj isEqual:PostFormatStandard];
    }];

    [sortedFormats addObjectsFromArray:sortedNonStandardFormats];

    return [NSArray arrayWithArray:sortedFormats];
}

- (NSArray *)sortedPostFormatNames
{    
    return [[self sortedPostFormats] wp_map:^id(NSString *key) {
        return self.postFormats[key];
    }];
}

- (NSArray *)sortedConnections
{
    NSSortDescriptor *sortServiceDescriptor = [[NSSortDescriptor alloc] initWithKey:@"service"
                                                                          ascending:YES
                                                                           selector:@selector(localizedCaseInsensitiveCompare:)];
    NSSortDescriptor *sortExternalNameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"externalName"
                                                                               ascending:YES
                                                                                selector:@selector(caseInsensitiveCompare:)];
    NSArray *sortDescriptors = @[sortServiceDescriptor, sortExternalNameDescriptor];
    return [[self.connections allObjects] sortedArrayUsingDescriptors:sortDescriptors];
}

- (NSArray<Role *> *)sortedRoles
{
    return [self.roles sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]]];
}

- (NSString *)defaultPostFormatText
{
    return [self postFormatTextFromSlug:self.settings.defaultPostFormat];
}

- (BOOL)hasMappedDomain {
    if (![self isHostedAtWPcom]) {
        return NO;
    }

    NSURL *unmappedURL = [NSURL URLWithString:[self getOptionValue:@"unmapped_url"]];
    NSURL *homeURL = [NSURL URLWithString:[self homeURL]];

    return ![[unmappedURL host] isEqualToString:[homeURL host]];
}

- (BOOL)hasIcon
{
    // A blog without an icon has the blog url in icon, so we can't directly check its
    // length to determine if we have an icon or not
    return self.icon.length > 0 ? [NSURL URLWithString:self.icon].pathComponents.count > 1 : NO;
}

- (NSTimeZone *)timeZone
{
    CGFloat const OneHourInSeconds = 60.0 * 60.0;

    NSString *timeZoneName = [self getOptionValue:@"timezone"];
    NSNumber *gmtOffSet = [self getOptionValue:@"gmt_offset"];
    id optionValue = [self getOptionValue:@"time_zone"];

    NSTimeZone *timeZone = nil;
    if (timeZoneName.length > 0) {
        timeZone = [NSTimeZone timeZoneWithName:timeZoneName];
    }

    if (!timeZone && gmtOffSet != nil) {
        timeZone = [NSTimeZone timeZoneForSecondsFromGMT:(gmtOffSet.floatValue * OneHourInSeconds)];
    }

    if (!timeZone && optionValue != nil) {
        NSInteger timeZoneOffsetSeconds = [optionValue floatValue] * OneHourInSeconds;
        timeZone = [NSTimeZone timeZoneForSecondsFromGMT:timeZoneOffsetSeconds];
    }

    if (!timeZone) {
        timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    }

    return timeZone;

}

- (NSString *)postFormatTextFromSlug:(NSString *)postFormatSlug
{
    NSDictionary *allFormats = self.postFormats;
    NSString *formatText = postFormatSlug;
    if (postFormatSlug && allFormats[postFormatSlug]) {
        formatText = allFormats[postFormatSlug];
    }
    // Default to standard if no name is found
    if ((formatText == nil || [formatText isEqualToString:@""]) && allFormats[PostFormatStandard]) {
        formatText = allFormats[PostFormatStandard];
    }
    return formatText;
}

/// Call this method to know whether the blog is private.
///
- (BOOL)isPrivate
{
    return [self.settings.privacy isEqualToNumber:@(SiteVisibilityPrivate)];
}

/// Call this method to know whether the blog is private AND hosted at WP.com.
///
- (BOOL)isPrivateAtWPCom
{
    return (self.isHostedAtWPcom && [self isPrivate]);
}

- (SiteVisibility)siteVisibility
{
    switch ([self.settings.privacy integerValue]) {
        case (SiteVisibilityHidden):
            return SiteVisibilityHidden;
            break;
        case (SiteVisibilityPublic):
            return SiteVisibilityPublic;
            break;
        case (SiteVisibilityPrivate):
            return SiteVisibilityPrivate;
            break;
        default:
            break;
    }
    return SiteVisibilityUnknown;
}

- (void)setSiteVisibility:(SiteVisibility)siteVisibility
{
    switch (siteVisibility) {
        case (SiteVisibilityHidden):
            self.settings.privacy = @(SiteVisibilityHidden);
            break;
        case (SiteVisibilityPublic):
            self.settings.privacy = @(SiteVisibilityPublic);
            break;
        case (SiteVisibilityPrivate):
            self.settings.privacy = @(SiteVisibilityPrivate);
            break;
        default:
            NSParameterAssert(siteVisibility >= SiteVisibilityPrivate && siteVisibility <= SiteVisibilityPublic);
            break;
    }
}

- (NSDictionary *)getImageResizeDimensions
{
    CGSize smallSize, mediumSize, largeSize;
    CGFloat smallSizeWidth = [[self getOptionValue:@"thumbnail_size_w"] floatValue] > 0 ? [[self getOptionValue:@"thumbnail_size_w"] floatValue] : ImageSizeSmallWidth;
    CGFloat smallSizeHeight = [[self getOptionValue:@"thumbnail_size_h"] floatValue] > 0 ? [[self getOptionValue:@"thumbnail_size_h"] floatValue] : ImageSizeSmallHeight;
    CGFloat mediumSizeWidth = [[self getOptionValue:@"medium_size_w"] floatValue] > 0 ? [[self getOptionValue:@"medium_size_w"] floatValue] : ImageSizeMediumWidth;
    CGFloat mediumSizeHeight = [[self getOptionValue:@"medium_size_h"] floatValue] > 0 ? [[self getOptionValue:@"medium_size_h"] floatValue] : ImageSizeMediumHeight;
    CGFloat largeSizeWidth = [[self getOptionValue:@"large_size_w"] floatValue] > 0 ? [[self getOptionValue:@"large_size_w"] floatValue] : ImageSizeLargeWidth;
    CGFloat largeSizeHeight = [[self getOptionValue:@"large_size_h"] floatValue] > 0 ? [[self getOptionValue:@"large_size_h"] floatValue] : ImageSizeLargeHeight;

    smallSize = CGSizeMake(smallSizeWidth, smallSizeHeight);
    mediumSize = CGSizeMake(mediumSizeWidth, mediumSizeHeight);
    largeSize = CGSizeMake(largeSizeWidth, largeSizeHeight);

    return @{@"smallSize": [NSValue valueWithCGSize:smallSize],
             @"mediumSize": [NSValue valueWithCGSize:mediumSize],
             @"largeSize": [NSValue valueWithCGSize:largeSize]};
}

- (void)setXmlrpc:(NSString *)xmlrpc
{
    [self willChangeValueForKey:@"xmlrpc"];
    [self setPrimitiveValue:xmlrpc forKey:@"xmlrpc"];
    [self didChangeValueForKey:@"xmlrpc"];

    // Reset the api client so next time we use the new XML-RPC URL
    self.xmlrpcApi = nil;
}

- (NSString *)version
{
    // Ensure the value being returned is a string to prevent a crash when using this value in Swift
    id value = [self getOptionValue:@"software_version"];

    // If its a string, then return its value 🎉
    if([value isKindOfClass:NSString.class]) {
        return value;
    }

    // If its not a string, but can become a string, then convert it
    if([value respondsToSelector:@selector(stringValue)]) {
        return [value stringValue];
    }

    // If the value is an unknown type, and can not become a string, then default to a blank string.
    return @"";
}

- (NSString *)password
{
    return [SFHFKeychainUtils getPasswordForUsername:self.username andServiceName:self.xmlrpc accessGroup:nil error:nil];
}

- (void)setPassword:(NSString *)password
{
    NSAssert(self.username != nil, @"Can't set password if we don't know the username yet");
    NSAssert(self.xmlrpc != nil, @"Can't set password if we don't know the XML-RPC endpoint yet");
    if (password) {
        [SFHFKeychainUtils storeUsername:self.username
                             andPassword:password
                          forServiceName:self.xmlrpc
                             accessGroup:nil
                          updateExisting:YES
                                   error:nil];
    } else {
        [SFHFKeychainUtils deleteItemForUsername:self.username
                                  andServiceName:self.xmlrpc
                                     accessGroup:nil
                                           error:nil];
    }
}

- (NSString *)authToken
{
    return self.account.authToken;
}

- (NSString *)usernameForSite
{
    if (self.username) {
        return self.username;
    } else if (self.account && self.isAccessibleThroughWPCom) {
        return self.account.username;
    } else {
        // FIXME: Figure out how to get the self hosted username when using Jetpack REST (@koke 2015-06-15)
        return nil;
    }
}

- (BOOL)canBlaze
{
    return [[self getOptionValue:@"can_blaze"] boolValue] && self.isAdmin;
}

- (BOOL)supportsFeaturedImages
{
    id hasSupport = [self getOptionValue:@"post_thumbnail"];
    if (hasSupport) {
        return [hasSupport boolValue];
    }

    return NO;
}

- (BOOL)supports:(BlogFeature)feature
{
    switch (feature) {
        case BlogFeatureRemovable:
            return ![self accountIsDefaultAccount];
        case BlogFeatureVisibility:
            /*
             See -[BlogListViewController fetchRequestPredicateForHideableBlogs]
             If the logic for this changes that needs to be updated as well
             */
            return [self accountIsDefaultAccount];
        case BlogFeaturePeople:
            return [self supportsRestApi] && self.isListingUsersAllowed;
        case BlogFeatureWPComRESTAPI:
        case BlogFeatureCommentLikes:
            return [self supportsRestApi];
        case BlogFeatureStats:
            return [self supportsRestApi] && [self isViewingStatsAllowed];
        case BlogFeatureStockPhotos:
            return [self supportsRestApi] && [JetpackFeaturesRemovalCoordinator jetpackFeaturesEnabled];
        case BlogFeatureTenor:
            return [JetpackFeaturesRemovalCoordinator jetpackFeaturesEnabled];
        case BlogFeatureSharing:
            return [self supportsSharing];
        case BlogFeatureOAuth2Login:
            return [self isHostedAtWPcom];
        case BlogFeatureMentions:
            return [self isAccessibleThroughWPCom];
        case BlogFeatureXposts:
            return [self isAccessibleThroughWPCom];
        case BlogFeatureReblog:
        case BlogFeaturePlans:
            return [self isHostedAtWPcom] && [self isAdmin];
        case BlogFeaturePluginManagement:
            return [self supportsPluginManagement];
        case BlogFeatureJetpackImageSettings:
            return [self supportsJetpackImageSettings];
        case BlogFeatureJetpackSettings:
            return [self supportsJetpackSettings];
        case BlogFeaturePushNotifications:
            return [self supportsPushNotifications];
        case BlogFeatureThemeBrowsing:
            return [self supportsRestApi] && [self isAdmin];
        case BlogFeatureActivity: {
            // For now Activity is suported for admin users
            return [self supportsRestApi] && [self isAdmin];
        }
        case BlogFeatureCustomThemes:
            return [self supportsRestApi] && [self isAdmin] && ![self isHostedAtWPcom];
        case BlogFeaturePremiumThemes:
            return [self supports:BlogFeatureCustomThemes] && (self.planID.integerValue == JetpackProfessionalYearlyPlanId
                                                               || self.planID.integerValue == JetpackProfessionalMonthlyPlanId);
        case BlogFeatureMenus:
            return [self supportsRestApi] && [self isAdmin];
        case BlogFeaturePrivate:
            // Private visibility is only supported by wpcom blogs
            return [self isHostedAtWPcom];
        case BlogFeatureSiteManagement:
            return [self supportsSiteManagementServices];
        case BlogFeatureDomains:
            return ([self isHostedAtWPcom] || [self isAtomic]) && [self isAdmin] && ![self isWPForTeams];
        case BlogFeatureNoncePreviews:
            return [self supportsRestApi] && ![self isHostedAtWPcom];
        case BlogFeatureMediaMetadataEditing:
            return [self supportsRestApi] && [self isAdmin];
        case BlogFeatureMediaDeletion:
            return [self isAdmin];
        case BlogFeatureHomepageSettings:
            return [self supportsRestApi] && [self isAdmin];
        case BlogFeatureStories:
            return [self supportsStories];
        case BlogFeatureContactInfo:
            return [self supportsContactInfo];
        case BlogFeatureBlockEditorSettings:
            return [self supportsBlockEditorSettings];
        case BlogFeatureLayoutGrid:
            return [self supportsLayoutGrid];
        case BlogFeatureTiledGallery:
            return [self supportsTiledGallery];
        case BlogFeatureVideoPress:
            return [self supportsVideoPress];
        case BlogFeatureFacebookEmbed:
            return [self supportsEmbedVariation: @"9.0"];
        case BlogFeatureInstagramEmbed:
            return [self supportsEmbedVariation: @"9.0"];
        case BlogFeatureLoomEmbed:
            return [self supportsEmbedVariation: @"9.0"];
        case BlogFeatureSmartframeEmbed:
            return [self supportsEmbedVariation: @"10.2"];
        case BlogFeatureFileDownloadsStats:
            return [self isHostedAtWPcom];
        case BlogFeatureBlaze:
            return [self canBlaze];
        case BlogFeaturePages:
            return [self isListingPagesAllowed];
    }
}

-(BOOL)supportsSharing
{
    return [self supportsPublicize] || [self supportsShareButtons];
}

- (BOOL)supportsPublicize
{
    // Publicize is only supported via REST
    if (![self supports:BlogFeatureWPComRESTAPI]) {
        return NO;
    }

    if (![self isPublishingPostsAllowed]) {
        return NO;
    }

    if (self.isHostedAtWPcom) {
        // For WordPress.com YES unless it's disabled
        return ![[self getOptionValue:OptionsKeyPublicizeDisabled] boolValue];

    } else {
        // For Jetpack, check if the module is enabled
        return [self jetpackPublicizeModuleEnabled];
    }
}

- (BOOL)supportsShareButtons
{
    // Share Button settings are only supported via REST, and for admins
    if (![self isAdmin] || ![self supports:BlogFeatureWPComRESTAPI]) {
        return NO;
    }

    if (self.isHostedAtWPcom) {
        // For WordPress.com YES
        return YES;

    } else {
        // For Jetpack, check if the module is enabled
        return [self jetpackSharingButtonsModuleEnabled];
    }
}

- (BOOL)isStatsActive
{
    return [self jetpackStatsModuleEnabled] || [self isHostedAtWPcom];
}

- (BOOL)supportsPushNotifications
{
    return [self accountIsDefaultAccount];
}

- (BOOL)supportsJetpackImageSettings
{
    return [self hasRequiredJetpackVersion:@"5.6"];
}

- (BOOL)supportsPluginManagement
{
    BOOL hasRequiredJetpack = [self hasRequiredJetpackVersion:@"5.6"];

    BOOL isTransferrable = self.isHostedAtWPcom
    && self.hasBusinessPlan
    && self.siteVisibility != SiteVisibilityPrivate
    && self.isAdmin;

    BOOL supports = isTransferrable || hasRequiredJetpack;

    // If the site is not hosted on WP.com we can still manage plugins directly using the WP.org rest API
    // Reference: https://make.wordpress.org/core/2020/07/16/new-and-modified-rest-api-endpoints-in-wordpress-5-5/
    if(!supports && !self.account){
        supports = !self.isHostedAtWPcom
        && self.wordPressOrgRestApi
        && [self hasRequiredWordPressVersion:@"5.5"]
        && self.isAdmin;
    }

    return supports;
}

- (BOOL)supportsStories
{
    BOOL hasRequiredJetpack = [self hasRequiredJetpackVersion:@"9.1"];
    // Stories are disabled in iPad until this Kanvas issue is solved: https://github.com/tumblr/kanvas-ios/issues/104
    return (hasRequiredJetpack || self.isHostedAtWPcom) && ![UIDevice isPad] && [JetpackFeaturesRemovalCoordinator jetpackFeaturesEnabled];
}

- (BOOL)supportsContactInfo
{
    return [self hasRequiredJetpackVersion:@"8.5"] || self.isHostedAtWPcom;
}

- (BOOL)supportsLayoutGrid
{
    return self.isHostedAtWPcom || self.isAtomic;
}

- (BOOL)supportsTiledGallery
{
    return self.isHostedAtWPcom;
}

- (BOOL)supportsVideoPress
{
    return self.isHostedAtWPcom;
}

- (BOOL)supportsEmbedVariation:(NSString *)requiredJetpackVersion
{
    return [self hasRequiredJetpackVersion:requiredJetpackVersion] || self.isHostedAtWPcom;
}

- (BOOL)supportsJetpackSettings
{
    return [JetpackFeaturesRemovalCoordinator jetpackFeaturesEnabled]
    && [self supportsRestApi]
    && ![self isHostedAtWPcom]
    && [self isAdmin];
}

- (BOOL)accountIsDefaultAccount
{
    return [[self account] isDefaultWordPressComAccount];
}

- (NSNumber *)dotComID
{
    [self willAccessValueForKey:@"blogID"];
    NSNumber *dotComID = [self primitiveValueForKey:@"blogID"];
    if (dotComID.integerValue == 0) {
        dotComID = self.jetpack.siteID;
        if (dotComID.integerValue > 0) {
            self.dotComID = dotComID;
        }
    }
    [self didAccessValueForKey:@"blogID"];
    return dotComID;
}

- (void)setDotComID:(NSNumber *)dotComID
{
    [self willChangeValueForKey:@"blogID"];
    [self setPrimitiveValue:dotComID forKey:@"blogID"];
    [self didChangeValueForKey:@"blogID"];
}

- (NSSet *)allowedFileTypes
{
    NSArray *allowedFileTypes = [self.options arrayForKeyPath:@"allowed_file_types.value"];
    if (!allowedFileTypes || allowedFileTypes.count == 0) {
        return nil;
    }
    
    return [NSSet setWithArray:allowedFileTypes];
}

- (void)setOptions:(NSDictionary *)options
{
    [self willChangeValueForKey:@"options"];
    [self setPrimitiveValue:options forKey:@"options"];
    [self didChangeValueForKey:@"options"];

    self.siteVisibility = (SiteVisibility)([[self getOptionValue:@"blog_public"] integerValue]);
    // HACK:Sergio Estevao (2015-08-31): Because there is no direct way to
    // know if a user has permissions to change the options we check if the blog title property is read only or not.
    // (Moved from BlogService, 2016-01-28 by aerych)
    if ([self.options numberForKeyPath:@"blog_title.readonly"]) {
        self.isAdmin = ![[self.options numberForKeyPath:@"blog_title.readonly"] boolValue];
    }
}

+ (NSSet *)keyPathsForValuesAffectingJetpack
{
    return [NSSet setWithObject:@"options"];
}

- (NSString *)logDescription
{
    NSString *extra = @"";
    if (self.account) {
        extra = [NSString stringWithFormat:@" wp.com account: %@ blogId: %@ plan: %@ (%@)", self.account ? self.account.username : @"NO", self.dotComID, self.planTitle, self.planID];
    } else {
        extra = [NSString stringWithFormat:@" jetpack: %@", [self.jetpack description]];
    }
    return [NSString stringWithFormat:@"<Blog Name: %@ URL: %@ XML-RPC: %@%@ ObjectID: %@>", self.settings.name, self.url, self.xmlrpc, extra, self.objectID.URIRepresentation];
}

- (NSString *)supportDescription
{
    // Gather information
    
    NSString *blogType = [NSString stringWithFormat:@"Type: (%@)", [self stateDescription]];
    NSString *urlType = [self wordPressComRestApi] ? @"REST" : @"Self-hosted";
    NSString *url = [NSString stringWithFormat:@"URL: %@", self.url];

    NSString *username;
    NSString *planDescription;
    if (self.account) {
        planDescription = [NSString stringWithFormat:@"Plan: %@ (%@)", self.planTitle, self.planID];
    } else {
        username = [self.jetpack connectedUsername];
    }
    
    NSString *jetpackVersion;
    if ([self.jetpack isInstalled]) {
        jetpackVersion = [NSString stringWithFormat:@"Jetpack-version: %@", [self.jetpack version]];
    }
    
    // Add information to array in the order we want to display it.
    
    NSMutableArray *blogInformation = [[NSMutableArray alloc] init];
    [blogInformation addObject:blogType];
    if (username) {
        [blogInformation addObject:username];
    }
    [blogInformation addObject:urlType];
    [blogInformation addObject:url];
    if (planDescription) {
        [blogInformation addObject:planDescription];
    }
    if (jetpackVersion) {
        [blogInformation addObject:jetpackVersion];
    }
    
    // Combine and return.
    return [NSString stringWithFormat:@"<%@>", [blogInformation componentsJoinedByString:@" "]];
}

- (NSString *)stateDescription
{
    if (self.account) {
        return @"wpcom";
    }
    
    if ([self.jetpack isConnected]) {
        NSString *apiType = [self wordPressComRestApi] ? @"REST" : @"XML-RPC";
        return [NSString stringWithFormat:@"jetpack_connected - %@", apiType];
    }
    
    if ([self.jetpack isInstalled]) {
        return @"self-hosted - jetpack_installed";
    }
    
    return @"self_hosted";
}

#pragma mark - api accessor

- (WordPressOrgXMLRPCApi *)xmlrpcApi
{
    NSURL *xmlRPCEndpoint = [NSURL URLWithString:self.xmlrpc];
    if (_xmlrpcApi == nil) {
        if (xmlRPCEndpoint != nil) {
        _xmlrpcApi = [[WordPressOrgXMLRPCApi alloc] initWithEndpoint:xmlRPCEndpoint
                                                                   userAgent:[WPUserAgent wordPressUserAgent]];
        }
    }
    return _xmlrpcApi;
}

- (WordPressOrgRestApi *)wordPressOrgRestApi
{
    if (_wordPressOrgRestApi == nil) {
        _wordPressOrgRestApi = [[WordPressOrgRestApi alloc] initWithBlog:self];
    }
    return _wordPressOrgRestApi;
}

- (WordPressComRestApi *)wordPressComRestApi
{
    if (self.account) {
        return self.account.wordPressComRestApi;
    }
    return nil;
}

- (BOOL)isAccessibleThroughWPCom {
    return self.wordPressComRestApi != nil;
}

- (BOOL)supportsRestApi {
    // We don't want to check for `restApi` as it can be `nil` when the token
    // is missing from the keychain.
    return self.account != nil;
}

#pragma mark - Jetpack

- (BOOL)jetpackActiveModule:(NSString *)moduleName
{
    NSArray *activeModules = (NSArray *)[self getOptionValue:OptionsKeyActiveModules];
    return [activeModules containsObject:moduleName] ?: NO;
}

- (BOOL)jetpackStatsModuleEnabled
{
    return [self jetpackActiveModule:ActiveModulesKeyStats];
}

- (BOOL)jetpackPublicizeModuleEnabled
{
    return [self jetpackActiveModule:ActiveModulesKeyPublicize];
}

- (BOOL)jetpackSharingButtonsModuleEnabled
{
    return [self jetpackActiveModule:ActiveModulesKeySharingButtons];
}

- (BOOL)isBasicAuthCredentialStored
{
    NSURLCredentialStorage *storage = [NSURLCredentialStorage sharedCredentialStorage];
    NSURL *url = [NSURL URLWithString:self.url];
    NSDictionary * credentials = storage.allCredentials;
    for (NSURLProtectionSpace *protectionSpace in credentials.allKeys) {
        if ( [protectionSpace.host isEqual:url.host]
           && (protectionSpace.port == ([url.port integerValue] ? : 80))
           && (protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPBasic)) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)hasRequiredJetpackVersion:(NSString *)requiredJetpackVersion
{
    return [self supportsRestApi]
    && ![self isHostedAtWPcom]
    && [self.jetpack.version compare:requiredJetpackVersion options:NSNumericSearch] != NSOrderedAscending;
}

/// Checks the blogs installed WordPress version is more than or equal to the requiredVersion
/// @param requiredVersion The minimum version to check for
- (BOOL)hasRequiredWordPressVersion:(NSString *)requiredVersion
{
    return [self.version compare:requiredVersion options:NSNumericSearch] != NSOrderedAscending;
}

#pragma mark - Private Methods

- (id)getOptionValue:(NSString *)name
{
    __block id optionValue;
    [self.managedObjectContext performBlockAndWait:^{
        if ( self.options == nil || (self.options.count == 0) ) {
            optionValue = nil;
        }
        NSDictionary *currentOption = [self.options objectForKey:name];
        optionValue = currentOption[@"value"];
    }];
    return optionValue;
}

- (void)setValue:(id)value forOption:(NSString *)name
{
    [self.managedObjectContext performBlockAndWait:^{
        if ( self.options == nil || (self.options.count == 0) ) {
            return;
        }

        NSMutableDictionary *mutableOptions = [self.options mutableCopy];

        NSDictionary *valueDict = @{ @"value": value };
        mutableOptions[name] = valueDict;

        self.options = [NSDictionary dictionaryWithDictionary:mutableOptions];
    }];
}

@end
