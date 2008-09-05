#import "BlogDataManager.h"
#import "CoreGraphics/CoreGraphics.h"

#define kURL @"URL"
#define kMETHOD @"METHOD"
#define kMETHODARGS @"METHODARGS"

#define pictureData @"pictureData"
#define pictureStatus @"pictureStatus"
#define pictureCaption @"pictureCaption"
#define pictureInfo @"pictureInfo"
#define pictureSize @"pictureSize"
#define pictureFileSize @"pictureFileSize"
#define pictureURL @"pictureURL"

#define kNextDraftIdStr @"kNextDraftIdStr"
#define kDraftsCount @"kDraftsCount"

@interface BlogDataManager (private)

- (void) loadBlogData;
- (void) setBlogsList:(NSMutableArray *)newArray;
- (void) createDemoBlogData;
- (void) sortBlogData;

- (NSString *)blogDir:(id)forBlog;
- (NSString *)pathToPostTitles:(id)forBlog;
- (NSString *)pathToPost:(id)aPost forBlog:(id)aBlog;
- (NSString *)postFileName:(id)aPost;
- (NSString *)templatePathForBlog:(id)aBlog;
- (NSString *)commentsFolderPathForBlog:(id)aBlog;
- (NSString *)commentFilePath:(id)aComment forBlog:(id)aBlog;

- (void) loadPhotosDB;
- (void) createPhotosDB;
- (void) loadPostTitlesForCurrentBlog;
- (void) setPostTitlesList:(NSMutableArray *)newArray;
- (void) setCommentTitlesList:(NSMutableArray *)newArray;
- (NSInteger) indexOfPostTitle:(id)postTitle inList:(NSArray *)aPostTitlesList;

// set methods will release current and create mutable copy
- (void) setCurrentBlog:(NSMutableDictionary *)aBlog;
- (void) setCurrentPost:(NSMutableDictionary *)aPost;

- (NSMutableDictionary *) postTitleForPost:(NSDictionary *)aPost;
- (NSMutableDictionary *) commentTitleForComment:(NSDictionary *)aComment ;


- (void) sortPostsList;
//- (void) sortPostsListByAuthorAndDate;
- (void)setDraftTitlesList:(NSMutableArray *)newArray;


//argument should provide all required perameters for 
- (void)addAsyncOperation:(SEL)anOperation withArg:(id)anArg;


- (BOOL)deleteAllPhotosForPost:(id)aPost forBlog:(id)aBlog;
- (BOOL)deleteAllPhotosForCurrentPostBlog;

@end

@implementation BlogDataManager

static BlogDataManager *sharedDataManager;

@synthesize blogFieldNames, blogFieldNamesByTag, blogFieldTagsByName, 
pictureFieldNames, postFieldNames, postFieldNamesByTag, postFieldTagsByName,
postTitleFieldNames, postTitleFieldNamesByTag, postTitleFieldTagsByName,
currentBlog, currentPost, currentDirectoryPath, photosDB, currentPicture, isLocaDraftsCurrent, currentPostIndex, currentDraftIndex;




- (void)dealloc {
	
	WPLog(@"retain count for blogsList at dealloc is %d", [blogsList retainCount]);
	[blogsList release];
	[currentBlog release];
	[postTitlesList release];
	[currentPost release];
	[currentDirectoryPath release];
	
	[photosDB release];
	[currentPicture release];
	
	[blogFieldNames release];
	[blogFieldNamesByTag release];
	[blogFieldTagsByName release];
	
	[pictureFieldNames release];
	
	[postTitleFieldNames release];
	[postTitleFieldNamesByTag release];
	[postTitleFieldTagsByName release];
	
	[postFieldNames release];
	[postFieldNamesByTag release];
	[postFieldTagsByName release];
	
	[asyncOperationsQueue release];
	[super dealloc];
}


// Initialize the singleton instance if needed and return
+(BlogDataManager *)sharedDataManager
{
//	@synchronized(self)
	{
		if (!sharedDataManager)
			sharedDataManager = [[BlogDataManager alloc] init];
		
		return sharedDataManager;
	}
}

+(id)alloc
{
//	@synchronized(self)
	{
		NSAssert(sharedDataManager == nil, @"Attempted to allocate a second instance of a singleton.");
		sharedDataManager = [super alloc];
		return sharedDataManager;
	}
}

+(id)copy
{
//	@synchronized(self)
	{
		NSAssert(sharedDataManager == nil, @"Attempted to copy the singleton.");
		return sharedDataManager;
	}
}

+ (void)initialize
{
    static BOOL initialized = NO;
    if (!initialized) {
		// Load any previously archived blog data
		[[BlogDataManager sharedDataManager] loadBlogData];

        initialized = YES;
    }
}

- (id)init
{
	if( self = [super init] )
	{
		asyncOperationsQueue = [[NSOperationQueue alloc] init];
		[asyncOperationsQueue setMaxConcurrentOperationCount:2];
		
		// Set current directory for Wordpress app
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		self.currentDirectoryPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"wordpress"];
		
		BOOL isDir;
		if (![fileManager fileExistsAtPath:self.currentDirectoryPath isDirectory:&isDir] || !isDir) {
			[fileManager createDirectoryAtPath:self.currentDirectoryPath attributes:nil];
		}
		// set the current dir
		[fileManager changeCurrentDirectoryPath:self.currentDirectoryPath];
		WPLog(@"current directory is set to : %@", [fileManager currentDirectoryPath]);
		
		// allocate lists
//		self->blogsList = [[NSMutableArray alloc] initWithCapacity:10];
//		self->postTitlesList = [[NSMutableArray alloc] initWithCapacity:50];
//		self->draftTitlesList = [[NSMutableArray alloc] initWithCapacity:50];
//		
	}
	return self;
}



#pragma mark - XMLRPC

- (NSError *)defaultError
{
	NSDictionary *usrInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"Failed to request the server.", NSLocalizedDescriptionKey, nil];
	return [NSError errorWithDomain:@"com.effigent.iphone.wordpress" code:-1 userInfo:usrInfo];
}

- (BOOL)handleError:(NSError *)err
{
//	WPLog(@"handleError ......");
	UIAlertView *alert1 = [[UIAlertView alloc] initWithTitle:@"Communication Error"
													 message:[err localizedDescription]
													delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	
	[alert1 show];
	[alert1 release];
	return YES;
}

- (NSError *)errorWithResponse:(XMLRPCResponse *)res shouldHandle:(BOOL)shouldHandleFlag
{
	NSError *err = nil;
	if( !res )
		err = [self defaultError];

	if ( [res isKindOfClass:[NSError class]] )
		err = (NSError *)res;
	else
	{
		if ( [res isFault] )
		{
			NSDictionary *usrInfo = [NSDictionary dictionaryWithObjectsAndKeys:[res fault], NSLocalizedDescriptionKey, nil];
			err = [NSError errorWithDomain:@"com.effigent.iphone.wordpress" code:[[res code] intValue] userInfo:usrInfo];
		}
		
		if ( [res isParseError] )
		{
			err = [res object];
		}		
	}
	
	if( err && shouldHandleFlag )
	{
		// patch to eat the zero posts error
		// "Either there are no posts, or something went wrong."
//		WPLog(@"XML RPC Error: %@", [err description]);
		
		NSString *zeroPostsError = @"Either there are no posts, or something went wrong.";
		NSRange range = [[err description] rangeOfString:zeroPostsError options:NSBackwardsSearch];
		if (range.location == NSNotFound) {
			[self handleError:err]; 
		} else {
			return [NSMutableArray array];
		}
	}
	
	return err;
}




- (id)executeXMLRPCRequest:(XMLRPCRequest *)req byHandlingError:(BOOL)shouldHandleFalg
{
	WPLog(@"XMLRPC sendSynchronousXMLRPCRequest %@", [req method]);
	XMLRPCResponse *userInfoResponse = [XMLRPCConnection sendSynchronousXMLRPCRequest:req];
	NSError *err = [self errorWithResponse:userInfoResponse shouldHandle:shouldHandleFalg];
	WPLog(@"END XMLRPC sendSynchronousXMLRPCRequest %@", [req method]);
	if( err )
		return err;
	
	return [userInfoResponse object];
}

#pragma mark -
#pragma mark async

//

- (void)addAsyncOperation:(SEL)anOperation withArg:(id)anArg
{	
	if( ![self respondsToSelector:anOperation] )
	{
		WPLog(@"ERROR: %@ can't respond to the Operation %@.", @"Blog Data Manager", NSStringFromSelector(anOperation));
		return;
	}
	
	NSInvocationOperation *op = [[NSInvocationOperation alloc] initWithTarget:self selector:anOperation object:anArg];
	[asyncOperationsQueue addOperation:op];
	[op release];
}

#pragma mark -

//syncronous method
//you can access the current context.
- (void)addSendPictureMsgToQueue:(id)aPicture
{	
	WPLog(@"addSendPictureMsgToQueue");
	//create args
	NSData *pictData = UIImagePNGRepresentation([aPicture valueForKey:@"pictureData"]);
	if( pictData == nil )
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
														message:@"Invalid Image. Unable to Upload to the server." 
													   delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		
		[alert show];
		[alert release];
		return;
	}
	
	//test code
	if( ![self countOfBlogs] )
	{
		WPLog(@"NOTE: addSendPictureMsgToQueue Rejected ... as no blogs exist.");
		return;
	}
	
//	[self makeBlogAtIndexCurrent:[self countOfBlogs]-1];
//	WPLog(@"currentBlog %@",currentBlog);

	if( !currentBlog )
	{
		WPLog(@"NOTE: addSendPictureMsgToQueue Rejected ... as no Current Blog exist.");
		return;
	}
	
//	NSString *name = [[[aPicture valueForKey:@"pictureFilePath"] stringByDeletingPathExtension] lastPathComponent];
//	name = ( name == nil ? @"", name );

	NSString *desc = [aPicture valueForKey:@"pictureCaption"];
	desc = ( desc == nil ? @"" : desc );
	
	NSString *name = [aPicture valueForKey:@"pictureCaption"];
	name = ( name == nil ? @"iphoneImage.png" : [name stringByAppendingFormat:@".png"] );

	NSString *categories = nil;//[aPicture valueForKey:@"pictureCaption"];
	categories = ( categories == nil ? [NSArray array] : categories );

	NSMutableDictionary *imageParms = [NSMutableDictionary dictionary];
	[imageParms setValue:@"image/png" forKey:@"type"];
	[imageParms setValue:pictData forKey:@"bits"];
	[imageParms setValue:name forKey:@"name"];
	[imageParms setValue:categories forKey:@"categories"];
	[imageParms setValue:desc forKey:@"description"];
	
	NSArray *args = [NSArray arrayWithObjects:[currentBlog valueForKey:@"blogid"],
					 [currentBlog valueForKey:@"username"],
					 [currentBlog valueForKey:@"pwd"],
					 imageParms,
					 nil
					 ];
	
	NSMutableDictionary *params = [NSMutableDictionary dictionary];
	[params setObject:[currentBlog valueForKey:@"xmlrpc"] forKey:kURL];
	[params setObject:@"metaWeblog.newMediaObject" forKey:kMETHOD];
	[params setObject:args forKey:kMETHODARGS];

	//method specific values
	[params setObject:aPicture forKey:@"pictureObj"];
	[aPicture setValue:[NSNumber numberWithInt:1] forKey:pictureStatus];

	[self addAsyncOperation:@selector(sendPictureAsyncronously:) withArg:params];
}

//asyncronous method
//you have to get every thing with the arg prepared by the syncronous method
- (void)sendPictureAsyncronously:(id)aPictureInfo
{
	//create an xmlrpc request
	//perform the operation
	//if success then update the picture object.
//	[[aPictureInfo valueForKey:@"pictureObj"] setValue:[NSNumber numberWithInt:1] forKey:pictureStatus];

	XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:[aPictureInfo valueForKey:kURL]]];
	[request setMethod:[aPictureInfo valueForKey:kMETHOD] withObjects:[aPictureInfo valueForKey:kMETHODARGS]];
	
	id response = [self executeXMLRPCRequest:request byHandlingError:YES];
	id pictObj = [aPictureInfo valueForKey:@"pictureObj"];
	WPLog(@"response %@", response);
	[request release];
//	XMLRPCResponse *response = [XMLRPCConnection sendSynchronousXMLRPCRequest:request];
	if( [response isKindOfClass:[NSError class]] )
	{
		WPLog(@"ERROR Occured %@", [response fault]);
		[pictObj setValue:[response fault] forKey:@"faultString"];
		[pictObj setValue:[NSNumber numberWithInt:-1] forKey:pictureStatus];
	}
	else
	{
		[pictObj setValue:[NSNumber numberWithInt:2] forKey:pictureStatus];
		[pictObj removeObjectForKey:@"faultString"];
		[pictObj setValue:[response valueForKey:@"url"] forKey:pictureURL];
//		[pictObj setValue:[response valueForKey:@"file"] forKey:pictureURL];
//		[pictObj setValue:[response valueForKey:@"type"] forKey:pictureURL];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:PictureObjectUploadedNotificationName object:pictObj];
	return;
}

- (void)addSyncPostsForBlogToQueue:(id)aBlog
{
	[aBlog setObject:[NSNumber numberWithInt:1] forKey:@"kIsSyncProcessRunning"];
	//TODO: Raise a notification so that post titles will reload data. if this blog is currently viewed.
	[self addAsyncOperation:@selector(syncPostsForBlog:) withArg:aBlog];
}

- (void)syncPostsForAllBlogsToQueue:(id)sender
{
	int i, countOfBlogs = [self countOfBlogs];
	for( i=1; i < countOfBlogs; i++ )
	{
		[self addSyncPostsForBlogToQueue:[blogsList objectAtIndex:i]];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:@"BlogsRefreshNotification" object:nil userInfo:nil];
}

#pragma mark -
#pragma mark Picture metadata

- (NSArray *)pictureFieldNames {	
	if (!pictureFieldNames) {
		self->pictureFieldNames = [NSArray arrayWithObjects:@"pictureFilePath", @"pictureStatus", @"pictureCaption",@"pictureInfo",@"pictureName",nil];
		[pictureFieldNames retain];
	}
	return pictureFieldNames;
}

- (NSString *)pictureURLBySendingToServer:(UIImage *)pict
{
	NSData *pictData = UIImagePNGRepresentation(pict);
	if( pictData == nil )
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
														message:@"Invalid Image. Unable to Upload to the server." 
													   delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		
		[alert show];
		return nil;
	}
	
	NSMutableDictionary *imageParms = [NSMutableDictionary dictionary];
	[imageParms setValue:@"image/png" forKey:@"type"];
	[imageParms setValue:pictData forKey:@"bits"];
	[imageParms setValue:@"iPhoneImage.png" forKey:@"name"];
	//	[imageParms setValue:categories forKey:@"categories"];
	//	[imageParms setValue:desc forKey:@"description"];
	
	id blog = [self blogForId:[currentPost valueForKey:@"blogid"] hostName:[currentPost valueForKey:@"blog_host_name"]];

	NSArray *args = [NSArray arrayWithObjects:[blog valueForKey:@"blogid"],
					 [blog valueForKey:@"username"],
					 [blog valueForKey:@"pwd"],
					 imageParms,
					 nil
					 ];
	
	XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:[blog valueForKey:@"xmlrpc"]]];
	[request setMethod:@"metaWeblog.newMediaObject" withObjects:args];
	
	id response = [self executeXMLRPCRequest:request byHandlingError:YES];
	[request release];
	
	if( [response isKindOfClass:[NSError class]] )
	{
		WPLog(@"ERROR Occured %@", response);
		return nil;
	}
	else
	{
		return [response valueForKey:@"url"];
	}
	
	return nil;
}

- (NSString *)pictureURLForPicturePathBySendingToServer:(NSString *)filePath
{
//	UIImage *pict = [UIImage imageWithContentsOfFile:filePath];
		//UIImagePNGRepresentation(pict);s
	NSData *pictData = [NSData dataWithContentsOfFile:filePath];
	WPLog(@"pictData leng %d", [pictData length]);
	if( pictData == nil )
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
														message:@"Invalid Image. Unable to Upload to the server." 
													   delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		
		[alert show];
		return nil;
	}

	NSMutableDictionary *imageParms = [NSMutableDictionary dictionary];
	[imageParms setValue:@"image/jpeg" forKey:@"type"];
	[imageParms setValue:pictData forKey:@"bits"];
	[imageParms setValue:[filePath lastPathComponent] forKey:@"name"];
	//	[imageParms setValue:categories forKey:@"categories"];
	//	[imageParms setValue:desc forKey:@"description"];
	
	id blog = [self blogForId:[currentPost valueForKey:@"blogid"] hostName:[currentPost valueForKey:@"blog_host_name"]];
//	WPLog(@"retrived blog from current post %@", blog);
	
	NSArray *args = [NSArray arrayWithObjects:[blog valueForKey:@"blogid"],
					 [blog valueForKey:@"username"],
					 [blog valueForKey:@"pwd"],
					 imageParms,
					 nil
					 ];
	
	XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:[blog valueForKey:@"xmlrpc"]]];
	[request setMethod:@"metaWeblog.newMediaObject" withObjects:args];
	
	id response = [self executeXMLRPCRequest:request byHandlingError:YES];
	[request release];
	if( [response isKindOfClass:[NSError class]] )
	{
		WPLog(@"ERROR Occured %@", response);
		return nil;
	}
	else
	{
		return [response valueForKey:@"url"];
	}
	
	return nil;
}

- (BOOL)postDescriptionHasValidDescription:(id)aPost
{
//	return [[WPXMLValidator sharedValidator] isValidXMLString:[aPost valueForKey:@"description"]];
	return YES;
}

- (NSString *)imageTagForPath:(NSString *)path andURL:(NSString *)urlStr
{
	NSArray *comps = [path componentsSeparatedByString:@"_"];

	float width, height;
	if( [path hasPrefix:@"l"] )
	{
		width = [[comps objectAtIndex:1] floatValue];
		height = [[comps objectAtIndex:2] floatValue];
	}
	else {
		width = [[comps objectAtIndex:2] floatValue];
		height = [[comps objectAtIndex:1] floatValue];
	}

	float kMaxResolution = 300.0f; // Or whatever
	if (width > kMaxResolution || height > kMaxResolution) {
		float ratio = width/height;

		if (ratio > 1.0) {
			width = kMaxResolution;
			height = (width / ratio);
		}
		else {

			height = kMaxResolution;
			width = (height * ratio);
		}
	}
	
	return [NSString stringWithFormat:@"<img src=\"%@\" alt=\"\" width=\"%d\" height=\"%d\" class=\"alignnone size-full wp-image-364\" />", urlStr, (int)width, (int)height ];
}

- (BOOL)appendImagesOfCurrentPostToDescription
{
	NSMutableArray *photos = [currentPost valueForKey:@"Photos"];
	int i, count = [photos count];
	NSString *curPath = nil;
//	WPLog(@"appendImagesOfCurrentPostToDescription. %u", currentPost);
	
	NSString *desc = [currentPost valueForKey:@"description"];
	BOOL firstImage = YES;
	BOOL paraOpen = NO;

	for( i=count-1; i >=0 ; i-- )
	{
		curPath = [photos objectAtIndex:i];
		NSString *filePAth = [NSString stringWithFormat:@"%@/%@",[self blogDir:currentBlog], curPath];
		NSAutoreleasePool *ap = [[NSAutoreleasePool alloc] init];
		NSString *urlStr = [self pictureURLForPicturePathBySendingToServer:filePAth];
		[urlStr retain];
		[ap release];
		[urlStr autorelease];
		if( !urlStr )
			return NO;
		else 
		{
			NSString *imgTag = [self imageTagForPath:curPath andURL:urlStr];
			if (firstImage) {
				desc = [desc  stringByAppendingString:@"\n<p>"];
				paraOpen = YES;
				desc = [desc stringByAppendingString:[NSString stringWithFormat:@"<a href=\"%@\">%@</a>", urlStr, imgTag]];
				firstImage = NO;
			} else {
			
				desc = [desc stringByAppendingString:[NSString stringWithFormat:@"<br /><br /><a href=\"%@\">%@</a>",urlStr, imgTag]];
			}
			[self deleteImageNamed:curPath forBlog:currentBlog];
			[photos removeLastObject];
		}
	}
	
	if (paraOpen)
		desc = [desc  stringByAppendingString:@"</p>"];
	
	[currentPost setObject:desc forKey:@"description"];
	
	
	return YES;
}

#pragma mark File Paths

//TODO: Why can't we create complete folder structure when we save the blog?
// So that we can reduse the file system references.
- (NSString *)blogDir:(id)aBlog
{
	NSString *blogHostDir = [currentDirectoryPath stringByAppendingPathComponent:[aBlog objectForKey:@"blog_host_name"]];
	// note that when the local drafts is set as current blog, a fake blogid "localdrafts" is used
	// this will resolve to a dir called "localdrafts" which is what we want
	NSString *blogDir = [blogHostDir stringByAppendingPathComponent:[aBlog objectForKey:@"blogid"]];
	NSString *localDraftsDir = [blogDir stringByAppendingPathComponent:@"localDrafts"];

	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL isDirectory;
	if( !([fm fileExistsAtPath:blogDir isDirectory:&isDirectory] && isDirectory) )
	{
		// [fm createDirectoryAtPath:blogHostDir attributes:nil];
		[fm createDirectoryAtPath:blogHostDir withIntermediateDirectories:YES attributes:nil error:nil];
		[fm createDirectoryAtPath:blogDir attributes:nil];
		[fm createDirectoryAtPath:localDraftsDir attributes:nil];
	}
	return blogDir;
}

- (NSString *)templatePathForBlog:(id)aBlog
{
	return [NSString stringWithFormat:@"%@/template.html",[self blogDir:aBlog]];
}

- (NSString *)autoSavePathForTheCurrentBlog
{
	return [[self blogDir:currentBlog] stringByAppendingFormat:@"/autoSavedPost.archive"];
}

- (BOOL)clearAutoSavedContext
{
	id aPost = [self autoSavedPostForCurrentBlog];
	[self deleteAllPhotosForPost:aPost forBlog:currentBlog];
	
	NSString *fp = [self autoSavePathForTheCurrentBlog];
	if( fp )
		return [[NSFileManager defaultManager] removeItemAtPath:fp error:NULL];
	
	return NO;	
}

- (BOOL)removeAutoSavedCurrentPostFile
{
	NSString *fp = [self autoSavePathForTheCurrentBlog];
	if( fp )
		return [[NSFileManager defaultManager] removeItemAtPath:fp error:NULL];
	
	return YES;
}

- (NSString *)pathToPostTitles:(id)aBlog
{
	NSString *pathToPostTitles = [[self blogDir:aBlog] stringByAppendingPathComponent:@"postTitles.archive"];	
	return pathToPostTitles;
}

- (NSString *)pathToCommentTitles:(id)aBlog
{
	NSString *pathToCommentTitles = [[self blogDir:aBlog] stringByAppendingPathComponent:@"commentTitles.archive"];	
	return pathToCommentTitles;
}

- (NSString *)pathToPost:(id)aPost forBlog:(id)aBlog
{
	NSString *pathToPost = [[self blogDir:aBlog] stringByAppendingPathComponent:[self postFileName:aPost]];
	return pathToPost;
}

- (NSString *)draftsPathForBlog:(id)aBlog
{
	NSString *draftsPath = [[self blogDir:aBlog] stringByAppendingPathComponent:@"localDrafts"];	
	return draftsPath;
}

- (NSString *)pathToDraftTitlesForBlog:(id)aBlog
{
	NSString *pathToDraftTitles = [[self draftsPathForBlog:aBlog] stringByAppendingPathComponent:@"draftTitles.archive"];	
	return pathToDraftTitles;
}

- (NSString *)pathToDraft:(id)aDraft forBlog:(id)aBlog
{
	NSString *draftid = [aDraft valueForKey:@"draftid"];
	NSString *draftFileName = [NSString stringWithFormat:@"draft.%@.archive", draftid];
	NSString *pathToDraft = [[self draftsPathForBlog:aBlog] stringByAppendingPathComponent:draftFileName];
	
//	WPLog(@"pathToDraft %@", pathToDraft);
	return pathToDraft;
}

- (NSString *)postFileName:(id)aPost 
{
	NSString *postid = [aPost valueForKey:@"postid"];
	NSString *postFileName = [NSString stringWithFormat:@"post.%@.archive", postid];
	return postFileName;
}

- (NSString *)commentsFolderPathForBlog:(id)aBlog
{
	NSString *commentsFolderPath = [[self blogDir:aBlog] stringByAppendingPathComponent:@"Comments"];	
	return commentsFolderPath;
}

- (NSString *)commentFilePath:(id)aComment forBlog:(id)aBlog
{
	NSString *comment_id = [aComment valueForKey:@"comment_id"];
	NSString *commentFileName = [NSString stringWithFormat:@"comment.%@.archive", comment_id];
	NSString *commentFilePath = [[self blogDir:aBlog] stringByAppendingPathComponent:commentFileName];
	return commentFilePath;
}

#pragma mark -
#pragma mark Blog metadata

- (NSArray *)blogFieldNames {
	
	if (!blogFieldNames) {

		self->blogFieldNames = [NSArray arrayWithObjects:@"url", @"username", @"blog_host_name",@"blog_host_software",
														@"isAdmin",@"blogid",@"blogName",@"xmlrpc",
														@"nickname",@"userid",@"lastname",@"firstname",
														@"newposts",@"totalposts",
														@"newcomments",@"totalcomments", @"xmlrpcsuffix",@"pwd", kPostsDownloadCount, nil];
		[blogFieldNames retain];
	
	}
	
	return blogFieldNames;
}



- (NSDictionary *)blogFieldNamesByTag {
	
	if(!blogFieldNamesByTag) {
		NSNumber *tag0 = [NSNumber numberWithInt:100];
		NSNumber *tag1 = [NSNumber numberWithInt:101];
		NSNumber *tag2 = [NSNumber numberWithInt:102];
		NSNumber *tag3 = [NSNumber numberWithInt:103];
		NSNumber *tag4 = [NSNumber numberWithInt:104];
		NSNumber *tag5 = [NSNumber numberWithInt:105];
		NSNumber *tag6 = [NSNumber numberWithInt:106];
		NSNumber *tag7 = [NSNumber numberWithInt:107];
		NSNumber *tag8 = [NSNumber numberWithInt:108];
		NSNumber *tag9 = [NSNumber numberWithInt:109];
		NSNumber *tag10 = [NSNumber numberWithInt:110];
		NSNumber *tag11 = [NSNumber numberWithInt:111];
		NSNumber *tag12 = [NSNumber numberWithInt:112];
		NSNumber *tag13 = [NSNumber numberWithInt:113];
		NSNumber *tag14 = [NSNumber numberWithInt:114];
		NSNumber *tag15 = [NSNumber numberWithInt:115];
		NSNumber *tag16 = [NSNumber numberWithInt:116];
		NSNumber *tag17 = [NSNumber numberWithInt:117];
		
		NSArray *tags = [NSArray arrayWithObjects:tag0, tag1, tag2, tag3, tag4, tag5, tag6, tag7, tag8, tag9, tag10, 
							tag11,tag12,tag13,tag14,tag15,tag16, tag17, nil];
		self->blogFieldNamesByTag = [NSDictionary dictionaryWithObjects:[self blogFieldNames] forKeys:tags];
		
		[blogFieldNamesByTag retain];

	}

	return blogFieldNamesByTag;
}

- (NSDictionary *)blogFieldTagsByName {
	
	if(!blogFieldTagsByName) {
		
		NSNumber *tag0 = [NSNumber numberWithInt:100];
		NSNumber *tag1 = [NSNumber numberWithInt:101];
		NSNumber *tag2 = [NSNumber numberWithInt:102];
		NSNumber *tag3 = [NSNumber numberWithInt:103];
		NSNumber *tag4 = [NSNumber numberWithInt:104];
		NSNumber *tag5 = [NSNumber numberWithInt:105];
		NSNumber *tag6 = [NSNumber numberWithInt:106];
		NSNumber *tag7 = [NSNumber numberWithInt:107];
		NSNumber *tag8 = [NSNumber numberWithInt:108];
		NSNumber *tag9 = [NSNumber numberWithInt:109];
		NSNumber *tag10 = [NSNumber numberWithInt:110];
		NSNumber *tag11 = [NSNumber numberWithInt:111];
		NSNumber *tag12 = [NSNumber numberWithInt:112];
		NSNumber *tag13 = [NSNumber numberWithInt:113];
		NSNumber *tag14 = [NSNumber numberWithInt:114];
		NSNumber *tag15 = [NSNumber numberWithInt:115];
		NSNumber *tag16 = [NSNumber numberWithInt:116];
		NSNumber *tag17 = [NSNumber numberWithInt:117];
		
		NSArray *tags = [NSArray arrayWithObjects:tag0, tag1, tag2, tag3, tag4, tag5, tag6, tag7, tag8, tag9, tag10,
							tag11,tag12,tag13,tag14,tag15, tag16, tag17, nil];
		self->blogFieldTagsByName = [NSDictionary dictionaryWithObjects:tags forKeys:[self blogFieldNames]];
		
		[blogFieldTagsByName retain];
		
	}
	
	return blogFieldTagsByName;
}


#pragma mark Blog data

- (NSString *)xmlurl:(NSString *)hosturl
{
	NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:hosturl]
											  cachePolicy:NSURLRequestUseProtocolCachePolicy							  
										  timeoutInterval:60.0];			
	NSData *data = [NSURLConnection sendSynchronousRequest:theRequest returningResponse:NULL error:NULL];
	
	// NSString *xmlstr = [NSString stringWithUTF8String:[data bytes]];
	NSString *xmlstr = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
//	WPLog(@"xmlstr %@", xmlstr);
	
	if( [data length] > 0 )
	{
		NSRange range1 = [xmlstr rangeOfString:@"preferred=\"true\""];
//		WPLog(@"range %@", NSStringFromRange(range1));
		if (range1.location != NSNotFound) {
			NSRange lr1 = NSMakeRange(range1.location, [xmlstr length]-range1.location);
	//		WPLog(@"lr %@", NSStringFromRange(lr1));
			
			NSRange endRange1 = [xmlstr rangeOfString:@"/>" options:NSLiteralSearch range:lr1];
	//		WPLog(@"endRange %@", NSStringFromRange(endRange1));
			if (endRange1.location != NSNotFound) {
				NSString *ourStr = [xmlstr substringWithRange:NSMakeRange(range1.location, endRange1.location-range1.location)];
		//		WPLog(@"ourStr %@", ourStr);
				
				ourStr = [ourStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
				ourStr = [ourStr substringWithRange:NSMakeRange(0, [ourStr length]-1)];
				NSRange r1 = [ourStr rangeOfString:@"\"" options:NSBackwardsSearch];
				if (r1.location != NSNotFound) {
					NSString *xmlrpcurl = [ourStr substringWithRange:NSMakeRange(r1.location+1, [ourStr length]-r1.location-1)];			
			//		WPLog(@"xmlrpcurl %@", xmlrpcurl);
					return xmlrpcurl;
				}
			}
		}
	}
	return nil;
}

- (NSString *)discoverxmlrpcurlForurl:(NSString *)urlstr
{
	urlstr = [NSString stringWithFormat:@"http://%@", urlstr];
//	WPLog(@"url str %@", urlstr);
	NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:urlstr]
											  cachePolicy:NSURLRequestUseProtocolCachePolicy							  
										  timeoutInterval:60.0];			
	NSData *data = [[NSURLConnection sendSynchronousRequest:theRequest returningResponse:NULL error:NULL] retain];
	if( [data length] > 0 )
	{
		//NSString *htmlStr = [NSString stringWithUTF8String:[data bytes]];
		NSString *htmlStr = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
//		WPLog(@"htmlStr %@", htmlStr);

		NSRange range = [htmlStr rangeOfString:@"EditURI"];
		if (range.location != NSNotFound) {
			NSRange lr = NSMakeRange(range.location, [htmlStr length]-range.location);
			NSRange endRange = [htmlStr rangeOfString:@"/>" options:NSLiteralSearch range:lr];
			if (endRange.location != NSNotFound) {
				NSString *ourStr = [htmlStr substringWithRange:NSMakeRange(range.location, endRange.location-range.location)];
				ourStr = [ourStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
				ourStr = [ourStr substringWithRange:NSMakeRange(0, [ourStr length]-1)];
				NSRange r = [ourStr rangeOfString:@"\"" options:NSBackwardsSearch];
				if (r.location != NSNotFound) {
					NSString *hosturl = [ourStr substringWithRange:NSMakeRange(r.location+1, [ourStr length]-r.location-1)];
		//			WPLog(@"hosturl %@", hosturl);
					if( hosturl != nil )
						[data release];
						return [self xmlurl:hosturl];
				}
			}
		}
		
	}
	[data release];
	return nil;
}

- (BOOL)validateCurrentBlog:(NSString *)url user:(NSString *)username password:(NSString*)pwd 
{	
	NSString *blogURL = [NSString stringWithFormat:@"http://%@", url];
	NSString *xmlrpc = [self discoverxmlrpcurlForurl:url];
	if (!xmlrpc) {
		xmlrpc = [blogURL stringByAppendingString:[currentBlog valueForKey:@"xmlrpcsuffix"]];
	}
	//  ------------------------- invoke login & getUserInfo
	
	XMLRPCRequest *reqUserInfo = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:xmlrpc]];
	[reqUserInfo setMethod:@"blogger.getUserInfo" withObjects:[NSArray arrayWithObjects:@"ABCDEF012345",username,pwd,nil]];
	
	NSDictionary *userInfo = [self executeXMLRPCRequest:reqUserInfo byHandlingError:YES];
	[reqUserInfo release];
	
	if( ![userInfo isKindOfClass:[NSDictionary class]] ) //err occured.
		return NO;
	return YES;
}

- (int)checkXML_RPC_URL_IsRunningSupportedVersionOfWordPress:(NSString *)xmlrpcurl
{
	XMLRPCRequest *listMethodsReq = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:xmlrpcurl]];
	[listMethodsReq setMethod:@"system.listMethods" withObjects:[NSArray array]];
	NSArray *listOfMethods = [self executeXMLRPCRequest:listMethodsReq byHandlingError:YES];
	[listMethodsReq release];
	
	if( [listOfMethods isKindOfClass:[NSError class]] )
		return -1;
	
	if( [listOfMethods containsObject:@"wp.getPostStatusList"] && [listOfMethods containsObject:@"blogger.getUserInfo"] && 
	   [listOfMethods containsObject:@"metaWeblog.newMediaObject"] && [listOfMethods containsObject:@"blogger.getUsersBlogs"] &&
	   [listOfMethods containsObject:@"wp.getAuthors"] && [listOfMethods containsObject:@"metaWeblog.getRecentPosts"] &&
	   [listOfMethods containsObject:@"metaWeblog.getPost"] &&
	   [listOfMethods containsObject:@"metaWeblog.newPost"] && [listOfMethods containsObject:@"metaWeblog.editPost"] &&
	   [listOfMethods containsObject:@"metaWeblog.deletePost"] && [listOfMethods containsObject:@"wp.newCategory"] &&
	   [listOfMethods containsObject:@"wp.deleteCategory"] && [listOfMethods containsObject:@"wp.getCategories"] )
		return 1;
	
	return 0;
}

/*
 Get blog data from host
 */
- (BOOL) refreshCurrentBlog:(NSString *)url user:(NSString *)username password:(NSString*)pwd 
{	
	// REFACTOR login method in BlogDetailModalViewControler so that all XML rpc interaction is handled from here
	// report exceptions back to caller
	// 1. test connection and xmlrpc call using blogger.getUserInfo
	// 2. update current blog with user info
	// 3. getUsersBlogs
	// 4. getAuthors
	// 5. get Categories
	// 6. get Statuses
	
	// Can have multiple usernames registered for the same blog
	NSString *blogHost = [NSString stringWithFormat:@"%@_%@", username, url];
	
	// Important: This is the only place where blog_host_name should be set
	// We use this as the blog folder name
	[currentBlog setValue:blogHost forKey:@"blog_host_name"];
	
	NSString *blogURL = [NSString stringWithFormat:@"http://%@", url];
	[currentBlog setValue:(blogURL?blogURL:@"") forKey:@"url"];
	
	NSString *xmlrpc = [self discoverxmlrpcurlForurl:url];
	if (!xmlrpc) {
		UIAlertView *rsdError = [[UIAlertView alloc] initWithTitle:@"We could not find the XML-RPC service for your blog. Please check your network connection and try again. if the problem persists, please visit \"iphone.wordpress.org\" to report the problem."
																	   message:nil
																	  delegate:[[UIApplication sharedApplication] delegate]
															 cancelButtonTitle:@"Visit Site"
															 otherButtonTitles:@"OK", nil];
		rsdError.tag = kRSDErrorTag;
		[rsdError show];
		[rsdError release];
		return NO;
	}
	
	int versionCheck = [self checkXML_RPC_URL_IsRunningSupportedVersionOfWordPress: xmlrpc];
	if( versionCheck < 0 )
		return NO;
	if( versionCheck == 0 )
	{
		UIAlertView *unsupportedWordpress = [[UIAlertView alloc] initWithTitle:@"Sorry, you appear to be running an older version of WordPress that is not supported by this app. Please visit \"iphone.wordpress.org\" for details."
																	   message:nil
																	  delegate:[[UIApplication sharedApplication] delegate]
															 cancelButtonTitle:@"Visit Site"
															 otherButtonTitles:@"OK", nil];
		unsupportedWordpress.tag = kUnsupportedWordpressVersionTag;
		[unsupportedWordpress show];
		[unsupportedWordpress release];
		return NO;
	}
	
	[currentBlog setValue:xmlrpc?xmlrpc:@"" forKey:@"xmlrpc"];
	[currentBlog setValue:(username?username:@"") forKey:@"username"];
	
	//  ------------------------- invoke login & getUserInfo
	
	WPLog(@"xmlrpc url %@" ,[NSURL URLWithString:xmlrpc] );
	
	XMLRPCRequest *reqUserInfo = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:xmlrpc]];
	[reqUserInfo setMethod:@"blogger.getUserInfo" withObjects:[NSArray arrayWithObjects:@"ABCDEF012345",username,pwd,nil]];
	
	NSDictionary *userInfo = [self executeXMLRPCRequest:reqUserInfo byHandlingError:YES];
	[reqUserInfo release];
	
	if( ![userInfo isKindOfClass:[NSDictionary class]] ) //err occured.
		return NO;

	// save values returned by getUserInfo into current blog
	NSString *nickname = [userInfo valueForKey:@"nickname"];
	[currentBlog setValue:nickname?nickname:@"" forKey:@"nickname"];
	
	NSString *userid = [userInfo valueForKey:@"userid"];
	[currentBlog setValue:userid?userid:@"" forKey:@"userid"];
	
	NSString *lastname = [userInfo valueForKey:@"lastname"];
	[currentBlog setValue:lastname?lastname:@"" forKey:@"lastname"];
	
	NSString *firstname = [userInfo valueForKey:@"firstname"];
	[currentBlog setValue:firstname?firstname:@"" forKey:@"firstname"];
	
	// ------------------------------invoke blogger.getUsersBlogs
	
	XMLRPCRequest *reqUsersBlogs = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:xmlrpc]];
	[reqUsersBlogs setMethod:@"blogger.getUsersBlogs" withObjects:[NSArray arrayWithObjects:@"ABCDEF012345",username,pwd,nil]];

	// we are expecting an array to be returned in the response with one dictionary containing 
	// the blog located by url used at login
	// If there is a fault, the returned object will be a dictionary with a fault element.
	// If the returned object is a NSArray, the, the object at index 0 will be the dictionary with blog info fields
	
	NSArray *usersBlogsResponseArray = [self executeXMLRPCRequest:reqUsersBlogs byHandlingError:YES];
	if( ![usersBlogsResponseArray isKindOfClass:[NSArray class]] )
		return NO;

	NSDictionary *usersBlogs = [usersBlogsResponseArray objectAtIndex:0];

	// load blog fields into currentBlog
	NSString *blogid = [usersBlogs valueForKey:@"blogid"];
	[currentBlog setValue:blogid?blogid:@"" forKey:@"blogid"];
	
	// blog id is unique within blog_host_ which = <username>_<blogURL>
	id existingBlog = [self blogForId:blogid hostName:[currentBlog valueForKey:@"blog_host_name"]];
	if( existingBlog != nil && [existingBlog count] != 0 )
	{
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
														message:[NSString stringWithFormat:@"Blog '%@' already configured on this iPhone.", [existingBlog valueForKey:@"blogName"]]
													   delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		
		[alert show];
		[alert release];		
		return NO;
	}
	
	/*
	 NSString *adminStr	= [usersBlogs valueForKey:@"isAdmin"];
	 NSNumber *isAdmin = [NSNumber numberWithBool:(BOOL) (adminStr == kCFBooleanTrue)?YES:NO) ];
	 */
	[currentBlog setValue:@"" forKey:@"isAdmin"];
	
	NSString *blogName = [usersBlogs valueForKey:@"blogName"];
	[currentBlog setValue:blogName?blogName:@"" forKey:@"blogName"];
	
	// Do not use this value
	//NSString *xmlrpc = url;//[usersBlogs valueForKey:@"xmlrpc"];
	//[currentBlog setValue:xmlrpc?xmlrpc:@"" forKey:@"xmlrpc"];
	
	// use the default value from the blog
	// if RSD failed to find the endpoint
	if (!xmlrpc) {
		xmlrpc = [usersBlogs valueForKey:@"xmlrpc"];
		[currentBlog setValue:xmlrpc?xmlrpc:@"" forKey:@"xmlrpc"];
	}
	
	
	
	
	
	// ----------------------------------------------  retrieve blog categories 
	
	// response will be array of category dictionaries
	
	// invoke wp.getCategories
	XMLRPCRequest *reqCategories = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:xmlrpc]];
	[reqCategories setMethod:@"wp.getCategories" withObjects:[NSArray arrayWithObjects:blogid,username,pwd,nil]];
	
	NSArray *categories = [self executeXMLRPCRequest:reqCategories byHandlingError:YES];
	if( [categories isKindOfClass:[NSArray class]])
	{
		
		// categoryName if blank will be set to id
		
		NSMutableArray *cats = [NSMutableArray arrayWithCapacity:15];
		
		for (NSDictionary *category in categories) {
			
			NSString *categoryId = [category valueForKey:@"categoryId"];
			NSString *categoryName = [category valueForKey:@"categoryName"];
			
			if (categoryName == nil || [categoryName isEqualToString:@""] ) {
				
				NSMutableDictionary *cat = [[category mutableCopy] retain];
				[cat setObject:categoryId forKey:@"categoryName"];
				[cats addObject:cat];
				[cat release];
			
			} else {
				
				[cats addObject:category];
			
			}
				
		
			
		}
		
		[currentBlog setObject:cats forKey:@"categories"];
		
		
	}
	else {
		return NO;
	}
	
	// retrieve blog authors 
	// response will be array of author dictionaries
	
	// invoke wp.getAuthors
	XMLRPCRequest *getAuthorsReq = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:xmlrpc]];
	[getAuthorsReq setMethod:@"wp.getAuthors" withObjects:[NSArray arrayWithObjects:blogid,username,pwd,nil]];
	NSArray *authors = [self executeXMLRPCRequest:getAuthorsReq byHandlingError:YES];
	if( [authors isKindOfClass:[NSArray class]] ) //might be an error.
	{
		[currentBlog setObject:authors forKey:@"authors"];
//		WPLog(@"authors %@", authors);
	}
	else {
		return NO;
	}
	
	// invoke wp.getPostStatusList	
	XMLRPCRequest *getPostStatusListReq = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:xmlrpc]];
	[getPostStatusListReq setMethod:@"wp.getPostStatusList" withObjects:[NSArray arrayWithObjects:blogid,username,pwd,nil]];
	NSDictionary *postStatusList = [self executeXMLRPCRequest:getPostStatusListReq byHandlingError:YES];

	if( [postStatusList isKindOfClass:[NSDictionary class]] ) //might be an error.
		//keys are actual values, values are display strings.
	{
		[currentBlog setObject:postStatusList forKey:@"postStatusList"];
	}
	else {
		return NO;
	}
	
	return YES;
}


- (void)deletedPostsForExistingPosts:(NSMutableArray *)ePosts ofBlog:(id)aBlog andNewPosts:(NSArray *)nPosts
{

	NSMutableArray *ePostIds = [[ePosts valueForKey:@"postid"] mutableCopy];
	NSArray *nPostIds = [nPosts valueForKey:@"postid"];
	
//	WPLog(@"deletedPostsForExistingPosts %d %d", [ePosts count], [nPosts count]);
//	WPLog(@"ePosts %@ nPosts %@", ePostIds, nPostIds);

	id curPost = nil;
	
	int i =0, count = [ePostIds count];
	for( i=count-1; i >=0; i-- )
	{
		if( ![nPostIds containsObject:[ePostIds objectAtIndex:i]] )
		{
			curPost = [ePosts objectAtIndex:i];
//			WPLog(@"hasChanges %@", [ePosts objectAtIndex:i]);

			if( ![[curPost valueForKey:@"hasChanges"] boolValue] )
			{
				NSString *pPath = [self pathToPost:curPost forBlog:aBlog];
				WPLog(@"removing post %@ ", pPath);
				if( [[NSFileManager defaultManager] removeItemAtPath:pPath error:NULL] )
				{
					[ePosts removeObjectAtIndex:i];
				}
			}
		}
	}
	
	[ePostIds release];
}


/* SYNC POSTS FOR BLOG
 ** leave UI state alone until download is resolved - update posts and postTitlesList on file system
 ** after the sync is completed, UI controllers which initiated the request will refresh their states by
	- setting a current blog
	- setting posts list
	- reloading data in tables
	- redisplaying views
 ** In our hierarchical nav model we have blogs list and posts list in the UI. When refresh is
    launched form posts lists and the user returns to blogs list, blogs data must be refreshed for revised counts.
    Toggle a flag on blogs list viewDidAppear to know if we returned there from a posts list drill down.
 
 ** We do not have update dates on posts in metaWeblog.getRecentPosts
    - strategy will be to keep adding new posts and updating existing ones that arrive in recent posts.
    - need to have an api to get recentlyupdated posts rather than n number of recent posts
 
 */


- (BOOL) syncPostsForCurrentBlog {
	
	if( isLocaDraftsCurrent )
		return NO;
	
	[self syncPostsForBlog:currentBlog];
	[self makeBlogAtIndexCurrent:currentBlogIndex];

	return YES;
	
}

// sync posts for a given blog
- (BOOL) syncPostsForBlog:(id)blog {
	WPLog(@"<<<<<<<<<<<<<<<<<< syncPostsForBlog >>>>>>>>>>>>>>");
	if( [[blog valueForKey:@"blogid"] isEqualToString:kDraftsBlogIdStr] )
		return NO;
	[blog setObject:[NSNumber numberWithInt:1] forKey:@"kIsSyncProcessRunning"];
	// Parameters
	NSString *username = [blog valueForKey:@"username"];
	NSString *pwd = [blog valueForKey:@"pwd"];
	NSString *fullURL = [blog valueForKey:@"xmlrpc"];
	NSString *blogid = [blog valueForKey:@"blogid"];
	NSNumber *maxToFetch =  [NSNumber numberWithInt:[[[currentBlog valueForKey:kPostsDownloadCount] substringToIndex:2] intValue]];
	
//	WPLog(@"Fetching posts for blog %@ user %@/%@ from %@", blogid, username, pwd, fullURL);
	
	//  ------------------------- invoke metaWeblog.getRecentPosts
	XMLRPCRequest *postsReq = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:fullURL]];
	[postsReq setMethod:@"metaWeblog.getRecentPosts" 
			withObjects:[NSArray arrayWithObjects:blogid,username, pwd, maxToFetch, nil]];
	
	NSArray *recentPostsList = [self executeXMLRPCRequest:postsReq byHandlingError:YES];
	
	// TODO:
	// Check for fault
	// check for nil or empty response
	// provide meaningful messge to user
	if ((!recentPostsList) || !([recentPostsList isKindOfClass:[NSArray class]]) ) {
		WPLog(@"Unknown Error");
		[blog setObject:[NSNumber numberWithInt:0] forKey:@"kIsSyncProcessRunning"];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"BlogsRefreshNotification" object:blog userInfo:nil];

		return NO;
	}
	
	// loop through each post
	// - add local_status, blogid and bloghost to the pos
	// - save the post
	// - count new posts
	// - add/replace postTitle for post 
	// Sort and Save postTitles list
	// Update blog counts and save blogs list	
	
	// get post titles from file
	NSMutableArray *newPostTitlesList;
	NSString *postTitlesPath = [self pathToPostTitles:blog];
	NSFileManager *fm = [NSFileManager defaultManager];

	if([fm fileExistsAtPath:postTitlesPath])
	{
		newPostTitlesList = [NSArray arrayWithContentsOfFile:postTitlesPath];
	} else {
		newPostTitlesList = [NSMutableArray arrayWithCapacity:30];
	}
	
	
	// loop thru posts list
	NSEnumerator *postsEnum = [recentPostsList objectEnumerator];
	NSDictionary *post;
	NSInteger newPostCount = 0;
	
	while (post = [postsEnum nextObject] ) {
		
		// add blogid and blog_host_name to post
		[post setValue:[blog valueForKey:@"blogid"] forKey:@"blogid"];
		[post setValue:[blog valueForKey:@"blog_host_name"] forKey:@"blog_host_name"];
		
		// Check if the post already exists 
		// yes: check if a local draft exists
		//		 yes: set the local-status to 'edit'
		//		 no: set the local_status to 'original'
		// no: increment new posts count
		
		NSString *pathToPost = [self pathToPost:post forBlog:blog];
		
		if([fm fileExistsAtPath:pathToPost]) {
			
			//TODO: if we implement drafts as a logical blog we may not need this logic any more.
//			if([fm fileExistsAtPath:pathToDraft]) {
//				[post setValue:@"edit" forKey:@"local_status"];
//			} else {
//				[post setValue:@"original" forKey:@"local_status"];
//			}
		
		} else {
			[post setValue:@"original" forKey:@"local_status"];
			newPostCount++ ;
		}
//		WPLog(@"post %@",post);

		// write the new post
		[post writeToFile:pathToPost atomically:YES];
		//WPLog(@"writing post(%@) to file path (%@)",post,pathToPost);
		
		// make a post title using the post
		NSMutableDictionary *postTitle = [self postTitleForPost:post];
		
		// delete existing postTitle and add new post title to list
		NSInteger index = [self indexOfPostTitle:postTitle inList:(NSArray *)newPostTitlesList];
		if (index != -1 ) {
			[newPostTitlesList removeObjectAtIndex:index];		
		} 
		[newPostTitlesList addObject:postTitle];

		
	}
	
	[self deletedPostsForExistingPosts:newPostTitlesList ofBlog:currentBlog andNewPosts:recentPostsList];

	
	// sort and save the postTitles list
	NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"date_created_gmt" ascending:NO];
	[newPostTitlesList sortUsingDescriptors:[NSArray arrayWithObject:sd]];
	[newPostTitlesList writeToFile:[self pathToPostTitles:blog]  atomically:YES];
	//WPLog(@"writing newPostTitlesList(%@) to file path (%@)",newPostTitlesList,[self pathToPostTitles:blog]);
	// increment blog counts and save blogs list
	[blog setObject:[NSNumber numberWithInt:[newPostTitlesList count]] forKey:@"totalposts"];
	[blog setObject:[NSNumber numberWithInt:newPostCount] forKey:@"newposts"];
	NSInteger blogIndex = [self indexForBlogid:[blog valueForKey:@"blogid"] hostName:[blog valueForKey:@"blog_host_name"]];
	if (blogIndex >= 0) {
		[self->blogsList replaceObjectAtIndex:blogIndex withObject:blog];
		
	} else {
//		[self->blogsList addObject:blog];
	
	}
	
	[blog setObject:[NSNumber numberWithInt:0] forKey:@"kIsSyncProcessRunning"];

	[self saveBlogData];

//	[[NSNotificationCenter defaultCenter] postNotificationName:@"BlogsRefreshNotification" object:blog userInfo:nil];
	[self performSelectorOnMainThread:@selector(postBlogsRefreshNotificationInMainThread:) withObject:blog waitUntilDone:NO];
	return YES;
}

- (void)postBlogsRefreshNotificationInMainThread:(id)blog
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"BlogsRefreshNotification" object:blog userInfo:nil];
}

// loads blogs for each host that has been defined
-(void)loadBlogData {

	// look for blogs.archive file under wordpress (the currrent dir), look for blogs.archive file
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *blogsArchiveFilePath = [currentDirectoryPath stringByAppendingPathComponent:@"blogs.archive"];
	
	WPLog(blogsArchiveFilePath);
	
	if ([fileManager fileExistsAtPath:blogsArchiveFilePath]) {
		// set method will release, make mutable copy and retain
		NSMutableArray *arr = [[NSKeyedUnarchiver unarchiveObjectWithFile:blogsArchiveFilePath] mutableCopy];
		[self setBlogsList:arr];
		[arr release];
	} 
	else{
		NSMutableArray * nBlogs = [NSMutableArray array];
		[self setBlogsList:nBlogs];
		[self saveBlogData];
	}
	
	WPLog(@"Number of blogs at launch: %d", [blogsList count]);
	
}

-(void)sortBlogData {
	
	if (blogsList.count) {
		
		WPLog(@"Sorting %d blogs in list....", [blogsList count]);
		
		// Create a descriptor to sort blog dictionaries by blogName
		NSSortDescriptor *blognameSortDescriptor =  [[NSSortDescriptor alloc] 
													 initWithKey:@"blogName" ascending:YES
													 selector:@selector(localizedCaseInsensitiveCompare:)];
		NSArray *sortDescriptors = [NSArray arrayWithObjects:blognameSortDescriptor, nil];
		[blogsList sortUsingDescriptors:sortDescriptors];
		[blognameSortDescriptor release];		
	}

}

- (void)saveBlogData {
	
	
	NSString *blogsArchiveFilePath = [currentDirectoryPath stringByAppendingPathComponent:@"blogs.archive"];
	
	// Empty blogs list may signify all blogs at launch were deleted;  
	// check for existence of prior archive before saving
	if ([blogsList count] || ([[NSFileManager defaultManager] fileExistsAtPath:blogsArchiveFilePath])) {
		
		WPLog(@"Saving %d blogs in list.", [blogsList count]);
		[NSKeyedArchiver archiveRootObject:blogsList toFile:blogsArchiveFilePath];
		
	} else {
		
		WPLog(@"No blogs in list. there is nothing to save!");
	}
	
	
	
}

/*
-(void)createDemoBlogData {
	
	// MAKE SAMPLE BLOG 1
	
	NSArray *names = [[BlogDataManager sharedDataManager] blogFieldNames];
	
	NSNumber *initCount = [NSNumber numberWithInt:0];
	NSArray *values = [NSArray arrayWithObjects:@"ganeshr.wordpress.com", @"ganeshr", @"wordpress.com",@"wordpress.org",
													@"1", @"3737428", @"Ganesh Weblog", @"http://ganeshr.wordpress.com/xmlrpc.php",
							@"ganeshr",@"3975991",@"Ramachandran",@"Ganesh",initCount,initCount,initCount,initCount, 
								@"/xmlrpc.php", @"pass", nil];
	NSMutableDictionary *aBlogDict = [NSMutableDictionary dictionaryWithObjects:values forKeys:names];
	[blogsList addObject:aBlogDict];
	
	
	// MAKE SAMPLE BLOG 2
	NSArray *values2 = [NSArray arrayWithObjects:@"effigentiphone.wordpress.com", @"ganeshr", @"wordpress.com",@"wordpress.org",
						@"1", @"3738567", @"Effigent iPhone Project", @"http://effigentiphone.wordpress.com/xmlrpc.php",
						@"ganeshr",@"3975991",@"Ramachandran",@"Ganesh",initCount,initCount,initCount,initCount, 
							@"/xmlrpc.php", @"pass", nil];
	
	aBlogDict = [NSMutableDictionary dictionaryWithObjects:values2 forKeys:names];
	[blogsList addObject:aBlogDict];
	
	
	// Sort and archive the sample data
	[self sortBlogData];
	[self saveBlogData];
}
*/
- (void) loadPhotosDB 
{
	NSString *photosArchiveFilePath = [self.currentDirectoryPath stringByAppendingPathComponent:@"wordpress.photos"];
	// Empty photos list may signify all photos at launch were deleted;  
	// check for existence of prior archive before saving
	if ([[NSFileManager defaultManager] fileExistsAtPath:photosArchiveFilePath]) {
		
		[self setPhotosDB:[NSKeyedUnarchiver unarchiveObjectWithFile:photosArchiveFilePath]];
//		WPLog(@"Loading %d photos....", [photosDB count]);
		
	} else {
		[[NSFileManager defaultManager] createDirectoryAtPath:[currentDirectoryPath stringByAppendingString:@"/Pictures"] attributes:nil];
		NSMutableArray *tempArray = [[NSMutableArray alloc] init];
		[self setPhotosDB:tempArray];
		[tempArray release];
	}		
}

- (void) savePhotosDB {
	WPLog(@"savePhotosDB");	
	NSString *photosArchiveFilePath = [self.currentDirectoryPath stringByAppendingPathComponent:@"wordpress.photos"];
	// Empty photos list may signify all photos at launch were deleted;  
	// check for existence of prior archive before saving
	if ([photosDB count] || ([[NSFileManager defaultManager] fileExistsAtPath:photosArchiveFilePath])) {
		
		WPLog(@"Saving %d photos in list....", [photosDB count]);
		[NSKeyedArchiver archiveRootObject:photosDB toFile:photosArchiveFilePath];
		
	} else {
		
		WPLog(@"No photos in list. there is nothing to save!");
	}
}

#pragma mark Image 

- (CGSize)imageResizeSizeForImageSize:(CGSize)imgSize
{	
	float oWidth = imgSize.width;
	float oHeight = imgSize.height;
	float nWidth = 64;
	float nHeight = 64;
	
	float aspectRatio =  oWidth / oHeight;
	
	if((float)nWidth/nHeight > aspectRatio) {
		nWidth = ceil(nHeight * aspectRatio);	
	} else {
		nHeight = ceil(nWidth / aspectRatio);
	}
	
	return CGSizeMake(nWidth, nHeight);	
}

- (UIImage *)smallImage:(UIImage *)image
{
	CGImageRef imageRef = [image CGImage];	
	
	CGSize imgSize = [image size];
	float oWidth = imgSize.width;
	float oHeight = imgSize.height;
	float nWidth = 64;
	float nHeight = 64;
	
	float aspectRatio =  oWidth / oHeight;
	CGRect drawRect = CGRectZero;

	if(aspectRatio < 1) { //p
		nHeight = ceil(nWidth / aspectRatio);
		drawRect.origin.y -= ((nHeight - nWidth)/2.0);
	} else { //l
		nWidth = ceil(nHeight * aspectRatio);	
		drawRect.origin.x -= ((nWidth-nHeight)/2.0);
	}
	
	CGContextRef bitmap = CGBitmapContextCreate(
												NULL,
												64,
												64,
												CGImageGetBitsPerComponent(imageRef),
												4*64,
												CGImageGetColorSpace(imageRef),
												CGImageGetBitmapInfo(imageRef)
												);	
	
	drawRect.size.width = nWidth;
	drawRect.size.height = nHeight;

	CGContextDrawImage( bitmap, drawRect, imageRef );
	CGImageRef ref = CGBitmapContextCreateImage( bitmap );
	
//	CGImageRef square = CGImageCreateWithImageInRect( ref, drawRect );
	//we are releasing in the called method.
	UIImage *theImage = [[UIImage alloc] initWithCGImage:ref];
	
	CGContextRelease( bitmap );
	CGImageRelease( ref );
//	CGImageRelease( square );
	
	//we are releasing in the called method.
	return theImage;
}

- (NSString *)saveImage:(UIImage *)aImage {
	CFUUIDRef     myUUID;
	CFStringRef   myUUIDString;
	char          strBuffer[256];
	
	myUUID = CFUUIDCreate(kCFAllocatorDefault);
	myUUIDString = CFUUIDCreateString(kCFAllocatorDefault, myUUID);
	
	// This is the safest way to obtain a C string from a CFString.
	CFStringGetCString(myUUIDString, strBuffer, 256, kCFStringEncodingASCII);
	
//	WPLog(@"aImage.imageOrientation %d", aImage.imageOrientation);
//	char *prefix = "l";
//	switch ( aImage.imageOrientation )
//	{
//		case UIImageOrientationUp:
//		case UIImageOrientationDown:
//		case UIImageOrientationUpMirrored:
//		case UIImageOrientationDownMirrored:
//			prefix = "p";
//			break;
//	}
	
	CFStringRef outputString = NULL;
	int width = aImage.size.width, height = aImage.size.height;
	if( width < height )
	{
		outputString = CFStringCreateWithFormat(kCFAllocatorDefault,
												NULL,
												CFSTR("p_%d_%d_%s"),
												height, width, strBuffer);		
	}
	else 
	{
		outputString = CFStringCreateWithFormat(kCFAllocatorDefault,
												NULL,
												CFSTR("l_%d_%d_%s"),
												width, height, strBuffer);		
	}

	CFShow(outputString);
	NSString *filePath = [NSString stringWithFormat:@"/%@/%@.jpeg",[self blogDir:currentBlog],(NSString *)outputString];
	NSData *imgData = UIImageJPEGRepresentation( aImage, 0.5 );
	[imgData writeToFile:filePath atomically:YES];
	NSString *returnValue = [NSString stringWithFormat:@"%@.jpeg",outputString];
	UIImage * si = [self smallImage:aImage];
	NSData *siData = UIImageJPEGRepresentation( si, 0.8 );
	[si release];
	filePath = [NSString stringWithFormat:@"/%@/t_%@.jpeg",[self blogDir:currentBlog],(NSString *)outputString];
	[siData writeToFile:filePath atomically:YES];

	WPLog(@"il %d til %d", [imgData length], [siData length] );
	CFRelease(outputString);
	CFRelease(myUUIDString);
	CFRelease(myUUID);

	return returnValue;
}

- (UIImage *)thumbnailImageNamed:(NSString *)name forBlog:(id)blog {
	UIImage *image = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/t_%@",[self blogDir:blog],name]];
	return [image autorelease];
}

- (UIImage *)imageNamed:(NSString *)name forBlog:(id)blog {
	UIImage *image = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/%@",[self blogDir:blog],name]];
	return [image autorelease];
}

- (BOOL)deleteImageNamed:(NSString *)name forBlog:(id)blog {
	NSError *error;
	NSString *imgPath = [NSString stringWithFormat:@"%@/%@",[self blogDir:blog], name];
	[[NSFileManager defaultManager] removeItemAtPath:imgPath error:&error];
	imgPath = [NSString stringWithFormat:@"%@/t_%@",[self blogDir:blog], name];
	[[NSFileManager defaultManager] removeItemAtPath:imgPath error:&error];
	if (error)
		return NO;
	return YES;
}

- (BOOL)deleteAllPhotosForCurrentPostBlog
{
	return [self deleteAllPhotosForPost:currentPost forBlog:currentBlog];
}

- (BOOL)deleteAllPhotosForPost:(id)aPost forBlog:(id)aBlog
{
	NSMutableArray *photos = [aPost valueForKey:@"Photos"];
	int i, count = [photos count];
	NSString *curPath = nil;
	
	for( i=count-1; i >=0 ; i-- )
	{
		curPath = [photos objectAtIndex:i];
		[self deleteImageNamed:curPath forBlog:aBlog];
	}
	
	return YES;
}

#pragma mark Blog

- (NSInteger)countOfBlogs {
	return [blogsList count];
}


- (NSDictionary *)blogAtIndex:(NSUInteger)theIndex {
	
	return [blogsList objectAtIndex:theIndex];

}

- (NSDictionary *) blogForId:(NSString *)aBlogid hostName:(NSString *)hostname{
	
	NSMutableDictionary *aBlog;
	NSEnumerator *blogEnum = [blogsList objectEnumerator];
	
	while (aBlog = [blogEnum nextObject])
	{
		if ([[aBlog valueForKey:@"blogid"] isEqualToString:aBlogid] &&
			[[aBlog valueForKey:@"blog_host_name"] isEqualToString:hostname]) {
			
			return aBlog; 
		}
	}
	
	// return an empty dictionary to signal that blog id was not found
	return [NSDictionary dictionary];
	
}

- (NSString *)defaultTemplateHTMLString
{
	NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
	NSString *fpath = [NSString stringWithFormat:@"%@/defaultPostTemplate.html", resourcePath];
	NSString *str = [NSString stringWithContentsOfFile:fpath];
	return str;
}

- (NSString *)templateHTMLStringForBlog:(id)aBlog isDefaultTemplate:(BOOL *)flag
{
	NSString *fpath = [self templatePathForBlog:currentBlog];
	NSString *str = [NSString stringWithContentsOfFile:fpath encoding:NSUTF8StringEncoding error:NULL];
	if( !str )
	{
		str = [self defaultTemplateHTMLString];
		*flag = YES; 
	}
	else 
	{
		*flag = NO;
	}

	return str;
}

//TODO: remove
- (id)newDraftsBlog 
{	
	NSArray *blogInitValues = [NSArray arrayWithObjects:@"Local Drafts", @"", kDraftsHostName,@"iPhone",
							   @"", kDraftsBlogIdStr, @"Local Drafts", @"",
							   @"",@"",@"",@"", 
							   [NSNumber numberWithInt:0], [NSNumber numberWithInt:0], 
							   [NSNumber numberWithInt:0], [NSNumber numberWithInt:0], @"/xmlrpc.php",@"", @"", nil];	
		
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjects:blogInitValues forKeys:[self blogFieldNames]];
	
	[dict setObject:@"0" forKey:@"kNextDraftIdStr"];
	return dict;
}

- (void)makeNewBlogCurrent {
	
	self->isLocaDraftsCurrent = NO;
	
	NSArray *blogInitValues = [NSArray arrayWithObjects:@"", @"", @"",@"",
									@"", @"", @"", @"",
									@"",@"",@"",@"", 
								   [NSNumber numberWithInt:0], [NSNumber numberWithInt:0], 
								   [NSNumber numberWithInt:0], [NSNumber numberWithInt:0], @"/xmlrpc.php",@"",@"10 Recent Posts", nil];	
	

	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjects:blogInitValues forKeys:[self blogFieldNames]];
	[dict setObject:@"0" forKey:kNextDraftIdStr];
	[dict setObject:[NSNumber numberWithInt:0] forKey:kDraftsCount];

	// setCurrentBlog will release current reference and make a mutable copy of this one
	[self setCurrentBlog:dict];
	
	// reset the currentBlogIndex to -1 indicating new blog;
	currentBlogIndex = -1;
	
}


- (void)makeLocalDraftsCurrent {
	
	self->isLocaDraftsCurrent = YES;
	
}


- (void)copyBlogAtIndexCurrent:(NSUInteger)theIndex
{
	id cb = [[blogsList objectAtIndex:theIndex] mutableCopy];
	[self setCurrentBlog:cb];
	[cb release];
	
	// save the current index as well
	currentBlogIndex = theIndex;
}

- (void)makeBlogAtIndexCurrent:(NSUInteger)theIndex {
	
	[self setCurrentBlog:[blogsList objectAtIndex:theIndex]];	
	
	// save the current index as well
	currentBlogIndex = theIndex;

	
}

- (void)saveCurrentBlog {
	
	if (isLocaDraftsCurrent) {
		WPLog(@"Tried to save local drafts fake blog!");
		return;
	}
	
	// save it to the current index if set or add it 
	
	if (currentBlogIndex == -1) {
		id cb = [currentBlog mutableCopy];
		[blogsList addObject:cb];
		[cb release];
		
		//re-sort the blogs list to place the new blog at the proper index
		[self sortBlogData];
		[self saveBlogData];
		
		//find the index where the blog was placed
		currentBlogIndex = [self indexForBlogid:[currentBlog valueForKey:@"blogid"] 
									   hostName:[currentBlog valueForKey:@"blog_host_name"]];
		
	} else {
		[blogsList replaceObjectAtIndex:currentBlogIndex withObject:[currentBlog mutableCopy]];
		// not need to re-sort here - we're not allowing change to blog name
	}

}

- (void)removeCurrentBlog
{
	if( [[NSFileManager defaultManager] removeItemAtPath:[self blogDir:currentBlog] error:nil] )
	{
		[blogsList removeObjectAtIndex:currentBlogIndex];
		[self saveBlogData];
		[self resetCurrentBlog];
	}
}

- (void)resetCurrentBlog {
	currentBlog = nil;
	currentBlogIndex = -3;
}

- (NSInteger) indexForBlogid:(NSString *)aBlogid  hostName:(NSString *)hostname {
	
	NSMutableDictionary *aBlog;
	NSEnumerator *blogEnum = [blogsList objectEnumerator];
	int index = 0;
	
	while (aBlog = [blogEnum nextObject])
	{
		if ([[aBlog valueForKey:@"blogid"] isEqualToString:aBlogid] &&
			[[aBlog valueForKey:@"blog_host_name"] isEqualToString:hostname]) {
			
			return index; 
		}
			
		index++;
	}
	
	// signal that blog id was not found
	return -1;
			
}

#pragma mark PostTitle metadata

- (NSArray *)postTitleFieldNames {
	
	if (!postTitleFieldNames) {
		
		self->postTitleFieldNames = [NSArray arrayWithObjects:@"local_status", @"dateCreated", @"blogid",  @"blog_host_name", 
														@"blogName", @"postid", @"title", @"authorid", @"wp_author_display_name", @"status", 
														@"mt_excerpt", @"mt_keywords", @"date_created_gmt", 
														@"newcomments", @"totalcomments",nil];
		[postTitleFieldNames retain];
		
	}
	
	return postTitleFieldNames;
}

- (NSDictionary *)postTitleFieldNamesByTag {
	
	if(!postTitleFieldNamesByTag) {
		NSNumber *tag0 = [NSNumber numberWithInt:100];
		NSNumber *tag1 = [NSNumber numberWithInt:101];
		NSNumber *tag2 = [NSNumber numberWithInt:102];
		NSNumber *tag3 = [NSNumber numberWithInt:103];
		NSNumber *tag4 = [NSNumber numberWithInt:104];
		NSNumber *tag5 = [NSNumber numberWithInt:105];
		NSNumber *tag6 = [NSNumber numberWithInt:106];
		NSNumber *tag7 = [NSNumber numberWithInt:107];
		NSNumber *tag8 = [NSNumber numberWithInt:108];
		NSNumber *tag9 = [NSNumber numberWithInt:109];
		NSNumber *tag10 = [NSNumber numberWithInt:110];
		NSNumber *tag11 = [NSNumber numberWithInt:111];
		NSNumber *tag12 = [NSNumber numberWithInt:112];
		NSNumber *tag13 = [NSNumber numberWithInt:113];
		NSNumber *tag14 = [NSNumber numberWithInt:114];
				
		
		
		NSArray *tags = [NSArray arrayWithObjects:tag0, tag1, tag2, tag3, tag4, tag5, tag6, tag7, tag8, 
						 tag9, tag10, tag11, tag12, tag13,tag14, nil];
		self->postTitleFieldNamesByTag = [NSDictionary dictionaryWithObjects:[self postTitleFieldNames] forKeys:tags];
		
		[postTitleFieldNamesByTag retain];
		
	}
	
	return postTitleFieldNamesByTag;
}

- (NSDictionary *)postTitleFieldTagsByName {
	
	if(!postTitleFieldTagsByName) {
		
		NSNumber *tag0 = [NSNumber numberWithInt:100];
		NSNumber *tag1 = [NSNumber numberWithInt:101];
		NSNumber *tag2 = [NSNumber numberWithInt:102];
		NSNumber *tag3 = [NSNumber numberWithInt:103];
		NSNumber *tag4 = [NSNumber numberWithInt:104];
		NSNumber *tag5 = [NSNumber numberWithInt:105];
		NSNumber *tag6 = [NSNumber numberWithInt:106];
		NSNumber *tag7 = [NSNumber numberWithInt:107];
		NSNumber *tag8 = [NSNumber numberWithInt:108];
		NSNumber *tag9 = [NSNumber numberWithInt:109];
		NSNumber *tag10 = [NSNumber numberWithInt:110];
		NSNumber *tag11 = [NSNumber numberWithInt:111];
		NSNumber *tag12 = [NSNumber numberWithInt:112];
		NSNumber *tag13 = [NSNumber numberWithInt:113];
		NSNumber *tag14 = [NSNumber numberWithInt:114];
		
		
		NSArray *tags = [NSArray arrayWithObjects:tag0, tag1, tag2, tag3, tag4, tag5, tag6, tag7, tag8, 
						 tag9, tag10, tag11, tag12, tag13, tag14, nil];
		self->postTitleFieldTagsByName = [NSDictionary dictionaryWithObjects:tags forKeys:[self postTitleFieldNames]];
		
		[postTitleFieldTagsByName retain];
	}
	
	return postTitleFieldTagsByName;
}

#pragma mark PostTitle Data

- (NSMutableArray *)postTitlesForBlog:(id)aBlog
{
	NSString *postTitlesFilePath = [self pathToPostTitles:aBlog];
	if ([[NSFileManager defaultManager] fileExistsAtPath:postTitlesFilePath]) 
	{
		return [NSMutableArray arrayWithContentsOfFile:postTitlesFilePath];
	}

	return [NSMutableArray array];
}

- (NSMutableArray *)commentTitlesForBlog:(id)aBlog
{
	NSString *commentTitlesFilePath = [self pathToCommentTitles:aBlog];
	if ([[NSFileManager defaultManager] fileExistsAtPath:commentTitlesFilePath]) 
	{
		return [NSMutableArray arrayWithContentsOfFile:commentTitlesFilePath];
	}
	
	return [NSMutableArray array];
}

- (NSMutableArray *)commentTitlesForCurrentBlog
{
	return [self commentTitlesForBlog:currentBlog];
}

- (NSInteger)numberOfDrafts
{
	return [draftTitlesList count];
}

- (NSMutableArray *)draftTitlesForBlog:(id)aBlog
{
	NSString *draftTitlesFilePath = [self pathToDraftTitlesForBlog:aBlog];
	WPLog(@"draftTitlesFilePath %@", draftTitlesFilePath);
	if ([[NSFileManager defaultManager] fileExistsAtPath:draftTitlesFilePath]) 
	{
		return [NSMutableArray arrayWithContentsOfFile:draftTitlesFilePath];
	}
	
	return [NSMutableArray array];	
}

- (void)loadDraftTitlesForBlog:(id)aBlog
{
	[self setDraftTitlesList:[self draftTitlesForBlog:aBlog]];
}

- (void)loadDraftTitlesForCurrentBlog
{
//	WPLog(@"loadDraftTitlesForCurrentBlog ...");
	[self loadDraftTitlesForBlog:currentBlog];
//	WPLog(@"draftTitlesList ...", draftTitlesList);
}

-(id)draftTitleAtIndex:(NSInteger)anIndex
{
	return [draftTitlesList objectAtIndex:anIndex];
}

- (BOOL)makeDraftWithIDCurrent:(NSString *)aDraftID
{
	NSArray *draftTitles = [self draftTitlesForBlog:self.currentBlog];
	int index = [[draftTitles valueForKey:@"draftid"] indexOfObject:aDraftID];
	if( index >=0 && index < [draftTitles count] )
	{
		return [self makeDraftAtIndexCurrent:index];
	}
	
	return NO;
}

- (BOOL)makeDraftAtIndexCurrent:(NSInteger)anIndex
{
	NSString *draftPath = [self pathToDraft:[self draftTitleAtIndex:anIndex] forBlog:currentBlog];
//	WPLog(@"draftPath %@", draftPath);
	NSMutableDictionary *draft = [NSMutableDictionary dictionaryWithContentsOfFile:draftPath];
	[self setCurrentPost:draft];
	currentDraftIndex = anIndex;
	currentPostIndex = -2;
	return YES;
}

- (BOOL)deleteDraftAtIndex:(NSInteger)anIndex forBlog:(id)aBlog
{
	NSString *draftPath = [self pathToDraft:[self draftTitleAtIndex:anIndex] forBlog:aBlog];
	NSMutableArray *dTitles = [self draftTitlesForBlog:(id)aBlog];
	[dTitles removeObjectAtIndex:anIndex];
	
	NSNumber *dc = [aBlog valueForKey:@"kDraftsCount"];
	[aBlog setValue:[NSNumber numberWithInt:[dc intValue]-1] forKey:@"kDraftsCount"];
	
	[self deleteAllPhotosForCurrentPostBlog];
	
	[[NSFileManager defaultManager] removeItemAtPath:draftPath error:nil];
	[dTitles writeToFile:[self pathToDraftTitlesForBlog:aBlog] atomically:YES];
	[self saveBlogData];
	return YES;
}

- (void)resetDrafts
{
	currentDraftIndex = -1;
	[self setDraftTitlesList:nil];
}

- (void)resetCurrentDraft
{
	currentDraftIndex = -1;
	[self setCurrentPost:nil];
}

- (id)loadPostTitlesForBlog:(id)aBlog
{
	// set method will make a mutable copy and retain
	[self setPostTitlesList: [self postTitlesForBlog:aBlog]];
	return nil;
	
	//TODO: Remove junk
//	
//	// append blog host to the curr dir path to get the dir at which a blog keeps its posts and drafts
//	NSString *blogHostDir = [currentDirectoryPath stringByAppendingPathComponent:[aBlog objectForKey:@"blog_host_name"]];
//	
////	// append blog id to the curr dir path to get the dir at which a blog keeps its posts and drafts
////	// local drafts are loaded from "localdrafts" dir
////	
//	NSString *blogDir;
////	if (isLocaDraftsCurrent) {
////		blogDir = [blogHostDir stringByAppendingPathComponent:@"localdrafts"];
////	} else {
//		
//		blogDir = [blogHostDir stringByAppendingPathComponent:[aBlog objectForKey:@"blogid"]];
////	}
//	
//	
//	NSString *postTitlesFilePath = [blogDir stringByAppendingPathComponent:@"postTitles.archive"];
//	
//	WPLog(postTitlesFilePath);
//	
//	if ([[NSFileManager defaultManager] fileExistsAtPath:postTitlesFilePath]) {
//		
//		// set method will make a mutable copy and retain
//		[self setPostTitlesList: [NSArray arrayWithContentsOfFile:postTitlesFilePath]];//[NSKeyedUnarchiver unarchiveObjectWithFile:]];
//		
//	} 
//	
//	WPLog(@"Loaded %d posts for blog %@ at host %@", [postTitlesList count],
//		  [aBlog objectForKey:@"blogName"],	
//		  [aBlog objectForKey:@"blog_host_name"]);	
//	return nil;
}

- (void)loadPostTitlesForCurrentBlog {
	[self loadPostTitlesForBlog:currentBlog];
}

- (void)loadCommentTitlesForCurrentBlog {
	[self loadCommentTitlesForBlog:currentBlog];
}

- (id)loadCommentTitlesForBlog:(id)aBlog
{
	// set method will make a mutable copy and retain
	[self setCommentTitlesList: [self commentTitlesForBlog:aBlog]];
	return nil;
}

// TODO: we don't need this any more.
-(void)sortPostTitlesList {
	
	if (postTitlesList.count) {
		
//		WPLog(@"Sorting %d posts in list....", [postTitlesList count]);
		
		// Create a descriptor to sort blog dictionaries by blogName
		NSSortDescriptor *dateCreatedSortDescriptor =  [[NSSortDescriptor alloc] 
														initWithKey:@"date_created_gmt" ascending:YES
														selector:@selector(localizedCaseInsensitiveCompare:)];
		NSArray *sortDescriptors = [NSArray arrayWithObjects:dateCreatedSortDescriptor, nil];
		[postTitlesList sortUsingDescriptors:sortDescriptors];
		[dateCreatedSortDescriptor release];
	}
	
}

- (NSInteger)countOfPostTitles {
	return [postTitlesList count];
}

- (NSInteger)countOfCommentTitles {
	return [commentTitlesList count];
}

- (NSArray *)commentTitles {
	return commentTitlesList;
}

- (NSDictionary *)postTitleAtIndex:(NSUInteger)theIndex {
	
	return [postTitlesList objectAtIndex:theIndex];
	
}

- (NSDictionary *)commentTitleAtIndex:(NSUInteger)theIndex {
	
	return [commentTitlesList objectAtIndex:theIndex];
	
}

- (NSInteger) indexOfPostTitle:(id)postTitle inList:(NSArray *)aPostTitlesList {
	
	NSDictionary *aPostTitle;
	NSEnumerator *postTitlesEnum = [aPostTitlesList objectEnumerator];
	
	int i = 0;
	while (aPostTitle = [postTitlesEnum nextObject])
	{
		if ([[aPostTitle valueForKey:@"blogid"] isEqualToString:[postTitle valueForKey:@"blogid"]] &&
			[[aPostTitle valueForKey:@"blog_host_name"]isEqualToString:[postTitle valueForKey:@"blog_host_name"]] &&
			[[aPostTitle valueForKey:@"postid"]isEqualToString:[postTitle valueForKey:@"postid"]]) {
			return i; 
		}
		i++;
	}
	
	// return -1 to signal that postTitle was not found
	return -1;
	
	
}

- (void)resetPostTitlesList {
	[postTitlesList removeAllObjects];
	[self resetCurrentPost];
}

#pragma mark Post metadata

- (NSArray *)postFieldNames {
	
	if (!postFieldNames) {
		// local_status is :
		//  'new' for posts created locally
		//  'edit' for posts that are downloaded and edited locally
		//  'original' for downlaoded posts that have not been edited locally
		// At the time a post is downloaded or created, we add blogid and blog_host_name fields to post dict
		
		self->postFieldNames = [NSArray arrayWithObjects:@"local_status", @"dateCreated", @"userid", 
								@"postid", @"description", @"title", @"permalink", 
								@"slug", @"wp_password", @"authorid", @"status", 
								@"mt_excerpt", @"mt_text_more", @"mt_keywords", 
								@"not_used_allow_comments", @"link_to_comments", @"not_used_allow_pings",@"dateUpdated", 
								@"blogid", @"blog_host_name", @"wp_author_display_name",@"date_created_gmt", nil];
		[postFieldNames retain];
		
	}
	
	return postFieldNames;
}


- (NSDictionary *)postFieldNamesByTag {
	
	if(!postFieldNamesByTag) {
		NSNumber *tag0 = [NSNumber numberWithInt:100];
		NSNumber *tag1 = [NSNumber numberWithInt:101];
		NSNumber *tag2 = [NSNumber numberWithInt:102];
		NSNumber *tag3 = [NSNumber numberWithInt:103];
		NSNumber *tag4 = [NSNumber numberWithInt:104];
		NSNumber *tag5 = [NSNumber numberWithInt:105];
		NSNumber *tag6 = [NSNumber numberWithInt:106];
		NSNumber *tag7 = [NSNumber numberWithInt:107];
		NSNumber *tag8 = [NSNumber numberWithInt:108];
		NSNumber *tag9 = [NSNumber numberWithInt:109];
		NSNumber *tag10 = [NSNumber numberWithInt:110];
		NSNumber *tag11 = [NSNumber numberWithInt:111];
		NSNumber *tag12 = [NSNumber numberWithInt:112];
		NSNumber *tag13 = [NSNumber numberWithInt:113];
		NSNumber *tag14 = [NSNumber numberWithInt:114];
		NSNumber *tag15 = [NSNumber numberWithInt:115];
		NSNumber *tag16 = [NSNumber numberWithInt:116];
		NSNumber *tag17 = [NSNumber numberWithInt:117];
		NSNumber *tag18 = [NSNumber numberWithInt:118];
		NSNumber *tag19 = [NSNumber numberWithInt:119];
		NSNumber *tag20 = [NSNumber numberWithInt:120];
		NSNumber *tag21 = [NSNumber numberWithInt:121];
		
		
		NSArray *tags = [NSArray arrayWithObjects:tag0, tag1, tag2, tag3, tag4, tag5, tag6, tag7, tag8, 
						 tag9, tag10, tag11, tag12, tag13, tag14, tag15, tag16,tag17,tag18, tag19, tag20, tag21,  nil];
		self->postFieldNamesByTag = [NSDictionary dictionaryWithObjects:[self postFieldNames] forKeys:tags];
		
		[postFieldNamesByTag retain];
		
	}
	
	return postFieldNamesByTag;
}

- (NSDictionary *)postFieldTagsByName {
	
	if(!postFieldTagsByName) {
		
		NSNumber *tag0 = [NSNumber numberWithInt:100];
		NSNumber *tag1 = [NSNumber numberWithInt:101];
		NSNumber *tag2 = [NSNumber numberWithInt:102];
		NSNumber *tag3 = [NSNumber numberWithInt:103];
		NSNumber *tag4 = [NSNumber numberWithInt:104];
		NSNumber *tag5 = [NSNumber numberWithInt:105];
		NSNumber *tag6 = [NSNumber numberWithInt:106];
		NSNumber *tag7 = [NSNumber numberWithInt:107];
		NSNumber *tag8 = [NSNumber numberWithInt:108];
		NSNumber *tag9 = [NSNumber numberWithInt:109];
		NSNumber *tag10 = [NSNumber numberWithInt:110];
		NSNumber *tag11 = [NSNumber numberWithInt:111];
		NSNumber *tag12 = [NSNumber numberWithInt:112];
		NSNumber *tag13 = [NSNumber numberWithInt:113];
		NSNumber *tag14 = [NSNumber numberWithInt:114];
		NSNumber *tag15 = [NSNumber numberWithInt:115];
		NSNumber *tag16 = [NSNumber numberWithInt:116];
		NSNumber *tag17 = [NSNumber numberWithInt:117];
		NSNumber *tag18 = [NSNumber numberWithInt:118];
		NSNumber *tag19 = [NSNumber numberWithInt:119];
		NSNumber *tag20 = [NSNumber numberWithInt:120];
		NSNumber *tag21 = [NSNumber numberWithInt:121];
		
		
		NSArray *tags = [NSArray arrayWithObjects:tag0, tag1, tag2, tag3, tag4, tag5, tag6, tag7, tag8, 
						 tag9, tag10, tag11, tag12, tag13, tag14, tag15, tag16, tag17,tag18, tag19, tag20,tag21, nil];
		self->postFieldTagsByName = [NSDictionary dictionaryWithObjects:tags forKeys:[self postFieldNames]];
		
		[postFieldTagsByName retain];
	}
	
	return postFieldTagsByName;
}


#pragma mark Post

- (NSInteger)countOfPosts {
	return 0;
}

- (NSDictionary *)postAtIndex:(NSUInteger)theIndex {
	return nil;
}

- (NSDictionary *)postForId:(NSString *)postid {
	return nil;
}

- (NSUInteger)indexForPostid:(NSString *)postid {
	return -1;
}

- (NSDictionary *)postTitleForId:(NSString *)postTitleid {
	return nil;
}



- (NSUInteger)indexForPostTitleId:(NSString *)postTitleid {
	return -1;
}

// this is a wrapper method which get called in a back ground thread.
// here we need to get the posts first and then we need to generate template.
// these two should not run in parallel, other wise the generate template will create some dummy templates, categories which may get downloaded when we  syncPostsForBlog:
// so these two should run in sequence. this is one way of doing it.
- (BOOL)wrapperForSyncPostsAndGetTemplateForBlog:(id)aBlog
{
	NSAutoreleasePool *ap = [[NSAutoreleasePool alloc] init];
	[aBlog retain];

	[self syncPostsForBlog:aBlog];
	[self generateTemplateForBlog:aBlog];
	
	[self syncCommentsForBlog:aBlog];

	[aBlog release];
	[ap release];
	
	return YES;
}

//TODO: preview based on template.
- (void)generateTemplateForBlog:(id)aBlog
{
	// skip template generation until !$title$! bug can be fixed
	return;
	
	NSAutoreleasePool *ap = [[NSAutoreleasePool alloc] init];
	[aBlog retain];
	
	NSDictionary *catParms = [NSMutableDictionary dictionaryWithCapacity:4];
	[catParms setValue:@"!$categories$!" forKey:@"name"];
	[catParms setValue:@"!$categories$!" forKey:@"description"];
	
	NSArray *catargs = [NSArray arrayWithObjects:[aBlog valueForKey:@"blogid"],
					 [aBlog valueForKey:@"username"],
					 [aBlog valueForKey:@"pwd"],
					 catParms,
					 nil
					 ];
	
	XMLRPCRequest *catRequest = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:[aBlog valueForKey:@"xmlrpc"]]];
	[catRequest setMethod:@"wp.newCategory" withObjects:catargs];
	id catResponse = [self executeXMLRPCRequest:catRequest byHandlingError:NO];
	[catRequest release]; 
	if( [catResponse isKindOfClass:[NSError class]] )
	{
		WPLog(@"ERROR in creating new cateogry %@", catResponse);
		catResponse = nil;
	}
	
	
	NSMutableDictionary *postParams = [NSMutableDictionary dictionary];
	
	[postParams setObject:@"!$title$!" forKey:@"title"];
	[postParams setObject:@"!$mt_keywords$!" forKey:@"mt_keywords"];
	[postParams setObject:@"!$text$!" forKey:@"description"];
	NSArray *cats = [NSArray arrayWithObjects:@"!$categories$!",nil];
	[postParams setObject:cats forKey:@"categories"];

	[postParams setObject:@"publish" forKey:@"post_status"];
	
	NSArray *args = [NSArray arrayWithObjects:[aBlog valueForKey:@"blogid"],
					 [aBlog valueForKey:@"username"],
					 [aBlog valueForKey:@"pwd"],
					 postParams,
					 nil
					 ];
	
	//TODO: take url from current post
	XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:[currentBlog valueForKey:@"xmlrpc"]]];
	[request setMethod:@"metaWeblog.newPost" withObjects:args];
	
	id postid = [self executeXMLRPCRequest:request byHandlingError:NO];
	[request release];
	
//	WPLog(@"------------- postid  --------- %@", postid	);
	if( ![postid isKindOfClass:[NSError class]] )
	{
		args = [NSArray arrayWithObjects:
				postid,
				[aBlog valueForKey:@"username"],
				[aBlog valueForKey:@"pwd"],nil];
		
		request = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:[aBlog valueForKey:@"xmlrpc"]]];
		[request setMethod:@"metaWeblog.getPost" withObjects:args];
		
		id post = [self executeXMLRPCRequest:request byHandlingError:NO];
		[request release];
		
//		WPLog(@"------------- post  --------- %u", post	);

		if( ![post isKindOfClass:[NSError class]] )
		{
			NSString *fpath = [self templatePathForBlog:aBlog];
			NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:[post valueForKey:@"link"]]
													  cachePolicy:NSURLRequestUseProtocolCachePolicy							  
												  timeoutInterval:60.0];			
			NSData *data = [NSURLConnection sendSynchronousRequest:theRequest returningResponse:NULL error:NULL];
			if( [data length] )
			{
				//NSString *str = [NSString stringWithUTF8String:[data bytes]];
				NSString *str = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
				WPLog(@"Received Template: %@", str);
				if(!str || [str rangeOfString:@"!$text$!"].location == NSNotFound ) {
					WPLog(@"Template not downloaded. Private Blog? Not writing to file");
				} else {
					WPLog(@"Writing Template to file");
					[data writeToFile:fpath atomically:YES];
				}
			}
		}
		
		NSString *bloggerAPIKey = @"ABCDEF012345";
		args = [NSArray arrayWithObjects:
				bloggerAPIKey,
				postid,
				[aBlog valueForKey:@"username"],
				[aBlog valueForKey:@"pwd"],nil];
		
		request = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:[aBlog valueForKey:@"xmlrpc"]]];
		[request setMethod:@"metaWeblog.deletePost" withObjects:args];
		[self executeXMLRPCRequest:request byHandlingError:NO];
//		WPLog(@"------------- res  --------- %@", res	);

		[request release];
		
	}

	//delete cat
	if( catResponse )
	{
		WPLog(@"wp.deleteCategory catResponse %@ ", catResponse);
		NSArray *catargs = [NSArray arrayWithObjects:[aBlog valueForKey:@"blogid"],
						 [aBlog valueForKey:@"username"],
						 [aBlog valueForKey:@"pwd"],
						 catResponse,
						 nil
						 ];
		
		XMLRPCRequest *catRequest = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:[aBlog valueForKey:@"xmlrpc"]]];
		[catRequest setMethod:@"wp.deleteCategory" withObjects:catargs];
		id catResponse = [self executeXMLRPCRequest:catRequest byHandlingError:NO];
		[catRequest release]; 
//		WPLog(@"catResponse %@", catResponse);
		if( [catResponse isKindOfClass:[NSError class]] )
		{
			WPLog(@"ERROR in creating deleting cateogry %@", catResponse);
			catResponse = nil;
		}		
	}
	
	[aBlog release];
	[ap release];
}

- (void)makeNewPostCurrent {
	
	WPLog(@" ........... makeNewPostCurrent");
	// Assign:
	// post_type = "post"
	// dateCreated = today
	// userid - assigned from current blog (which needs to be set at the right times)
	// author id = userid 
	
	// Edit
	// postid -  TO-DO need temporary post id for local draft, replaced with server assigned id at publish
	// description - TO_DO the content; needs to be well formed when user hits done on keyboard.
	// title - TO-DO warn if empty; needs to be well formed when user hits done on keyboard.
	// mt_excerpt
	// mt_keywords
	// categories
	// password - have the option to show the password; 
	//   TO-DO store password with simple encryption
	// status : chooser from getAvailableStatuses (draft, pending, private, publish
	// - TO-DO clarify how this is used in mw.newPost and mw.EditPost
	// mt_text_more
	// not_used_allow_comments
	// link_to_comments
	// not_used_allow_pings
				// not_used_allow_pings
	
	// Wordpress Custom Fields - TO-DO
	
	
	NSString *userid = [currentBlog valueForKey:@"userid"];
	userid = userid ? userid:@"";
	
	// load blog fields into currentBlog
	NSString *blogid = [currentBlog valueForKey:@"blogid"];
	blogid = blogid ? blogid:@"";
		
	NSString *pwd = [currentBlog valueForKey:@"pwd"];
	pwd = pwd ? pwd:@"";
	
	NSString *xmlrpc = [currentBlog valueForKey:@"xmlrpc"];
	xmlrpc = xmlrpc ? xmlrpc:@"";
	NSString *blogHost = [currentBlog valueForKey:@"blog_host_name"];
	
	NSCalendar *cal = [NSCalendar currentCalendar];
	
	NSDateComponents *comps = [cal components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit
																	 fromDate:[NSDate date]];
	//	[comps setYear:[year integerValue]];
	//	[comps setMonth:[month integerValue]];
	//	[comps setDay:[day integerValue]];
	//	[comps setHour:[hr integerValue]];
	//	[comps setMinute:[mn integerValue]];
	//	[comps setSecond:[sec	integerValue]];
	
	NSString *month = [NSString stringWithFormat:@"%d",[comps month]];
	if ([month length] == 1)
		month = [NSString stringWithFormat:@"0%@",month];
	
	NSString *day = [NSString stringWithFormat:@"%d",[comps day]];
	if ([day length] == 1)
		day = [NSString stringWithFormat:@"0%@",day];
	NSString *hour = [NSString stringWithFormat:@"%d",[comps hour]];
	if ([hour length] == 1)
		hour = [NSString stringWithFormat:@"0%@",hour];
	NSString *minute = [NSString stringWithFormat:@"%d",[comps minute]];
	if ([minute length] == 1)
		minute = [NSString stringWithFormat:@"0%@",minute];
	NSString *second = [NSString stringWithFormat:@"%d",[comps second]];
	if ([second length] == 1)
		second = [NSString stringWithFormat:@"0%@",second];
	
	NSString *now =  [NSString stringWithFormat:@"%d%@%@T%@:%@:%@", [comps year]	,month	,day		,hour	,minute,second];

	//[[NSCalendarDate date] descriptionWithCalendarFormat:@"%Y%m%dT%H:%M:%S"];
	//												  timeZone:nil locale:nil];
	// TO_DO translate "draft" to "Draft" using the list of supported statuses
	//NSSTring *status = [[BlogDataManager sharedDataManager] blogPostStatusList] valueForKey:@"draft"]
	
//	
//	self->postFieldNames = [NSArray arrayWithObjects:@"local_status", @"dateCreated", @"userid", 
//							@"postid", @"description", @"title", @"permalink", 
//							@"slug", @"wp_password", @"authorid", @"status", 
//							@"mt_excerpt", @"mt_text_more", @"mt_keywords", 
//							@"not_used_allow_comments", @"link_to_comments", @"not_used_allow_pings",@"dateUpdated", 
//							@"blogid", @"blog_host_name", @"wp_author_display_name",@"date_created_gmt", nil];
	
	
	NSArray *postInitValues = 	[NSArray arrayWithObjects:@"post", now, userid, 
								 @"", @"", @"", @"", 
								 @"", @"", @"", @"draft", 
								 @"", @"", @"", 
								 @"", @"", @"", @"", 
								 blogid, blogHost, @"", now,
								 nil];
	
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjects:postInitValues  forKeys:[self postFieldNames]];
	
	[dict setObject:xmlrpc forKey:@"xmlrpc"];

	//TODO: How to handle localization here.
	NSMutableArray *cats = nil;
	//int index = [[[currentBlog valueForKey:@"categories"] valueForKey:@"categoryName"] indexOfObject:@"Uncategorized"];
	//if( index == -1 )
		cats = [NSMutableArray array];
	//else 
	//	cats = [NSMutableArray arrayWithObject:@"Uncategorized"];
	[dict setObject:cats forKey:@"categories"];

	[dict setObject:@"" forKey:@"title"];
	[dict setObject:@"Local Draft" forKey:@"post_status"];
	[dict setObject:@"Local Draft" forKey:@"post_status_description"];

	[dict setObject:[NSDate date] forKey:@"date_created_gmt"];

	[dict setObject:@"" forKey:@"wp_password"];
	[dict setObject:@"" forKey:@"mt_keywords"];
	[dict setObject:[NSNumber numberWithInt:0] forKey:@"not_used_allow_pings"];
	[dict setObject:@"" forKey:@"mt_excerpt"];
	[dict setObject:[NSNumber numberWithInt:0] forKey:@"not_used_allow_comments"];
	[dict setObject:@"" forKey:@"mt_keywords"];
	
	// setCurrentPost will release current reference and make a mutable copy of this one
	[self setCurrentPost:dict];
	
	// reset the currentPostIndex to nil;
	currentPostIndex = -1;
	
}

- (BOOL)makePostWithPostIDCurrent:(NSString *)postID
{	
	int index = [[postTitlesList valueForKey:@"postid"] indexOfObject:postID];
	if( index >= 0 && index < [postTitlesList count] )
	{
		[self makePostAtIndexCurrent:index];
		return YES;
	}
	return NO;
}

- (void)makePostAtIndexCurrent:(NSUInteger)theIndex {
	
//	WPLog(@"postTitlesList objectAtIndex:theIndex %@", [postTitlesList objectAtIndex:theIndex]);
	
	NSString *pathToPost = [self pathToPost:[self postTitleAtIndex:theIndex] forBlog:currentBlog];
	[self setCurrentPost:[NSMutableDictionary dictionaryWithContentsOfFile:pathToPost]];	
	
	// save the current index as well
	currentPostIndex = theIndex;
	isLocaDraftsCurrent = NO;
	currentDraftIndex = -1;
}

- (int)draftExistsForPostTitle:(id)aPostTitle inDraftsPostTitles:(NSArray *)somePostTitles 
{
	int i, count = [somePostTitles count];
	for ( i=0; i<count ; i++)
	{
		id postTitle = [somePostTitles objectAtIndex:i];
//		WPLog(@"aPostTitle %@ %@ %@", [aPostTitle valueForKey:@"blogid"], [aPostTitle valueForKey:@"blog_host_name"], [aPostTitle valueForKey:@"postid"]);
//		WPLog(@"postTitle %@ %@ %@", [postTitle valueForKey:@"blogid"], [postTitle valueForKey:@"blog_host_name"], [aPostTitle valueForKey:@"original_postid"]);

		if ([[aPostTitle valueForKey:@"blogid"] isEqualToString:[postTitle valueForKey:@"blogid"]] &&
			[[aPostTitle valueForKey:@"blog_host_name"]isEqualToString:[postTitle valueForKey:@"blog_host_name"]] &&
			[[aPostTitle valueForKey:@"postid"]isEqualToString:[postTitle valueForKey:@"original_postid"]]) {
				return i;
			}
 	}

	return -1;
}


- (id)autoSavedPostForCurrentBlog
{
	return [NSMutableDictionary dictionaryWithContentsOfFile:[self autoSavePathForTheCurrentBlog]];
}

- (BOOL)makeAutoSavedPostCurrentForCurrentBlog
{
	NSMutableDictionary *post = [self autoSavedPostForCurrentBlog];
	if( !post || [post count] == 0 )
		return NO;
	
	NSString *draftID = [post valueForKey:@"draftid"];
	if( draftID )
	{
		[self loadDraftTitlesForBlog:currentBlog];
		int index = [[draftTitlesList valueForKey:@"draftid"] indexOfObject:draftID];
		if( index >= 0 && index < [draftTitlesList count] )
		{
			currentDraftIndex = index;
			currentPostIndex = -2;
		}
		else {
			WPLog(@"ERROR : we could not retrieve currentPostIndex from the post title list");
			return NO;
		}
	}	
	else 
	{
		NSString *postID = [post valueForKey:@"postid"];
		if( postID && [postID length] > 0 )
		{
			int index = [[postTitlesList valueForKey:@"postid"] indexOfObject:postID];
			if( index >= 0 && index < [postTitlesList count] )
				currentPostIndex = index;
			else {
				WPLog(@"ERROR : we could not retrieve currentPostIndex from the post title list");
				return NO;
			}
		}		
		else
		{
			//new post
			currentPostIndex = -1;
			currentDraftIndex = -1;
		}
	}
	
	[self setCurrentPost:post];
	
	return YES;
}

- (BOOL)autoSaveCurrentPost
{
	return [currentPost writeToFile:[self autoSavePathForTheCurrentBlog] atomically:YES];
}

- (void)saveCurrentPostAsDraft
{	
	WPLog(@"saveCurrentPostAsDraft ...");
	WPLog(@"isLocaDraftsCurrent %d currentPostIndex %d currentDraftIndex %d", isLocaDraftsCurrent, currentPostIndex, currentDraftIndex );
	
	//we can't save existing post as draft.
	if( !isLocaDraftsCurrent && currentPostIndex != -1 )
	{
		WPLog(@"ERROR: we can't save existing post as draft ....");
		return;
	}

	NSMutableArray *draftTitles = [self draftTitlesForBlog:currentBlog];

	if (currentPostIndex == -1) 
	{
		NSMutableDictionary *postTitle = [self postTitleForPost:currentPost];
		[draftTitles insertObject:postTitle atIndex:0];
		
		NSString *nextDraftID = [[[currentBlog valueForKey:@"kNextDraftIdStr"] retain] autorelease];
		[currentBlog setObject:[[NSNumber numberWithInt:[nextDraftID intValue]+1] stringValue] forKey:@"kNextDraftIdStr"];
		NSNumber *draftsCount = [currentBlog valueForKey:kDraftsCount];
		[currentBlog setObject:[NSNumber numberWithInt:[draftsCount intValue]+1] forKey:kDraftsCount];
		[self saveBlogData];
		
		[currentPost setObject:nextDraftID forKey:@"draftid"];
		[postTitle setObject:nextDraftID forKey:@"draftid"];
		
		[draftTitles writeToFile:[self pathToDraftTitlesForBlog:currentBlog]  atomically:YES];
		NSString *pathToDraft = [self pathToDraft:currentPost forBlog:currentBlog];
		[currentPost writeToFile:pathToDraft atomically:YES];
	}
	else
	{
		NSMutableDictionary *postTitle = [self postTitleForPost:currentPost];
		[postTitle setObject:[currentPost valueForKey:@"draftid"] forKey:@"draftid"];

		[draftTitles replaceObjectAtIndex:currentDraftIndex withObject:postTitle];
		[draftTitles writeToFile:[self pathToDraftTitlesForBlog:currentBlog]  atomically:YES];
		
		[draftTitlesList replaceObjectAtIndex:currentDraftIndex withObject:postTitle];
		
		NSString *pathToPost = [self pathToDraft:currentPost forBlog:currentBlog];
		[currentPost writeToFile:pathToPost atomically:YES];	
	}
	
	[self resetCurrentPost];
	[self resetCurrentDraft];
	
	WPLog(@"draftTitles %u %@", draftTitles, draftTitles);
}

- (id)fectchNewPost:(NSString *)postid formBlog:(id)aBlog
{
	
	WPLog(@"fectchNewPost %@", postid);
	NSArray *args = [NSArray arrayWithObjects:
					 postid,
					 [aBlog valueForKey:@"username"],
					 [aBlog valueForKey:@"pwd"],nil];
	
	XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:[aBlog valueForKey:@"xmlrpc"]]];
	[request setMethod:@"metaWeblog.getPost" withObjects:args];
	
	id post = [self executeXMLRPCRequest:request byHandlingError:YES];
	[request release];
	
	if( [post isKindOfClass:[NSError class]] )
	{
		return nil;
	}
	
	[post setValue:[aBlog valueForKey:@"blogid"] forKey:@"blogid"];
	[post setValue:[aBlog valueForKey:@"blog_host_name"] forKey:@"blog_host_name"];
	[post setValue:@"original" forKey:@"local_status"];

	id posttile = [self postTitleForPost:post];
	NSMutableArray *newPostTitlesList = [NSMutableArray arrayWithContentsOfFile:[self pathToPostTitles:aBlog]];
	
	int index = [[newPostTitlesList valueForKey:@"postid"] indexOfObject:postid];
//	WPLog(@"index %d", index);
	if( index >= 0 && index < [newPostTitlesList count] )
	{
		[newPostTitlesList removeObjectAtIndex:index];
	}
	
	[newPostTitlesList addObject:posttile];
	
	NSSortDescriptor *dateCreatedSortDescriptor =  [[NSSortDescriptor alloc] 
													initWithKey:@"date_created_gmt" ascending:NO];
	NSArray *sortDescriptors = [NSArray arrayWithObjects:dateCreatedSortDescriptor, nil];
	[newPostTitlesList sortUsingDescriptors:sortDescriptors];
	[dateCreatedSortDescriptor release];
	
	if( !( index >= 0 && index < [newPostTitlesList count] ) ) //not existing post, new post
	{
		[aBlog setObject:[NSNumber numberWithInt:[newPostTitlesList count]] forKey:@"totalposts"];
		[aBlog setObject:[NSNumber numberWithInt:[[aBlog valueForKey:@"newposts"] intValue]+1] forKey:@"newposts"];
	}

	[post writeToFile:[self pathToPost:post forBlog:aBlog] atomically:YES]; ;
	[newPostTitlesList writeToFile:[self pathToPostTitles:aBlog]  atomically:YES];
	
	return post;
}

		
//taking post as arg. will help us in implementing async in future.
- (BOOL)savePost:(id)aPost
{
	WPLog(@"------publishCurrentPost ...");
	WPLog(@"publishCurrentPost isLocaDraftsCurrent %d currentPostIndex %d currentDraftIndex %d", isLocaDraftsCurrent, currentPostIndex, currentDraftIndex, currentDraftIndex);
	WPLog(@"current Poist %@", currentPost);
	BOOL successFlag = NO;

	if( ![self appendImagesOfCurrentPostToDescription] )
	{
		WPLog(@"ERROR : unable to add images to server.");
		return successFlag;
	}
	
	if (currentPostIndex == -1 || isLocaDraftsCurrent)
	{
		NSMutableDictionary *postParams = [NSMutableDictionary dictionary];
		
		NSString *title = [currentPost valueForKey:@"title"];
		title = (title == nil ? @"" : title );
		[postParams setObject:title forKey:@"title"];
		
		NSString *tags = [currentPost valueForKey:@"mt_keywords"];
		tags = (tags == nil ? @"" : tags );
		[postParams setObject:tags forKey:@"mt_keywords"];
		
		NSString *description = [currentPost valueForKey:@"description"];
		description = (description == nil ? @"" : description );
		[postParams setObject:description forKey:@"description"];
		
		[postParams setObject:[currentPost valueForKey:@"categories"] forKey:@"categories"];
		
		NSDate *date = [currentPost valueForKey:@"date_created_gmt"];
		NSInteger secs = [[NSTimeZone localTimeZone] secondsFromGMTForDate:date];
		NSDate *gmtDate = [date addTimeInterval:(secs*-1)];
		//[postParams setObject:gmtDate forKey:@"dateCreated"];
		[postParams setObject:gmtDate forKey:@"date_created_gmt"];

		NSString *post_status = [currentPost valueForKey:@"post_status"];		
		if ( !post_status || [post_status isEqualToString:@""] )
			post_status = @"publish";
		[postParams setObject:post_status forKey:@"post_status"];

		[postParams setObject:[[currentPost valueForKey:@"not_used_allow_comments"] stringValue] forKey:@"not_used_allow_comments"];
		[postParams setObject:[[currentPost valueForKey:@"not_used_allow_pings"] stringValue] forKey:@"not_used_allow_pings"];
		[postParams setObject:[currentPost valueForKey:@"wp_password"] forKey:@"wp_password"];
		
//		WPLog(@"currentBlog pwd %@", [currentBlog valueForKey:@"pwd"] );
		NSArray *args = [NSArray arrayWithObjects:[currentBlog valueForKey:@"blogid"],
						 [currentBlog valueForKey:@"username"],
						 [currentBlog valueForKey:@"pwd"],
						 postParams,
						 nil
						 ];
		
		//TODO: take url from current post
		XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:[currentBlog valueForKey:@"xmlrpc"]]];
		[request setMethod:@"metaWeblog.newPost" withObjects:args];
		
		id response = [self executeXMLRPCRequest:request byHandlingError:YES];
//		WPLog(@"publishCurrentPost %@", response);
		[request release];

		if( ![response isKindOfClass:[NSError class]] )
			successFlag = YES;

		//if it is a draft and we successfully published then remove from drafts.
		if( isLocaDraftsCurrent && ![response isKindOfClass:[NSError class]] )
		{
			NSMutableArray *draftPostTitleList = [self draftTitlesForBlog:currentBlog];
			[draftPostTitleList removeObjectAtIndex:currentDraftIndex];
			[draftPostTitleList writeToFile:[self pathToDraftTitlesForBlog:currentBlog]  atomically:YES];
			[self setDraftTitlesList:draftPostTitleList];
			
			NSString *draftPath = [self pathToDraft:currentPost forBlog:currentBlog];
			[[NSFileManager defaultManager] removeItemAtPath:draftPath error:nil];
			
			NSNumber *dc = [currentBlog valueForKey:@"kDraftsCount"];
			[currentBlog setValue:[NSNumber numberWithInt:[dc intValue]-1] forKey:@"kDraftsCount"];			
			[self saveBlogData];
		}
		
		[self fectchNewPost:response formBlog:currentBlog];
	}
	else
	{
//		WPLog(@"currentPost %@", currentPost);
		[currentPost setValue:[currentPost valueForKey:@"userid"] forKey:@"userid"];
		
		NSString *post_status = [currentPost valueForKey:@"post_status"];
		if ( !post_status || [post_status isEqualToString:@""] ) 
			post_status = @"publish";
		[currentPost setObject:post_status forKey:@"post_status"];
		
		NSArray *args = [NSArray arrayWithObjects:[currentPost valueForKey:@"postid"],
						 [currentBlog valueForKey:@"username"],
						 [currentBlog valueForKey:@"pwd"],
						 currentPost,
						 nil
						 ];
//		WPLog(@"args %@", args);
		//TODO: take url from current post
		XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:[currentBlog valueForKey:@"xmlrpc"]]];
		[request setMethod:@"metaWeblog.editPost" withObjects:args];
		
		id response = [self executeXMLRPCRequest:request byHandlingError:YES];
//		WPLog(@"response ... %@", response);
		[request release];
		
		if( ![response isKindOfClass:[NSError class]] )
		{
			[self fectchNewPost:[currentPost valueForKey:@"postid"] formBlog:currentBlog];
			successFlag = YES;
		}

	}
	
	WPLog(@" return flag from save post ... %d", successFlag);
	
	return successFlag;
}

- (void)resetCurrentPost {
	currentPost = nil;
	currentPostIndex = -2;
}

- (NSMutableDictionary *) postTitleForPost:(NSDictionary *)aPost 
{
	NSMutableDictionary *postTitle = [NSMutableDictionary dictionary];
	
	/*
	 self->postFieldNames = [NSArray arrayWithObjects:@"local_status", @"dateCreated", @"userid", 
	 @"postid", @"description", @"title", @"permalink", 
	 @"slug", @"wp_password", @"authorid", @"status", 
	 @"mt_excerpt", @"mt_text_more", @"mt_keywords", 
	 @"not_used_allow_comments", @"link_to_comments", @"not_used_allow_pings",@"dateUpdated", 
	 @"blogid", @"blog_host_name", @"wp_author_display_name", nil];
	 */
	/*
	 
	 self->postTitleFieldNames = [NSArray arrayWithObjects:@"local_status", @"dateCreated", @"blogid",  @"blog_host_name", 
	 @"blogName", @"postid", @"title", @"authorid", @"wp_author_display_name", @"status", 
	 @"mt_excerpt", @"mt_keywords", @"date_created_gmt", 
	 @"newcomments", @"totalcomments",nil];
	 
	 */
	
	
	//NSString *dateCreated = [aPost valueForKey:@"dateCreated"];
	//[postTitle setObject:(dateCreated?dateCreated:@"") forKey:@"date_created_gmt"];
	
	NSString *blogid = [aPost valueForKey:@"blogid"];
	[postTitle setObject:(blogid?blogid:@"") forKey:@"blogid"];
	
	NSString *blogHost = [aPost valueForKey:@"blog_host_name"];
	[postTitle setObject:(blogHost?blogHost:@"") forKey:@"blog_host_name"];
	
	NSString *blogName = [[self blogForId:blogid hostName:blogHost] valueForKey:@"blogName"];
	[postTitle setObject:(blogName?blogName:@"") forKey:@"blogName"];

	
	NSString *postid = [aPost valueForKey:@"postid"];
	[postTitle setObject:(postid?postid:@"") forKey:@"postid"];
	
	// <-- TITLE - first 50 non-WS chars of title or description
	NSCharacterSet *whitespaceCS = [NSCharacterSet whitespaceCharacterSet];
	
	NSString *title = [[aPost valueForKey:@"title"] stringByTrimmingCharactersInSet:whitespaceCS];
//	NSString *description = [[aPost valueForKey:@"description"]
//											stringByTrimmingCharactersInSet:whitespaceCS];
	NSString *trimTitle;
	if ([title length] > 0) {
		
		trimTitle = ([title length] > 50)?[[title substringToIndex:50] stringByAppendingString:@"..."]
										 :title;
		
	} else {
		
		trimTitle = @"(no title)";//([description length] > 50)?[[description substringToIndex:50] stringByAppendingString:@"..."]
									//		   :description;
	}
	
	
	[postTitle setObject:(trimTitle?trimTitle:@"") forKey:@"title"];
	//------ TITLE -->

	NSString *authorid = [aPost valueForKey:@"wp_authorid"];
	[postTitle setObject:(authorid?authorid:@"") forKey:@"wp_authorid"];

	NSString *authorDisplayName = [aPost valueForKey:@"wp_author_display_name"];
	[postTitle setObject:(authorDisplayName?authorDisplayName:@"") forKey:@"wp_author_display_name"];

	NSString *status = [aPost valueForKey:@"post_status"];
	[postTitle setObject:(status?status:@"") forKey:@"post_status"];

	NSString *mtKeywords = [aPost valueForKey:@"mt_keywords"];
	[postTitle setObject:(mtKeywords?mtKeywords:@"") forKey:@"mt_keywords"];
	
	NSString *mtExcerpt = [aPost valueForKey:@"mt_excerpt"];
	[postTitle setObject:(mtExcerpt?mtExcerpt:@"") forKey:@"mt_excerpt"];
	
	NSString *dateCreatedGMT = [aPost valueForKey:@"date_created_gmt"];
	[postTitle setObject:(dateCreatedGMT?dateCreatedGMT:@"") forKey:@"date_created_gmt"];

	NSString *newcomments = [aPost valueForKey:@"newcomments"];
	[postTitle setObject:(newcomments?newcomments:@"0") forKey:@"newcomments"];
	
	NSString *totalcomments = [aPost valueForKey:@"totalcomments"];
	[postTitle setObject:(totalcomments?totalcomments:@"0") forKey:@"totalcomments"];

	return postTitle;	
	
}

#pragma mark -

- (BOOL)createCategory:(NSString *)catTitle parentCategory:(NSString *)parentTitle forBlog:(id)blog
{
//	[[blog valueForKey:@"categories"] addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"sra1", @"categoryName", nil]]; ;
////	[blog setObject:categories forKey:@"categories"];
//	return YES;
	
	NSDictionary *catParms = [NSMutableDictionary dictionaryWithCapacity:4];
	
	[catParms setValue:catTitle forKey:@"name"];
	if( parentTitle && [parentTitle length] )
		[catParms setValue:catTitle forKey:@"parent_id"];
	[catParms setValue:catTitle forKey:@"description"];

	NSArray *args = [NSArray arrayWithObjects:[blog valueForKey:@"blogid"],
					 [blog valueForKey:@"username"],
					 [blog valueForKey:@"pwd"],
					 catParms,
					 nil
					 ];
	
	XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:[blog valueForKey:@"xmlrpc"]]];
	[request setMethod:@"wp.newCategory" withObjects:args];
	
	id response = [self executeXMLRPCRequest:request byHandlingError:YES];
	[request release]; 
	if( [response isKindOfClass:[NSError class]] )
	{
		WPLog(@"ERROR Occured %@", response);
		return NO;
	}
	
	// invoke wp.getCategories
	XMLRPCRequest *reqCategories = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:[blog valueForKey:@"xmlrpc"]]];
	[reqCategories setMethod:@"wp.getCategories" withObjects:args];
	
	NSArray *categories = [self executeXMLRPCRequest:reqCategories byHandlingError:YES];
	[reqCategories release];
	
	if( [categories isKindOfClass:[NSArray class]] ) //might be an error.
	{
//		WPLog(@"categories %@", categories);
		[blog setObject:categories forKey:@"categories"];
	}
	
	[self saveBlogData];
	return YES;
}

#pragma mark -
#pragma mark pictures

- (void)resetPicturesList {
	[photosDB removeAllObjects];
	[self resetCurrentPicture];
}

- (NSDictionary *)pictureAtIndex:(NSUInteger)theIndex{
	return [photosDB objectAtIndex:theIndex];
}

- (void)makePictureAtIndexCurrent:(NSUInteger)theIndex {
	WPLog(@"makePictureAtIndexCurrent");
	[self setCurrentPicture:(NSMutableDictionary*)[self pictureAtIndex:theIndex]];
}

- (void)makeNewPictureCurrent {
	NSArray *pictureInitValues = [NSArray arrayWithObjects:@"", @"", @"untitled",[NSMutableDictionary dictionary], @"", nil];	
	
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjects:pictureInitValues forKeys:[self pictureFieldNames]];
	
	// setCurrentBlog will release current reference and make a mutable copy of this one
	[self setCurrentPicture:dict];
	currentPictureIndex = -1;
}

- (int)currentPictureIndex {
	return currentPictureIndex;
}

- (void)setCurrentPictureIndex:(int)anIndex {
	currentPictureIndex = anIndex;
}

- (void)saveCurrentPicture {
	// save it to the current index if set or add it 
}

- (int)countOfPictures {
	return [photosDB count];
}

- (void)resetCurrentPicture {
	currentPicture = nil;
	currentPictureIndex = -2;
}

- (void)addValueToCurrentPicture:(id)anObject forKey:(NSString *)aKey {
	if ([aKey isEqualToString:pictureSize] || [aKey isEqualToString:pictureFileSize])
		[[currentPicture objectForKey:pictureInfo] setObject:anObject forKey:aKey];
	else
		[currentPicture setObject:anObject forKey:aKey];
}

- (NSString *)statusStringForPicture:(id)aPictObj
{
	switch ([[aPictObj valueForKey:pictureStatus] intValue])
	{
		case -1:
			return [NSString stringWithFormat:@"Uploading err:%@", [aPictObj valueForKey:@"faultString"]];
		case 0:
			return @"Locally Saved";
		case 1:
			return @"Uploadeding to WordPress";
		case 2:
			return @"Uploaded to WordPress";
		default:
			break;
	}
	
	return @"";
}

#pragma mark Pictures List
- (void)loadPictures {
	[self loadPhotosDB];
}


#pragma mark Override mutable collection set methods to make mutableCopy

- (void)setBlogsList:(NSMutableArray *)newArray
{
    if (blogsList != newArray)
    {
        [blogsList release];
        blogsList = [newArray retain];
	}
}


- (void)setPostTitlesList:(NSMutableArray *)newArray
{
    if (postTitlesList != newArray)
    {
        [postTitlesList release];
        postTitlesList = [newArray retain];
    }
}

- (void)setCommentTitlesList:(NSMutableArray *)newArray
{
    if (commentTitlesList != newArray)
    {
        [commentTitlesList release];
        commentTitlesList = [newArray retain];
    }
}

- (void)setDraftTitlesList:(NSMutableArray *)newArray
{
	if (draftTitlesList != newArray)
    {
		[newArray retain];
		[draftTitlesList release];
		draftTitlesList = newArray;
	}
}

- (void)setPhotosDB:(NSMutableArray *)newArray
{
	if (photosDB != newArray)
	{
		[photosDB release];
		photosDB = [newArray mutableCopy];
	}
}

- (void) setCurrentBlog:(NSMutableDictionary *)aBlog {
	
	if (currentBlog != aBlog)
    {
        [currentBlog release];
        currentBlog = [aBlog retain];
    }
}

- (void) setCurrentPost:(NSMutableDictionary *)aPost {
	
	if (currentPost != aPost)
    {
        [currentPost release];
        currentPost = [aPost retain];
    }
}

- (void) setCurrentPicture:(NSMutableDictionary *)aPicture {

	if (currentPicture != aPicture)
	{
		[currentPicture release];
		currentPicture = [aPicture mutableCopy];
	}
}


#pragma mark util methods

- (NSArray *)uniqueArray:(NSArray *)array
{
	int i, count = [array count];
	NSMutableArray *a = [NSMutableArray arrayWithCapacity:[array count]];
	id curOBj = nil;
	
	for( i = 0; i < count; i++ )
	{
		curOBj = [array objectAtIndex:i];
		if( ![a containsObject:curOBj] )
			[a addObject:curOBj];
	}
	
	return a;
}

- (NSString *)statusDescriptionForStatus:(NSString *)curStatus fromBlog:(id)aBlog
{
	if( [curStatus isEqual:@"Local Draft"] )
		return curStatus;
	NSDictionary *postStatusList = [aBlog valueForKey:@"postStatusList"];
	return [postStatusList valueForKey:curStatus];
}

- (NSString *)statusForStatusDescription:(NSString *)statusDescription fromBlog:(id)aBlog
{
	if( [statusDescription isEqual:@"Local Draft"] )
		return statusDescription;
	NSDictionary *postStatusList = [aBlog valueForKey:@"postStatusList"];
	NSArray *dataSource = [postStatusList allValues] ;
	int index = [dataSource indexOfObject:statusDescription];
	if( index != -1 )
	{
		return [[postStatusList allKeys] objectAtIndex:index];
	}
	
	return nil;
}



- (BOOL) syncCommentsForCurrentBlog {
	[self syncCommentsForBlog:currentBlog];
	[self makeBlogAtIndexCurrent:currentBlogIndex];
	return YES;
}

// sync comments for a given blog
- (BOOL) syncCommentsForBlog:(id)blog {
	WPLog(@"<<<<<<<<<<<<<<<<<< syncPostsForBlog >>>>>>>>>>>>>>");
	
	[blog setObject:[NSNumber numberWithInt:1] forKey:@"kIsSyncProcessRunning"];
	// Parameters
	NSString *username = [blog valueForKey:@"username"];
	NSString *pwd = [blog valueForKey:@"pwd"];
	NSString *fullURL = [blog valueForKey:@"xmlrpc"];
	NSString *blogid = [blog valueForKey:@"blogid"];
	
	
	//	WPLog(@"Fetching posts for blog %@ user %@/%@ from %@", blogid, username, pwd, fullURL);
	
	//  ------------------------- invoke metaWeblog.getRecentPosts
	XMLRPCRequest *postsReq = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:fullURL]];
	[postsReq setMethod:@"wp.getComments" 
			withObjects:[NSArray arrayWithObjects:blogid,username, pwd, nil]];
	
	NSMutableArray *commentsList = [NSMutableArray arrayWithArray:[self executeXMLRPCRequest:postsReq byHandlingError:YES]];

	// TODO:
	// Check for fault
	// check for nil or empty response
	// provide meaningful messge to user
	if ((!commentsList) || !([commentsList isKindOfClass:[NSArray class]]) ) {
		WPLog(@"Unknown Error");
		[blog setObject:[NSNumber numberWithInt:0] forKey:@"kIsSyncProcessRunning"];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"BlogsRefreshNotification" object:blog userInfo:nil];
		return NO;
	}
	
	WPLog(@"commentsList is (%@)",commentsList);
	
	NSFileManager *defaultFileManager = [NSFileManager defaultManager];

	NSMutableArray *commentTitlesArray = [NSMutableArray array];
	
	for ( NSDictionary *comment in commentsList ) {
		// add blogid and blog_host_name to post
		NSMutableDictionary *updatedComment = [NSMutableDictionary dictionaryWithDictionary:comment];
		
		[updatedComment setValue:[blog valueForKey:@"blogid"] forKey:@"blogid"];
		[updatedComment setValue:[blog valueForKey:@"blog_host_name"] forKey:@"blog_host_name"];
		
		NSString *path = [self commentFilePath:updatedComment forBlog:blog];

		[defaultFileManager removeFileAtPath:path handler:nil];
		[updatedComment writeToFile:path atomically:YES];
		
		[commentTitlesArray addObject:[self commentTitleForComment:updatedComment]];
	}

	// sort and save the postTitles list
	NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"date_created_gmt" ascending:NO];
	[commentTitlesArray sortUsingDescriptors:[NSArray arrayWithObject:sd]];
	NSString *pathToCommentTitles = [self pathToCommentTitles:blog];
	[defaultFileManager removeFileAtPath:pathToCommentTitles handler:nil];
	[commentTitlesArray writeToFile:pathToCommentTitles  atomically:YES];
	WPLog(@"writing commentTitlesList(%@) to file path (%@)",commentTitlesArray,[self pathToCommentTitles:blog]);
	
	[blog setObject:[NSNumber numberWithInt:0] forKey:@"kIsSyncProcessRunning"];
	return YES;
}


- (NSMutableDictionary *) commentTitleForComment:(NSDictionary *)aComment 
{
	NSMutableDictionary *commentTitle = [NSMutableDictionary dictionary];
	
	NSString *blogid = [aComment valueForKey:@"blogid"];
	[commentTitle setObject:(blogid?blogid:@"") forKey:@"blogid"];
	
	NSString *blogHost = [aComment valueForKey:@"blog_host_name"];
	[commentTitle setObject:(blogHost?blogHost:@"") forKey:@"blog_host_name"];
	
	NSString *blogName = [[self blogForId:blogid hostName:blogHost] valueForKey:@"blogName"];
	[commentTitle setObject:(blogName?blogName:@"") forKey:@"blogName"];
	
	
	NSString *commentid = [aComment valueForKey:@"comment_id"];
	[commentTitle setObject:(commentid?commentid:@"") forKey:@"comment_id"];

	NSString *author = [aComment valueForKey:@"author"];
	[commentTitle setObject:(author?author:@"") forKey:@"author"];

	NSString *status = [aComment valueForKey:@"status"];
	[commentTitle setObject:(status?status:@"") forKey:@"status"];

	NSString *posttitle = [aComment valueForKey:@"post_title"];
	[commentTitle setObject:(posttitle?posttitle:@"") forKey:@"post_title"];

	NSString *dateCreated = [aComment valueForKey:@"date_created_gmt"];
	[commentTitle setObject:(dateCreated?dateCreated:@"") forKey:@"date_created_gmt"];

	NSString *content = [aComment valueForKey:@"content"];
	[commentTitle setObject:(content?content:@"") forKey:@"content"];

	return commentTitle;	
}

// delete comment for a given blog
- (BOOL) deleteComment:(id) aComment forBlog:(id)blog {

	
//function wp_deleteComment($args) { 
//	$this->escape($args); 
//	$blog_id        = (int) $args[0]; 
//	$username       = $args[1]; 
//	$password       = $args[2]; 
//	$comment_ID     = (int) $args[3]; 	WPLog(@"<<<<<<<<<<<<<<<<<< syncPostsForBlog >>>>>>>>>>>>>>");
//}	

	[blog setObject:[NSNumber numberWithInt:1] forKey:@"kIsSyncProcessRunning"];
	// Parameters
	NSString *username = [blog valueForKey:@"username"];
	NSString *pwd = [blog valueForKey:@"pwd"];
	NSString *fullURL = [blog valueForKey:@"xmlrpc"];
	NSString *blogid = [blog valueForKey:@"blogid"];
	NSString *commentid = [aComment valueForKey:@"comment_id"];
	WPLog(@"comment is (%@)",aComment);
	WPLog(@"DELETE COMMENT DETAILS ARE %@",[NSArray arrayWithObjects:blogid,username, pwd, commentid,nil]);

	//  ------------------------- invoke metaWeblog.getRecentPosts
	XMLRPCRequest *postsReq = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:fullURL]];
	[postsReq setMethod:@"wp.deleteComment" 
			withObjects:[NSArray arrayWithObjects:blogid,username, pwd, commentid,nil]];
	
	id result = [self executeXMLRPCRequest:postsReq byHandlingError:YES];
	
	WPLog(@"result is %@ -- its class is %@",result,[result className]);
	
	// TODO:
	// Check for fault
	// check for nil or empty response
	// provide meaningful messge to user
	if ((!result) || !([result isKindOfClass:[NSNumber class]]) ) {
		WPLog(@"Unknown Error");
		[blog setObject:[NSNumber numberWithInt:0] forKey:@"kIsSyncProcessRunning"];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"BlogsRefreshNotification" object:blog userInfo:nil];
		return NO;
	}
		
	NSFileManager *defaultFileManager = [NSFileManager defaultManager];
	
	NSMutableArray *commentTitlesArray = commentTitlesList;
	
	
	NSString *path = [self commentFilePath:aComment forBlog:blog];
	[defaultFileManager removeFileAtPath:path handler:nil];
		
	[commentTitlesList removeObject:aComment];

	// sort and save the postTitles list
	NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"date_created_gmt" ascending:NO];
	[commentTitlesArray sortUsingDescriptors:[NSArray arrayWithObject:sd]];
	NSString *pathToCommentTitles = [self pathToCommentTitles:blog];
	[defaultFileManager removeFileAtPath:pathToCommentTitles handler:nil];
	[commentTitlesArray writeToFile:pathToCommentTitles  atomically:YES];
	WPLog(@"writing commentTitlesList(%@) to file path (%@)",commentTitlesArray,[self pathToCommentTitles:blog]);
	
	[blog setObject:[NSNumber numberWithInt:0] forKey:@"kIsSyncProcessRunning"];
	return YES;
}


// approve comment for a given blog
- (BOOL) approveComment:(id) aComment forBlog:(id)blog {
	
//function wp_editComment($args) { 
//	 $blog_id        = (int) $args[0]; 
//	 $username       = $args[1]; 
//	$password       = $args[2]; 
//	$comment_ID     = (int) $args[3]; 
//	$content_struct = $args[4]; 	
//}
	[blog setObject:[NSNumber numberWithInt:1] forKey:@"kIsSyncProcessRunning"];
	// Parameters
	NSString *username = [blog valueForKey:@"username"];
	NSString *pwd = [blog valueForKey:@"pwd"];
	NSString *fullURL = [blog valueForKey:@"xmlrpc"];
	NSString *blogid = [blog valueForKey:@"blogid"];
	NSString *commentid = [aComment valueForKey:@"comment_id"];
	WPLog(@"comment is (%@)",aComment);
	
	NSString *commentFilePath = [self commentFilePath:aComment forBlog:blog];
	NSDictionary *completeComment = [NSMutableDictionary dictionaryWithContentsOfFile:commentFilePath];

	[aComment setValue:@"approve" forKey:@"status"];
	[completeComment setValue:@"approve" forKey:@"status"];

	WPLog(@"APPROVE COMMENT DETAILS ARE %@",[NSArray arrayWithObjects:blogid,username, pwd, commentid,completeComment,nil]);
	//  ------------------------- invoke metaWeblog.getRecentPosts
	XMLRPCRequest *postsReq = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:fullURL]];
	[postsReq setMethod:@"wp.editComment" 
			withObjects:[NSArray arrayWithObjects:blogid,username, pwd, commentid,completeComment,nil]];
	
	id result = [self executeXMLRPCRequest:postsReq byHandlingError:YES];
	
	WPLog(@"result is %@ -- its class is %@",result,[result className]);
	
	// TODO:
	// Check for fault
	// check for nil or empty response
	// provide meaningful messge to user
	if ((!result) || !([result isKindOfClass:[NSNumber class]]) ) {
		WPLog(@"Unknown Error");
		[blog setObject:[NSNumber numberWithInt:0] forKey:@"kIsSyncProcessRunning"];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"BlogsRefreshNotification" object:blog userInfo:nil];
		return NO;
	}
	
	NSFileManager *defaultFileManager = [NSFileManager defaultManager];
	
	NSMutableArray *commentTitlesArray = commentTitlesList;

	int i=0,count = [commentTitlesArray count];
	
	for ( i = 0; i < count ; i++ ) {
		NSDictionary *dict = [commentTitlesArray objectAtIndex:i];
		
		if ( [[dict valueForKey:@"comment_id"] isEqualToString:commentid] )
			[commentTitlesArray replaceObjectAtIndex:i withObject:aComment];
	}
	

	// sort and save the postTitles list
	NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"date_created_gmt" ascending:NO];
	[commentTitlesArray sortUsingDescriptors:[NSArray arrayWithObject:sd]];
	NSString *pathToCommentTitles = [self pathToCommentTitles:blog];
	[defaultFileManager removeFileAtPath:pathToCommentTitles handler:nil];
	[commentTitlesArray writeToFile:pathToCommentTitles  atomically:YES];
	WPLog(@"writing commentTitlesList(%@) to file path (%@)",commentTitlesArray,[self pathToCommentTitles:blog]);

	[completeComment writeToFile:commentFilePath atomically:YES];
	
	[blog setObject:[NSNumber numberWithInt:0] forKey:@"kIsSyncProcessRunning"];
	return YES;
}


// approve comment for a given blog
- (BOOL) unApproveComment:(id) aComment forBlog:(id)blog {
	
	//function wp_editComment($args) { 
	//	 $blog_id        = (int) $args[0]; 
	//	 $username       = $args[1]; 
	//	$password       = $args[2]; 
	//	$comment_ID     = (int) $args[3]; 
	//	$content_struct = $args[4]; 	
	//}
	[blog setObject:[NSNumber numberWithInt:1] forKey:@"kIsSyncProcessRunning"];
	// Parameters
	NSString *username = [blog valueForKey:@"username"];
	NSString *pwd = [blog valueForKey:@"pwd"];
	NSString *fullURL = [blog valueForKey:@"xmlrpc"];
	NSString *blogid = [blog valueForKey:@"blogid"];
	NSString *commentid = [aComment valueForKey:@"comment_id"];
	WPLog(@"comment is (%@)",aComment);
	
	NSString *commentFilePath = [self commentFilePath:aComment forBlog:blog];
	NSDictionary *completeComment = [NSMutableDictionary dictionaryWithContentsOfFile:commentFilePath];

	
	[aComment setValue:@"spam" forKey:@"status"];
	[completeComment setValue:@"spam" forKey:@"status"];
	
	WPLog(@"UNAPPROVE COMMENT DETAILS ARE %@",[NSArray arrayWithObjects:blogid,username, pwd, commentid,completeComment,nil]);

	//  ------------------------- invoke metaWeblog.getRecentPosts
	XMLRPCRequest *postsReq = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:fullURL]];
	[postsReq setMethod:@"wp.editComment" 
			withObjects:[NSArray arrayWithObjects:blogid,username, pwd, commentid,completeComment,nil]];
	
	id result = [self executeXMLRPCRequest:postsReq byHandlingError:YES];
	
	WPLog(@"result is %@ -- its class is %@",result,[result className]);
	
	// TODO:
	// Check for fault
	// check for nil or empty response
	// provide meaningful messge to user
	if ((!result) || !([result isKindOfClass:[NSNumber class]]) ) {
		WPLog(@"Unknown Error");
		[blog setObject:[NSNumber numberWithInt:0] forKey:@"kIsSyncProcessRunning"];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"BlogsRefreshNotification" object:blog userInfo:nil];
		return NO;
	}
	NSFileManager *defaultFileManager = [NSFileManager defaultManager];
	
	NSMutableArray *commentTitlesArray = commentTitlesList;
	
	
	NSString *path = [self commentFilePath:aComment forBlog:blog];
	[defaultFileManager removeFileAtPath:path handler:nil];
	
	[commentTitlesList removeObject:aComment];
	
	// sort and save the postTitles list
	NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"date_created_gmt" ascending:NO];
	[commentTitlesArray sortUsingDescriptors:[NSArray arrayWithObject:sd]];
	NSString *pathToCommentTitles = [self pathToCommentTitles:blog];
	[defaultFileManager removeFileAtPath:pathToCommentTitles handler:nil];
	[commentTitlesArray writeToFile:pathToCommentTitles  atomically:YES];
	WPLog(@"writing commentTitlesList(%@) to file path (%@)",commentTitlesArray,[self pathToCommentTitles:blog]);
	
	[blog setObject:[NSNumber numberWithInt:0] forKey:@"kIsSyncProcessRunning"];
	return YES;
	
	[blog setObject:[NSNumber numberWithInt:0] forKey:@"kIsSyncProcessRunning"];
	return YES;
}

@end
