//
//  IncrementPost.m
//  WordPress
//
//  Created by John Bickerstaff on 2/18/10.
//  
//

#import "IncrementPost.h"

@interface IncrementPost (private)

- (void)loadBlogData;

@end

@implementation IncrementPost
@synthesize currentBlog, currentPost, numberOfPostsCurrentlyLoaded, next10PostIdArray, dm;

#pragma mark -
#pragma mark Initialize and dealloc

- (id)init {
    if (self = [super init]) {
	
		[self loadBlogData];
	 
    }
    return self;
}

- (void)dealloc {
	[currentBlog release];
	[currentPost release];
	//[postID release];
	[next10PostIdArray release];
    [super dealloc];
}

#pragma mark -
#pragma mark init methods

- (void)loadBlogData {
	dm = [BlogDataManager sharedDataManager];
	self.currentBlog = dm.currentBlog;
	self.currentPost = dm.currentPost;
}

#pragma mark -
#pragma mark Get More Posts/Refresh Posts

-(BOOL)loadOlderPosts {
	//Code for Pages should be very similar.  Any point in refactoring to have one method work for both?
		//Pro: it may be more elegant with one place to handle both...
		//Con: Posts and Pages are different.  
				//If handling ever needs to change because Posts or Pages changed, it's problematic because it's now tightly coupled...
	
    // get post titles from file for use in this method
	NSMutableArray *newPostTitlesList;
    NSString *postTitlesPath = [dm pathToPostTitles:currentBlog];
	newPostTitlesList = [NSMutableArray arrayWithContentsOfFile:postTitlesPath];
	//NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"date_created_gmt" ascending:YES];
	NSSortDescriptor *sd = [[NSSortDescriptor alloc]
							initWithKey:@"date_created_gmt" ascending:NO
							selector:@selector(compare:)];
	[newPostTitlesList sortUsingDescriptors:[NSArray arrayWithObject:sd]];
	[sd release];
	
	//get the mt.getRecentPostTitles (post metadata) or whatever it was for 10 + numberOfPostsToDisplay
	//  ------------------------- invoke metaWeblog.getRecentPosts
	[currentBlog setObject:[NSNumber numberWithInt:1] forKey:@"kIsSyncProcessRunning"];
	// Parameters
    NSString *username = [currentBlog valueForKey:@"username"];
	NSString *pwd =	[dm getPasswordFromKeychainInContextOfCurrentBlog:currentBlog];
    NSString *fullURL = [currentBlog valueForKey:@"xmlrpc"];
    NSString *blogid = [currentBlog valueForKey:kBlogId];
	NSNumber *totalPosts = [currentBlog valueForKey:@"totalPosts"];
	//CAN I USE totalposts here???
	int previousNumberOfPosts = [totalPosts intValue];
	NSNumber *userSetMaxToFetch = [NSNumber numberWithInt:[[currentBlog valueForKey:kPostsDownloadCount] intValue]];
	int max = previousNumberOfPosts + ([userSetMaxToFetch intValue] + 50);
	int loadLimit = [userSetMaxToFetch intValue];
	NSNumber *numberOfPostsToGet = [NSNumber numberWithInt:max];
	XMLRPCRequest *postsMetadata = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:fullURL]];
	[postsMetadata setMethod:@"mt.getRecentPostTitles"
	withObjects:[NSArray arrayWithObjects:blogid, username, pwd, numberOfPostsToGet, nil]];

	id response = [dm executeXMLRPCRequest:postsMetadata byHandlingError:YES];
	[postsMetadata release];

	// TODO:
	// Check for fault
	// check for nil or empty response
	// provide meaningful messge to user
	if ((!response) || !([response isKindOfClass:[NSArray class]])) {
		[currentBlog setObject:[NSNumber numberWithInt:0] forKey:@"kIsSyncProcessRunning"];
		//		[[NSNotificationCenter defaultCenter] postNotificationName:@"BlogsRefreshNotification" object:blog userInfo:nil];
		return NO;
	}

//parse the returned data for the "new" post ids
//these will be the ids of posts that are "deeper" in the array than previousNumberOfPosts/@"totalPosts"
//use the ids to build the system.multicall and get the next X (user set value) number of posts
	
	int metadataCount = ((NSArray *)response).count;
	//bail if there are no more "old" posts to load.  (this does not deal with new posts posted after the last "refresh")
	if (metadataCount == previousNumberOfPosts) {
		//TODO: JOHNB popup an alert view that says "All Posts have Been retrieved"
		return NO;
	}
	
	NSEnumerator *postsEnum = [response objectEnumerator];
	NSMutableArray *onlyOlderPostsArray = [[NSMutableArray alloc] init];
	NSDictionary *postMetadataDict;
	NSInteger newPostCount = 0;
	NSMutableArray *getMorePostsArray = [[NSMutableArray alloc] init];
	NSString *postID = @"nil";
	
	NSDate *lastKnownCreatedAt = [[newPostTitlesList objectAtIndex:0] valueForKey:@"date_created_gmt"];
	//newPostCount = 0;
	while (postMetadataDict = [postsEnum nextObject]) {
		//newPostCount ++;
	
		//postID = [postMetadataDict valueForKey:@"postid"];
		//postIDInt = [postID intValue];
		
		NSDate *postGMTDate = [postMetadataDict valueForKey:@"date_created_gmt"];
		NSInteger secs = [[NSTimeZone localTimeZone] secondsFromGMTForDate:postGMTDate];
		NSDate *newCreatedAt = [postGMTDate addTimeInterval:(secs * +1)];
		
		switch ([newCreatedAt compare:lastKnownCreatedAt]){
			case NSOrderedAscending:
				[onlyOlderPostsArray addObject:postMetadataDict];
				//[postMetadataDict release];
				break;
			case NSOrderedSame:
				[onlyOlderPostsArray addObject:postMetadataDict];
				//[postMetadataDict release];
				break;
			case NSOrderedDescending:
				break;
		}
	}
	
	NSEnumerator *postsEnum2 = [onlyOlderPostsArray objectEnumerator];
	while (postMetadataDict = [postsEnum2 nextObject]) {
		newPostCount ++;
		//postID = [postMetadataDict valueForKey:@"postid"];
		
		if (previousNumberOfPosts < newPostCount && newPostCount <= (previousNumberOfPosts + loadLimit ) ) {
			//get the postid
			postID = [postMetadataDict valueForKey:@"postid"];
			
			//make the dict to hold the values
			NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
			//add the methodName to the dict
			[dict setValue:@"metaWeblog.getPost" forKey:@"methodName"];
			//make an array with the "getPost" values and put it into the dict in the methodName key
		    [dict setValue:[NSArray arrayWithObjects:postID, username, pwd, nil] forKey:@"params"];
			//add the dict to the MutableArray that will get sent in the XMLRPC request
			[getMorePostsArray addObject:dict];
			[dict release];
		}
	}
	[onlyOlderPostsArray release];
//ask for the next 10 posts via system.multicall using getMorePostsArray			
	XMLRPCRequest *postsReq = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:fullURL]];
	[postsReq setMethod:@"system.multicall" withObject:getMorePostsArray];
	NSArray *nextTenPosts = [dm executeXMLRPCRequest:postsReq byHandlingError:YES];
	[postsReq release];

	//if error, turn off kIsSyncProcessRunning and return
	if ((!nextTenPosts) || !([nextTenPosts isKindOfClass:[NSArray class]])) {
	[currentBlog setObject:[NSNumber numberWithInt:0] forKey:@"kIsSyncProcessRunning"];
	//			[[NSNotificationCenter defaultCenter] postNotificationName:@"BlogsRefreshNotification" object:blog userInfo:nil];
	[getMorePostsArray release];
	return NO;
	} else {
	//here is where we add data to the posts and write to the filesystem, and sort that list
	//	///AFTER I HAVE AN ARRAY OF POST DICTS...
	
    // loop through each post
    // - add local_status, blogid and bloghost to the post
    // - save the post
    // - count new posts
    // - add/replace postTitle for post
    // Sort and Save postTitles list
    // Update blog counts and save blogs list
	
	// get post titles from file
	//	NSMutableArray *newPostTitlesList;
	//    NSString *postTitlesPath = [dm pathToPostTitles:currentBlog];
	NSFileManager *fm = [NSFileManager defaultManager];
	//	
	//    if ([fm fileExistsAtPath:postTitlesPath]) {
	//        newPostTitlesList = [NSMutableArray arrayWithContentsOfFile:postTitlesPath];
	//    } else {
	//        newPostTitlesList = [NSMutableArray arrayWithCapacity:30];
	//    }
	//[newPostTitlesList removeAllObjects];
			
    // loop thru posts list and massage new posts data... see comments throughout.
    NSArray *singlePostArray;
	NSDictionary *post;
	NSInteger newPostCount = 0;
	

	NSEnumerator *postsEnum = [nextTenPosts objectEnumerator];
    while (singlePostArray = [postsEnum nextObject]) {
		
		//strip the extra array returned by system.multicall so we really have a post NSDictionary
		post = [singlePostArray objectAtIndex:0];
		
		//fix the date
		NSDate *postGMTDate = [post valueForKey:@"date_created_gmt"];
        NSInteger secs = [[NSTimeZone localTimeZone] secondsFromGMTForDate:postGMTDate];
		NSDate *currentDate = [postGMTDate addTimeInterval:(secs * +1)];
        [post setValue:currentDate forKey:@"date_created_gmt"];
		
		// add blogid and blog_host_name to post
        [post setValue:[currentBlog valueForKey:kBlogId] forKey:kBlogId];
        [post setValue:[currentBlog valueForKey:kBlogHostName] forKey:kBlogHostName];
		
        // Check if the post already exists
        // yes: check if a local draft exists
        //		 yes: set the local-status to 'edit'
        //		 no: set the local_status to 'original'
        // no: increment new posts count
        NSString *pathToPost = [dm getPathToPost:post forBlog:currentBlog];
        if ([fm fileExistsAtPath:pathToPost]) {
		}
		else {
            [post setValue:@"original" forKey:@"local_status"];
            newPostCount++;
        }
		
        // write the new post
        [post writeToFile:pathToPost atomically:YES];
		
        // make a post title using the post
        NSMutableDictionary *postTitle = [dm postTitleForPost:post];
		
		//add the new post title to the list (shouldn't need to delete as all in here should be new)
        [newPostTitlesList addObject:postTitle];
    }

    // sort and save the postTitles list
    NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"date_created_gmt" ascending:NO];
    [newPostTitlesList sortUsingDescriptors:[NSArray arrayWithObject:sd]];
    [sd release];
    [newPostTitlesList writeToFile:[dm pathToPostTitles:currentBlog]  atomically:YES];
			
    // increment blog counts and save blogs list
    [currentBlog setObject:[NSNumber numberWithInt:[newPostTitlesList count]] forKey:@"totalPosts"];
	[currentBlog setObject:[NSNumber numberWithInt:newPostCount] forKey:@"newposts"];
			
    NSInteger blogIndex = [dm indexForBlogid:[currentBlog valueForKey:kBlogId] url:[currentBlog valueForKey:@"url"]];
    if (blogIndex >= 0) {
        //[dm->blogsList replaceObjectAtIndex:blogIndex withObject:currentBlog];
		[dm updateBlogsListByIndex:blogIndex withDict:currentBlog];
    } else {
		//		[self->blogsList addObject:blog];
    }
			
	[getMorePostsArray release];
	
    [currentBlog setObject:[NSNumber numberWithInt:0] forKey:@"kIsSyncProcessRunning"];
    [dm performSelectorOnMainThread:@selector(postBlogsRefreshNotificationInMainThread:) withObject:currentBlog waitUntilDone:NO];
	}
	
	if (metadataCount < previousNumberOfPosts + loadLimit) {
		//tell calling class that there are no more items past this point, so anyMorePosts can be NO and we don't display the cell
		return NO;
	}else {
		return YES;
	}
}

-(BOOL)loadOlderPages {
	
	//Code for Pages should be very similar.  Any point in refactoring to have one method work for both?
	//Pro: it may be more elegant with one place to handle both...
	//Con: Pages and Pages are different.  
	//If handling ever needs to change because Pages or Pages changed, it's problematic because it's now tightly coupled...
	
    // get page titles from file for use in this method
	NSMutableArray *newPageTitlesList;
    NSString *pageTitlesPath = [dm pathToPageTitles:currentBlog];
	newPageTitlesList = [NSMutableArray arrayWithContentsOfFile:pageTitlesPath];
	//NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"date_created_gmt" ascending:YES];
	NSSortDescriptor *sd = [[NSSortDescriptor alloc]
							initWithKey:@"date_created_gmt" ascending:YES
							selector:@selector(compare:)];
	[newPageTitlesList sortUsingDescriptors:[NSArray arrayWithObject:sd]];
	[sd release];
	
	//get the mt.getRecentPageTitles (page metadata) or whatever it was for 10 + numberOfPagesToDisplay
	
	//  ------------------------- invoke metaWeblog.getRecentPages
	[currentBlog setObject:[NSNumber numberWithInt:1] forKey:@"kIsSyncProcessRunning"];
	// Parameters
    NSString *username = [currentBlog valueForKey:@"username"];
	NSString *pwd =	[dm getPasswordFromKeychainInContextOfCurrentBlog:currentBlog];
    NSString *fullURL = [currentBlog valueForKey:@"xmlrpc"];
    NSString *blogid = [currentBlog valueForKey:kBlogId];
	

	
	NSNumber *totalpages = [currentBlog valueForKey:@"totalpages"];
	//CAN I USE totalpages here???
	int previousNumberOfPages = [totalpages intValue];
	NSNumber *userSetMaxToFetch = [NSNumber numberWithInt:[[[currentBlog valueForKey:kPostsDownloadCount] substringToIndex:3] intValue]];
	//is this possibly just a holder for # of items to download?  if so, then we're fine and don't need to reproduce it.  
		//We should probably change the name to something like kNumberOfItemsToDownloadCount or something similar though...
	//because pages are handled differently than posts in the current version, (pagesDownloadCount) will  need to be added to the pages datastructure
	//this also will require code (probably in applicationDidFinishLaunching) to add this to currently existing blogs or we'll crash users
	//also, find all instances of kPostsDownloadCount and figure out what's going on...
	int max = previousNumberOfPages + ([userSetMaxToFetch intValue] + 50);
	int loadLimit = [userSetMaxToFetch intValue];
	NSNumber *numberOfPagesToGet = [NSNumber numberWithInt:max];
	
	
	
	XMLRPCRequest *pagesMetadata = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:fullURL]];
	[pagesMetadata setMethod:@"wp.getPageList"
				 withObjects:[NSArray arrayWithObjects:blogid, username, pwd, numberOfPagesToGet, nil]];
	
	id response = [dm executeXMLRPCRequest:pagesMetadata byHandlingError:YES];
	[pagesMetadata release];
	
	// TODO:
	// Check for fault
	// check for nil or empty response
	// provide meaningful messge to user
	if ((!response) || !([response isKindOfClass:[NSArray class]])) {
		[currentBlog setObject:[NSNumber numberWithInt:0] forKey:@"kIsSyncProcessRunning"];
		//		[[NSNotificationCenter defaultCenter] pageNotificationName:@"BlogsRefreshNotification" object:blog userInfo:nil];
		return NO;
	}
	
	
	//parse the returned data for the "new" page ids
	//these will be the pages that are "deeper" in the array than previousNumberOfPages/@"totalPages"
	//use the ids to build the system.multicall and get the next X (user set value) number of pages
	
	int metadataCount = ((NSArray *)response).count;
	//bail if there are no more "old" pages to load.  (this does not deal with new pages added after the last "refresh")
	if (metadataCount == previousNumberOfPages) {
		//TODO: JOHNB popup an alert view that says "All Pages have Been retrieved"
		return NO;
	}
	
	
	
	NSEnumerator *pagesEnum = [response objectEnumerator];
	//NSMutableArray *onlyOlderPagesArray = [[NSMutableArray alloc] init];
	NSMutableArray *onlyOlderPagesArray = [[NSMutableArray alloc] init];
	NSDictionary *pageMetadataDict;
	//NSMutableDictionary *pageRequestDict;
	NSInteger newPageCount = 0;
	NSMutableArray *getMorePagesArray = [[NSMutableArray alloc] init];
	
	
	NSString *pageID = @"nil";
	NSDate *lastKnownCreatedAt = [[newPageTitlesList objectAtIndex:0] valueForKey:@"date_created_gmt"];
	
	//newPageCount = 0;
	while (pageMetadataDict = [pagesEnum nextObject]) {
		//newPageCount ++;
		
		//pageID = [pageMetadataDict valueForKey:@"page_id"];
		//pageIDInt = [pageID intValue];
		
		NSDate *pageGMTDate = [pageMetadataDict valueForKey:@"date_created_gmt"];
			
		//if the recently loaded metadata contains a date that is greater than the last stored page date 
		//then ignore it and move to the next object, because we're only updating older items here, not items more recent
		//than the last refresh.
		switch ([pageGMTDate compare:lastKnownCreatedAt]){
			case NSOrderedAscending:
				[onlyOlderPagesArray addObject:pageMetadataDict];
				break;
			case NSOrderedSame:
				break;
			case NSOrderedDescending:
				break;
		}

	}
	
	NSSortDescriptor *sd3 = [[NSSortDescriptor alloc]
							initWithKey:@"date_created_gmt" ascending:NO
							selector:@selector(compare:)];
	[onlyOlderPagesArray sortUsingDescriptors:[NSArray arrayWithObject:sd3]];
	[sd3 release];
	
	NSEnumerator *pagesEnum2 = [onlyOlderPagesArray objectEnumerator];
	//int olderPagesArrayCount = onlyOlderPagesArray.count;
	int numberOfPagesToRequest = 0;
	
	if (onlyOlderPagesArray.count < loadLimit) {
		numberOfPagesToRequest = onlyOlderPagesArray.count;
	}else {
		numberOfPagesToRequest = loadLimit;
	}

	for (int i = 0; i < numberOfPagesToRequest; i++) {
		pageMetadataDict = [pagesEnum2 nextObject];
		pageID = [pageMetadataDict valueForKey:@"page_id"];
		NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
		
		//add the methodName to the dict
		[dict setValue:@"wp.getPage" forKey:@"methodName"];
		//make an array with the "getPage" values and put it into the dict in the methodName key
		[dict setValue:[NSArray arrayWithObjects:blogid, pageID, username, pwd, nil] forKey:@"params"];
		NSLog(@"dict! %@", dict);
		//add the dict to the MutableArray that will get sent in the XMLRPC request
		[getMorePagesArray addObject:dict];
		NSLog(@"the latest dict %@", dict);
		//NSLog(@"the array %@", [onlyOlderPagesArray objectAtIndex:i]);
		[dict release];
	}
	[onlyOlderPagesArray release];
	
	//ask for the next X pages via system.multicall using getMorePagesArray			
	XMLRPCRequest *pagesReq = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:fullURL]];
	[pagesReq setMethod:@"system.multicall" withObject:getMorePagesArray];
	NSArray *response2 = [dm executeXMLRPCRequest:pagesReq byHandlingError:YES];
	[pagesReq release];
	
	//if error, turn off kIsSyncProcessRunning and return
	if ((!response2) || !([response2 isKindOfClass:[NSArray class]])) {
		[currentBlog setObject:[NSNumber numberWithInt:0] forKey:@"kIsSyncProcessRunning"];
		//			[[NSNotificationCenter defaultCenter] pageNotificationName:@"BlogsRefreshNotification" object:blog userInfo:nil];
		[getMorePagesArray release];
		return NO;
	} //else {
	
	//------need these for work later in the method
	NSFileManager *defaultFileManager = [NSFileManager defaultManager];
	//NSMutableArray *pageTitlesArray = [NSMutableArray array];

	//-----------------------unravel the extra wrappers from the system.multicall response
	NSArray *singlePageArray;
	NSDictionary *page;
	newPageCount = 0;
		
//walk through the final dataset and make the needed update to date, write to filesystem, and set into memory
	
	NSEnumerator *pagesEnum3 = [response2 objectEnumerator];
	while (singlePageArray = [pagesEnum3 nextObject]) {
		
		if ( newPageCount <= response2.count ) {
			newPageCount ++;
			
		page = [singlePageArray objectAtIndex:0];
		
		//-----------------------continue with the old -syncPagesForBlog code
		NSMutableDictionary *updatedPage = [NSMutableDictionary dictionaryWithDictionary:page];
		
        NSDate *pageGMTDate = [updatedPage valueForKey:@"date_created_gmt"];
        NSInteger secs = [[NSTimeZone localTimeZone] secondsFromGMTForDate:pageGMTDate];
        NSDate *currentDate = [pageGMTDate addTimeInterval:(secs * +1)];
        [updatedPage setValue:currentDate forKey:@"date_created_gmt"];
		
        [updatedPage setValue:[currentBlog valueForKey:kBlogId] forKey:kBlogId];
        [updatedPage setValue:[currentBlog valueForKey:kBlogHostName] forKey:kBlogHostName];
		
        NSString *path = [dm pageFilePath:updatedPage forBlog:currentBlog];
		
        [defaultFileManager removeItemAtPath:path error:nil];
        [updatedPage writeToFile:path atomically:YES];
		
        [newPageTitlesList addObject:[dm pageTitleForPage:updatedPage]];
		
		
		// sort and save the postTitles list
		NSSortDescriptor *sd2 = [[NSSortDescriptor alloc] initWithKey:@"date_created_gmt" ascending:NO];
		[newPageTitlesList sortUsingDescriptors:[NSArray arrayWithObject:sd2]];
		[sd2 release];
		[currentBlog setObject:[NSNumber numberWithInt:[newPageTitlesList count]] forKey:@"totalpages"];
		[currentBlog setObject:[NSNumber numberWithInt:1] forKey:@"newpages"];
		
		NSString *pathToCommentTitles = [dm pathToPageTitles:currentBlog];
		[defaultFileManager removeItemAtPath:pathToCommentTitles error:nil];
		
		[newPageTitlesList writeToFile:pathToCommentTitles atomically:YES];
		[dm setPageTitlesList:newPageTitlesList];
		}
	}
	[getMorePagesArray release];
    [currentBlog setObject:[NSNumber numberWithInt:0] forKey:@"kIsSyncProcessRunning"];
	
	if (metadataCount < previousNumberOfPages + loadLimit) {
		//tell calling class that there are no more items past this point, so anyMorePages can be NO and we don't display the cell
		return NO;
	}else {
		return YES;
	}
	
}

@end

