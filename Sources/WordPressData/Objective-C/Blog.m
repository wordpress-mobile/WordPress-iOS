#import "Blog.h"
@import WordPressShared;
#import "WordPressData-Swift.h"

@import SFHFKeychainUtils;
@import WordPressShared;
@import WordPressKit;

@class Comment;

NSString * const BlogEntityName = @"Blog";
NSString * const PostFormatStandard = @"standard";
NSString * const ActiveModulesKeyStats = @"stats";

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
@dynamic lastCommentsSync;
@dynamic lastUpdateWarning;
@dynamic options;
@dynamic postTypes;
@dynamic postFormats;
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

- (NSNumber *)organizationID {
    NSNumber *organizationID = [self primitiveValueForKey:@"organizationID"];

    if (organizationID == nil) {
        return @0;
    } else {
        return organizationID;
    }
}

- (void)setXmlrpc:(NSString *)xmlrpc
{
    [self willChangeValueForKey:@"xmlrpc"];
    [self setPrimitiveValue:xmlrpc forKey:@"xmlrpc"];
    [self didChangeValueForKey:@"xmlrpc"];

    // Reset the api client so next time we use the new XML-RPC URL
    self.xmlrpcApi = nil;
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

- (BOOL)isStatsActive
{
    return [self jetpackStatsModuleEnabled] || [self isHostedAtWPcom];
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

- (BOOL)jetpackStatsModuleEnabled
{
    NSArray *activeModules = (NSArray *)[self getOptionValue:@"active_modules"];
    return [activeModules containsObject:ActiveModulesKeyStats] ?: NO;
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
