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
@dynamic isAdmin, hasOlderPosts, hasOlderPages;
@dynamic posts, categories, comments; 
@dynamic lastPostsSync, lastStatsSync, lastPagesSync, lastCommentsSync, lastUpdateWarning;
@synthesize isSyncingPosts, isSyncingPages, isSyncingComments;
@dynamic geolocationEnabled, options, postFormats, isActivated;
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

+ (NSMutableURLRequest *)requestForFetchRequest:(NSFetchRequest *)fetchRequest withContext:(NSManagedObjectContext *)context {
    return nil;
}

+ (NSString *)methodNameForCRUDOperation:(XMLRPCCRUDOperation)op {
    return nil;
}

+ (BOOL)shouldFetchRemoteValuesForRelationship:(NSRelationshipDescription *)relationship forObjectWithID:(NSManagedObjectID *)objectID inManagedObjectContext:(NSManagedObjectContext *)context {
    if ([relationship.name isEqualToString:@"posts"]) {
        return YES;
    }
    return NO;
}

+ (NSMutableURLRequest *)requestWithMethod:(NSString *)method pathForRelationship:(NSRelationshipDescription *)relationship forObjectWithID:(NSManagedObjectID *)objectID withContext:(NSManagedObjectContext *)context {
    NSLog(@"Relationship %@ on Blog queried", relationship.name);
    if ([relationship.name isEqualToString:@"posts"]) {
        Blog *theBlog = (Blog *)[context objectWithID:objectID];
        NSFetchRequest *r = [NSFetchRequest fetchRequestWithEntityName:@"Post"];
        r.predicate = [NSPredicate predicateWithFormat:@"blog == %@ AND 1 == 1", theBlog.objectID];
        return [Post requestForFetchRequest:r withContext:context];
    }
    return nil;
}

+ (NSDictionary *)representationsForRelationshipsFromRepresentation:(NSDictionary *)representation ofEntity:(NSEntityDescription *)entity fromResponse:(NSHTTPURLResponse *)response {
    return @{};
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
    if ([[self getOptionValue:@"wordpress.com"] boolValue]) {
        return YES;
    }
    NSRange range = [self.xmlrpc rangeOfString:@"wordpress.com"];
	return (range.location != NSNotFound);
}

//WP.COM private blog. 
- (BOOL)isPrivate {
    if ( [self isWPcom] && [[self getOptionValue:@"blog_public"] isEqual:@"-1"] )
        return YES;
    return NO;
}

- (NSDictionary *) getImageResizeDimensions{
    CGSize smallSize, mediumSize, largeSize;
    int small_size_w =      [[self getOptionValue:@"thumbnail_size_w"] intValue]    > 0 ? [[self getOptionValue:@"thumbnail_size_w"] intValue] : image_small_size_w;
    int small_size_h =      [[self getOptionValue:@"thumbnail_size_h"] intValue]    > 0 ? [[self getOptionValue:@"thumbnail_size_h"] intValue] : image_small_size_h;
    int medium_size_w =     [[self getOptionValue:@"medium_size_w"] intValue]       > 0 ? [[self getOptionValue:@"medium_size_w"] intValue] : image_medium_size_w;
    int medium_size_h =     [[self getOptionValue:@"medium_size_h"] intValue]       > 0 ? [[self getOptionValue:@"medium_size_h"] intValue] : image_medium_size_h;
    int large_size_w =      [[self getOptionValue:@"large_size_w"] intValue]        > 0 ? [[self getOptionValue:@"large_size_w"] intValue] : image_large_size_w;
    int large_size_h =      [[self getOptionValue:@"large_size_h"] intValue]        > 0 ? [[self getOptionValue:@"large_size_h"] intValue] : image_large_size_h;
    
    smallSize = CGSizeMake(small_size_w, small_size_h);
    mediumSize = CGSizeMake(medium_size_w, medium_size_h);
    largeSize = CGSizeMake(large_size_w, large_size_h);
    
    return [NSDictionary dictionaryWithObjectsAndKeys: [NSValue valueWithCGSize:smallSize], @"smallSize", 
            [NSValue valueWithCGSize:mediumSize], @"mediumSize", 
            [NSValue valueWithCGSize:largeSize], @"largeSize", 
            nil];
}

- (void)awakeFromFetch {
    [self reachability];
}

- (void)dataSave {
    return;
    [self.managedObjectContext performBlock:^{
        [self.managedObjectContext save:nil];
    }];
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

- (NSArray *)syncedPostsWithEntityName:(NSString *)entityName withContext:(NSManagedObjectContext*)context {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:context]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(remoteStatusNumber = %@) AND (postID != NULL) AND (original == NULL) AND (blog = %@)",
							  [NSNumber numberWithInt:AbstractPostRemoteStatusSync], self]; 
    [request setPredicate:predicate];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date_created_gmt" ascending:YES];
    [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    NSError *error = nil;
    NSArray *array = [context executeFetchRequest:request error:&error];
    if (array == nil) {
        array = [NSArray array];
    }
    return array;
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
	if ( self.options == nil || (self.options.count == 0) ) {
        return nil;
    }
    NSDictionary *currentOption = [self.options objectForKey:name];
    return [currentOption objectForKey:@"value"];
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
    return;
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

- (void)syncBlogPostsWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    return;
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


- (void)checkActivationStatusWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    WPFLogMethod();
    WPXMLRPCClient *api = [WPXMLRPCClient clientWithXMLRPCEndpoint:[NSURL URLWithString:[NSString stringWithFormat: @"%@", kWPcomXMLRPCUrl]]];
    [api callMethod:@"wpcom.getActivationStatus"
         parameters:[NSArray arrayWithObjects:[self hostURL], nil]
            success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSString *returnData = responseObject;
                if ([returnData isKindOfClass:[NSString class]]) {
                    [self setBlogID:[returnData numericValue]];
                    [self setIsActivated:[NSNumber numberWithBool:YES]];
                    [self dataSave];
                }
                if (success) success();
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                DDLogError(@"Error while checking if VideoPress is enabled: %@", error);
                
                NSString *errorMessage = [error localizedDescription];
                
                // FIXME - This is very fragile checking error messages text
                if ([errorMessage isEqualToString:@"Parse Error. Please check your XML-RPC endpoint."])
                {
                    [self setIsActivated:[NSNumber numberWithBool:YES]];
                    [self dataSave];
                    if (success) {
                        success();
                    }
                } else if ([errorMessage isEqualToString:@"Site not activated."]) {
                    if (failure) {
                        failure(error);
                    }
                } else if ([errorMessage isEqualToString:@"Blog not found."]) {
                    if (failure) {
                        failure(error);
                    }
                } else {
                    if (failure) {
                        failure(error);
                    }
                }
                
            }];
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
        }
    }
    return _api;
}

#pragma mark -

- (WPXMLRPCRequestOperation *)operationForOptionsWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    NSArray *parameters = [self getXMLRPCArgsWithExtra:nil];
    WPXMLRPCRequest *request = [self.api XMLRPCRequestWithMethod:@"wp.getOptions" parameters:parameters];
    WPXMLRPCRequestOperation *operation = [self.api XMLRPCRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([self isDeleted] || self.managedObjectContext == nil)
            return;

        self.options = [NSDictionary dictionaryWithDictionary:(NSDictionary *)responseObject];
        NSString *minimumVersion = @"3.1";
        float version = [[self version] floatValue];
        if (version < [minimumVersion floatValue]) {
            if (self.lastUpdateWarning == nil || [self.lastUpdateWarning floatValue] < [minimumVersion floatValue]) {
                [[WordPressAppDelegate sharedWordPressApplicationDelegate] showAlertWithTitle:NSLocalizedString(@"WordPress version too old", @"")
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

    return operation;
}

- (WPXMLRPCRequestOperation *)operationForPostFormatsWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    NSDictionary *dict = [NSDictionary dictionaryWithObject:@"1" forKey:@"show-supported"];
    NSArray *parameters = [self getXMLRPCArgsWithExtra:dict];
    
    WPXMLRPCRequest *request = [self.api XMLRPCRequestWithMethod:@"wp.getPostFormats" parameters:parameters];
    WPXMLRPCRequestOperation *operation = [self.api XMLRPCRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
        DDLogError(@"Error syncing post formats: %@", error);

        if (failure) {
            failure(error);
        }
    }];
    
    return operation;
}

- (WPXMLRPCRequestOperation *)operationForCommentsWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    NSDictionary *requestOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:100] forKey:@"number"];
    NSArray *parameters = [self getXMLRPCArgsWithExtra:requestOptions];
    WPXMLRPCRequest *request = [self.api XMLRPCRequestWithMethod:@"wp.getComments" parameters:parameters];
    WPXMLRPCRequestOperation *operation = [self.api XMLRPCRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([self isDeleted] || self.managedObjectContext == nil)
            return;

        [Comment mergeNewComments:responseObject forBlog:self];
        self.isSyncingComments = NO;
        self.lastCommentsSync = [NSDate date];

        if (success) {
            success();
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:kCommentsChangedNotificationName object:self];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogError(@"Error syncing comments: %@", error);
        self.isSyncingComments = NO;

        if (failure) {
            failure(error);
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:kCommentsChangedNotificationName object:self];
    }];
    
    return operation;
}

- (WPXMLRPCRequestOperation *)operationForCategoriesWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    NSArray *parameters = [self getXMLRPCArgsWithExtra:nil];
    WPXMLRPCRequest *request = [self.api XMLRPCRequestWithMethod:@"wp.getCategories" parameters:parameters];
    WPXMLRPCRequestOperation *operation = [self.api XMLRPCRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([self isDeleted] || self.managedObjectContext == nil)
            return;

        [Category mergeNewCategories:responseObject forBlog:self];
        
        if (success) {
            success();
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogError(@"Error syncing categories: %@", error);

        if (failure) {
            failure(error);
        }
    }];
    
    return operation;    
}

- (WPXMLRPCRequestOperation *)operationForPostsWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure loadMore:(BOOL)more {
    int num;

    // Don't load more than 20 posts if we aren't at the end of the table,
    // even if they were previously donwloaded
    // 
    // Blogs with long history can get really slow really fast, 
    // with no chance to go back
    int postBatchSize = 40;
    if (more) {
        num = MAX([self.posts count], postBatchSize);
        if ([self.hasOlderPosts boolValue]) {
            num += postBatchSize;
        }
    } else {
        num = postBatchSize;
    }

    NSArray *parameters = [self getXMLRPCArgsWithExtra:[NSNumber numberWithInt:num]];
    WPXMLRPCRequest *request = [self.api XMLRPCRequestWithMethod:@"metaWeblog.getRecentPosts" parameters:parameters];
    WPXMLRPCRequestOperation *operation = [self.api XMLRPCRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
        DDLogError(@"Error syncing posts: %@", error);
        self.isSyncingPosts = NO;

        if (failure) {
            failure(error);
        }
    }];
    
    return operation;        
}

- (WPXMLRPCRequestOperation *)operationForPagesWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure loadMore:(BOOL)more {
    int num;
	
    int syncCount = [[self syncedPostsWithEntityName:@"Page" withContext:self.managedObjectContext] count];
    // Don't load more than 20 pages if we aren't at the end of the table,
    // even if they were previously donwloaded
    // 
    // Blogs with long history can get really slow really fast, 
    // with no chance to go back
    int pageBatchSize = 40;
    if (more) {
        num = MAX(syncCount, pageBatchSize);
        if ([self.hasOlderPages boolValue]) {
            num += pageBatchSize;
        }
    } else {
        num = pageBatchSize;
    }

    NSArray *parameters = [self getXMLRPCArgsWithExtra:[NSNumber numberWithInt:num]];
    WPXMLRPCRequest *request = [self.api XMLRPCRequestWithMethod:@"wp.getPages" parameters:parameters];
    WPXMLRPCRequestOperation *operation = [self.api XMLRPCRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
        DDLogError(@"Error syncing pages: %@", error);
        self.isSyncingPages = NO;

        if (failure) {
            failure(error);
        }
    }];

    return operation;
}

@end
