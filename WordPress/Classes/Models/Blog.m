#import "Blog.h"
#import "Post.h"
#import "Comment.h"
#import "WPAccount.h"
#import "NSURL+IDN.h"
#import "ContextManager.h"

static NSInteger const ImageSizeSmallWidth = 240;
static NSInteger const ImageSizeSmallHeight = 180;
static NSInteger const ImageSizeMediumWidth = 480;
static NSInteger const ImageSizeMediumHeight = 360;
static NSInteger const ImageSizeLargeWidth = 640;
static NSInteger const ImageSizeLargeHeight = 480;

@implementation Blog {
    WPXMLRPCClient *_api;
    NSString *_blavatarUrl;
}

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
@synthesize isSyncingPosts;
@synthesize isSyncingPages;
@synthesize isSyncingComments;
@synthesize videoPressEnabled;
@synthesize isSyncingMedia;

#pragma mark - NSManagedObject subclass methods

- (void)didTurnIntoFault {
    [super didTurnIntoFault];
    
    // Clean up instance variables
    _blavatarUrl = nil;
    _api = nil;
    
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
    
    if([result hasSuffix:@"/"])
        result = [result substringToIndex:[result length] - 1];
    
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
    if(parts.count) {
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
            if ( [@"hold" isEqualToString: element.status] )
                pendingComments++;
        }
    }
    
    return pendingComments;
}

-(NSArray *)sortedCategories
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

- (BOOL)isWPcom
{
    return self.account.isWpcom;
}

// WP.COM private blog.
- (BOOL)isPrivate
{
    return (self.isWPcom && [[self getOptionValue:@"blog_public"] isEqual:@"-1"]);
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


- (void)dataSave
{
    [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
}

- (void)remove
{
    DDLogInfo(@"<Blog:%@> remove", self.hostURL);
    [self.api cancelAllHTTPOperations];
    [self.managedObjectContext performBlock:^{
        WPAccount *account = self.account;

        NSManagedObjectContext *context = [self managedObjectContext];
        [context deleteObject:self];
        // For self hosted blogs, remove account unless there are other associated blogs
        if (account && !account.isWpcom) {
            if ([account.blogs count] == 1 && [[account.blogs anyObject] isEqual:self]) {
                [context deleteObject:account];
            }
        }
        [self dataSave];
        [WPAnalytics refreshMetadata];
    }];
}

- (void)setXmlrpc:(NSString *)xmlrpc
{
    [self willChangeValueForKey:@"xmlrpc"];
    [self setPrimitiveValue:xmlrpc forKey:@"xmlrpc"];
    [self didChangeValueForKey:@"xmlrpc"];
     _blavatarUrl = nil;

    // Reset the api client so next time we use the new XML-RPC URL
     _api = nil;
}

- (NSArray *)getXMLRPCArgsWithExtra:(id)extra
{
    NSMutableArray *result = [NSMutableArray array];
    NSString *password = self.password;
    if (!password) {
        password = @"";
    }
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
    WPAccount *account = self.account;
    NSString *password = account.password ?: @"";
    
    return password;
}

- (BOOL)supportsFeaturedImages
{
    id hasSupport = [self getOptionValue:@"post_thumbnail"];
    if (hasSupport) {
        return [hasSupport boolValue];
    }
    
    return NO;
}

- (NSNumber *)dotComID
{
    return self.blogID;
}

#pragma mark - api accessor

- (WPXMLRPCClient *)api
{
    if (_api == nil) {
        _api = [[WPXMLRPCClient alloc] initWithXMLRPCEndpoint:[NSURL URLWithString:self.xmlrpc]];
        // Enable compression for wp.com only, as some self hosted have connection issues
        if (self.isWPcom) {
            [_api setDefaultHeader:@"Accept-Encoding" value:@"gzip, deflate"];
            [_api setAuthorizationHeaderWithToken:self.account.authToken];
        }
    }
    return _api;
}

- (WordPressComApi *)restApi
{
    if (self.isWPcom) {
        return self.account.restApi;
    } else if (self.jetpackAccount) {
        return self.jetpackAccount.restApi;
    }
    return nil;
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
