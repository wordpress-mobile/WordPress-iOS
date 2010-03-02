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
 self.currentBlog = dm.currentBlog;//may not need this
 self.currentPost = dm.currentPost;//may not need this
	

 //DO THIS NEXT !!! //self.numberOfPostsLoaded = [[core data get value], [or BDM getvalue] or [read/write to disk per blog]]
	//can't really do this until we rip out "load all posts" and instead only load 10
	//had to add a value to blog data array to blogFieldNames/newDraftsBlog @"totalPostsLoaded"
	//NSNumber *maxToFetch = [currentBlog valueForKey:@"totalPostsLoaded"];
	//[[dataManager currentBlog] setObject:[selectedObjects objectAtIndex:0] forKey:@totalPostsLoaded];
 
 //set instance variable (array/dict) = current blog
 //set instance variable = current post
 //set instance variable == currentBlog value for key numberOfPostsToDisplay
	//Or keep this in a core data value or write it to disk
	
 
 
 }
 
 


#pragma mark -
#pragma mark Get More Posts/Refresh Posts


-(BOOL)getPostMetadata {
	
 
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
	NSLog(@"previous number of posts %d", previousNumberOfPosts);
	int max = previousNumberOfPosts + 10;
	NSNumber *numberOfPostsToGet = [NSNumber numberWithInt:max];

	
 XMLRPCRequest *postsMetadata = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:fullURL]];
 [postsMetadata setMethod:@"mt.getRecentPostTitles"
 withObjects:[NSArray arrayWithObjects:blogid, username, pwd, numberOfPostsToGet, nil]];
 
 id response = [dm executeXMLRPCRequest:postsMetadata byHandlingError:YES];
	NSLog(@"the response %@", response);
	//NSLog(@"the id, %@",postID);
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
//use the ids to build the system.multicall and get the next 10 posts
	
	int metadataCount = ((NSArray *)response).count;
	//bail if there was no new post metadata available - i.e. we got it all already.
	if (metadataCount == previousNumberOfPosts) {
		//TODO: JOHNB popup an alert view that says "All Posts have Been retrieved"
		return NO;
	}
	
	
	NSEnumerator *postsEnum = [response objectEnumerator];
	NSDictionary *postMetadataDict;
	//NSMutableDictionary *postRequestDict;
	NSInteger newPostCount = 0;
	NSMutableArray *getMorePostsArray = [[NSMutableArray alloc] init];
	NSString *postID = @"nil";
	
	while (postMetadataDict = [postsEnum nextObject]) {
		newPostCount ++;
		//if the old count of posts is less than the count of cycles through this loop, we're into the "new" data
		//less than total count of the returned array so we don't fall off the end
		//TODO: JOHNB TEST that a < 10 number of posts at the tail end of the total posts for a blog will pass through correctly
		NSLog(@"previousNumberofPosts %d", previousNumberOfPosts);
		NSLog(@"newPostCount  : %d", newPostCount);
		NSLog(@"metadataCount  : %d", metadataCount);
		
		if (previousNumberOfPosts < newPostCount && newPostCount <= metadataCount) {
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
	NSMutableArray *newPostTitlesList;
    NSString *postTitlesPath = [dm pathToPostTitles:currentBlog];
    NSFileManager *fm = [NSFileManager defaultManager];
	
    if ([fm fileExistsAtPath:postTitlesPath]) {
        newPostTitlesList = [NSMutableArray arrayWithContentsOfFile:postTitlesPath];
    } else {
        newPostTitlesList = [NSMutableArray arrayWithCapacity:30];
    }
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
       } else {
            [post setValue:@"original" forKey:@"local_status"];
            newPostCount++;
        }
		
        // write the new post
        [post writeToFile:pathToPost atomically:YES];
		NSLog(@"this is the post %@", post);
		
        // make a post title using the post
        NSMutableDictionary *postTitle = [dm postTitleForPost:post];
		//NSLog(@"postTitle %@", postTitle);
		//NSLog(@"posttitleslist count is: %d", [newPostTitlesList count]);
		
	
		//add the new post title to the list (shouldn't need to delete as all in here should be new)
        [newPostTitlesList addObject:postTitle];
		//NSLog(@"newposttitleslist %@", newPostTitlesList);
    }
	

    // sort and save the postTitles list
    NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"date_created_gmt" ascending:NO];
    [newPostTitlesList sortUsingDescriptors:[NSArray arrayWithObject:sd]];
    [sd release];
    [newPostTitlesList writeToFile:[dm pathToPostTitles:currentBlog]  atomically:YES];
			
    // increment blog counts and save blogs list
	//NSLog(@"posttitleslist count is: %d", [newPostTitlesList count]);
    [currentBlog setObject:[NSNumber numberWithInt:[newPostTitlesList count]] forKey:@"totalPosts"];
	[currentBlog setObject:[NSNumber numberWithInt:newPostCount] forKey:@"newposts"];
			
    NSInteger blogIndex = [dm indexForBlogid:[currentBlog valueForKey:kBlogId] hostName:[currentBlog valueForKey:kBlogHostName]];
	
    if (blogIndex >= 0) {
        //[dm->blogsList replaceObjectAtIndex:blogIndex withObject:currentBlog];
		[dm updateBlogsListByIndex:blogIndex withDict:currentBlog];
    } else {
		//		[self->blogsList addObject:blog];
    }
			
	[getMorePostsArray release];
    [currentBlog setObject:[NSNumber numberWithInt:0] forKey:@"kIsSyncProcessRunning"];
    [dm performSelectorOnMainThread:@selector(postBlogsRefreshNotificationInMainThread:) withObject:currentBlog waitUntilDone:NO];

	return YES;
}



	
}
@end

