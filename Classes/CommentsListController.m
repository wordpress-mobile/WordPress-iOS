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
	editButtonItem.title = @"Edit";
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
	[spamButton setEnabled:editMode];

	editMode = !editMode;
	[commentsTableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return YES;
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
#pragma mark -
#pragma mark Action methods
- (IBAction)downloadRecentComments:(id)sender {
	
	if( !connectionStatus ){
		UIAlertView *alert1 = [[UIAlertView alloc] initWithTitle:@"No connection to host."
														 message:@"Sync operation is not supported now."
														delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		
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
//    UIAlertView *deleteAlert = [[UIAlertView alloc] initWithTitle:@"Delete Comments" message:@"Are you sure you want to delete this comment?" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"Cancel", nil];
    UIAlertView *deleteAlert = [[UIAlertView alloc] initWithTitle:@"Delete Comments" message:@"Are you sure you want to delete the selected comment(s)?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];                                                
    [deleteAlert setTag:1];  // for UIAlertView Delegate to handle which view is popped.
    [deleteAlert show];
		
}
- (IBAction)approveSelectedComments:(id)sender{
	
	WPLog(@"approveSelectedComments");
//	UIAlertView *deleteAlert = [[UIAlertView alloc] initWithTitle:@"Approve Comments" message:@"Are you sure you want to Approve this comment?" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"Cancel", nil];
	UIAlertView *deleteAlert = [[UIAlertView alloc] initWithTitle:@"Approve Comments" message:@"Are you sure you want to approve the selected comment(s)?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];                                                
	[deleteAlert setTag:2];  // for UIAlertView Delegate to handle which view is popped.
	[deleteAlert show];
	
}
- (IBAction)unapproveSelectedComments:(id)sender{
	WPLog(@"unapproveSelectedComments");
//	UIAlertView *deleteAlert = [[UIAlertView alloc] initWithTitle:@"Unapprove Comments" message:@"Are you sure you want to Unapprove this comment?" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"Cancel", nil];
	UIAlertView *deleteAlert = [[UIAlertView alloc] initWithTitle:@"Unapprove Comments" message:@"Are you sure you want to unapprove the selected comment(s)?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];                                                
	[deleteAlert setTag:3];  // for UIAlertView Delegate to handle which view is popped.
	[deleteAlert show];
}

- (IBAction)spamSelectedComments:(id)sender{
	WPLog(@"spamSelectedComments");
//	UIAlertView *deleteAlert = [[UIAlertView alloc] initWithTitle:@"Spam Comments" message:@"Are you sure you want to Spam this comment?" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"Cancel", nil];
	UIAlertView *deleteAlert = [[UIAlertView alloc] initWithTitle:@"Spam Comments" message:@"Are you sure you want to mark the selected comment(s) as spam?. This action can only be reversed in the web admin." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];                                                
	[deleteAlert setTag:4];  // for UIAlertView Delegate to handle which view is popped.
	[deleteAlert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    WPLog(@"The Alet name %d",[alertView tag]);
	
	//optimised code but need to comprimise at Alert messages.....Common message for all @"Operation is not supported now."
//	if ( buttonIndex == 0 ) 
	if ( buttonIndex == 1 ) 
	{
		if ( ![[Reachability sharedReachability] remoteHostStatus] != NotReachable ) {
			
			UIAlertView *connectionFailAlert = [[UIAlertView alloc] initWithTitle:@"No connection to host."
															 message:@"Operation is not supported now."
															delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[connectionFailAlert show];
			[connectionFailAlert release];		
			return;
		}  
		
		[self performSelectorInBackground:@selector(addProgressIndicator) withObject:nil];
		BlogDataManager *sharedDataManager = [BlogDataManager sharedDataManager];
		
		BOOL result;
		NSArray *selectedItems=[self selectedComments];
		if([alertView tag] == 1){
			result = [sharedDataManager deleteComment:selectedItems forBlog:[sharedDataManager currentBlog]];
		} else if([alertView tag] == 2){
			result = [sharedDataManager approveComment:(NSMutableArray *)selectedItems forBlog:[sharedDataManager currentBlog]];
		} else if([alertView tag] == 3){
			result = [sharedDataManager unApproveComment:(NSMutableArray *)selectedItems forBlog:[sharedDataManager currentBlog]];
		}else if([alertView tag] == 4){
			result = [sharedDataManager spamComment:(NSMutableArray *)selectedItems forBlog:[sharedDataManager currentBlog]];
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

#define COMMENT_NAME_TAG 100
#define COMMENT_POST_NAME_AND_DATE_TAG 200
#define COMMENT_MAIL_TAG 300

NSString *NSStringFromCGRect(CGRect rect ) {
	
	return [NSString stringWithFormat:@"x-%f,y-%f,width-%f,heigh-%f",rect.origin.x,rect.origin.y,rect.size.width,rect.size.height];
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
	
	int i,approvedCount,unapprovedCount,spamCount,count=[selectedComments count];
	
	approvedCount = unapprovedCount = spamCount = 0;
	for (i=0; i<count; i++) {
		NSDictionary *dict=[selectedComments objectAtIndex:i];
		if([[dict valueForKey:@"status"] isEqualToString:@"hold"])
			unapprovedCount++;
		else if([[dict valueForKey:@"status"] isEqualToString:@"approve"])
			approvedCount++;
		else if([[dict valueForKey:@"status"] isEqualToString:@"spam"])
			spamCount++;
	}
	
	[deleteButton setEnabled:((count > 0)?YES:NO)];
	[approveButton setEnabled:(((count-approvedCount) > 0)?YES:NO)];
	[unapproveButton setEnabled:(((count-unapprovedCount) > 0)?YES:NO)];
	[spamButton setEnabled:(((count-spamCount) > 0)?YES:NO)];
	
	[approveButton setTitle:(((count-approvedCount) > 0)?[NSString stringWithFormat:@"Approve (%d)",count-approvedCount]:@"Approve")];
	[unapproveButton setTitle:(((count-unapprovedCount) > 0)?[NSString stringWithFormat:@"Unapprove (%d)",count-unapprovedCount]:@"Unapprove")];
	[spamButton setTitle:(((count-spamCount) > 0)?[NSString stringWithFormat:@"Spam (%d)",count-spamCount]:@"Spam")];
	
	//WPLog(@"unapprovedCount %d approvedCount %d spamCount %d",unapprovedCount,approvedCount,spamCount);
}
#pragma mark -
#pragma mark tableview methods

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
	
#define LABEL_HEIGHT 20.0f
#define DATE_LABEL_HEIGHT 35.0f
#define VERTICAL_OFFSET	1.0f
	
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
	
	rect = CGRectMake(LEFT_OFFSET+buttonOffset+150, (COMMENTS_TABLE_ROW_HEIGHT - LABEL_HEIGHT - DATE_LABEL_HEIGHT - VERTICAL_OFFSET ) / 2.0, 150-buttonOffset, LABEL_HEIGHT);
	UILabel *alabel = [[UILabel alloc]initWithFrame:rect];
	alabel.tag = COMMENT_MAIL_TAG;
	alabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
	[cell.contentView addSubview:alabel];
	[alabel release];

	
	rect = CGRectMake(LEFT_OFFSET+buttonOffset, (COMMENTS_TABLE_ROW_HEIGHT - LABEL_HEIGHT - DATE_LABEL_HEIGHT - VERTICAL_OFFSET ) / 2.0, 150-buttonOffset, LABEL_HEIGHT);
	label = [[UILabel alloc] initWithFrame:rect];
	label.tag = COMMENT_NAME_TAG;
	label.font = [UIFont boldSystemFontOfSize:MAIN_FONT_SIZE];
	[cell.contentView addSubview:label];
	label.highlightedTextColor = [UIColor whiteColor];
	[label release];
	
	
	rect = CGRectMake(LEFT_OFFSET+buttonOffset, rect.origin.y+ LABEL_HEIGHT + VERTICAL_OFFSET , 288-buttonOffset, DATE_LABEL_HEIGHT);
	
	label = [[UILabel alloc] initWithFrame:rect];
	label.tag = COMMENT_POST_NAME_AND_DATE_TAG;
	label.font = [UIFont systemFontOfSize:DATE_FONT_SIZE];
	[cell.contentView addSubview:label];
	label.highlightedTextColor = [UIColor whiteColor];
	label.textColor = [UIColor colorWithRed:0.560f green:0.560f blue:0.560f alpha:1];
	label.numberOfLines = 3;
	label.lineBreakMode = UILineBreakModeTailTruncation;
	[label release];
	
	return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == 0) {
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
	}
	
	
	NSCharacterSet *whitespaceCS = [NSCharacterSet whitespaceCharacterSet];
	NSString *author = [[currentComment valueForKey:@"author"] stringByTrimmingCharactersInSet:whitespaceCS];
	NSString *commentStatus=[currentComment valueForKey:@"status"];
	UILabel *label = (UILabel *)[cell viewWithTag:COMMENT_NAME_TAG];
	label.text = author;

	NSString *authorEmail = [currentComment valueForKey:@"author_email"] ;
	UILabel *alabel = (UILabel *)[cell viewWithTag:COMMENT_MAIL_TAG];
	alabel.text=authorEmail;
	[cell.contentView addSubview:alabel];

	if([commentStatus isEqual:@"hold"] || !connectionStatus)
	{
	   [alabel setTextColor:[UIColor grayColor]];
		[label setTextColor:[UIColor grayColor]];
	}
	
	NSString *content= [currentComment valueForKey:@"content"] ;
	label = (UILabel *)[cell viewWithTag:COMMENT_POST_NAME_AND_DATE_TAG];
	NSString *statuString= [NSString stringWithString:@"(Awaiting moderation)"] ;
	label.text = ( [commentStatus isEqual:@"hold"] ? [NSString stringWithFormat:@"%@%@",statuString,content] : [NSString stringWithFormat:@"%@",content] );

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
	if(editMode)  {
		[atableView deselectRowAtIndexPath:indexPath animated:NO];
		UITableViewCell *indexViewCell = [atableView cellForRowAtIndexPath:indexPath];
		[self commentSelected:[[[[indexViewCell subviews] objectAtIndex:0]subviews] objectAtIndex:0]];//;(id)self.senderObj];//[atableView cellForRowAtIndexPath:indexPath]];
		return;
	}
		
	
    WPCommentsDetailViewController *commentsViewController = [[WPCommentsDetailViewController alloc] initWithNibName:@"WPCommentsDetailViewController" bundle:nil];
    [self.navigationController pushViewController:commentsViewController animated:YES];
	[commentsViewController fillCommentDetails:[[BlogDataManager sharedDataManager] commentTitles]
										 atRow:indexPath.row];
	[commentsViewController release];
}

- (void)tableView:(UITableView *)atableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	if(editMode)  {
		[atableView deselectRowAtIndexPath:indexPath animated:NO];
		UITableViewCell *indexViewCell = [atableView cellForRowAtIndexPath:indexPath];
		[self commentSelected:[[[[indexViewCell subviews] objectAtIndex:0]subviews] objectAtIndex:0]];//;(id)self.senderObj];//[atableView cellForRowAtIndexPath:indexPath]];
		return;
	}
}

@end