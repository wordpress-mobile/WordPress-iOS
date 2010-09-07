//
//  PageManager.m
//  WordPress
//
//  Created by Chris Boyd on 9/6/10.
//

#import "PageManager.h"

@implementation PageManager
@synthesize appDelegate, dm, xmlrpcURL, connection, payload, urlRequest, urlResponse, pages, saveKey, statuses, pageIDs, isGettingPages;

#pragma mark -
#pragma mark Initialize

- (id)init {
    if((self = [super init])) {
		appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
		dm = [BlogDataManager sharedDataManager];
		saveKey = [[NSString stringWithFormat:@"pages-%@", [dm.currentBlog valueForKey:kBlogHostName]] retain];
		pages = [[NSMutableArray alloc] init];
		pageIDs = [[NSMutableArray alloc] init];
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
		pageIDs = [[NSMutableArray alloc] init];
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
	[request setMethod:@"wp.getPageList" withObjects:params];
	
	connection = [[NSURLConnection alloc] initWithRequest:[request request] delegate:self];
	if (connection) {
		payload = [[NSMutableData data] retain];
	}
}

- (void)didSyncPages {
	// Sort
	NSSortDescriptor *sortByDate = [NSSortDescriptor sortDescriptorWithKey:@"date_created_gmt" ascending:NO];
	[pages sortUsingDescriptors:[NSArray arrayWithObject:sortByDate]];
	
	// Save page data for offline
	[[NSUserDefaults standardUserDefaults] setObject:pages forKey:saveKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	// Post notification
	[[NSNotificationCenter defaultCenter] postNotificationName:@"DidSyncPages" object:nil];
}

- (void)syncStatuses {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if ([[Reachability sharedReachability] internetConnectionStatus]) {
		//[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
		
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
		
		//[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
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
	return result;
}

- (void)addPage:(NSDictionary *)page {
	[pages insertObject:page atIndex:0];
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
		[self performSelectorOnMainThread:@selector(addPage:) withObject:page waitUntilDone:NO];
	}
	
	isGettingPages = NO;
	[self performSelectorOnMainThread:@selector(didGetPages) withObject:nil waitUntilDone:NO];
	
	[pool release];
}

- (void)didGetPages {
	// Sort
	NSSortDescriptor *sortByDate = [NSSortDescriptor sortDescriptorWithKey:@"date_created_gmt" ascending:NO];
	[pages sortUsingDescriptors:[NSArray arrayWithObject:sortByDate]];
	
	// Save page data for offline
	[[NSUserDefaults standardUserDefaults] setObject:pages forKey:saveKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
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
	if(![response isKindOfClass:[NSDictionary class]]) {
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
	if(![response isKindOfClass:[NSDictionary class]]) {
		// Success
		[self performSelectorOnMainThread:@selector(syncPages) withObject:nil waitUntilDone:NO];
	}
	else {
		// Failure
		NSLog(@"wp.editPage failed: %@", response);
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
	
	NSDictionary *newPage = [self downloadPage:pageID];
	if(newPage != nil) {
		NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
		[f setNumberStyle:NSNumberFormatterDecimalStyle];
		NSNumber *newPageID = [newPage valueForKey:@"page_id"];
		[f release];
		if([pageID isEqualToNumber:newPageID]) {
			// Publish was successful
			[self performSelectorOnMainThread:@selector(addPage:) withObject:newPage waitUntilDone:NO];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"DidCreatePage" object:newPage];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"LocalDraftWasPublishedSuccessfully" object:uniqueID];
			result = YES;
			[self performSelectorOnMainThread:@selector(syncPages) withObject:nil waitUntilDone:NO];
		}
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
					
					if(isGettingPages == NO) {
						if(![responseMeta isKindOfClass:[NSError class]]) {
							[pageIDs removeAllObjects];
							// Handle response here.
							if(responseMeta.count > 0) {
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
