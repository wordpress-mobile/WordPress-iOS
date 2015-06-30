#import "Blog.h"
#import "Post.h"
#import "Comment.h"
#import "WPAccount.h"
#import "AccountService.h"
#import "NSURL+IDN.h"
#import "ContextManager.h"
#import "Constants.h"

static NSInteger const ImageSizeSmallWidth = 240;
static NSInteger const ImageSizeSmallHeight = 180;
static NSInteger const ImageSizeMediumWidth = 480;
static NSInteger const ImageSizeMediumHeight = 360;
static NSInteger const ImageSizeLargeWidth = 640;
static NSInteger const ImageSizeLargeHeight = 480;

@interface Blog ()
@property (nonatomic, strong, readwrite) WPXMLRPCClient *api;
@property (nonatomic, weak, readwrite) NSString *blavatarUrl;
@property (nonatomic, strong, readwrite) JetpackState *jetpack;
@end

@implementation Blog

@dynamic blogID;
@dynamic blogName;
@dynamic url;
@dynamic xmlrpc;
@dynamic apiKey;
@dynamic hasOlderPosts;
@dynamic hasOlderPages;
@dynamic posts;
@dynamic categories;
@dynamic comments;
@dynamic themes;
@dynamic media;
@dynamic currentThemeId;
@dynamic lastPostsSync;
@dynamic lastStatsSync;
@dynamic lastPagesSync;
@dynamic lastCommentsSync;
@dynamic lastUpdateWarning;
@dynamic geolocationEnabled;
@dynamic options;
@dynamic postFormats;
@dynamic isActivated;
@dynamic visible;
@dynamic account;
@dynamic jetpackAccount;
@dynamic isMultiAuthor;
@dynamic isJetpack;
@synthesize api = _api;
@synthesize blavatarUrl = _blavatarUrl;
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
    self.blavatarUrl = nil;
    self.api = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -

- (BOOL)geolocationEnabled
{
    BOOL tmpValue;

    [self willAccessValueForKey:@"geolocationEnabled"];
    tmpValue = [[self primitiveValueForKey:@"geolocationEnabled"] boolValue];
    [self didAccessValueForKey:@"geolocationEnabled"];

    return tmpValue;
}

- (void)setGeolocationEnabled:(BOOL)value
{
    [self willChangeValueForKey:@"geolocationEnabled"];
    [self setPrimitiveValue:[NSNumber numberWithBool:value] forKey:@"geolocationEnabled"];
    [self didChangeValueForKey:@"geolocationEnabled"];
}

#pragma mark -
#pragma mark Custom methods

- (NSString *)blavatarUrl
{
    if (_blavatarUrl == nil) {
        NSString *hostUrl = [[NSURL URLWithString:self.xmlrpc] host];
        if (hostUrl == nil) {
            hostUrl = self.xmlrpc;
        }

        _blavatarUrl = hostUrl;
    }

    return _blavatarUrl;
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
            if ( [@"hold" isEqualToString: element.status] ) {
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

- (NSArray *)sortedPostFormatNames
{
    NSMutableArray *sortedNames = [NSMutableArray arrayWithCapacity:[self.postFormats count]];

    if ([self.postFormats count] != 0) {
        id standardPostFormat = [self.postFormats objectForKey:@"standard"];
        if (standardPostFormat) {
            [sortedNames addObject:standardPostFormat];
        }
        [self.postFormats enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if (![key isEqual:@"standard"]) {
                [sortedNames addObject:obj];
            }
        }];
    }

    return [NSArray arrayWithArray:sortedNames];
}

// WP.COM private blog.
- (BOOL)isPrivate
{
    return (self.isHostedAtWPcom && [[self getOptionValue:@"blog_public"] isEqualToString:@"-1"]);
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
    
    self.blavatarUrl = nil;

    // Reset the api client so next time we use the new XML-RPC URL
    self.api = nil;
}

- (NSArray *)getXMLRPCArgsWithExtra:(id)extra
{
    NSMutableArray *result = [NSMutableArray array];
    NSString *password = self.password ?: [NSString string];
    
    [result addObject:self.blogID];
    [result addObject:self.username];
    [result addObject:password];

    if ([extra isKindOfClass:[NSArray class]]) {
        [result addObjectsFromArray:extra];
    } else if (extra != nil) {
        [result addObject:extra];
    }

    return [NSArray arrayWithArray:result];
}

- (NSString *)version
{
    return [self getOptionValue:@"software_version"];
}

- (NSString *)username
{
    [self willAccessValueForKey:@"username"];

    NSString *username = self.account.username ?: @"";

    [self didAccessValueForKey:@"username"];

    return username;
}

- (NSString *)password
{
    return self.account.password ?: @"";
}

- (NSString *)authToken
{
    if (self.jetpackAccount) {
        return self.jetpackAccount.authToken;
    } else {
        return self.account.authToken;
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
        case BlogFeatureWPComRESTAPI:
            return [self restApi] != nil;
        case BlogFeatureStats:
            return [self restApiForStats] != nil;
        case BlogFeatureCommentLikes:
        case BlogFeatureReblog:
        case BlogFeatureMentions:
        case BlogFeatureOAuth2Login:
            return [self isHostedAtWPcom];
        case BlogFeaturePushNotifications:
            return [self supportsPushNotifications];
    }
}

- (BOOL)supportsPushNotifications
{
    if (self.jetpackAccount) {
        return [self jetpackAccountIsDefaultAccount];
    } else {
        return [self accountIsDefaultAccount];
    }
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

- (BOOL)isHostedAtWPcom
{
    return self.account.isWpcom && !self.isJetpack;
}

- (NSNumber *)dotComID
{
    /*
     mergeBlogs isn't atomic so there might be a small window for Jetpack sites
     where self.account is the WordPress.com account, but self.blogID still has
     the self hosted ID.
     
     Even if the blog is using Jetpack REST, self.jetpack.siteID should still
     have the correct wp.com blog ID, so let's try that one first
     */
    if (self.jetpack.siteID) {
        return self.jetpack.siteID;
    } else if (self.account.isWpcom) {
        return self.blogID;
    } else {
        return nil;
    }
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
}

+ (NSSet *)keyPathsForValuesAffectingJetpack
{
    return [NSSet setWithObject:@"options"];
}

- (NSString *)logDescription
{
    NSString *extra = @"";
    if (self.account.isWpcom) {
        extra = [NSString stringWithFormat:@" wp.com account: %@ blogId: %@", self.account.isWpcom ? self.account.username : @"NO", self.blogID];
    } else if (self.jetpackAccount) {
        extra = [NSString stringWithFormat:@" jetpack: 🚀🚀 Jetpack %@ fully connected as %@ with site ID %@", self.jetpack.version, self.jetpackAccount.username, self.jetpack.siteID];
    } else {
        extra = [NSString stringWithFormat:@" jetpack: %@", [self.jetpack description]];
    }
    return [NSString stringWithFormat:@"<Blog Name: %@ URL: %@ XML-RPC: %@%@>", self.blogName, self.url, self.xmlrpc, extra];
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
    if (self.account.isWpcom) {
        return self.account.restApi;
    } else if ([self jetpackRESTSupported]) {
        return self.jetpackAccount.restApi;
    }
    return nil;
}

/*
 2015-05-26 koke: this is a temporary method to check if a blog supports BlogFeatureStats.
 It works like restApi, but bypasses WPJetpackRESTEnabled, since we always want to use rest for Stats.
 */
- (WordPressComApi *)restApiForStats
{
    if (self.account.isWpcom) {
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
    return WPJetpackRESTEnabled && self.jetpackAccount && self.dotComID;
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
