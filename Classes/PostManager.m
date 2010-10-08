//
//  PostManager.m
//  WordPress
//
//  Created by Chris Boyd on 9/6/10.
//

#import "PostManager.h"

@implementation PostManager
@synthesize appDelegate, dm, xmlrpcURL, connection, payload, urlRequest, urlResponse, posts, saveKey, statuses, postIDs;
@synthesize statusKey, isGettingPosts;

#pragma mark -
#pragma mark Initialize

- (id)init {
    if((self = [super init])) {
		[self initObjects];
		[self loadData];
    }
    return self;
}

- (id)initWithXMLRPCUrl:(NSString *)xmlrpc {
    if((self = [super init])) {
		[self initObjects];
		[self loadData];
		
		self.xmlrpcURL = [NSURL URLWithString:xmlrpc];
    }
    return self;
}

- (void)initObjects {
	posts = [[NSMutableArray alloc] init];
	postIDs = [[NSMutableArray alloc] init];
	statuses = [[NSMutableDictionary alloc] init];
	
	appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
	dm = [BlogDataManager sharedDataManager];
	saveKey = [[NSString stringWithFormat:@"posts-%@", [dm.currentBlog valueForKey:kBlogHostName]] retain];
	statusKey = [[NSString stringWithFormat:@"statuses-%@", [dm.currentBlog valueForKey:kBlogHostName]] retain];
	
	[self loadStatuses];
	[self syncStatuses];
}

#pragma mark -
#pragma mark Post Methods

- (void)loadData {
	if([[NSUserDefaults standardUserDefaults] objectForKey:saveKey] != nil) {
		NSArray *savedPosts = (NSArray *)[[NSUserDefaults standardUserDefaults] objectForKey:saveKey];
		for(NSDictionary *savedPost in savedPosts) {
			[posts addObject:savedPost];
		}
		[[NSNotificationCenter defaultCenter] postNotificationName:@"DidSyncPosts" object:nil];
	}
}

- (void)loadStatuses {
	if([[NSUserDefaults standardUserDefaults] objectForKey:statusKey] != nil) {
		NSDictionary *savedStatuses = [[NSUserDefaults standardUserDefaults] objectForKey:statusKey];
		for(NSString *key in savedStatuses) {
			[statuses setObject:[savedStatuses objectForKey:key] forKey:key];
		}
	}
	else
		[statuses setObject:@"Local Draft" forKey:[NSString stringWithString:kLocalDraftKey]];
}

- (void)syncPosts {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	NSArray *params = [NSArray arrayWithObjects:
					   [dm.currentBlog valueForKey:@"blogid"],
					   [dm.currentBlog objectForKey:@"username"],
					   [dm getPasswordFromKeychainInContextOfCurrentBlog:dm.currentBlog],
					   nil];
	
	// Execute the XML-RPC request
	XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithHost:xmlrpcURL];
	[request setMethod:@"wp.getPostList" withObjects:params];
	
	connection = [[NSURLConnection alloc] initWithRequest:[request request] delegate:self];
	if (connection) {
		payload = [[NSMutableData data] retain];
	}
}

- (void)didSyncPosts {
	NSSortDescriptor *postSorter = [[NSSortDescriptor alloc] initWithKey:@"date_created_gmt" ascending:NO];
	[posts sortUsingDescriptors:[NSArray arrayWithObject:postSorter]];
	
	[self storeData];
	
	// Post notification
	[[NSNotificationCenter defaultCenter] postNotificationName:@"DidSyncPosts" object:nil];
}

- (void)syncPost:(NSNumber *)postID {
	NSDictionary *post = [[self downloadPost:postID] retain];
	int updateIndex = [self indexForPostID:postID];
	if((updateIndex > -1) && (post != nil))
		[posts replaceObjectAtIndex:updateIndex withObject:post];
}

- (void)syncStatuses {
	[self performSelectorInBackground:@selector(syncStatusesInBackground) withObject:nil];
}

- (void)syncStatusesInBackground {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if ([[Reachability sharedReachability] internetConnectionStatus]) {
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
		
		NSArray *params = [NSArray arrayWithObjects:
						   [dm.currentBlog valueForKey:kBlogId],
						   [dm.currentBlog valueForKey:@"username"],
						   [dm getPasswordFromKeychainInContextOfCurrentBlog:dm.currentBlog], nil];
		XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithHost:xmlrpcURL];
		[request setMethod:@"wp.getPostStatusList" withObjects:params];
		id response = [self executeXMLRPCRequest:request];
		
		if([response isKindOfClass:[NSDictionary class]]) {
			// Success
			[statuses removeAllObjects];
			for(NSString *status in response) {
				if([[status lowercaseString] isEqualToString:@"publish"])
					[statuses setObject:@"Published" forKey:status];
				else
					[statuses setObject:[status capitalizedString] forKey:status];
			}
			[statuses setObject:@"Local Draft" forKey:[NSString stringWithString:kLocalDraftKey]];
			[[NSUserDefaults standardUserDefaults] setObject:statuses forKey:statusKey];
		}
		
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	}
	
	[pool release];
}

- (NSDictionary *)getPost:(NSNumber *)postID {
	NSDictionary *result = nil;
	if(isGettingPosts == NO) {
		for(NSDictionary *post in posts) {
			NSNumber *thispostID = [post objectForKey:@"post_id"];
			if((thispostID != nil) && ([thispostID isEqualToNumber:postID])) {
				result = post;
				break;
			}
			
		}
	}
	
	if(result == nil) {
		result = [self downloadPost:(NSNumber *)postID];
	}
	
	return result;
}

- (NSDictionary *)downloadPost:(NSNumber *)postID {
	NSDictionary *result = nil;
	if ([[Reachability sharedReachability] internetConnectionStatus]) {
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
		
		// We haven't downloaded the post in the background yet, so get it synchronously
		NSArray *params = [NSArray arrayWithObjects:
						   [dm.currentBlog valueForKey:kBlogId], 
						   [postID stringValue],
						   [dm.currentBlog valueForKey:@"username"],
						   [dm getPasswordFromKeychainInContextOfCurrentBlog:dm.currentBlog], nil];
		XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithHost:xmlrpcURL];
		[request setMethod:@"wp.getPost" withObjects:params];
		id post = [self executeXMLRPCRequest:request];
		
		if([post isKindOfClass:[NSDictionary class]]) {
			// Success
			result = post;
		}
		else {
			// Failure
			NSLog(@"error: %@", post);
		}
		
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	}
	return result;
}

- (void)addPost:(NSDictionary *)post {
	[posts insertObject:post atIndex:0];
}

- (void)getPosts {
	if(isGettingPosts == NO) {
		isGettingPosts = YES;
		[posts removeAllObjects];
		[self performSelectorInBackground:@selector(getPostsInBackground) withObject:nil];
	}
}

- (void)getPostsInBackground {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	for(NSNumber *postID in postIDs) {
		NSDictionary *post = [self getPost:postID];
		if(![[[post objectForKey:@"post_status"] lowercaseString] isEqualToString:@"trash"])
			[self performSelectorOnMainThread:@selector(addPost:) withObject:post waitUntilDone:NO];
	}
	
	isGettingPosts = NO;
	[self performSelectorOnMainThread:@selector(didGetPosts) withObject:nil waitUntilDone:NO];
	
	[pool release];
}

- (void)didGetPosts {
	NSSortDescriptor *postSorter = [[NSSortDescriptor alloc] initWithKey:@"date_created_gmt" ascending:NO];
	[posts sortUsingDescriptors:[NSArray arrayWithObject:postSorter]];
	
	[self storeData];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"DidGetPosts" object:nil];
}

- (BOOL)hasPostWithID:(NSNumber *)postID {
	BOOL result = NO;
	for(NSDictionary *post in posts) {
		NSNumber *thispostID = [post objectForKey:@"post_id"];
		if((thispostID != nil) && ([thispostID isEqualToNumber:postID])) {
			result = YES;
			break;
		}
		
	}
	return result;
}

- (int)indexForPostID:(NSNumber *)postID {
	int result = -1;
	int currentIndex = 0;
	for(NSDictionary *post in posts) {
		NSNumber *thisPostID = [post objectForKey:@"post_id"];
		if((thisPostID != nil) && ([thisPostID isEqualToNumber:postID])) {
			result = currentIndex;
			break;
		}
		currentIndex++;
	}
	return result;
}

- (void)createPost:(Post *)post {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	NSString *shouldPublish = @"false";
	if([post.status isEqualToString:@"publish"])
		shouldPublish = @"true";
	
	// We haven't downloaded the post in the background yet, so get it synchronously
	NSArray *params = [NSArray arrayWithObjects:
					   [dm.currentBlog valueForKey:kBlogId],
					   [dm.currentBlog valueForKey:@"username"],
					   [dm getPasswordFromKeychainInContextOfCurrentBlog:dm.currentBlog],
					   [post legacyPost],
					   shouldPublish, nil];
	XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithHost:xmlrpcURL];
	[request setMethod:@"wp.newPost" withObjects:params];
	
	id response = [self executeXMLRPCRequest:request];
	if(![response isKindOfClass:[NSDictionary class]]) {
		// Success
		NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
		[f setNumberStyle:NSNumberFormatterDecimalStyle];
		NSNumber *newpostID = [f numberFromString:response];
		[f release];
		
		[self storeData];
		[self verifyPublishSuccessful:newpostID localDraftID:post.uniqueID];
	}
	else {
		// Failure
		NSLog(@"wp.newPost failed: %@", response);
	}
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)savePost:(Post *)post {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	NSString *shouldPublish = @"false";
	if([post.status isEqualToString:@"publish"])
		shouldPublish = @"true";
	
	// We haven't downloaded the post in the background yet, so get it synchronously
	NSArray *params = [NSArray arrayWithObjects:
					   [dm.currentBlog valueForKey:kBlogId],
					   post.postID,
					   [dm.currentBlog valueForKey:@"username"],
					   [dm getPasswordFromKeychainInContextOfCurrentBlog:dm.currentBlog],
					   [post legacyPost], nil];
	XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithHost:xmlrpcURL];
	[request setMethod:@"wp.editPost" withObjects:params];
	
	id response = [self executeXMLRPCRequest:request];
	if(![response isKindOfClass:[NSDictionary class]]) {
		// Success
		NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
		[f setNumberStyle:NSNumberFormatterDecimalStyle];
		NSNumber *postID = [f numberFromString:post.postID];
		[f release];
		[self syncPost:postID];
		[self storeData];
	}
	else {
		// Failure
		NSLog(@"wp.editPost failed: %@", response);
	}
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (BOOL)deletePost:(NSNumber *)postID {
	BOOL result = NO;
	
	if(postID != nil) {
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
		
		// We haven't downloaded the post in the background yet, so get it synchronously
		NSArray *params = [NSArray arrayWithObjects:
						   [dm.currentBlog valueForKey:kBlogId],
						   [dm.currentBlog valueForKey:@"username"],
						   [dm getPasswordFromKeychainInContextOfCurrentBlog:dm.currentBlog],
						   [postID stringValue], nil];
		XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithHost:xmlrpcURL];
		[request setMethod:@"wp.deletePost" withObjects:params];
		[params release];
		
		NSString *response = (NSString *)[self executeXMLRPCRequest:request];
		if([response intValue] == 1) {
			// Success
			result = YES;
			[posts removeObject:[self getPost:postID]];
			[self storeData];
		}
		else {
			// Failure
		}
		
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	}
	
	return result;
}

- (BOOL)verifyPublishSuccessful:(NSNumber *)postID localDraftID:(NSString *)uniqueID {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	BOOL result = NO;
	
	NSDictionary *newPost = [self downloadPost:postID];
	if(newPost != nil) {
		NSNumber *newpostID = [newPost valueForKey:@"post_id"];
		if([postID isEqualToNumber:newpostID]) {
			// Publish was successful
			[self performSelectorOnMainThread:@selector(addPost:) withObject:newPost waitUntilDone:NO];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"DidCreatePost" object:newPost];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"LocalDraftWasPublishedSuccessfully" object:uniqueID];
			result = YES;
		}
	}
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	return result;
}

- (void)storeData {
	// Save post data for offline
	[[NSUserDefaults standardUserDefaults] setObject:posts forKey:saveKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark -
#pragma mark NSURLConnection Methods

- (void)stop {
	[connection cancel];
}

- (void)connection:(NSURLConnection *)conn didReceiveResponse:(NSURLResponse *)response {	
	[self.payload setLength:0];
	[self setUrlResponse:response];
}

- (void)connection:(NSURLConnection *)conn didReceiveData:(NSData *)data {
	[self.payload appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)conn {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	conn = nil;
	
	if(payload != nil)
	{
		NSString  *str = [[NSString alloc] initWithData:payload encoding:NSUTF8StringEncoding];
		if ( ! str ) {
			str = [[NSString alloc] initWithData:payload encoding:[NSString defaultCStringEncoding]];
			payload = (NSMutableData *)[[str dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES] retain];
		}
		
		if ([urlResponse isKindOfClass:[NSHTTPURLResponse class]]) {
			if ([(NSHTTPURLResponse *)urlResponse statusCode] < 400) {
				XMLRPCResponse *xmlrpcResponse = [[XMLRPCResponse alloc] initWithData:payload];
				
				if ([xmlrpcResponse isKindOfClass:[XMLRPCResponse class]]) {
					NSDictionary *responseMeta = [xmlrpcResponse object];
					
					if(isGettingPosts == NO) {
						if(![responseMeta isKindOfClass:[NSError class]]) {
							[postIDs removeAllObjects];
							// Handle response here.
							if(responseMeta.count > 0) {
								NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
								[f setNumberStyle:NSNumberFormatterDecimalStyle];
								for(NSDictionary *post in responseMeta) {
									NSNumber *postID = [f numberFromString:[post valueForKey:@"post_id"]];
									[postIDs addObject:postID];
								}
								[f release];
							}
							
							if(postIDs.count > 0)
								[self performSelectorOnMainThread:@selector(getPosts) withObject:nil waitUntilDone:NO];
							else
								[[NSNotificationCenter defaultCenter] postNotificationName:@"DidSyncPosts" object:nil];
						}
						else {
							NSLog(@"error syncing posts: %@", responseMeta);
						}
					}
					else
						[[NSNotificationCenter defaultCenter] postNotificationName:@"DidSyncPosts" object:nil];
					
				}
				
				[xmlrpcResponse release];
			}
			
		}
		
		[str release];
	}
}

- (void)connection:(NSURLConnection *)conn didFailWithError:(NSError *)error {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

#pragma mark -
#pragma mark XMLRPCConnection Methods

- (id)executeXMLRPCRequest:(XMLRPCRequest *)xmlrpcRequest {
	BOOL httpAuthEnabled = [[dm.currentBlog objectForKey:@"authEnabled"] boolValue];
	NSString *httpAuthUsername = [dm.currentBlog valueForKey:@"authUsername"];
	NSString *httpAuthPassword = [dm getHTTPPasswordFromKeychainInContextOfCurrentBlog:dm.currentBlog];
	
	XMLRPCResponse *userInfoResponse = nil;
	if (httpAuthEnabled) {
		userInfoResponse = [XMLRPCConnection sendSynchronousXMLRPCRequest:xmlrpcRequest
															 withUsername:httpAuthUsername
															  andPassword:httpAuthPassword];
	}
	else {
		userInfoResponse = [XMLRPCConnection sendSynchronousXMLRPCRequest:xmlrpcRequest];
	}
	
	if([userInfoResponse isKindOfClass:[XMLRPCResponse class]])
		return [userInfoResponse object];
	else
		return userInfoResponse;
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
	[statusKey release];
	[postIDs release];
	[statuses release];
	[saveKey release];
	[xmlrpcURL release];
	[connection release];
	[payload release];
	[urlRequest release];
	[urlResponse release];
	[posts release];
	[super dealloc];
}

@end
