//
//  Blog.m
//  WordPress
//
//  Created by Gareth Townsend on 24/06/09.
//

#import "Blog.h"
#import "Post.h"
#import "Page.h"
#import "Category.h"
#import "Comment.h"
#import "WPAccount.h"
#import "UIImage+Resize.h"
#import "NSURL+IDN.h"
#import "NSString+XMLExtensions.h"
#import "WPError.h"
#import "ContextManager.h"
#import "WordPressComApi.h"

static NSInteger const ImageSizeSmallWidth = 240;
static NSInteger const ImageSizeSmallHeight = 180;
static NSInteger const ImageSizeMediumWidth = 480;
static NSInteger const ImageSizeMediumHeight = 360;
static NSInteger const ImageSizeLargeWidth = 640;
static NSInteger const ImageSizeLargeHeight = 480;

@interface Blog (PrivateMethods)

@property (readwrite, assign) BOOL reachable;

@end


@implementation Blog {
    WPXMLRPCClient *_api;
    NSString *_blavatarUrl;
    Reachability *_reachability;
    BOOL _isReachable;
}

@dynamic blogID, blogName, url, xmlrpc, apiKey;
@dynamic hasOlderPosts, hasOlderPages;
@dynamic posts, categories, comments; 
@dynamic lastPostsSync, lastStatsSync, lastPagesSync, lastCommentsSync, lastUpdateWarning;
@synthesize isSyncingPosts, isSyncingPages, isSyncingComments;
@dynamic geolocationEnabled, options, postFormats, isActivated, visible;
@dynamic account;
@dynamic jetpackAccount;

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
    _blavatarUrl = nil;
    _api = nil;
    [_reachability stopNotifier];
    _reachability = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


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

+ (NSInteger)countVisibleWithContext:(NSManagedObjectContext *)moc {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"Blog" inManagedObjectContext:moc]];
    [request setIncludesSubentities:NO];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"visible = %@" argumentArray:@[@(YES)]];
    [request setPredicate:predicate];
    
    NSError *err;
    NSUInteger count = [moc countForFetchRequest:request error:&err];
    if(count == NSNotFound) {
        count = 0;
    }
    return count;
}

+ (NSInteger)countWithContext:(NSManagedObjectContext *)moc {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"Blog" inManagedObjectContext:moc]];
    [request setIncludesSubentities:NO];
    
    NSError *err;
    NSUInteger count = [moc countForFetchRequest:request error:&err];
    if(count == NSNotFound) {
        count = 0;
    }
    return count;
}

- (NSString *)blavatarUrl {
	if (_blavatarUrl == nil) {
        NSString *hostUrl = [[NSURL URLWithString:self.xmlrpc] host];
        if (hostUrl == nil) {
            hostUrl = self.xmlrpc;
        }
		
        _blavatarUrl = hostUrl;
    }

    return _blavatarUrl;
}

// used as a key to store passwords, if you change the algorithm, logins will break
- (NSString *)displayURL {
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

- (NSString *)hostURL {
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

- (NSString *)hostname {
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
    if([parts count] > 0) {
        hostname = [parts objectAtIndex:0];
    }
    
    return hostname;
}

- (NSString *)loginUrl {
    NSString *loginUrl = [self getOptionValue:@"login_url"];
    if (!loginUrl) {
        loginUrl = [self urlWithPath:@"wp-login.php"];
    }
    return loginUrl;
}

- (NSString *)urlWithPath:(NSString *)path {
    NSError *error = nil;
    NSRegularExpression *xmlrpc = [NSRegularExpression regularExpressionWithPattern:@"xmlrpc.php$" options:NSRegularExpressionCaseInsensitive error:&error];
    return [xmlrpc stringByReplacingMatchesInString:self.xmlrpc options:0 range:NSMakeRange(0, [self.xmlrpc length]) withTemplate:path];
}

- (NSString *)adminUrlWithPath:(NSString *)path {
    NSString *adminBaseUrl = [self getOptionValue:@"admin_url"];
    if (!adminBaseUrl) {
        adminBaseUrl = [self urlWithPath:@"wp-admin/"];
    }
    if (![adminBaseUrl hasSuffix:@"/"]) {
        adminBaseUrl = [adminBaseUrl stringByAppendingString:@"/"];
    }
    return [NSString stringWithFormat:@"%@%@", adminBaseUrl, path];
}

- (int)numberOfPendingComments{
    int pendingComments = 0;
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

-(NSArray *)sortedCategories {
	NSSortDescriptor *sortNameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"categoryName" 
																		ascending:YES 
																		 selector:@selector(caseInsensitiveCompare:)];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortNameDescriptor, nil];
	
	return [[self.categories allObjects] sortedArrayUsingDescriptors:sortDescriptors];
}

- (NSArray *)sortedPostFormatNames {
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

- (BOOL)isWPcom {
    return self.account.isWpcom;
}

//WP.COM private blog. 
- (BOOL)isPrivate {
    if ( [self isWPcom] && [[self getOptionValue:@"blog_public"] isEqual:@"-1"] )
        return YES;
    return NO;
}

- (NSDictionary *)getImageResizeDimensions{
    CGSize smallSize, mediumSize, largeSize;
    NSInteger smallSizeWidth = [[self getOptionValue:@"thumbnail_size_w"] integerValue] > 0 ? [[self getOptionValue:@"thumbnail_size_w"] integerValue] : ImageSizeSmallWidth;
    NSInteger smallSizeHeight = [[self getOptionValue:@"thumbnail_size_h"] integerValue] > 0 ? [[self getOptionValue:@"thumbnail_size_h"] integerValue] : ImageSizeSmallHeight;
    NSInteger mediumSizeWidth = [[self getOptionValue:@"medium_size_w"] integerValue] > 0 ? [[self getOptionValue:@"medium_size_w"] integerValue] : ImageSizeMediumWidth;
    NSInteger mediumSizeHeight = [[self getOptionValue:@"medium_size_h"] integerValue] > 0 ? [[self getOptionValue:@"medium_size_h"] integerValue] : ImageSizeMediumHeight;
    NSInteger largeSizeWidth = [[self getOptionValue:@"large_size_w"] integerValue] > 0 ? [[self getOptionValue:@"large_size_w"] integerValue] : ImageSizeLargeWidth;
    NSInteger largeSizeHeight = [[self getOptionValue:@"large_size_h"] integerValue] > 0 ? [[self getOptionValue:@"large_size_h"] integerValue] : ImageSizeLargeHeight;
    
    smallSize = CGSizeMake(smallSizeWidth, smallSizeHeight);
    mediumSize = CGSizeMake(mediumSizeWidth, mediumSizeHeight);
    largeSize = CGSizeMake(largeSizeWidth, largeSizeHeight);
    
    return [NSDictionary dictionaryWithObjectsAndKeys: [NSValue valueWithCGSize:smallSize], @"smallSize", 
            [NSValue valueWithCGSize:mediumSize], @"mediumSize", 
            [NSValue valueWithCGSize:largeSize], @"largeSize", 
            nil];
}

- (void)awakeFromFetch {
    if (!self.isDeleted) {
        [self reachability];
    }
}

- (void)dataSave {
    [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
}

- (void)remove {
    DDLogInfo(@"<Blog:%@> remove", self.hostURL);
    [self.api cancelAllHTTPOperations];
    _reachability.reachableBlock = nil;
    _reachability.unreachableBlock = nil;
    [_reachability stopNotifier];
    [self.managedObjectContext performBlock:^{
        [[self managedObjectContext] deleteObject:self];
        [self dataSave];
    }];
}

- (void)setXmlrpc:(NSString *)xmlrpc {
    [self willChangeValueForKey:@"xmlrpc"];
    [self setPrimitiveValue:xmlrpc forKey:@"xmlrpc"];
    [self didChangeValueForKey:@"xmlrpc"];
     _blavatarUrl = nil;

    // Reset the api client so next time we use the new XML-RPC URL
     _api = nil;
}

- (NSArray *)getXMLRPCArgsWithExtra:(id)extra {
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

- (NSString *)version {
    return [self getOptionValue:@"software_version"];
}

- (Reachability *)reachability {
    if (_reachability == nil) {
        _reachability = [Reachability reachabilityWithHostname:self.hostname];
        __weak Blog *blog = self;
        blog.reachable = YES;
        _reachability.reachableBlock = ^(Reachability *reach) {
            blog.reachable = YES;
        };
        _reachability.unreachableBlock = ^(Reachability *reach) {
            blog.reachable = NO;
        };
        [_reachability startNotifier];
    }
    
    return _reachability;
}

- (BOOL)reachable {
    // Creates reachability object if it's nil
    [self reachability];
    return _isReachable;
}

- (void)setReachable:(BOOL)reachable {
    _isReachable = reachable;
}

- (NSString *)username {
    return self.account.username ?: @"";
}

- (NSString *)password {
    return self.account.password ?: @"";
}

#pragma mark -
#pragma mark Synchronization

- (NSUInteger)countForSyncedPostsWithEntityName:(NSString *)entityName {
    __block NSUInteger count = 0;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(remoteStatusNumber == %@) AND (postID != NULL) AND (original == NULL) AND (blog == %@)",
                              [NSNumber numberWithInt:AbstractPostRemoteStatusSync], self];
    [request setPredicate:predicate];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date_created_gmt" ascending:YES];
    [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    request.includesSubentities = NO;
    request.resultType = NSCountResultType;
    
    [self.managedObjectContext performBlockAndWait:^{
        NSError *error = nil;
        count = [self.managedObjectContext countForFetchRequest:request error:&error];
    }];
    return count;
}

- (void)syncPostsWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure loadMore:(BOOL)more {
    if (self.isSyncingPosts) {
        DDLogWarn(@"Already syncing posts. Skip");
        return;
    }
    self.isSyncingPosts = YES;

    WPXMLRPCRequestOperation *operation = [self operationForPostsWithSuccess:success failure:failure loadMore:more];
    [self.api enqueueXMLRPCRequestOperation:operation];
}

- (void)syncPagesWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure loadMore:(BOOL)more {
	if (self.isSyncingPages) {
        DDLogWarn(@"Already syncing pages. Skip");
        return;
    }
    self.isSyncingPages = YES;
    WPXMLRPCRequestOperation *operation = [self operationForPagesWithSuccess:success failure:failure loadMore:more];
    [self.api enqueueXMLRPCRequestOperation:operation];
}

- (void)syncCategoriesWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    WPXMLRPCRequestOperation *operation = [self operationForCategoriesWithSuccess:success failure:failure];
    [self.api enqueueXMLRPCRequestOperation:operation];
}

- (void)syncOptionsWithWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    WPXMLRPCRequestOperation *operation = [self operationForOptionsWithSuccess:success failure:failure];
    [self.api enqueueXMLRPCRequestOperation:operation];
}

- (id)getOptionValue:(NSString *) name {
    __block id optionValue;
    [self.managedObjectContext performBlockAndWait:^{
        if ( self.options == nil || (self.options.count == 0) ) {
            optionValue = nil;
        }
        NSDictionary *currentOption = [self.options objectForKey:name];
        optionValue = [currentOption objectForKey:@"value"];
    }];
	return optionValue;
}

- (void)syncCommentsWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
	if (self.isSyncingComments) {
        DDLogWarn(@"Already syncing comments. Skip");
        return;
    }
    self.isSyncingComments = YES;
    WPXMLRPCRequestOperation *operation = [self operationForCommentsWithSuccess:success failure:failure];
    [self.api enqueueXMLRPCRequestOperation:operation];
}

- (void)syncPostFormatsWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    WPXMLRPCRequestOperation *operation = [self operationForPostFormatsWithSuccess:success failure:failure];
    [self.api enqueueXMLRPCRequestOperation:operation];
}

- (void)syncBlogWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    WPXMLRPCRequestOperation *operation;
    NSMutableArray *operations = [NSMutableArray arrayWithCapacity:6];
    operation = [self operationForOptionsWithSuccess:nil failure:nil];
    [operations addObject:operation];
    operation = [self operationForPostFormatsWithSuccess:nil failure:nil];
    [operations addObject:operation];
    operation = [self operationForCategoriesWithSuccess:nil failure:nil];
    [operations addObject:operation];
    
    if (!self.isSyncingComments) {
        operation = [self operationForCommentsWithSuccess:nil failure:nil];
        [operations addObject:operation];
        self.isSyncingComments = YES;
    }
    
    if (!self.isSyncingPosts) {
        operation = [self operationForPostsWithSuccess:nil failure:nil loadMore:NO];
        [operations addObject:operation];
        self.isSyncingPosts = YES;
    }
    
    if (!self.isSyncingPages) {
        operation = [self operationForPagesWithSuccess:nil failure:nil loadMore:NO];
        [operations addObject:operation];
        self.isSyncingPages = YES;
    }

    AFHTTPRequestOperation *combinedOperation = [self.api combinedHTTPRequestOperationWithOperations:operations success:^(AFHTTPRequestOperation *operation, id responseObject) {
        DDLogVerbose(@"syncBlogWithSuccess:failure: completed successfully.");
        if (success) {
            success();
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogError(@"syncBlogWithSuccess:failure: encountered an error: %@", error);
        if (failure) {
            failure(error);
        }
    }];
    
    [self.api enqueueHTTPRequestOperation:combinedOperation];
}

- (void)syncPostsAndMetadataWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    WPXMLRPCRequestOperation *operation;
    NSMutableArray *operations = [NSMutableArray arrayWithCapacity:4];
    operation = [self operationForOptionsWithSuccess:nil failure:nil];
    [operations addObject:operation];
    operation = [self operationForPostFormatsWithSuccess:nil failure:nil];
    [operations addObject:operation];
    operation = [self operationForCategoriesWithSuccess:nil failure:nil];
    [operations addObject:operation];
    if (!self.isSyncingPosts) {
        operation = [self operationForPostsWithSuccess:success failure:failure loadMore:NO];
        [operations addObject:operation];
        self.isSyncingPosts = YES;
    }
    
    AFHTTPRequestOperation *combinedOperation = [self.api combinedHTTPRequestOperationWithOperations:operations success:nil failure:nil];
    [self.api enqueueHTTPRequestOperation:combinedOperation];    
}

- (void)checkVideoPressEnabledWithSuccess:(void (^)(BOOL enabled))success failure:(void (^)(NSError *error))failure {
    if (!self.isWPcom) {
        if (success) success(YES);
        return;
    }
    NSArray *parameters = [self getXMLRPCArgsWithExtra:nil];
    WPXMLRPCRequest *request = [self.api XMLRPCRequestWithMethod:@"wpcom.getFeatures" parameters:parameters];
    WPXMLRPCRequestOperation *operation = [self.api XMLRPCRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        BOOL videoEnabled = YES;
        if(([responseObject isKindOfClass:[NSDictionary class]]) && ([responseObject objectForKey:@"videopress_enabled"] != nil)) {
            videoEnabled = [[responseObject objectForKey:@"videopress_enabled"] boolValue];
        } else {
            videoEnabled = YES;
        }

        if (success) {
            success(videoEnabled);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogError(@"Error while checking if VideoPress is enabled: %@", error);
        
        if (failure) {
            failure(error);
        }
    }];
    [self.api enqueueXMLRPCRequestOperation:operation];
}

#pragma mark - api accessor

- (WPXMLRPCClient *)api {
    if (_api == nil) {
        _api = [[WPXMLRPCClient alloc] initWithXMLRPCEndpoint:[NSURL URLWithString:self.xmlrpc]];
        // Enable compression for wp.com only, as some self hosted have connection issues
        if (self.isWPcom) {
            [_api setDefaultHeader:@"gzip, deflate" value:@"Accept-Encoding"];
            [_api setAuthorizationHeaderWithToken:self.account.authToken];
        }
    }
    return _api;
}

#pragma mark -

- (WPXMLRPCRequestOperation *)operationForOptionsWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    __block WPXMLRPCRequestOperation *operation;
    [self.managedObjectContext performBlockAndWait:^{
        NSArray *parameters = [self getXMLRPCArgsWithExtra:nil];
        WPXMLRPCRequest *request = [self.api XMLRPCRequestWithMethod:@"wp.getOptions" parameters:parameters];
        operation = [self.api XMLRPCRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if ([self isDeleted] || self.managedObjectContext == nil)
                return;
            
            self.options = [NSDictionary dictionaryWithDictionary:(NSDictionary *)responseObject];
            NSString *minimumVersion = @"3.5";
            float version = [[self version] floatValue];
            if (version < [minimumVersion floatValue]) {
                if (self.lastUpdateWarning == nil || [self.lastUpdateWarning floatValue] < [minimumVersion floatValue]) {
                    [WPError showAlertWithTitle:NSLocalizedString(@"WordPress version too old", @"")
                                        message:[NSString stringWithFormat:NSLocalizedString(@"The site at %@ uses WordPress %@. We recommend to update to the latest version, or at least %@", @""), [self hostname], [self version], minimumVersion]];
                    self.lastUpdateWarning = minimumVersion;
                }
            }
            if (success) {
                success();
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            DDLogError(@"Error syncing options: %@", error);
            
            if (failure) {
                failure(error);
            }
        }];
    }];
    return operation;
}

- (WPXMLRPCRequestOperation *)operationForPostFormatsWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    __block WPXMLRPCRequestOperation *operation;
    [self.managedObjectContext performBlockAndWait:^{
        NSDictionary *dict = [NSDictionary dictionaryWithObject:@"1" forKey:@"show-supported"];
        NSArray *parameters = [self getXMLRPCArgsWithExtra:dict];
        
        WPXMLRPCRequest *request = [self.api XMLRPCRequestWithMethod:@"wp.getPostFormats" parameters:parameters];
        operation = [self.api XMLRPCRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if ([self isDeleted] || self.managedObjectContext == nil)
                return;
            
            NSDictionary *respDict = [NSDictionary dictionaryWithDictionary:(NSDictionary *)responseObject];
            if ([respDict objectForKey:@"supported"] && [[respDict objectForKey:@"supported"] isKindOfClass:[NSArray class]]) {
                NSMutableArray *supportedKeys = [NSMutableArray arrayWithArray:[respDict objectForKey:@"supported"]];
                // Standard isn't included in the list of supported formats? Maybe it will be one day?
                if (![supportedKeys containsObject:@"standard"]) {
                    [supportedKeys addObject:@"standard"];
                }
                
                NSDictionary *allFormats = [respDict objectForKey:@"all"];
                NSMutableArray *supportedValues = [NSMutableArray array];
                for (NSString *key in supportedKeys) {
                    [supportedValues addObject:[allFormats objectForKey:key]];
                }
                respDict = [NSDictionary dictionaryWithObjects:supportedValues forKeys:supportedKeys];
            }
            self.postFormats = respDict;
            if (success) {
                success();
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
	        DDLogError(@"Error syncing post formats (%@): %@", operation.request.URL, error);
            
            if (failure) {
                failure(error);
            }
        }];
    }];
    return operation;
}

- (WPXMLRPCRequestOperation *)operationForCommentsWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    __block WPXMLRPCRequestOperation *operation;
    [self.managedObjectContext performBlockAndWait:^{
        NSDictionary *requestOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:100] forKey:@"number"];
        NSArray *parameters = [self getXMLRPCArgsWithExtra:requestOptions];
        WPXMLRPCRequest *request = [self.api XMLRPCRequestWithMethod:@"wp.getComments" parameters:parameters];
        operation = [self.api XMLRPCRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if ([self isDeleted] || self.managedObjectContext == nil)
                return;
            
            [Comment mergeNewComments:responseObject forBlog:self];
            self.isSyncingComments = NO;
            self.lastCommentsSync = [NSDate date];
            
            if (success) {
                success();
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
	        DDLogError(@"Error syncing comments (%@): %@", operation.request.URL, error);
            self.isSyncingComments = NO;
            
            if (failure) {
                failure(error);
            }
        }];
    }];
    return operation;
}

- (WPXMLRPCRequestOperation *)operationForCategoriesWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    __block WPXMLRPCRequestOperation *operation;
    [self.managedObjectContext performBlockAndWait:^{
        NSArray *parameters = [self getXMLRPCArgsWithExtra:nil];
        WPXMLRPCRequest *request = [self.api XMLRPCRequestWithMethod:@"wp.getCategories" parameters:parameters];
        operation = [self.api XMLRPCRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if ([self isDeleted] || self.managedObjectContext == nil)
                return;
            
            [Category mergeNewCategories:responseObject forBlog:self];
            
            if (success) {
                success();
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
	        DDLogError(@"Error syncing categories (%@): %@", operation.request.URL, error);
            
            if (failure) {
                failure(error);
            }
        }];
    }];
    return operation;    
}

- (WPXMLRPCRequestOperation *)operationForPostsWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure loadMore:(BOOL)more {
    // Don't load more than 20 posts if we aren't at the end of the table,
    // even if they were previously donwloaded
    //
    // Blogs with long history can get really slow really fast,
    // with no chance to go back
    
    NSUInteger postBatchSize = 40;
    __block WPXMLRPCRequestOperation *operation;
    [self.managedObjectContext performBlockAndWait:^{
        NSUInteger postsToRequest = postBatchSize;
        if (more) {
            postsToRequest = MAX([self.posts count], postBatchSize);
            if ([self.hasOlderPosts boolValue]) {
                postsToRequest += postBatchSize;
            }
        }
        
        NSArray *parameters = [self getXMLRPCArgsWithExtra:[NSNumber numberWithInt:postsToRequest]];
        WPXMLRPCRequest *request = [self.api XMLRPCRequestWithMethod:@"metaWeblog.getRecentPosts" parameters:parameters];
        operation = [self.api XMLRPCRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if ([self isDeleted] || self.managedObjectContext == nil)
                return;
            
            NSArray *posts = (NSArray *)responseObject;
            
            // If we asked for more and we got what we had, there are no more posts to load
            if (more && ([posts count] <= [self.posts count])) {
                self.hasOlderPosts = [NSNumber numberWithBool:NO];
            } else if (!more) {
                //we should reset the flag otherwise when you refresh this blog you can't get more than 20 posts
                self.hasOlderPosts = [NSNumber numberWithBool:YES];
            }
            
            [Post mergeNewPosts:responseObject forBlog:self];
            
            self.lastPostsSync = [NSDate date];
            self.isSyncingPosts = NO;
            
            if (success) {
                success();
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
	        DDLogError(@"Error syncing posts (%@): %@", operation.request.URL, error);
            self.isSyncingPosts = NO;
            
            if (failure) {
                failure(error);
            }
        }];
    }];
    return operation;        
}

- (WPXMLRPCRequestOperation *)operationForPagesWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure loadMore:(BOOL)more {
    // Don't load more than 20 pages if we aren't at the end of the table,
    // even if they were previously donwloaded
    //
    // Blogs with long history can get really slow really fast,
    // with no chance to go back
    
    NSUInteger pageBatchSize = 40;
    __block WPXMLRPCRequestOperation *operation;
    [self.managedObjectContext performBlockAndWait:^{
        NSUInteger pagesToRequest = pageBatchSize;
        NSUInteger syncCount = [self countForSyncedPostsWithEntityName:@"Page"];
        if (more) {
            pagesToRequest = MAX(syncCount, pageBatchSize);
            if ([self.hasOlderPages boolValue]) {
                pagesToRequest += pageBatchSize;
            }
        }
        
        NSArray *parameters = [self getXMLRPCArgsWithExtra:[NSNumber numberWithInt:pagesToRequest]];
        WPXMLRPCRequest *request = [self.api XMLRPCRequestWithMethod:@"wp.getPages" parameters:parameters];
        operation = [self.api XMLRPCRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if ([self isDeleted] || self.managedObjectContext == nil)
                return;
            
            NSArray *pages = (NSArray *)responseObject;
            
            // If we asked for more and we got what we had, there are no more pages to load
            if (more && ([pages count] <= syncCount)) {
                self.hasOlderPages = [NSNumber numberWithBool:NO];
            } else if (!more) {
                //we should reset the flag otherwise when you refresh this blog you can't get more than 20 pages
                self.hasOlderPages = [NSNumber numberWithBool:YES];
            }
            
            [Page mergeNewPosts:responseObject forBlog:self];
            self.lastPagesSync = [NSDate date];
            self.isSyncingPages = NO;
            if (success) {
                success();
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
	        DDLogError(@"Error syncing pages (%@): %@", operation.request.URL, error);
            self.isSyncingPages = NO;
            
            if (failure) {
                failure(error);
            }
        }];
    }];
    return operation;
}

@end
