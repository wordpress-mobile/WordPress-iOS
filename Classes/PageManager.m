//
//  PageManager.m
//  WordPress
//
//  Created by Chris Boyd on 9/6/10.
//

#import "PageManager.h"

@implementation PageManager
@synthesize appDelegate, dm, xmlrpcURL, connection, payload, urlRequest, urlResponse, pages, saveKey, statuses, pageIDs;
@synthesize statusKey, isGettingPages, password;

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
	pages = [[NSMutableArray alloc] init];
	pageIDs = [[NSMutableArray alloc] init];
	statuses = [[NSMutableDictionary alloc] init];
	
	appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
	dm = [BlogDataManager sharedDataManager];
	password = [[dm getPasswordFromKeychainInContextOfCurrentBlog:dm.currentBlog] retain];
	
	saveKey = [[NSString stringWithFormat:@"pages-%@", [dm.currentBlog valueForKey:kBlogHostName]] retain];
	statusKey = [[NSString stringWithFormat:@"statuses-%@", [dm.currentBlog valueForKey:kBlogHostName]] retain];
	
	[self loadStatuses];
	[self syncStatuses];
}

#pragma mark -
#pragma mark Page Methods

- (void)loadData {
	if([[NSUserDefaults standardUserDefaults] objectForKey:saveKey] != nil) {
		NSArray *savedPages = (NSArray *)[[NSUserDefaults standardUserDefaults] objectForKey:saveKey];
		for(NSDictionary *savedPage in savedPages) {
			[pages addObject:savedPage];
		}
		[[NSNotificationCenter defaultCenter] postNotificationName:@"DidSyncPages" object:nil];
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

- (void)syncPages {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	NSArray *params = [NSArray arrayWithObjects:
					   [dm.currentBlog valueForKey:@"blogid"],
					   [dm.currentBlog objectForKey:@"username"],
					   password, nil];
	//NSLog(@"syncPages.params: %@", params);
	
	// Execute the XML-RPC request
	XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithHost:xmlrpcURL];
	[request setMethod:@"wp.getPageList" withObjects:params];
	
	connection = [[NSURLConnection alloc] initWithRequest:[request request] delegate:self];
	if (connection) {
		payload = [[NSMutableData data] retain];
	}
	[request release];
}

- (void)didSyncPages {
	NSSortDescriptor *pageSorter = [[NSSortDescriptor alloc] initWithKey:@"date_created_gmt" ascending:NO];
	[pages sortUsingDescriptors:[NSArray arrayWithObject:pageSorter]];
	[pageSorter release];
	
	[self storeData];
	
	// Post notification
	[[NSNotificationCenter defaultCenter] postNotificationName:@"DidSyncPages" object:nil];
}

- (void)syncPage:(NSNumber *)pageID {
	NSDictionary *page = [[self downloadPage:pageID] retain];
	int updateIndex = [self indexForPageID:pageID];
	if((updateIndex > -1) && (page != nil))
		[pages replaceObjectAtIndex:updateIndex withObject:page];
    [page release];
}

- (void)syncStatuses {
	[self performSelectorInBackground:@selector(syncStatusesInBackground) withObject:nil];
}

- (void)syncStatusesInBackground {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if ([[WPReachability sharedReachability] internetConnectionStatus]) {
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
		
		NSArray *params = [NSArray arrayWithObjects:
						   [dm.currentBlog valueForKey:kBlogId],
						   [dm.currentBlog valueForKey:@"username"],
						   password,
						   nil];
		XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithHost:xmlrpcURL];
		[request setMethod:@"wp.getPageStatusList" withObjects:params];
		//NSLog(@"syncStatusesInBackground.params: %@", params);
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
		[request release];
		
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	}
	
	[pool release];
}

- (NSDictionary *)getPage:(NSNumber *)pageID {
	NSDictionary *result = nil;
	if(isGettingPages == NO) {
		for(NSDictionary *page in pages) {
			NSNumber *thisPageID = [page objectForKey:@"page_id"];
			if((thisPageID != nil) && ([thisPageID isEqualToNumber:pageID])) {
				result = page;
				break;
			}
			
		}
	}
	
	if(result == nil) {
		result = [self downloadPage:(NSNumber *)pageID];
	}
	
	return result;
}

- (NSDictionary *)downloadPage:(NSNumber *)pageID {
	NSDictionary *result = nil;
	if ([[WPReachability sharedReachability] internetConnectionStatus]) {
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
		
		// We haven't downloaded the page in the background yet, so get it synchronously
		NSArray *params = [NSArray arrayWithObjects:
						   [dm.currentBlog valueForKey:kBlogId], 
						   [pageID stringValue],
						   [dm.currentBlog valueForKey:@"username"],
						   password,
						   nil];
		//NSLog(@"downloadPage.params: %@", params);
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
		[request release];
		
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	}
	return result;
}

- (void)addPage:(NSDictionary *)page {
	[pages insertObject:page atIndex:0];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"DidAddPage" object:nil];
}

- (void)getPages {
	if(isGettingPages == NO) {
		isGettingPages = YES;
		[pages removeAllObjects];
		[self performSelectorInBackground:@selector(getPagesInBackground) withObject:nil];
	}
}

- (void)getPagesInBackground {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	for(NSNumber *pageID in pageIDs) {
		NSDictionary *page = [self getPage:pageID];
		if(![[[page objectForKey:@"page_status"] lowercaseString] isEqualToString:@"trash"])
			[self performSelectorOnMainThread:@selector(addPage:) withObject:page waitUntilDone:NO];
	}
	
	isGettingPages = NO;
	[self performSelectorOnMainThread:@selector(didGetPages) withObject:nil waitUntilDone:NO];
	
	[pool release];
}

- (void)didGetPages {
	NSSortDescriptor *pageSorter = [[NSSortDescriptor alloc] initWithKey:@"date_created_gmt" ascending:NO];
	[pages sortUsingDescriptors:[NSArray arrayWithObject:pageSorter]];
	[pageSorter release];
	
	[self storeData];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"DidGetPages" object:nil];
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

- (int)indexForPageID:(NSNumber *)pageID {
	int result = -1;
	int currentIndex = 0;
	for(NSDictionary *page in pages) {
		NSNumber *thisPageID = [page objectForKey:@"page_id"];
		if((thisPageID != nil) && ([thisPageID isEqualToNumber:pageID])) {
			result = currentIndex;
			break;
		}
		currentIndex++;
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
					   password,
					   [page legacyPost],
					   shouldPublish, nil];
	XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithHost:xmlrpcURL];
	[request setMethod:@"wp.newPage" withObjects:params];
	
	id response = [self executeXMLRPCRequest:request];
	if(![response isKindOfClass:[NSDictionary class]]) {
		// Success
		NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
		[f setNumberStyle:NSNumberFormatterDecimalStyle];
		NSNumber *newPageID = [f numberFromString:response];
		[f release];
		
		[self storeData];
		[self verifyPublishSuccessful:newPageID localDraftID:page.uniqueID];
	}
	else {
		// Failure
		NSLog(@"wp.newPage failed: %@", response);
	}
	[request release];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)savePage:(Post *)page {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	// We haven't downloaded the page in the background yet, so get it synchronously
	NSArray *params = [NSArray arrayWithObjects:
					   [dm.currentBlog valueForKey:kBlogId],
					   page.postID,
					   [dm.currentBlog valueForKey:@"username"],
					   password,
					   [page legacyPost], nil];
	XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithHost:xmlrpcURL];
	[request setMethod:@"wp.editPage" withObjects:params];
	
	id response = [self executeXMLRPCRequest:request];
	if(![response isKindOfClass:[NSDictionary class]]) {
		// Success
		NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
		[f setNumberStyle:NSNumberFormatterDecimalStyle];
		NSNumber *pageID = [f numberFromString:page.postID];
		[f release];
		[self syncPage:pageID];
		[self storeData];
	}
	else {
		// Failure
		NSLog(@"wp.editPage failed: %@", response);
	}
	[request release];
	
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
						   password,
						   [pageID stringValue], nil];
		XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithHost:xmlrpcURL];
		[request setMethod:@"wp.deletePage" withObjects:params];
		
		NSString *response = (NSString *)[self executeXMLRPCRequest:request];
		if([response intValue] == 1) {
			// Success
			result = YES;
			[pages removeObject:[self getPage:pageID]];
			[self storeData];
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
	
	NSDictionary *newPage = [self downloadPage:pageID];
	if(newPage != nil) {
		NSNumber *newPageID = [newPage valueForKey:@"page_id"];
		if([pageID isEqualToNumber:newPageID]) {
			// Publish was successful
			[self performSelectorOnMainThread:@selector(addPage:) withObject:newPage waitUntilDone:NO];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"DidCreatePage" object:newPage];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"LocalDraftWasPublishedSuccessfully" object:uniqueID];
			result = YES;
		}
	}
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	return result;
}

- (void)storeData {
	// Save page data for offline
	[[NSUserDefaults standardUserDefaults] setObject:pages forKey:saveKey];
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
					
					if(isGettingPages == NO) {
						if(![responseMeta isKindOfClass:[NSError class]]) {
							[pageIDs removeAllObjects];
							
							// Handle response here.
							if([responseMeta isKindOfClass:[NSArray class]]) {
								NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
								[f setNumberStyle:NSNumberFormatterDecimalStyle];
								for(NSDictionary *page in responseMeta) {
									NSNumber *pageID = [f numberFromString:[page valueForKey:@"page_id"]];
									[pageIDs addObject:pageID];
								}
								[f release];
							}
							
							if(pageIDs.count > 0)
								[self performSelectorOnMainThread:@selector(getPages) withObject:nil waitUntilDone:NO];
							else
								[[NSNotificationCenter defaultCenter] postNotificationName:@"DidSyncPages" object:nil];
						}
						else {
							NSLog(@"error syncing pages: %@", responseMeta);
						}
					}
					else
						[[NSNotificationCenter defaultCenter] postNotificationName:@"DidSyncPages" object:nil];

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
	[password release];
	[statusKey release];
	[pageIDs release];
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
