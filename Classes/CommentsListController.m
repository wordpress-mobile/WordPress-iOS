//
//  CommentsListController.m
//  WordPress
//
//  Created by Janakiram on 02/09/08.
//  Copyright 2008 Effigent. All rights reserved.
//

#import "CommentsListController.h"

#import "XMLRPCRequest.h"
#import "XMLRPCResponse.h"
#import "XMLRPCConnection.h"
#import "BlogDataManager.h"
#import "Reachability.h"
#import "NSString+XMLExtensions.h"
#import "WPCommentsDetailViewController.h"

#define COMMENTS_TABLE_ROW_HEIGHT 65.0f


@implementation CommentsListController
@synthesize selectedComments,commentsArray;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		// Initialization code
		editMode = NO;
		changeEditMode = NO;
		commentsDict=[[NSMutableDictionary alloc]init];
		selectedComments=[[NSMutableArray alloc]init];
	}
	return self;
}

/*
 Implement loadView if you want to create a view hierarchy programmatically
 - (void)loadView {
 }
 */

- (void)viewWillAppear:(BOOL)animated {
	
	WPLog(@"PostsList:viewWillAppear");
	
	editMode = NO;
	changeEditMode = YES;
	
	BlogDataManager *sharedDataManager = [BlogDataManager sharedDataManager];
	[sharedDataManager loadCommentTitlesForCurrentBlog];
	
	if(!selectedComments)
		selectedComments=[[NSMutableArray alloc]init];
	else
		[selectedComments removeAllObjects];
	BlogDataManager *sharedBlogDataManager = [BlogDataManager sharedDataManager];
	NSMutableArray *commentsList = [sharedBlogDataManager commentTitlesForBlog:[sharedBlogDataManager currentBlog]];
	[self setCommentsArray:commentsList];
	int awaitingComments = 0;
	
	for ( NSDictionary *dict in commentsArray ) {
		NSString *str=[dict valueForKey:@"comment_id"];
		[commentsDict setValue:dict forKey:str];
		WPLog(@"Comment Status is (%@)",[dict valueForKey:@"status"]);
		if ( [[dict valueForKey:@"status"] isEqualToString:@"hold"] ) {
			awaitingComments++;
		}
	}
	
	WPLog(@"awaitingComments (%d)",awaitingComments);
	if ( awaitingComments == 0 )
		[commentStatusButton setTitle:@"" forState:UIControlStateNormal];
	else
		[commentStatusButton setTitle:[NSString stringWithFormat:@"%d awaiting moderation",awaitingComments] forState:UIControlStateNormal];
	
	connectionStatus = ( [[Reachability sharedReachability] remoteHostStatus] != NotReachable );
	[commentsTableView deselectRowAtIndexPath:[commentsTableView indexPathForSelectedRow] animated:NO];
	[commentsTableView reloadData];
	
	[editToolbar setHidden:YES];

	[editButtonItem setEnabled:([commentsArray count]>0)];

	[super viewWillAppear:animated];
}
- (void)viewWillDisappear:(BOOL)animated{
	WPLog(@"viewWillDisappear ");
	[commentsArray removeAllObjects];
	[selectedComments removeAllObjects];
}

// If you need to do additional setup after loading the view, override viewDidLoad.
- (void)viewDidLoad {
	
	[super viewDidLoad];
	[commentsTableView setDataSource:self];
	// Observe the kNetworkReachabilityChangedNotification. When that notification is posted, the
	// method "reachabilityChanged" will be called. 
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged) name:@"kNetworkReachabilityChangedNotification" object:nil];	
	editButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStyleBordered 
													 target:self action:@selector(editComments:)];
	self.navigationItem.rightBarButtonItem = editButtonItem;
		
		[editButtonItem setEnabled:([commentsArray count]>0)];
	
}

- (void)reachabilityChanged
{
	WPLog(@"reachabilityChanged ....");
	connectionStatus = ( [[Reachability sharedReachability] remoteHostStatus] != NotReachable );
	
	[commentsTableView reloadData];
}

- (void) editComments :(id)sender {
	changeEditMode=YES;
	
	editButtonItem.title = (editMode==NO) ? @"Cancel" : @"Edit";
	
	[editToolbar setHidden:editMode];
	
	[deleteButton setEnabled:editMode];
	[approveButton setEnabled:editMode];
	[unapproveButton setEnabled:editMode];

	editMode = !editMode;
	[commentsTableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return NO;
}



- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}


- (void)dealloc {
	[commentsArray release];
	[commentsDict release];
	[selectedComments release];
    [editButtonItem release];
	[commentsTableView release];
	[syncPostsButton release];
	[super dealloc];
}

- (void)addProgressIndicator
{
	NSAutoreleasePool *apool = [[NSAutoreleasePool alloc] init];
	UIActivityIndicatorView *aiv = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	UIBarButtonItem *activityButtonItem = [[UIBarButtonItem alloc] initWithCustomView:aiv];
	[aiv startAnimating]; 
	[aiv release];
	
	self.navigationItem.rightBarButtonItem = activityButtonItem;
	[activityButtonItem release];
	[apool release];
}

- (void)removeProgressIndicator
{
	NSAutoreleasePool *apool = [[NSAutoreleasePool alloc] init];
	//wait incase the other thread did not complete its work.
	while (self.navigationItem.rightBarButtonItem == nil){
		[[NSRunLoop currentRunLoop] runUntilDate:[[NSDate date] addTimeInterval:0.1]];
	}
	
	self.navigationItem.rightBarButtonItem = editButtonItem;
	[apool release];
}

- (IBAction)downloadRecentComments:(id)sender {
	
	if( !connectionStatus ){
		UIAlertView *alert1 = [[UIAlertView alloc] initWithTitle:@"No connection to host."
														 message:@"Sync operation is not supported now."
														delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
		
		[alert1 show];
		[alert1 release];		
		
		return;
	}
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[self performSelectorInBackground:@selector(addProgressIndicator) withObject:nil];
	
	
	BlogDataManager *sharedBlogDataManager = [BlogDataManager sharedDataManager];
	[sharedBlogDataManager syncCommentsForCurrentBlog];
	[sharedBlogDataManager loadCommentTitlesForCurrentBlog];
	
	NSArray *commentsList = [sharedBlogDataManager commentTitlesForBlog:[sharedBlogDataManager currentBlog]];
	[self setCommentsArray:(NSMutableArray *)commentsList];
	int awaitingComments = 0;
	
	for ( NSDictionary *dict in commentsList ) {
		if ( [[dict valueForKey:@"status"] isEqualToString:@"hold"] ) {
			awaitingComments++;
		}
	}
	
	if ( awaitingComments == 0 )
		[commentStatusButton setTitle:@"" forState:UIControlStateNormal];
	else
		[commentStatusButton setTitle:[NSString stringWithFormat:@"%d awaiting moderation",awaitingComments] forState:UIControlStateNormal];
			
	[self removeProgressIndicator];
	
	[commentsTableView reloadData];
	[editButtonItem setEnabled:([commentsArray count]>0)];

	[pool release];
}

- (IBAction)deleteSelectedComments:(id)sender{
	WPLog(@"deleteSelectedComments");
    UIAlertView *deleteAlert = [[UIAlertView alloc] initWithTitle:@"Delete Comments" message:@"Are you sure you want to delete this Comments?" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:@"Cancel", nil];                                                
    [deleteAlert setTag:1];  // for UIAlertView Delegate to handle which view is popped.
    [deleteAlert show];
		
}
- (IBAction)approveSelectedComments:(id)sender{
	
	WPLog(@"approveSelectedComments");
	UIAlertView *deleteAlert = [[UIAlertView alloc] initWithTitle:@"Approve Comments" message:@"Are you sure you want to Approve this Comments?" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:@"Cancel", nil];                                                
	[deleteAlert setTag:2];  // for UIAlertView Delegate to handle which view is popped.
	[deleteAlert show];
	
}
- (IBAction)unapproveSelectedComments:(id)sender{
	WPLog(@"unapproveSelectedComments");
	UIAlertView *deleteAlert = [[UIAlertView alloc] initWithTitle:@"Unapprove Comments" message:@"Are you sure you want to Unapprove this Comments?" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:@"Cancel", nil];                                                
	[deleteAlert setTag:3];  // for UIAlertView Delegate to handle which view is popped.
	[deleteAlert show];
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	
    WPLog(@"The Alet name %d",[alertView tag]);
	
	//optimised code but need to comprimise at Alert messages.....Common message for all @"Operation is not supported now."
	if ( buttonIndex == 0 ) {
		
		if ( ![[Reachability sharedReachability] remoteHostStatus] != NotReachable ) {
			
			UIAlertView *alert1 = [[UIAlertView alloc] initWithTitle:@"No connection to host."
															 message:@"Operation is not supported now."
															delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
			[alert1 show];
			[alert1 release];		
			return;
		}  
		
		[self performSelectorInBackground:@selector(addProgressIndicator) withObject:nil];
		BlogDataManager *sharedDataManager = [BlogDataManager sharedDataManager];
		
		BOOL result;
		NSArray *selectedItems=[self selectedComments];
		if([alertView tag] == 1){
			result = [sharedDataManager deleteComment:selectedItems forBlog:[sharedDataManager currentBlog]];
		} else if([alertView tag] == 2){
			result = [sharedDataManager approveComment:selectedItems forBlog:[sharedDataManager currentBlog]];
		} else if([alertView tag] == 3){
			result = [sharedDataManager unApproveComment:selectedItems forBlog:[sharedDataManager currentBlog]];
		}
		
		if ( result ) {
			[sharedDataManager loadCommentTitlesForCurrentBlog];
			[self.navigationController popViewControllerAnimated:YES];
		}
		[self performSelectorInBackground:@selector(removeProgressIndicator) withObject:nil];
    }
	[editButtonItem setEnabled:([commentsArray count]>0)];
    [alertView autorelease];
}

// sync posts for a given blog
//- (NSArray *) getCommentsForBlog:(id)blog {
//	WPLog(@"<<<<<<<<<<<<<<<<<< syncPostsForBlog >>>>>>>>>>>>>>");
//
//	[blog setObject:[NSNumber numberWithInt:1] forKey:@"kIsSyncProcessRunning"];
//	// Parameters
//	NSString *username = [blog valueForKey:@"username"];
//	NSString *pwd = [blog valueForKey:@"pwd"];
//	NSString *fullURL = [blog valueForKey:@"xmlrpc"];
//	NSString *blogid = [blog valueForKey:@"blogid"];
//
//	
//	//	WPLog(@"Fetching posts for blog %@ user %@/%@ from %@", blogid, username, pwd, fullURL);
//	
//	//  ------------------------- invoke metaWeblog.getRecentPosts
//	XMLRPCRequest *postsReq = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:fullURL]];
//	[postsReq setMethod:@"wp.getComments" 
//			withObjects:[NSArray arrayWithObjects:blogid,username, pwd, nil]];
//	
//	NSArray *commentsList = [[BlogDataManager sharedDataManager] executeXMLRPCRequest:postsReq byHandlingError:YES];
//	
//	WPLog(@"commentsList is (%@)",commentsList);
//	
//	[blog setObject:[NSNumber numberWithInt:0] forKey:@"kIsSyncProcessRunning"];
//	return commentsList;
//}

#define COMMENT_NAME_TAG 100
#define COMMENT_POST_NAME_AND_DATE_TAG 200

NSString *NSStringFromCGRect(CGRect rect ) {
	
	return [NSString stringWithFormat:@"x-%f,y-%f,width-%f,heigh-%f",rect.origin.x,rect.origin.y,rect.size.width,rect.size.height];
}

- (UITableViewCell *)tableviewCellWithReuseIdentifier:(NSString *)identifier withCategoryId:(int)categoryId {
	
	/*
	 Create an instance of UITableViewCell and add tagged subviews for the name, local time, and quarter image of the time zone.
	 */
	CGRect rect;
	
	rect = CGRectMake(0.0, 0.0, 400.0, COMMENTS_TABLE_ROW_HEIGHT);
	
	UITableViewCell *cell = [[[UITableViewCell alloc] initWithFrame:rect reuseIdentifier:identifier] autorelease];
	
#define LEFT_OFFSET 10.0f
#define RIGHT_OFFSET 280.0f
	
#define MAIN_FONT_SIZE 18.0f
#define DATE_FONT_SIZE 13.0f
	
#define LABEL_HEIGHT 18.0f
#define DATE_LABEL_HEIGHT 13.0f
#define VERTICAL_OFFSET	4.0f
	
	int buttonOffset = 0;
	if ( editMode == YES ) {
		rect = CGRectMake(LEFT_OFFSET,15, 30, COMMENTS_TABLE_ROW_HEIGHT-30);
		UIButton *but = [[UIButton alloc] initWithFrame:rect]; 
		[but setImage:[UIImage imageNamed:@"uncheck.png"] forState:UIControlStateNormal];
		[but setTag:categoryId];
		[but addTarget:self action:@selector(commentSelected:) forControlEvents:UIControlEventTouchUpInside];
		[cell.contentView addSubview:but];
		[but release];
		buttonOffset = 35;
	}
	
	/*
	 Create labels for the text fields; set the highlight color so that when the cell is selected it changes appropriately.
	 */
	UILabel *label;
	
	rect = CGRectMake(LEFT_OFFSET+buttonOffset, (COMMENTS_TABLE_ROW_HEIGHT - LABEL_HEIGHT - DATE_LABEL_HEIGHT - VERTICAL_OFFSET ) / 2.0, 288-buttonOffset, LABEL_HEIGHT);
	
	label = [[UILabel alloc] initWithFrame:rect];
	label.tag = COMMENT_NAME_TAG;
	label.font = [UIFont boldSystemFontOfSize:MAIN_FONT_SIZE];
	[cell.contentView addSubview:label];
	label.highlightedTextColor = [UIColor whiteColor];
	[label release];
	
	
	rect = CGRectMake(LEFT_OFFSET+buttonOffset, rect.origin.y+ LABEL_HEIGHT + VERTICAL_OFFSET , rect.size.width, DATE_LABEL_HEIGHT);
	
	label = [[UILabel alloc] initWithFrame:rect];
	label.tag = COMMENT_POST_NAME_AND_DATE_TAG;
	label.font = [UIFont systemFontOfSize:DATE_FONT_SIZE];
	[cell.contentView addSubview:label];
	label.highlightedTextColor = [UIColor whiteColor];
	label.textColor = [UIColor colorWithRed:0.560f green:0.560f blue:0.560f alpha:1];
	[label release];
	
	return cell;
}

-(void)commentSelected:(id)sender
{
   int toggleTag = [sender tag];
	NSString *str=[NSString stringWithFormat:@"%d",toggleTag];
	
	NSDictionary *dict  = [commentsDict valueForKey:str];
	if ( [selectedComments containsObject:dict] ) {
		[selectedComments removeObject:dict];
		[sender setImage:[UIImage imageNamed:@"uncheck.png"] forState:UIControlStateNormal];  
	} else {
		[selectedComments addObject:dict];
        [sender setImage:[UIImage imageNamed:@"check.png"] forState:UIControlStateNormal];  
	}
	int count=[selectedComments count];
	
	if(count){
		[approveButton setTitle:[NSString stringWithFormat:@"Approve (%d)",count]];
		[unapproveButton setTitle:[NSString stringWithFormat:@"Unapprove (%d)",count]];
		[spamButton setTitle:[NSString stringWithFormat:@"Spam (%d)",count]];
		[deleteButton setEnabled:YES];
		[approveButton setEnabled:YES];
		[unapproveButton setEnabled:YES];
	}else{
		[approveButton setTitle:@"Approve"];
		[unapproveButton setTitle:@"Unapprove"];
		[spamButton setTitle:@"Spam"];
		[deleteButton setEnabled:NO];
		[approveButton setEnabled:NO];
		[unapproveButton setEnabled:NO];
	}
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == 0) {
		WPLog(@" countOfCommentTitles -- %d",[[BlogDataManager sharedDataManager] countOfCommentTitles]);
//		return [[BlogDataManager sharedDataManager] countOfCommentTitles];
		return [commentsArray count];
	}	
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *postsTableRowId = @"postsTableRowId";

	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:postsTableRowId];
	id currentComment = [commentsArray objectAtIndex:indexPath.row];
	
	if (cell == nil || changeEditMode) {
		cell = [self tableviewCellWithReuseIdentifier:postsTableRowId withCategoryId:[[currentComment valueForKey:@"comment_id"]intValue]];
		//- (UITableViewCell *)tableviewCellWithReuseIdentifier:(NSString *)identifier withCategoryId:(NSNumber *)categoryId
		//[[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:postsTableRowId] autorelease];
	}
	
	
	//WPLog(@"currentComment %@",currentComment);
	NSCharacterSet *whitespaceCS = [NSCharacterSet whitespaceCharacterSet];
	NSString *author = [[currentComment valueForKey:@"author"] stringByTrimmingCharactersInSet:whitespaceCS];
	NSString *post_title = [[currentComment valueForKey:@"post_title"]stringByTrimmingCharactersInSet:whitespaceCS];
	NSDate *date_created_gmt = [currentComment valueForKey:@"date_created_gmt"];
	NSString *commentStatus=[currentComment valueForKey:@"status"];
	UILabel *label = (UILabel *)[cell viewWithTag:COMMENT_NAME_TAG];
	label.text = author;
	
	static NSDateFormatter *dateFormatter = nil;
	if (dateFormatter == nil) {
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		[dateFormatter setDateStyle:NSDateFormatterLongStyle];
	}
	
	label.textColor = ( connectionStatus ? [UIColor blackColor] : [UIColor grayColor] );
	if([commentStatus isEqual:@"hold"])
	   [label setTextColor:[UIColor grayColor]];
		
	label = (UILabel *)[cell viewWithTag:COMMENT_POST_NAME_AND_DATE_TAG];
	label.text = [NSString stringWithFormat:@"%@ , %@",post_title,[[dateFormatter stringFromDate:date_created_gmt] description]];
	[label setLineBreakMode:UILineBreakModeTailTruncation];
	label.textColor = ( connectionStatus ? [UIColor blackColor] : [UIColor grayColor] );
	
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	return cell;
	
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return COMMENTS_TABLE_ROW_HEIGHT;
}

// Show PostList when row is selected
- (void)tableView:(UITableView *)atableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WPLog(@"didSelectRowAtIndexPath:: Load The View");
    WPCommentsDetailViewController *commentsViewController = [[WPCommentsDetailViewController alloc] initWithNibName:@"WPCommentsDetailViewController" bundle:nil];
    [self.navigationController pushViewController:commentsViewController animated:YES];
    [commentsViewController fillCommentDetails:[[BlogDataManager sharedDataManager] commentTitles]
										 atRow:indexPath.row];
	
    [commentsViewController release];
	
}


@end