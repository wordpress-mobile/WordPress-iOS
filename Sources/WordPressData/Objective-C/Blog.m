#import "Blog.h"
@import WordPressShared;
#import "WordPressData-Swift.h"

@import WordPressShared;
@import WordPressKit;

@class Comment;


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

@end
