#import "Blog.h"
#import "WPAccount.h"
@import WordPressShared;
#import "WordPressData-Swift.h"

@import SFHFKeychainUtils;
@import WordPressShared;
@import NSObject_SafeExpectations;
@import WordPressKit;

@class Comment;

static NSInteger const JetpackProfessionalYearlyPlanId = 2004;
static NSInteger const JetpackProfessionalMonthlyPlanId = 2001;

NSString * const BlogEntityName = @"Blog";
NSString * const PostFormatStandard = @"standard";
NSString * const ActiveModulesKeyStats = @"stats";
NSString * const ActiveModulesKeyPublicize = @"publicize";
NSString * const ActiveModulesKeySharingButtons = @"sharedaddy";
NSString * const OptionsKeyActiveModules = @"active_modules";
NSString * const OptionsKeyPublicizeDisabled = @"publicize_permanently_disabled";

@interface Blog ()

@property (nonatomic, strong, readwrite) WordPressOrgXMLRPCApi *xmlrpcApi;
@property (nonatomic, strong, readwrite) WordPressOrgRestApi *selfHostedSiteRestApi;

@end

@implementation Blog

@dynamic accountForDefaultBlog;
@dynamic blogID;
@dynamic url;
@dynamic xmlrpc;
@dynamic restApiRootURL;
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
@dynamic lastPagesSync;
@dynamic lastCommentsSync;
@dynamic lastUpdateWarning;
@dynamic options;
@dynamic postTypes;
@dynamic postFormats;
@dynamic isActivated;
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
@dynamic userID;
@dynamic quotaSpaceAllowed;
@dynamic quotaSpaceUsed;
@dynamic pageTemplateCategories;
@dynamic publicizeInfo;
@dynamic rawTaxonomies;

@synthesize videoPressEnabled;
@synthesize xmlrpcApi = _xmlrpcApi;
@synthesize selfHostedSiteRestApi = _selfHostedSiteRestApi;

#pragma mark - NSManagedObject subclass methods

- (void)willSave {
    [super willSave];

    // The `dotComID` getter has a speicial code to _update_ `blogID` value.
    // This is a weird patch to make sure `blogID` is set to a correct value.
    //
    // It's important that calling `[self dotComID]` repeatedly only updates
    // `Blog` instance once, which is the case at the moment.
    [self dotComID];
}

- (void)prepareForDeletion
{
    [super prepareForDeletion];

    // delete stored password in the keychain for self-hosted sites.
    if ([self.username length] > 0 && [self.xmlrpc length] > 0) {
        self.password = nil;
    }

    if (self.account == nil) {
        [self deleteApplicationToken];
    }

    [_xmlrpcApi invalidateAndCancelTasks];
    [_selfHostedSiteRestApi invalidateAndCancelTasks];

    // Remove the self-hosted site cookies from the shared cookie storage.
    if (self.account == nil && self.url != nil) {
        NSURL *siteURL = [NSURL URLWithString:self.url];
        if (siteURL != nil) {
            NSHTTPCookieStorage *cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
            for (NSHTTPCookie *cookie in [cookieJar cookiesForURL:siteURL]) {
                [cookieJar deleteCookie:cookie];
            }
        }
    }
}

- (void)didTurnIntoFault
{
    [super didTurnIntoFault];

    // Clean up instance variables
    self.xmlrpcApi = nil;
    self.selfHostedSiteRestApi = nil;
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

- (NSArray *)sortedCategories
{
    NSSortDescriptor *sortNameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"categoryName"
                                                                        ascending:YES
                                                                         selector:@selector(caseInsensitiveCompare:)];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortNameDescriptor, nil];

    return [[self.categories allObjects] sortedArrayUsingDescriptors:sortDescriptors];
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
    NSString *accountPassword = [SFHFKeychainUtils getPasswordForUsername:self.username andServiceName:self.xmlrpc accessGroup:nil error:nil];
    if (accountPassword != nil) {
        return accountPassword;
    }

    // Application password can also be used to authenticate XML-RPC.
    return [self getApplicationTokenWithError:nil];
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
            return [self supportsRestApi];
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
            return [self supportsPluginManagement] && [self isAdmin];
        case BlogFeatureJetpackImageSettings:
            return [self supportsJetpackImageSettings];
        case BlogFeatureJetpackSettings:
            return [self supportsRestApi] && ![self isHostedAtWPcom] && [self isAdmin];
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
            return [self isAdmin];
        case BlogFeatureMediaAltEditing:
            // alt is not supported via XML-RPC API
            // https://core.trac.wordpress.org/ticket/58582
            // https://github.com/wordpress-mobile/WordPress-Android/issues/18514#issuecomment-1589752274
            return [self supportsRestApi] || [self supportsCoreRestApi];
        case BlogFeatureMediaDeletion:
            return [self isAdmin];
        case BlogFeatureHomepageSettings:
            return [self supportsRestApi] && [self isAdmin];
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
        case BlogFeatureVideoPressV5:
            return [self supportsVideoPressV5];
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
        case BlogFeatureSiteMonitoring:
            return [self isAdmin] && [self isAtomic];
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
    && self.siteVisibility != SiteVisibilityPrivate;

    BOOL supports = isTransferrable || hasRequiredJetpack;

    // If the site is not hosted on WP.com we can still manage plugins directly using the WP.org rest API
    // Reference: https://make.wordpress.org/core/2020/07/16/new-and-modified-rest-api-endpoints-in-wordpress-5-5/
    if(!supports && !self.account){
        supports = !self.isHostedAtWPcom
        && self.selfHostedSiteRestApi
        && [self hasRequiredWordPressVersion:@"5.5"];
    }

    return supports;
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

- (BOOL)supportsVideoPressV5
{
    return self.isHostedAtWPcom || self.isAtomic || [self hasRequiredJetpackVersion:@"8.5"];
}

- (BOOL)supportsEmbedVariation:(NSString *)requiredJetpackVersion
{
    return [self hasRequiredJetpackVersion:requiredJetpackVersion] || self.isHostedAtWPcom;
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

- (WordPressOrgRestApi *)selfHostedSiteRestApi
{
    if (_selfHostedSiteRestApi == nil) {
        _selfHostedSiteRestApi = self.account == nil ? [[WordPressOrgRestApi alloc] initWithBlog:self] : nil;
    }
    return _selfHostedSiteRestApi;
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
        NSDictionary *options = self.options == nil ? [NSDictionary dictionary] : self.options;
        NSMutableDictionary *mutableOptions = [options mutableCopy];

        NSDictionary *valueDict = @{ @"value": value };
        mutableOptions[name] = valueDict;

        self.options = [NSDictionary dictionaryWithDictionary:mutableOptions];
    }];
}

@end
