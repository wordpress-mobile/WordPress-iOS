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

//@synthesize commentDetails;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		// Initialization code
		commentsList = [[NSMutableArray alloc] initWithCapacity:10];
//        commentDetails = [[NSMutableArray alloc] initWithCapacity:3];
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
	connectionStatus = ( [[Reachability sharedReachability] remoteHostStatus] != NotReachable );
	[commentsTableView reloadData];
	[commentsTableView deselectRowAtIndexPath:[commentsTableView indexPathForSelectedRow] animated:NO];
	commentStatusButton.title=@"";
	[super viewWillAppear:animated];
}


// If you need to do additional setup after loading the view, override viewDidLoad.
- (void)viewDidLoad {
	
	[commentsTableView setDataSource:self];
	// Observe the kNetworkReachabilityChangedNotification. When that notification is posted, the
	// method "reachabilityChanged" will be called. 
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged) name:@"kNetworkReachabilityChangedNotification" object:nil];	
	

	UIBarButtonItem *editButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStyleBordered 
												target:self action:@selector(editComments:)];
	self.navigationItem.rightBarButtonItem = editButtonItem;
	[editButtonItem release];
	
//	[commentsList removeAllObjects];
//	[commentsList addObjectsFromArray:[self getCommentsForBlog:[[BlogDataManager sharedDataManager] currentBlog]]];	
//	
//	int awaitingComments = 0;
//	
//	for ( NSDictionary *dict in commentsList ) {
//		if ( [[dict valueForKey:@"status"] isEqualToString:@"hold"] ) {
//			awaitingComments++;
//		}
//	}
//	
//	if ( awaitingComments == 0 )
//		commentStatusButton.title=@"";
//	else
//		commentStatusButton.title=[NSString stringWithFormat:@"%d awaiting moderation",awaitingComments];
//	
//	[commentsTableView reloadData];
	if ( [commentsList count] == 0 )
		[self performSelectorInBackground:@selector(downloadRecentComments:) withObject:nil];
}
 
- (void)reachabilityChanged
{
	
	WPLog(@"reachabilityChanged ....");
	connectionStatus = ( [[Reachability sharedReachability] remoteHostStatus] != NotReachable );
	
	[commentsTableView reloadData];
}

- (void) editComments :(id)sender {
	
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}


- (void)dealloc {
	
	[commentsTableView release];
	[syncPostsButton release];
	[commentStatusButton release];
	[commentsList release];
//    [commentDetails release];
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
	//wait incase the other thread did not complete its work.
	while (self.navigationItem.rightBarButtonItem == nil)
	{
		[[NSRunLoop currentRunLoop] runUntilDate:[[NSDate date] addTimeInterval:0.1]];
	}
	
	UIBarButtonItem *editButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStyleBordered 
																	  target:self action:@selector(editComments:)];
	self.navigationItem.rightBarButtonItem = editButtonItem;
	[editButtonItem release];
}

- (IBAction)downloadRecentComments:(id)sender {
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	[self performSelectorInBackground:@selector(addProgressIndicator) withObject:nil];

	[commentsList removeAllObjects];
	[commentsList addObjectsFromArray:[self getCommentsForBlog:[[BlogDataManager sharedDataManager] currentBlog]]];	
	
	int awaitingComments = 0;
	
	for ( NSDictionary *dict in commentsList ) {
		if ( [[dict valueForKey:@"status"] isEqualToString:@"hold"] ) {
			awaitingComments++;
		}
	}
	
	if ( awaitingComments == 0 )
		commentStatusButton.title=@"";
	else
		commentStatusButton.title=[NSString stringWithFormat:@"%d awaiting moderation",awaitingComments];

	
	[self removeProgressIndicator];
	
	[commentsTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
	[pool release];
}


// sync posts for a given blog
- (NSArray *) getCommentsForBlog:(id)blog {
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
	
	NSArray *commentsList = [[BlogDataManager sharedDataManager] executeXMLRPCRequest:postsReq byHandlingError:YES];
	
	WPLog(@"commentsList is (%@)",commentsList);
	
	[blog setObject:[NSNumber numberWithInt:0] forKey:@"kIsSyncProcessRunning"];
	return commentsList;
}

#define COMMENT_NAME_TAG 100
#define COMMENT_POST_NAME_AND_DATE_TAG 200

NSString *NSStringFromCGRect(CGRect rect ) {

	return [NSString stringWithFormat:@"x-%f,y-%f,width-%f,heigh-%f",rect.origin.x,rect.origin.y,rect.size.width,rect.size.height];
}

- (UITableViewCell *)tableviewCellWithReuseIdentifier:(NSString *)identifier {
	
	/*
	 Create an instance of UITableViewCell and add tagged subviews for the name, local time, and quarter image of the time zone.
	 */
	CGRect rect;
	
	rect = CGRectMake(0.0, 0.0, 320.0, COMMENTS_TABLE_ROW_HEIGHT);
	
	UITableViewCell *cell = [[[UITableViewCell alloc] initWithFrame:rect reuseIdentifier:identifier] autorelease];
	
#define LEFT_OFFSET 10.0f
#define RIGHT_OFFSET 280.0f
	
#define MAIN_FONT_SIZE 18.0f
#define DATE_FONT_SIZE 13.0f
	
#define LABEL_HEIGHT 18.0f
#define DATE_LABEL_HEIGHT 13.0f
#define VERTICAL_OFFSET	4.0f
	
	
	/*
	 Create labels for the text fields; set the highlight color so that when the cell is selected it changes appropriately.
	 */
	UILabel *label;
	
	rect = CGRectMake(LEFT_OFFSET, (COMMENTS_TABLE_ROW_HEIGHT - LABEL_HEIGHT - DATE_LABEL_HEIGHT - VERTICAL_OFFSET ) / 2.0, 288, LABEL_HEIGHT);
	NSLog(@"COMMENT_NAME_TAG rect is (%@)",NSStringFromCGRect(rect));
	
	label = [[UILabel alloc] initWithFrame:rect];
	label.tag = COMMENT_NAME_TAG;
	label.font = [UIFont boldSystemFontOfSize:MAIN_FONT_SIZE];
	//	label.adjustsFontSizeToFitWidth = YES;
	[cell.contentView addSubview:label];
	label.highlightedTextColor = [UIColor whiteColor];
	[label release];
	

	rect = CGRectMake(LEFT_OFFSET, rect.origin.y+ LABEL_HEIGHT + VERTICAL_OFFSET , 320, DATE_LABEL_HEIGHT);
	
	label = [[UILabel alloc] initWithFrame:rect];
	label.tag = COMMENT_POST_NAME_AND_DATE_TAG;
	label.font = [UIFont systemFontOfSize:DATE_FONT_SIZE];
	[cell.contentView addSubview:label];
	label.highlightedTextColor = [UIColor whiteColor];
	label.textColor = [UIColor colorWithRed:0.560f green:0.560f blue:0.560f alpha:1];
	[label release];
	
	
	return cell;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == 0)
		return [commentsList count];
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
		
	if (indexPath.section == 0) 
	{
		WPLog(@"[commentsList objectAtIndex:(indexPath.row)] is (%@)",[commentsList objectAtIndex:(indexPath.row)]);
//		
//		cell.text = [NSString stringWithFormat:@"%@,%@,%@",author,post_title,date_created_gmt];
//		
//		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
//		//#define MAIN_FONT_SIZE 15.0f
//		cell.font = [cell.font fontWithSize:15.0f];
		static NSString *postsTableRowId = @"postsTableRowId";
		
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:postsTableRowId];
		if (cell == nil) {
			cell = [self tableviewCellWithReuseIdentifier:postsTableRowId];
			//[[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:postsTableRowId] autorelease];
		}
		
		NSLog(@"cell is (%@)",cell);
				
		if ( [[commentsList objectAtIndex:(indexPath.row)] count] ) 
		{

			NSCharacterSet *whitespaceCS = [NSCharacterSet whitespaceCharacterSet];
			
			NSString *author = [[[commentsList objectAtIndex:(indexPath.row)] valueForKey:@"author"] stringByTrimmingCharactersInSet:whitespaceCS];
			NSString *post_title = [[[commentsList objectAtIndex:(indexPath.row)] valueForKey:@"post_title"]stringByTrimmingCharactersInSet:whitespaceCS];
			NSString *date_created_gmt = [[commentsList objectAtIndex:(indexPath.row)] valueForKey:@"date_created_gmt"];

			UILabel *label = (UILabel *)[cell viewWithTag:COMMENT_NAME_TAG];
			label.text = author;
			
			static NSDateFormatter *dateFormatter = nil;
			if (dateFormatter == nil) {
				dateFormatter = [[NSDateFormatter alloc] init];
				[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
				[dateFormatter setDateStyle:NSDateFormatterLongStyle];
			}

			label = (UILabel *)[cell viewWithTag:COMMENT_POST_NAME_AND_DATE_TAG];
			label.text = [NSString stringWithFormat:@"%@ , %@",post_title,[[dateFormatter stringFromDate:date_created_gmt] description]];

			label.textColor = ( connectionStatus ? [UIColor blackColor] : [UIColor grayColor] );
			
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}
		return cell;
	}
	return nil;
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
    [commentsViewController fillCommentDetails:commentsList atRow:indexPath.row];
    [commentsViewController release];
        
}


@end