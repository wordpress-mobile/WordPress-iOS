//
//  PageManager.m
//  WordPress
//
//  Created by Chris Boyd on 9/6/10.
//

#import "PageManager.h"

@implementation PageManager
@synthesize appDelegate, dm, xmlrpcURL, connection, payload, urlRequest, urlResponse, pages, saveKey, statuses;

#pragma mark -
#pragma mark Initialize

- (id)init {
    if((self = [super init])) {
		appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
		dm = [BlogDataManager sharedDataManager];
		saveKey = [[NSString stringWithFormat:@"pages-%@", [dm.currentBlog valueForKey:kBlogHostName]] retain];
		pages = [[NSMutableArray alloc] init];
		statuses = [[NSMutableDictionary alloc] init];
		[statuses setObject:@"Local Draft" forKey:[NSString stringWithString:kLocalDraftKey]];
		
		[self loadSavedPages];
    }
    return self;
}

- (id)initWithXMLRPCUrl:(NSString *)xmlrpc {
    if((self = [super init])) {
		appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
		dm = [BlogDataManager sharedDataManager];
		saveKey = [[NSString stringWithFormat:@"pages-%@", [dm.currentBlog valueForKey:kBlogHostName]] retain];
		pages = [[NSMutableArray alloc] init];
		statuses = [[NSMutableDictionary alloc] init];
		[statuses setObject:@"Local Draft" forKey:[NSString stringWithString:kLocalDraftKey]];
		[self loadSavedPages];
		
		self.xmlrpcURL = [NSURL URLWithString:xmlrpc];
		[self performSelectorInBackground:@selector(syncStatuses) withObject:nil];
		[self syncPages];
    }
    return self;
}

#pragma mark -
#pragma mark Page Methods

- (void)loadSavedPages {
	if([[NSUserDefaults standardUserDefaults] objectForKey:saveKey] != nil) {
		NSArray *savedPages = (NSArray *)[[NSUserDefaults standardUserDefaults] objectForKey:saveKey];
		for(NSDictionary *savedPage in savedPages) {
			[pages addObject:savedPage];
		}
		[[NSNotificationCenter defaultCenter] postNotificationName:@"DidSyncPages" object:nil];
	}
}

- (void)syncPages {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	NSArray *params = [NSArray arrayWithObjects:
					   [dm.currentBlog valueForKey:@"blogid"],
					   [dm.currentBlog objectForKey:@"username"],
					   [dm getPasswordFromKeychainInContextOfCurrentBlog:dm.currentBlog],
					   nil];
	
	// Execute the XML-RPC request
	XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithHost:xmlrpcURL];
	[request setMethod:@"wp.getPages" withObjects:params];
	
	connection = [[NSURLConnection alloc] initWithRequest:[request request] delegate:self];
	if (connection) {
		payload = [[NSMutableData data] retain];
	}
}

- (void)didSyncPages {
	// Save page data for offline
	[[NSUserDefaults standardUserDefaults] setObject:pages forKey:saveKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	// Post notification
	[[NSNotificationCenter defaultCenter] postNotificationName:@"DidSyncPages" object:nil];
}

- (void)syncStatuses {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if ([[Reachability sharedReachability] internetConnectionStatus]) {
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
		
		NSArray *params = [NSArray arrayWithObjects:
						   [dm.currentBlog valueForKey:kBlogId],
						   [dm.currentBlog valueForKey:@"username"],
						   [dm getPasswordFromKeychainInContextOfCurrentBlog:dm.currentBlog], nil];
		XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithHost:xmlrpcURL];
		[request setMethod:@"wp.getPageStatusList" withObjects:params];
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
		}
		
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	}
	
	[pool release];
}

- (NSDictionary *)getPage:(NSNumber *)pageID {
	NSDictionary *result = nil;
	for(NSDictionary *page in pages) {
		NSNumber *thisPageID = [page objectForKey:@"page_id"];
		if((thisPageID != nil) && ([thisPageID isEqualToNumber:pageID])) {
			result = page;
			break;
		}
		
	}
	
	if(result == nil) {
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
		
		// We haven't downloaded the page in the background yet, so get it synchronously
		NSArray *params = [NSArray arrayWithObjects:
						 [dm.currentBlog valueForKey:kBlogId], 
						 [pageID stringValue],
						 [dm.currentBlog valueForKey:@"username"],
						 [dm getPasswordFromKeychainInContextOfCurrentBlog:dm.currentBlog], nil];
		XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithHost:xmlrpcURL];
		[request setMethod:@"wp.getPage" withObjects:params];
		id page = [self executeXMLRPCRequest:request];
		
		if([page isKindOfClass:[NSDictionary class]]) {
			// Success
			result = page;
		}
		else {
			// Failure
			NSLog(@"error: %@", page);
		}
		
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	}
	
	return result;
}

- (BOOL)hasPageWithID:(NSNumber *)pageID {
	BOOL result = NO;
	for(NSDictionary *page in pages) {
		NSNumber *thisPageID = [page objectForKey:@"page_id"];
		if((thisPageID != nil) && ([thisPageID isEqualToNumber:pageID])) {
			result = YES;
			break;
		}
			
	}
	return result;
}

- (void)createPage:(Post *)page {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	NSString *shouldPublish = @"false";
	if([page.status isEqualToString:@"publish"])
		shouldPublish = @"true";
	
	// We haven't downloaded the page in the background yet, so get it synchronously
	NSArray *params = [NSArray arrayWithObjects:
					   [dm.currentBlog valueForKey:kBlogId],
					   [dm.currentBlog valueForKey:@"username"],
					   [dm getPasswordFromKeychainInContextOfCurrentBlog:dm.currentBlog],
					   [page legacyPost],
					   shouldPublish, nil];
	XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithHost:xmlrpcURL];
	[request setMethod:@"wp.newPage" withObjects:params];
	
	id response = [self executeXMLRPCRequest:request];
	if([response intValue] > -1) {
		// Success
		NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
		[f setNumberStyle:NSNumberFormatterDecimalStyle];
		NSNumber *newPageID = [f numberFromString:response];
		[f release];
		[self verifyPublishSuccessful:newPageID localDraftID:page.uniqueID];
	}
	else {
		// Failure
		NSLog(@"wp.newPage failed: %@", response);
	}
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)savePage:(Post *)page {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	NSString *shouldPublish = @"false";
	if([page.status isEqualToString:@"publish"])
		shouldPublish = @"true";
	
	// We haven't downloaded the page in the background yet, so get it synchronously
	NSArray *params = [NSArray arrayWithObjects:
					   [dm.currentBlog valueForKey:kBlogId],
					   page.postID,
					   [dm.currentBlog valueForKey:@"username"],
					   [dm getPasswordFromKeychainInContextOfCurrentBlog:dm.currentBlog],
					   [page legacyPost], nil];
	XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithHost:xmlrpcURL];
	[request setMethod:@"wp.editPage" withObjects:params];
	
	id response = [self executeXMLRPCRequest:request];
	NSLog(@"savePage response: %@", response);
	if([response intValue] == 1) {
		// Success
		[self performSelectorOnMainThread:@selector(syncPages) withObject:nil waitUntilDone:NO];
	}
	else {
		// Failure
		NSLog(@"wp.newPage failed: %@", response);
	}
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (BOOL)deletePage:(NSNumber *)pageID {
	BOOL result = NO;
	
	if(pageID != nil) {
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
		
		// We haven't downloaded the page in the background yet, so get it synchronously
		NSArray *params = [NSArray arrayWithObjects:
						   [dm.currentBlog valueForKey:kBlogId],
						   [dm.currentBlog valueForKey:@"username"],
						   [dm getPasswordFromKeychainInContextOfCurrentBlog:dm.currentBlog],
						   [pageID stringValue], nil];
		XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithHost:xmlrpcURL];
		[request setMethod:@"wp.deletePage" withObjects:params];
		[params release];
		
		NSString *response = (NSString *)[self executeXMLRPCRequest:request];
		if([response intValue] == 1) {
			// Success
			result = YES;
			[pages removeObject:[self getPage:pageID]];
		}
		else {
			// Failure
		}
		
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	}
	
	return result;
}

- (BOOL)verifyPublishSuccessful:(NSNumber *)pageID localDraftID:(NSString *)uniqueID {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	BOOL result = NO;
	NSArray *params = [NSArray arrayWithObjects:
					   [dm.currentBlog valueForKey:@"blogid"],
					   [pageID stringValue],
					   [dm.currentBlog objectForKey:@"username"],
					   [dm getPasswordFromKeychainInContextOfCurrentBlog:dm.currentBlog], nil];
	
	XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithHost:xmlrpcURL];
	[request setMethod:@"wp.getPage" withObjects:params];
	[params release];
	
	XMLRPCResponse *response = [self executeXMLRPCRequest:request];
	if([response isKindOfClass:[NSDictionary class]]) {
		NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
		[f setNumberStyle:NSNumberFormatterDecimalStyle];
		NSNumber *newPageID = [response valueForKey:@"page_id"];
		[f release];
		if([pageID isEqualToNumber:newPageID]) {
			// Publish was successful
			[[NSNotificationCenter defaultCenter] postNotificationName:@"LocalDraftWasPublishedSuccessfully" object:uniqueID];
			result = YES;
			[self performSelectorOnMainThread:@selector(syncPages) withObject:nil waitUntilDone:NO];
		}
	}
	else {
		// Failure
	}
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	return result;
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
					
					if(![responseMeta isKindOfClass:[NSError class]]) {
						// Handle response here.
						if(responseMeta.count > 0) {
							[pages removeAllObjects];
							for(NSDictionary *page in responseMeta) {
								[pages addObject:page];
							}
						}
						
						[self didSyncPages];
					}
					else {
						NSLog(@"error syncing pages: %@", responseMeta);
					}

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
	[statuses release];
	[saveKey release];
	[xmlrpcURL release];
	[connection release];
	[payload release];
	[urlRequest release];
	[urlResponse release];
	[pages release];
	[super dealloc];
}

@end
