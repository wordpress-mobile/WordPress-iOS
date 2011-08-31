//
//  WPDataController.m
//  WordPress
//
//  Created by Chris Boyd on 6/17/10.
//

#import "WPDataController.h"

@interface WPDataController(PrivateMethods)
- (id) init;
- (NSMutableDictionary *)getXMLRPCDictionaryForPost:(AbstractPost *)post;
- (NSArray *)getXMLRPCArgsForBlog:(Blog *)blog  withExtraArgs:(NSArray *)args;
- (id)executeXMLRPCRequest:(XMLRPCRequest *)req;
- (NSError *)errorWithResponse:(XMLRPCResponse *)res;
@end

@implementation WPDataController
@synthesize error;

- (id) init {
	self = [super init];
	if (self == nil)
		return nil;
	return self;
}

- (void)dealloc {
	[super dealloc];
}

+ (WPDataController *)sharedInstance {
	static WPDataController *instance = nil;
	if (instance == nil) instance = [[WPDataController alloc] init];
	return instance;
}

#pragma mark -
#pragma mark User

- (BOOL)checkXMLRPC:(NSString *)xmlrpc username:(NSString *)username password:(NSString *)password {
	BOOL result = NO;
	
	ASIHTTPRequest *request = [[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:xmlrpc]];
	[request setRequestMethod:@"POST"];
	[request setShouldPresentCredentialsBeforeChallenge:NO];
	[request setShouldPresentAuthenticationDialog:YES];
	[request setUseKeychainPersistence:YES];
	
	XMLRPCRequest *xmlrpcRequest = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:xmlrpc]];
	[xmlrpcRequest setMethod:@"wp.getUsersBlogs" withObjects:[NSArray arrayWithObjects:username, password, nil]];
	[request appendPostData:[[xmlrpcRequest source] dataUsingEncoding:NSUTF8StringEncoding]];
	[request startSynchronous];
	[xmlrpcRequest release];
	
	self.error = [request error];
	if (!self.error && [request responseString] != nil) {
		CXMLDocument *xml = [[[CXMLDocument alloc] initWithXMLString:[request responseString] options:CXMLDocumentTidyXML error:nil] autorelease];
		CXMLElement *node = [[xml nodesForXPath:@"//methodResponse" error:nil] objectAtIndex:0];
		if(node != nil)
			result = YES;
		else
			result = NO;
	}
    [request release];
	
	return result;
}

- (NSString *)guessXMLRPCForUrl:(NSString *)url {
	[FileLogger log:@"%@ %@ %@", self, NSStringFromSelector(_cmd), url];
    if (url == nil || [url isEqualToString:@""])
        return nil;
    
    if(![url hasPrefix:@"http"])
        url = [NSString stringWithFormat:@"http://%@", url];

    url = [url stringByReplacingOccurrencesOfRegex:@"/wp-admin/?$" withString:@""]; 
    url = [url stringByReplacingOccurrencesOfRegex:@"/?$" withString:@""]; 
    
    NSString *xmlrpc;
    if ([url hasSuffix:@"xmlrpc.php"])
        xmlrpc = url;
    else
        xmlrpc = [NSString stringWithFormat:@"%@/xmlrpc.php", url];
    
    XMLRPCRequest *req = [[[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:xmlrpc]] autorelease];
    NSArray *result;
    [req setMethod:@"system.listMethods" withObjects:[NSArray array]];

    retryOnTimeout = YES;
    result = [self executeXMLRPCRequest:req];
    
    if([result isKindOfClass:[NSError class]]) {
        NSError *err = (NSError *)result;
        if ([err code] == ASIConnectionFailureErrorType) {
            // Couldn't get a connection to host, so no variant of the url will work
            // Don't keep trying
            return nil;
        }
    } else {
		[FileLogger log:@"%@ %@ -> %@", self, NSStringFromSelector(_cmd), xmlrpc];
        return xmlrpc;
    }
    
    // Normal way failed, let's see if url was already a xmlrpc endpoint
    [req setHost:[NSURL URLWithString:url]];
    result = [self executeXMLRPCRequest:req];
    if(![result isKindOfClass:[NSError class]]) {
		[FileLogger log:@"%@ %@ -> %@", self, NSStringFromSelector(_cmd), url];
        return url;
	}

    // Nothing? Let's go for the RSD file
    ASIHTTPRequest *request = [[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:url]];
    [request setShouldPresentCredentialsBeforeChallenge:YES];
    [request setShouldPresentAuthenticationDialog:YES];
    [request setUseKeychainPersistence:YES];
    [request setValidatesSecureCertificate:NO];
    [request startSynchronous];
    [request setNumberOfTimesToRetryOnTimeout:2];
	
    NSString *rsdURL = [[request responseString] stringByMatching:@"<link rel=\"EditURI\" type=\"application/rsd\\+xml\" title=\"RSD\" href=\"([^\"]*)\"[^/]*/>" capture:1];
    
	if (rsdURL == nil) {
		//the RSD link not found using RegExp, try to find it again on a "cleaned" HTML document
		NSError *htmlError;
		CXMLDocument *rsdHTML = [[[CXMLDocument alloc] initWithXMLString:[request responseString] options:CXMLDocumentTidyXML error:&htmlError] autorelease];
		if(!htmlError) {
			NSString *cleanedHTML = [rsdHTML XMLStringWithOptions:CXMLDocumentTidyXML];
			rsdURL = [cleanedHTML stringByMatching:@"<link rel=\"EditURI\" type=\"application/rsd\\+xml\" title=\"RSD\" href=\"([^\"]*)\"[^/]*/>" capture:1];
		}
	}
    
	// Release the ASIHTTPRequest    
	[request release];
	
	if (rsdURL != nil) {
        WPLog(@"rsdURL: %@", rsdURL);
        xmlrpc = [rsdURL stringByReplacingOccurrencesOfString:@"?rsd" withString:@""];
        WPLog(@"xmlrpc from rsd url: %@", xmlrpc);
        if (![xmlrpc isEqualToString:rsdURL]) {
            [req setHost:[NSURL URLWithString:xmlrpc]];
            result = [self executeXMLRPCRequest:req];
            if(![result isKindOfClass:[NSError class]]) {
				[FileLogger log:@"%@ %@ -> %@", self, NSStringFromSelector(_cmd), xmlrpc];
                return xmlrpc;
			}
        }
        
        // No tricks, let's parse the rsd
        NSError *rsdError;
        CXMLDocument *rsdXML = [[[CXMLDocument alloc] initWithContentsOfURL:[NSURL URLWithString:rsdURL] options:CXMLDocumentTidyXML error:&rsdError] autorelease];
        if(!rsdError) {
            @try {
                CXMLElement *serviceXML = [[[rsdXML rootElement] children] objectAtIndex:1];
                for(CXMLElement *api in [[[serviceXML elementsForName:@"apis"] objectAtIndex:0] elementsForName:@"api"]) {
                    if([[[api attributeForName:@"name"] stringValue] isEqualToString:@"WordPress"]) {
                        // Bingo! We found the WordPress XML-RPC element
                        xmlrpc = [[api attributeForName:@"apiLink"] stringValue];
                        [req setHost:[NSURL URLWithString:xmlrpc]];
                        result = [self executeXMLRPCRequest:req];
                        if(![result isKindOfClass:[NSError class]]) {
							[FileLogger log:@"%@ %@ -> %@", self, NSStringFromSelector(_cmd), xmlrpc];
                            return xmlrpc;
                        } else {
							[FileLogger log:@"%@ %@ -> (null)", self, NSStringFromSelector(_cmd)];
                            return nil; // Sorry, I give up. Bad URL
						}
                    }
                }
            }
            @catch (NSException *ex) {
                WPFLog(@"Error parsing RSD file: %@ %@", [ex name], [ex reason]);
            }
        }        
    }
    
    return nil;    
}

- (void)registerForPushNotifications {
	[self performSelectorInBackground:@selector(registerForPushNotificationsInBackground) withObject:nil];
}

- (void)registerForPushNotificationsInBackground {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if([[NSUserDefaults standardUserDefaults] objectForKey:@"apnsDeviceToken"] != nil) {
		XMLRPCRequest *req = [[[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:@"http://frsh.wordpress.com/xmlrpc.php"]] autorelease];
		NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_username_preference"];
		NSArray *result;
		NSError *pwError;
		NSArray *params = [NSArray arrayWithObjects:
						   username, 
						   [SFHFKeychainUtils getPasswordForUsername:username andServiceName:@"WordPress.com" error:&pwError], 
						   [[NSUserDefaults standardUserDefaults] objectForKey:@"apnsDeviceToken"],
						   nil];
		[req setMethod:@"wpcom.addiOSDeviceToken" withObjects:params];
		
        retryOnTimeout = YES;
		result = [self executeXMLRPCRequest:req];
		
		// We want this to fail silently.
		if(![result isKindOfClass:[NSError class]])
			NSLog(@"successfully registered for push notifications with WordPress.com: %@", result);
		else
			NSLog(@"failed to register for push notifications with WordPress.com: %@", result);
	}
	
	[pool release];
}

- (BOOL)authenticateUser:(NSString *)xmlrpc username:(NSString *)username password:(NSString *)password {
	BOOL result = NO;
	if((xmlrpc != nil) && (username != nil) && (password != nil)) {
		if([self getBlogsForUrl:xmlrpc username:username password:password] != nil)
			result = YES;
	}
	return result;
}

- (NSMutableArray *)getBlogsForUrl:(NSString *)xmlrpc username:(NSString *)username password:(NSString *)password {
	NSMutableArray *usersBlogs = [[NSMutableArray alloc] init];
		
	@try {
		XMLRPCRequest *xmlrpcUsersBlogs = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:xmlrpc]];
		[xmlrpcUsersBlogs setMethod:@"wp.getUsersBlogs" withObjects:[NSArray arrayWithObjects:username, password, nil]];
        retryOnTimeout = YES;
		NSArray *usersBlogsData = [self executeXMLRPCRequest:xmlrpcUsersBlogs];
        [xmlrpcUsersBlogs release];
		
		if([usersBlogsData isKindOfClass:[NSArray class]]) {
            [usersBlogs release];
            usersBlogs = [NSArray arrayWithArray:usersBlogsData];
		}
		else if([usersBlogsData isKindOfClass:[NSError class]]) {
			self.error = (NSError *)usersBlogsData;
			NSString *errorMessage = [self.error localizedDescription];
			
			usersBlogs = nil;
			
			if([errorMessage isEqualToString:@"The operation couldn’t be completed. (NSXMLParserErrorDomain error 4.)"])
				errorMessage = @"Your blog's XML-RPC endpoint was found but it isn't communicating properly. Try disabling plugins or contacting your host.";
			//else if([errorMessage isEqualToString:@"Bad login/pass combination."])
				//errorMessage = nil;			
		}
		else {
			usersBlogs = nil;
			NSLog(@"getBlogsForUrl failed: %@", usersBlogsData);
		}
	}
	@catch (NSException * e) {
		usersBlogs = nil;
		NSLog(@"getBlogsForUrl failed: %@", e);
	}
	
	return usersBlogs;
}

#pragma mark -
#pragma mark Blog

- (NSString *)passwordForBlog:(Blog *)blog {
    NSError *err;
	NSString *password;
	
	if (blog.isWPcom) {
        password = [SFHFKeychainUtils getPasswordForUsername:blog.username
												   andServiceName:@"WordPress.com"
															error:&error];
        
    } else {
	
		password = [SFHFKeychainUtils getPasswordForUsername:blog.username
													andServiceName:blog.hostURL
															 error:&err];
	}
	if (password == nil)
		password = @""; // FIXME: not good either, but prevents from crashing
	
	return password;
}

- (NSMutableArray *)getRecentPostsForBlog:(Blog *)blog number:(NSNumber *)number {
    XMLRPCRequest *xmlrpcRequest = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:blog.xmlrpc]];
    // TODO: use app-wide setting for number of posts
    NSArray *args = [NSArray arrayWithObject:number];
	[xmlrpcRequest setMethod:@"metaWeblog.getRecentPosts" withObjects:[self getXMLRPCArgsForBlog:blog withExtraArgs:args]];
    retryOnTimeout = YES;
    NSArray *recentPosts = [self executeXMLRPCRequest:xmlrpcRequest];
	[xmlrpcRequest release];
    
    if ([recentPosts isKindOfClass:[NSError class]]) {
        NSLog(@"Couldn't get recent posts: %@", [(NSError *)recentPosts localizedDescription]);
        return [NSMutableArray array];
    }
    return [NSMutableArray arrayWithArray:recentPosts];
}

- (NSMutableArray *)getCategoriesForBlog:(Blog *)blog {
    XMLRPCRequest *xmlrpcRequest = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:blog.xmlrpc]];
	[xmlrpcRequest setMethod:@"wp.getCategories" withObjects:[self getXMLRPCArgsForBlog:blog withExtraArgs:nil]];
	
    retryOnTimeout = YES;
    NSArray *categories = [self executeXMLRPCRequest:xmlrpcRequest];
    [xmlrpcRequest release];

    if ([categories isKindOfClass:[NSError class]]) {
        NSLog(@"Couldn't get categories: %@", [(NSError *)categories localizedDescription]);
        return [NSMutableArray array];
    }

    return [NSMutableArray arrayWithArray:categories];
}

- (NSArray *)wpGetPostFormats:(Blog *)blog {
    XMLRPCRequest *xmlrpcRequest = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:blog.xmlrpc]];
	[xmlrpcRequest setMethod:@"wp.getPostFormats" withObjects:[self getXMLRPCArgsForBlog:blog withExtraArgs:nil]];
    retryOnTimeout = YES;
    NSArray *postFormats = [self executeXMLRPCRequest:xmlrpcRequest];
	[xmlrpcRequest release];
    
    if ([postFormats isKindOfClass:[NSError class]]) {
        NSLog(@"Couldn't get post formats: %@", [(NSError *)postFormats localizedDescription]);
        return [NSArray array];
    }
    return postFormats;    
}

#pragma mark -
#pragma mark Category
- (int)wpNewCategory:(Category *)category {
    XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:category.blog.xmlrpc]];
    NSDictionary *categoryDict = [NSDictionary dictionaryWithObjectsAndKeys:category.categoryName,
                                  @"name",
                                  category.parentID,
                                  @"parent_id",
                                  nil];
    NSArray *args = [NSArray arrayWithObject:categoryDict];
    [request setMethod:@"wp.newCategory" withObjects:[self getXMLRPCArgsForBlog:category.blog withExtraArgs:args]];
    retryOnTimeout = NO;
    NSNumber *categoryID = [self executeXMLRPCRequest:request];
    if (self.error) {
        NSLog(@"Error creating category: %@", categoryID);
        return -1;
    } else {
        return [categoryID intValue];
    }
}

#pragma mark -
#pragma mark Post

- (NSMutableDictionary *)getXMLRPCDictionaryForPost:(AbstractPost *)post {
    NSMutableDictionary *postParams = [NSMutableDictionary dictionary];
    if (post.postTitle != nil)
        [postParams setObject:post.postTitle forKey:@"title"];
    if (post.content != nil)
        [postParams setObject:post.content forKey:@"description"];
    if ([post isKindOfClass:[Post class]]) {
        if ([post valueForKey:@"postFormat"] != nil)
            [postParams setObject:[post valueForKey:@"postFormat"] forKey:@"wp_post_format"];
        if ([post valueForKey:@"tags"] != nil)
            [postParams setObject:[post valueForKey:@"tags"] forKey:@"mt_keywords"];
        if ([post valueForKey:@"categories"] != nil) {
            NSMutableSet *categories = [post mutableSetValueForKey:@"categories"];
            NSMutableArray *categoryNames = [NSMutableArray arrayWithCapacity:[categories count]];
            for (Category *cat in categories) {
                [categoryNames addObject:cat.categoryName];
            }
            [postParams setObject:categoryNames forKey:@"categories"];
        }
		Coordinate *c = [post valueForKey:@"geolocation"];
		// Warning
		// XMLRPCEncoder sends floats with an integer type (i4), so WordPress ignores the decimal part
		// We send coordinates as strings to avoid that
		NSMutableArray *customFields = [NSMutableArray array];
		NSMutableDictionary *latitudeField = [NSMutableDictionary dictionaryWithCapacity:3];
		NSMutableDictionary *longitudeField = [NSMutableDictionary dictionaryWithCapacity:3];
		NSMutableDictionary *publicField = [NSMutableDictionary dictionaryWithCapacity:3];
		if (c != nil) {
			[latitudeField setValue:@"geo_latitude" forKey:@"key"];
			[latitudeField setValue:[NSString stringWithFormat:@"%f", c.latitude] forKey:@"value"];
			[longitudeField setValue:@"geo_longitude" forKey:@"key"];
			[longitudeField setValue:[NSString stringWithFormat:@"%f", c.longitude] forKey:@"value"];
			[publicField setValue:@"geo_public" forKey:@"key"];
			[publicField setValue:@"1" forKey:@"value"];
		}
		if ([post valueForKey:@"latitudeID"]) {
			[latitudeField setValue:[post valueForKey:@"latitudeID"] forKey:@"id"];
		}
		if ([post valueForKey:@"longitudeID"]) {
			[longitudeField setValue:[post valueForKey:@"longitudeID"] forKey:@"id"];
		}
		if ([post valueForKey:@"publicID"]) {
			[publicField setValue:[post valueForKey:@"publicID"] forKey:@"id"];
		}
		if ([latitudeField count] > 0) {
			[customFields addObject:latitudeField];
		}
		if ([longitudeField count] > 0) {
			[customFields addObject:longitudeField];
		}
		if ([publicField count] > 0) {
			[customFields addObject:publicField];
		}

		if ([customFields count] > 0) {
			[postParams setObject:customFields forKey:@"custom_fields"];
		}
    }
	
    if (post.status == nil)
        post.status = @"publish";
	 if ([post isKindOfClass:[Post class]]) {
	     [postParams setObject:post.status forKey:@"post_status"];
	 } else {
		 [postParams setObject:post.status forKey:@"page_status"];
	 }
    
	if (post.date_created_gmt != nil) {
        //post.date_created_gmt = [DateUtils localDateToGMTDate:[NSDate date]];
		[postParams setObject:post.date_created_gmt forKey:@"date_created_gmt"];
	}
	
    if (post.password != nil)
        [postParams setObject:post.password forKey:@"wp_password"];
	
	if (post.permaLink != nil)
        [postParams setObject:post.permaLink forKey:@"permaLink"];
	
	if (post.mt_excerpt != nil)
        [postParams setObject:post.mt_excerpt forKey:@"mt_excerpt"];
	
	if (post.mt_text_more != nil && [post.mt_text_more length] > 0)
        [postParams setObject:post.mt_text_more forKey:@"mt_text_more"];
	
	if (post.wp_slug != nil)
        [postParams setObject:post.wp_slug forKey:@"wp_slug"];
	
    return postParams;
}

// Returns post ID, -1 if unsuccessful
- (int)mwNewPost:(Post *)post {
    XMLRPCRequest *xmlrpcRequest = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:post.blog.xmlrpc]];
    NSMutableDictionary *postParams = [self getXMLRPCDictionaryForPost:post];
    if (post.specialType != nil) {
        [xmlrpcRequest setValue:post.specialType forHTTPHeaderField:@"WP-Quick-Post"];
    }

    [xmlrpcRequest setMethod:@"metaWeblog.newPost" withObjects:[self getXMLRPCArgsForBlog:post.blog withExtraArgs:[NSArray arrayWithObject:postParams]]];

    retryOnTimeout = NO;
    id result = [self executeXMLRPCRequest:xmlrpcRequest];
    if ([result isKindOfClass:[NSError class]]) {
        return -1;
    }

    // Result should be a string with the post ID
    WPLog(@"newPost result: %@", result);
    return [result intValue];
}

- (BOOL)updateSinglePost:(Post *)post{
    XMLRPCRequest *xmlrpcRequest = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:post.blog.xmlrpc]];
	 NSMutableDictionary *postParams = [self getXMLRPCDictionaryForPost:post];
	 NSArray *args = [NSArray arrayWithObjects:post.postID, post.blog.username, [self passwordForBlog:post.blog], postParams, nil];
    [xmlrpcRequest setMethod:@"metaWeblog.getPost" withObjects:args];
    retryOnTimeout = NO;
    id result = [self executeXMLRPCRequest:xmlrpcRequest];
    if ([result isKindOfClass:[NSError class]]) {
        return NO;
    }
	[post updateFromDictionary:result];
    return YES;
}



- (BOOL)mwEditPost:(Post *)post{
    if (post.postID == nil) {
        return NO;
    }
    
    XMLRPCRequest *xmlrpcRequest = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:post.blog.xmlrpc]];
    NSMutableDictionary *postParams = [self getXMLRPCDictionaryForPost:post];
    NSArray *args = [NSArray arrayWithObjects:post.postID, post.blog.username, [self passwordForBlog:post.blog], postParams, nil];
    
    [xmlrpcRequest setMethod:@"metaWeblog.editPost" withObjects:args];
    retryOnTimeout = NO;
    id result = [self executeXMLRPCRequest:xmlrpcRequest];
    if ([result isKindOfClass:[NSError class]]) {
        NSLog(@"mwEditPost failed: %@", result);
        return NO;
    } else {
        return YES;
    }	
}

- (BOOL)mwDeletePost:(Post *)post {
    if (post.postID == nil) {
        // No post ID means no need to delete anything in the server
        // so we return YES to allow the Post to be deleted from the app
        return YES;
    }

    XMLRPCRequest *xmlrpcRequest = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:post.blog.xmlrpc]];
    NSArray *args = [NSArray arrayWithObjects:@"unused", post.postID, post.blog.username, [self passwordForBlog:post.blog], nil];

    [xmlrpcRequest setMethod:@"metaWeblog.deletePost" withObjects:args];
    retryOnTimeout = NO;
    id result = [self executeXMLRPCRequest:xmlrpcRequest];
    if ([result isKindOfClass:[NSError class]]) {
        WPLog(@"metaWeblog.deletePost failed: %@", result);
        return NO;
    } else {
        return YES;
    }
}

#pragma mark -
#pragma mark Page
- (NSMutableArray *)wpGetPages:(Blog *)blog number:(NSNumber *)number {
    XMLRPCRequest *xmlrpcRequest = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:blog.xmlrpc]];
    // TODO: use app-wide setting for number of posts
    NSArray *args = [NSArray arrayWithObject:number];
	[xmlrpcRequest setMethod:@"wp.getPages" withObjects:[self getXMLRPCArgsForBlog:blog withExtraArgs:args]];
    retryOnTimeout = YES;
    NSArray *recentPages = [self executeXMLRPCRequest:xmlrpcRequest];
	[xmlrpcRequest release];
    if ([recentPages isKindOfClass:[NSError class]]) {
        return [NSMutableArray array];
    }    
    
    return [NSMutableArray arrayWithArray:recentPages];
}

// Returns post ID, -1 if unsuccessful
- (int)wpNewPage:(Page *)post {
    XMLRPCRequest *xmlrpcRequest = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:post.blog.xmlrpc]];
    NSMutableDictionary *postParams = [self getXMLRPCDictionaryForPost:post];
    
    [xmlrpcRequest setMethod:@"wp.newPage" withObjects:[self getXMLRPCArgsForBlog:post.blog withExtraArgs:[NSArray arrayWithObject:postParams]]];
    
    retryOnTimeout = NO;
    id result = [self executeXMLRPCRequest:xmlrpcRequest];
    if ([result isKindOfClass:[NSError class]]) {
        return -1;
    }
    
    // Result should be a string with the post ID
    NSLog(@"wpNewPage result: %@", result);
    return [result intValue];
}

- (BOOL)updateSinglePage:(Page *)post {
    if (post.postID == nil) {
        return NO;
    }
    
    XMLRPCRequest *xmlrpcRequest = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:post.blog.xmlrpc]];
    NSMutableDictionary *postParams = [self getXMLRPCDictionaryForPost:post];
    NSArray *args = [NSArray arrayWithObjects:post.blog.blogID, post.postID, post.blog.username, [self passwordForBlog:post.blog], postParams, nil];
    
    [xmlrpcRequest setMethod:@"wp.getPage" withObjects:args];
    retryOnTimeout = YES;
    id result = [self executeXMLRPCRequest:xmlrpcRequest];
    if ([result isKindOfClass:[NSError class]]) {
        WPLog(@"wpGetPage failed: %@", result);
        return NO;
    } 
	
	[post updateFromDictionary:result];
	return YES;
}

- (BOOL)wpEditPage:(Page *)post {
    if (post.postID == nil) {
        return NO;
    }
    
    XMLRPCRequest *xmlrpcRequest = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:post.blog.xmlrpc]];
    NSMutableDictionary *postParams = [self getXMLRPCDictionaryForPost:post];
    NSArray *args = [NSArray arrayWithObjects:post.blog.blogID, post.postID, post.blog.username, [self passwordForBlog:post.blog], postParams, nil];
    
    [xmlrpcRequest setMethod:@"wp.editPage" withObjects:args];
    retryOnTimeout = NO;
    id result = [self executeXMLRPCRequest:xmlrpcRequest];
    if ([result isKindOfClass:[NSError class]]) {
        NSLog(@"wpEditPage failed: %@", result);
        return NO;
    } else {
        return YES;
    }
}

- (BOOL)wpDeletePage:(Page *)post {
    if (post.postID == nil) {
        // No post ID means no need to delete anything in the server
        // so we return YES to allow the Post to be deleted from the app
        return YES;
    }
    
    XMLRPCRequest *xmlrpcRequest = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:post.blog.xmlrpc]];
    NSArray *args = [NSArray arrayWithObjects:post.blog.blogID, post.blog.username, [self passwordForBlog:post.blog], post.postID, nil];
    
    [xmlrpcRequest setMethod:@"wp.deletePage" withObjects:args];
    retryOnTimeout = NO;
    id result = [self executeXMLRPCRequest:xmlrpcRequest];
    if ([result isKindOfClass:[NSError class]]) {
        NSLog(@"wpDeletePage failed: %@", result);
        return NO;
    } else {
        return YES;
    }
}

#pragma mark -
#pragma mark Comment

- (NSMutableDictionary *)getXMLRPCDictionaryForComment:(Comment *)comment {
    NSMutableDictionary *commentParams = [NSMutableDictionary dictionary];
    
	if(comment.content != nil)
		[commentParams setObject:comment.content forKey:@"content"];
	else 
		[commentParams setObject:@"" forKey:@"content"];
	
    [commentParams setObject:comment.parentID forKey:@"comment_parent"]; //keep attention. getComment, getComments are returning a different key "parent" that is a string.
    [commentParams setObject:comment.postID forKey:@"post_id"];
    [commentParams setObject:comment.status forKey:@"status"];
    
    return commentParams;
}

- (NSMutableArray *)wpGetCommentsForBlog:(Blog *)blog {
    XMLRPCRequest *xmlrpcRequest = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:blog.xmlrpc]];
    // TODO: use app-wide setting for number of posts
    NSDictionary *commentsStructure = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:100] forKey:@"number"];
    NSArray *args = [NSArray arrayWithObject:commentsStructure];
	[xmlrpcRequest setMethod:@"wp.getComments" withObjects:[self getXMLRPCArgsForBlog:blog withExtraArgs:args]];
    retryOnTimeout = YES;
    NSArray *recentComments = [self executeXMLRPCRequest:xmlrpcRequest];
	[xmlrpcRequest release];
    if ([recentComments isKindOfClass:[NSError class]]) {
        NSLog(@"Couldn't get recent comments: %@", [(NSError *)recentComments localizedDescription]);
        return [NSMutableArray array];
    }
    return [NSMutableArray arrayWithArray:recentComments];
}

- (NSNumber *)wpNewComment:(Comment *)comment {
    XMLRPCRequest *xmlrpcRequest = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:comment.blog.xmlrpc]];
    NSMutableDictionary *commentParams = [self getXMLRPCDictionaryForComment:comment];
    NSArray *args = [NSArray arrayWithObjects:comment.blog.blogID, comment.blog.username, [self passwordForBlog:comment.blog], comment.postID, commentParams, nil];
    
    [xmlrpcRequest setMethod:@"wp.newComment" withObjects:args];
    retryOnTimeout = NO;
    NSNumber *result = [self executeXMLRPCRequest:xmlrpcRequest];
    if ([result isKindOfClass:[NSError class]]) {
        NSLog(@"wpNewComment failed: %@", result);
        return nil;
    } else {
        return result;
    } 
}

- (BOOL)wpEditComment:(Comment *)comment {
    if (comment.commentID == nil) {
        return NO;
    }
    
    XMLRPCRequest *xmlrpcRequest = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:comment.blog.xmlrpc]];
    NSMutableDictionary *commentParams = [self getXMLRPCDictionaryForComment:comment];
    NSArray *args = [NSArray arrayWithObjects:comment.blog.blogID, comment.blog.username, [self passwordForBlog:comment.blog], comment.commentID, commentParams, nil];
    
    [xmlrpcRequest setMethod:@"wp.editComment" withObjects:args];
    retryOnTimeout = NO;
    id result = [self executeXMLRPCRequest:xmlrpcRequest];
    if ([result isKindOfClass:[NSError class]]) {
        NSLog(@"wpEditComment failed: %@", result);
        return NO;
    } else {
        return YES;
    }    
}

- (BOOL)updateSingleComment:(Comment *)comment {
    if (comment.commentID == nil) {
        return NO;
    }
    
    XMLRPCRequest *xmlrpcRequest = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:comment.blog.xmlrpc]];
    NSMutableDictionary *commentParams = [self getXMLRPCDictionaryForComment:comment];
    NSArray *args = [NSArray arrayWithObjects:comment.blog.blogID, comment.blog.username, [self passwordForBlog:comment.blog], comment.commentID, commentParams, nil];
    
    [xmlrpcRequest setMethod:@"wp.getComment" withObjects:args];
    retryOnTimeout = YES;
    id result = [self executeXMLRPCRequest:xmlrpcRequest];
    if ([result isKindOfClass:[NSError class]]) {
        NSLog(@"updateComment failed: %@", result);
        return NO;
    } else {
		[comment updateFromDictionary:result];
		return YES;
    }    
}


- (BOOL)wpDeleteComment:(Comment *)comment {
    if (comment.commentID == nil)
        return YES;
    
    XMLRPCRequest *xmlrpcRequest = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:comment.blog.xmlrpc]];
    NSArray *args = [NSArray arrayWithObjects:comment.blog.blogID, comment.blog.username, [self passwordForBlog:comment.blog], comment.commentID, nil];
    
    [xmlrpcRequest setMethod:@"wp.deleteComment" withObjects:args];
    retryOnTimeout = NO;
    id result = [self executeXMLRPCRequest:xmlrpcRequest];
    if ([result isKindOfClass:[NSError class]]) {
        NSLog(@"wpDeleteComment failed: %@", result);
        return NO;
    } else {
        return YES;
    }    
}

#pragma mark -
#pragma mark XMLRPC

- (NSArray *)getXMLRPCArgsForBlog:(Blog *)blog  withExtraArgs:(NSArray *)args {
    int size = 3;
    if (args != nil) {
        size += [args count];
    }
    
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:size];
    [result addObject:blog.blogID];
    [result addObject:blog.username];
    [result addObject:[self passwordForBlog:blog]];
    if (args != nil) {
        [result addObjectsFromArray:args];
    }
    
    return [NSArray arrayWithArray:result];
}

- (id)executeXMLRPCRequest:(XMLRPCRequest *)req {
	[FileLogger log:@"%@ %@ %@ %@", self, NSStringFromSelector(_cmd), [req method], [req host]];
	ASIHTTPRequest *request = [[ASIHTTPRequest alloc] initWithURL:[req host]];
	[request setRequestMethod:@"POST"];
	[request setShouldPresentCredentialsBeforeChallenge:YES];
	[request setShouldPresentAuthenticationDialog:YES];
	[request setUseKeychainPersistence:YES];
    [request setValidatesSecureCertificate:NO];
	[request setTimeOutSeconds:30];
	NSString *version  = [[[NSBundle mainBundle] infoDictionary] valueForKey:[NSString stringWithFormat:@"CFBundleVersion"]];
	[request addRequestHeader:@"User-Agent" value:[NSString stringWithFormat:@"wp-iphone/%@",version]];
    [request addRequestHeader:@"Content-Type" value:@"text/xml"];

    NSString *quickPostType = [[req request] valueForHTTPHeaderField:@"WP-Quick-Post"];
    if (quickPostType != nil) {
        [request addRequestHeader:@"WP-Quick-Post" value:quickPostType];
    }

    if (retryOnTimeout) {
        [request setNumberOfTimesToRetryOnTimeout:2];
    } else {
        [request setNumberOfTimesToRetryOnTimeout:0];
    }
	if(getenv("WPDebugXMLRPC"))
		NSLog(@"executeXMLRPCRequest request: %@",[req source]);
    [request appendPostData:[[req source] dataUsingEncoding:NSUTF8StringEncoding]];
	[request startSynchronous];
	
	//generic error
	NSError *err = [request error];
    if (err) {
        self.error = err;
        NSLog(@"executeXMLRPCRequest error: %@", err);
		[request release];
        return err;
    }
    
    
    int statusCode = [request responseStatusCode];
    if (statusCode >= 404) {
        NSDictionary *usrInfo = [NSDictionary dictionaryWithObjectsAndKeys:[request responseStatusMessage], NSLocalizedDescriptionKey, nil];
        self.error = [NSError errorWithDomain:@"org.wordpress.iphone" code:statusCode userInfo:usrInfo];
		[request release];
        return self.error;
    }
	if(getenv("WPDebugXMLRPC"))
		NSLog(@"executeXMLRPCRequest response: %@", [request responseString]);
	
	XMLRPCResponse *userInfoResponse = [[[XMLRPCResponse alloc] initWithData:[request responseData]] autorelease];
	[request release];
		
    err = [self errorWithResponse:userInfoResponse];
	
    if (err) {
		self.error = err;
        return err;
	} else 	
		self.error = nil;
		
    return [userInfoResponse object];
}

- (NSError *)errorWithResponse:(XMLRPCResponse *)res {
    NSError *err = nil;
	
    if ([res isKindOfClass:[NSError class]]) {
        err = (NSError *)res;
    } else {
        if ([res isFault]) {
            NSDictionary *usrInfo = [NSDictionary dictionaryWithObjectsAndKeys:[res fault], NSLocalizedDescriptionKey, nil];
            err = [NSError errorWithDomain:@"org.wordpress.iphone" code:[[res code] intValue] userInfo:usrInfo];
        }
		
        if ([res isParseError]) {
            err = [res object];
        }
    }
    
	[FileLogger log:@"%@ %@ %@", self, NSStringFromSelector(_cmd), err];
	return err;
}

@end
