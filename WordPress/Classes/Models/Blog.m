#import "Blog.h"
#import "Post.h"
#import "Comment.h"
#import "WPAccount.h"
#import "AccountService.h"
#import "NSURL+IDN.h"
#import "ContextManager.h"
#import "Constants.h"
#import "WordPress-Swift.h"
#import "SFHFKeychainUtils.h"
#import <WordPressApi/WordPressApi.h>

static NSInteger const ImageSizeSmallWidth = 240;
static NSInteger const ImageSizeSmallHeight = 180;
static NSInteger const ImageSizeMediumWidth = 480;
static NSInteger const ImageSizeMediumHeight = 360;
static NSInteger const ImageSizeLargeWidth = 640;
static NSInteger const ImageSizeLargeHeight = 480;

NSString * const PostFormatStandard = @"standard";
NSString * const ActiveModulesKeyPublicize = @"publicize";
NSString * const ActiveModulesKeySharingButtons = @"sharedaddy";
NSString * const OptionsKeyActiveModules = @"active_modules";
NSString * const OptionsKeyPublicizeDisabled = @"publicize_permanently_disabled";


@interface Blog ()

@property (nonatomic, strong, readwrite) WPXMLRPCClient *api;
@property (nonatomic, strong, readwrite) JetpackState *jetpack;

@end

@implementation Blog

@dynamic accountForDefaultBlog;
@dynamic blogID;
@dynamic url;
@dynamic xmlrpc;
@dynamic apiKey;
@dynamic hasOlderPosts;
@dynamic hasOlderPages;
@dynamic posts;
@dynamic categories;
@dynamic tags;
@dynamic comments;
@dynamic connections;
@dynamic themes;
@dynamic media;
@dynamic menus;
@dynamic menuLocations;
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
@dynamic jetpackAccount;
@dynamic isAdmin;
@dynamic isMultiAuthor;
@dynamic isHostedAtWPcom;
@dynamic icon;
@dynamic username;
@dynamic settings;
@dynamic planID;
@dynamic sharingButtons;

@synthesize api = _api;
@synthesize isSyncingPosts;
@synthesize isSyncingPages;
@synthesize videoPressEnabled;
@synthesize isSyncingMedia;
@synthesize jetpack = _jetpack;

#pragma mark - NSManagedObject subclass methods

- (void)prepareForDeletion
{
    [super prepareForDeletion];
    
    // Beware: Lazy getters below. Let's hit directly the ivar
    [_api.operationQueue cancelAllOperations];
}

- (void)didTurnIntoFault
{
    [super didTurnIntoFault];

    // Clean up instance variables
    self.api = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark -
#pragma mark Custom methods

- (NSString *)icon
{
    [self willAccessValueForKey:@"icon"];
    NSString *icon = [self primitiveValueForKey:@"icon"];
    [self didAccessValueForKey:@"icon"];

    if (icon) {
        return icon;
    }

    // if the icon is not set we can use the host url to construct it
    NSString *hostUrl = [[NSURL URLWithString:self.xmlrpc] host];
    if (hostUrl == nil) {
        hostUrl = self.xmlrpc;
    }
    return hostUrl;
}

// Used as a key to store passwords, if you change the algorithm, logins will break
- (NSString *)displayURL
{
    NSString *url = [NSURL IDNDecodedHostname:self.url];
    NSAssert(url != nil, @"Decoded url shouldn't be nil");
    if (url == nil) {
        DDLogInfo(@"displayURL: decoded url is nil: %@", self.url);
        return self.url;
    }
    NSError *error = nil;
    NSRegularExpression *protocol = [NSRegularExpression regularExpressionWithPattern:@"http(s?)://" options:NSRegularExpressionCaseInsensitive error:&error];
    NSString *result = [NSString stringWithFormat:@"%@", [protocol stringByReplacingMatchesInString:url options:0 range:NSMakeRange(0, [url length]) withTemplate:@""]];

    if ([result hasSuffix:@"/"]) {
        result = [result substringToIndex:[result length] - 1];
    }

    return result;
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

- (NSUInteger)numberOfPendingComments
{
    NSUInteger pendingComments = 0;
    if ([self hasFaultForRelationshipNamed:@"comments"]) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Comment"];
        [request setPredicate:[NSPredicate predicateWithFormat:@"blog = %@ AND status like 'hold'", self]];
        [request setIncludesSubentities:NO];
        NSError *error;
        pendingComments = [self.managedObjectContext countForFetchRequest:request error:&error];
    } else {
        for (Comment *element in self.comments) {
            if ( [CommentStatusPending isEqualToString:element.status] ) {
                pendingComments++;
            }
        }
    }

    return pendingComments;
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
    [self.postFormats enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (![key isEqual:PostFormatStandard]) {
            [sortedFormats addObject:key];
        }
    }];

    return [NSArray arrayWithArray:sortedFormats];
}

- (NSArray *)sortedPostFormatNames
{    
    return [[self sortedPostFormats] wp_map:^id(NSString *key) {
        return self.postFormats[key];
    }];
}

- (NSString *)defaultPostFormatText
{
    return [self postFormatTextFromSlug:self.settings.defaultPostFormat];
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

// WP.COM private blog.
- (BOOL)isPrivate
{
    return (self.isHostedAtWPcom && [self.settings.privacy isEqualToNumber:@(SiteVisibilityPrivate)]);
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
    self.api = nil;
}

- (NSString *)version
{
    return [self getOptionValue:@"software_version"];
}

- (NSString *)password
{
    return [SFHFKeychainUtils getPasswordForUsername:self.username andServiceName:self.xmlrpc error:nil];
}

- (void)setPassword:(NSString *)password
{
    NSAssert(self.username != nil, @"Can't set password if we don't know the username yet");
    NSAssert(self.xmlrpc != nil, @"Can't set password if we don't know the XML-RPC endpoint yet");
    if (password) {
        [SFHFKeychainUtils storeUsername:self.username
                             andPassword:password
                          forServiceName:self.xmlrpc
                          updateExisting:YES
                                   error:nil];
    } else {
        [SFHFKeychainUtils deleteItemForUsername:self.username
                                  andServiceName:self.xmlrpc
                                           error:nil];
    }
}

- (NSString *)authToken
{
    if (self.jetpackAccount) {
        return self.jetpackAccount.authToken;
    } else {
        return self.account.authToken;
    }
}

- (NSString *)usernameForSite
{
    if (self.username) {
        return self.username;
    } else if (self.account && self.isHostedAtWPcom) {
        return self.account.username;
    } else {
        // FIXME: Figure out how to get the self hosted username when using Jetpack REST (@koke 2015-06-15)
        return nil;
    }
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
        case BlogFeatureWPComRESTAPI:
            return [self restApi] != nil;
        case BlogFeatureSharing:
            return [self supportsSharing];
        case BlogFeatureStats:
            return [self restApiForStats] != nil;
        case BlogFeatureCommentLikes:
        case BlogFeatureReblog:
        case BlogFeatureMentions:
        case BlogFeatureOAuth2Login:
        case BlogFeaturePlans:
            return [self isHostedAtWPcom];
        case BlogFeaturePushNotifications:
            return [self supportsPushNotifications];
        case BlogFeatureThemeBrowsing:
            return [self isHostedAtWPcom] && [self isAdmin];
        case BlogFeaturePrivate:
            // Private visibility is only supported by wpcom blogs
            return [self isHostedAtWPcom];
        case BlogFeatureSiteManagement:
            return [self supportsSiteManagementServices];
    }
}

-(BOOL)supportsSharing
{
    return ([self supportsPublicize] || [self supportsShareButtons]) && [self isAdmin];
}

- (BOOL)supportsPublicize
{
    // Publicize is only supported via REST, and for admins
    if (![self supports:BlogFeatureWPComRESTAPI]) {
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
    if (![self supports:BlogFeatureWPComRESTAPI]) {
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

- (BOOL)supportsPushNotifications
{
    return [self accountIsDefaultAccount];
}

- (BOOL)accountIsDefaultAccount
{
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:self.managedObjectContext];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
    return [defaultAccount isEqual:self.account];
}

- (BOOL)jetpackAccountIsDefaultAccount
{
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:self.managedObjectContext];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
    return [defaultAccount isEqual:self.jetpackAccount];
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
    NSArray * allowedFileTypes = self.options[@"allowed_file_types"][@"value"];
    if (!allowedFileTypes || allowedFileTypes.count == 0) {
        return nil;
    }
    
    return [NSSet setWithArray:allowedFileTypes];
}

- (void)setOptions:(NSDictionary *)options
{
    [self willChangeValueForKey:@"options"];
    [self setPrimitiveValue:options forKey:@"options"];
    // Invalidate the Jetpack state since it's constructed from options
    self.jetpack = nil;
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
        extra = [NSString stringWithFormat:@" wp.com account: %@ blogId: %@", self.account ? self.account.username : @"NO", self.dotComID];
    } else if (self.jetpackAccount) {
        extra = [NSString stringWithFormat:@" jetpack: 🚀🚀 Jetpack %@ fully connected as %@ with site ID %@", self.jetpack.version, self.jetpackAccount.username, self.jetpack.siteID];
    } else {
        extra = [NSString stringWithFormat:@" jetpack: %@", [self.jetpack description]];
    }
    return [NSString stringWithFormat:@"<Blog Name: %@ URL: %@ XML-RPC: %@%@>", self.settings.name, self.url, self.xmlrpc, extra];
}

#pragma mark - api accessor

- (WPXMLRPCClient *)api
{
    if (_api == nil) {
        _api = [[WPXMLRPCClient alloc] initWithXMLRPCEndpoint:[NSURL URLWithString:self.xmlrpc]];
        // Enable compression for wp.com only, as some self hosted have connection issues
        if ([self isHostedAtWPcom]) {
            [_api setDefaultHeader:@"Accept-Encoding" value:@"gzip, deflate"];
            [_api setAuthorizationHeaderWithToken:self.account.authToken];
        }
    }
    return _api;
}

- (WordPressComApi *)restApi
{
    if (self.account) {
        return self.account.restApi;
    } else if ([self jetpackRESTSupported]) {
        return self.jetpackAccount.restApi;
    }
    return nil;
}

/*
 2015-05-26 koke: this is a temporary method to check if a blog supports BlogFeatureStats.
 It works like restApi, but bypasses Jetpack REST checks, since we always want to use rest for Stats.
 */
- (WordPressComApi *)restApiForStats
{
    if (self.account) {
        return self.account.restApi;
    } else if (self.jetpackAccount && self.dotComID) {
        return self.jetpackAccount.restApi;
    }
    return nil;
}

#pragma mark - Jetpack

- (JetpackState *)jetpack
{
    if (_jetpack) {
        return _jetpack;
    }
    if ([self.options count] == 0) {
        return nil;
    }
    _jetpack = [JetpackState new];
    _jetpack.siteID = [[self getOptionValue:@"jetpack_client_id"] numericValue];
    _jetpack.version = [self getOptionValue:@"jetpack_version"];
    if (self.jetpackAccount.username) {
        _jetpack.connectedUsername = self.jetpackAccount.username;
    } else {
        _jetpack.connectedUsername = [self getOptionValue:@"jetpack_user_login"];
    }
    _jetpack.connectedEmail = [self getOptionValue:@"jetpack_user_email"];
    return _jetpack;
}

- (BOOL)jetpackRESTSupported
{
    return self.jetpackAccount && self.dotComID;
}

- (BOOL)jetpackActiveModule:(NSString *)moduleName
{
    NSArray *activeModules = (NSArray *)[self getOptionValue:OptionsKeyActiveModules];
    return [activeModules containsObject:moduleName] ?: NO;
}

- (BOOL)jetpackPublicizeModuleEnabled
{
    return [self jetpackActiveModule:ActiveModulesKeyPublicize];
}

- (BOOL)jetpackSharingButtonsModuleEnabled
{
    return [self jetpackActiveModule:ActiveModulesKeySharingButtons];
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

@end
