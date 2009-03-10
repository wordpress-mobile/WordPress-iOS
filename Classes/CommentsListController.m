//
//  CommentsListController.m
//  WordPress
//
//  Created by Janakiram on 02/09/08.
//

#import "CommentsListController.h"

#import "XMLRPCRequest.h"
#import "XMLRPCResponse.h"
#import "XMLRPCConnection.h"
#import "BlogDataManager.h"
#import "Reachability.h"
#import "NSString+XMLExtensions.h"
#import "WPCommentsDetailViewController.h"
#import "WordPressAppDelegate.h"

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
		
	editMode = NO;
	changeEditMode = YES;

	BlogDataManager *sharedDataManager = [BlogDataManager sharedDataManager];
	[sharedDataManager loadCommentTitlesForCurrentBlog];
	
	if(!selectedComments)
		selectedComments=[[NSMutableArray alloc]init];
	else
		[selectedComments removeAllObjects];

	[self updateToolBarStatus];
	
	NSMutableArray *commentsList = [sharedDataManager commentTitlesForBlog:[sharedDataManager currentBlog]];
	[self setCommentsArray:commentsList];
	for ( NSDictionary *dict in commentsArray ) {
		NSString *str=[dict valueForKey:@"comment_id"];
		[commentsDict setValue:dict forKey:str];
	}
	
	connectionStatus = ( [[Reachability sharedReachability] remoteHostStatus] != NotReachable );
	[commentsTableView deselectRowAtIndexPath:[commentsTableView indexPathForSelectedRow] animated:NO];
	[commentsTableView reloadData];
	
	[editToolbar setHidden:YES];

	[editButtonItem setEnabled:([commentsArray count]>0)];

	[super viewWillAppear:animated];
}
- (void)viewWillDisappear:(BOOL)animated{
	editButtonItem.title = @"Edit";
	[super viewWillDisappear:animated];
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

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[ commentsTableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	
	WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
	if([delegate isAlertRunning] == YES)
		return NO;
	
	// Return YES for supported orientations
	return YES;
}

- (void)didReceiveMemoryWarning {
	WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
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
	
	
	editButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStyleBordered 
													 target:self action:@selector(editComments:)];
	self.navigationItem.rightBarButtonItem = editButtonItem;
	
	[apool release];
}

-(void)updateToolBarStatus
{
	BlogDataManager *sharedBlogDataManager = [BlogDataManager sharedDataManager];
	NSArray *commentsList = [sharedBlogDataManager commentTitlesForBlog:[sharedBlogDataManager currentBlog]];
	[self setCommentsArray:(NSMutableArray *)commentsList];
	int awaitingComments = 0;
	
	for ( NSDictionary *dict in commentsList ) {
		if ( [[dict valueForKey:@"status"] isEqualToString:@"hold"] ) {
			awaitingComments++;
		}
	}
	
	if ( awaitingComments == 0 )
	{
		[commentStatusButton setEnabled:NO];
		[commentStatusButton setTitle:@""];
	}
	else
	{
		[commentStatusButton setEnabled:YES];
		[commentStatusButton setTitle:[NSString stringWithFormat:@"%d awaiting moderation",awaitingComments]];
	}
}

#pragma mark -
#pragma mark Action methods
- (IBAction)downloadRecentComments:(id)sender {
	if( !connectionStatus ){
		UIAlertView *alertt1 = [[UIAlertView alloc] initWithTitle:@"No connection to host."
														 message:@"Sync operation is not supported now."
														delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		
		[alertt1 show];
		WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
		[delegate setAlertRunning:YES];
		return;
	}
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[self performSelectorInBackground:@selector(addProgressIndicator) withObject:nil];

	BlogDataManager *sharedBlogDataManager = [BlogDataManager sharedDataManager];
	[sharedBlogDataManager syncCommentsForCurrentBlog];
	[sharedBlogDataManager loadCommentTitlesForCurrentBlog];
	
	[self updateToolBarStatus];
	[self removeProgressIndicator];
	
	[commentsTableView reloadData];
	[editButtonItem setEnabled:([commentsArray count]>0)];

	[pool release];
}

- (IBAction)deleteSelectedComments:(id)sender{
//    UIAlertView *deleteAlert = [[UIAlertView alloc] initWithTitle:@"Delete Comments" message:@"Are you sure you want to delete this comment?" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"Cancel", nil];
    UIAlertView *deleteAlert = [[UIAlertView alloc] initWithTitle:@"Delete Comments" message:@"Are you sure you want to delete the selected comment(s)?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];                                                
    [deleteAlert setTag:1];  // for UIAlertView Delegate to handle which view is popped.
    [deleteAlert show];
	WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
	[delegate setAlertRunning:YES];

		
}
- (IBAction)approveSelectedComments:(id)sender{
//	UIAlertView *deleteAlert = [[UIAlertView alloc] initWithTitle:@"Approve Comments" message:@"Are you sure you want to Approve this comment?" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"Cancel", nil];
	UIAlertView *deleteAlert = [[UIAlertView alloc] initWithTitle:@"Approve Comments" message:@"Are you sure you want to approve the selected comment(s)?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];                                                
	[deleteAlert setTag:2];  // for UIAlertView Delegate to handle which view is popped.
	[deleteAlert show];
	WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
	[delegate setAlertRunning:YES];

	
}
- (IBAction)unapproveSelectedComments:(id)sender{
//	UIAlertView *deleteAlert = [[UIAlertView alloc] initWithTitle:@"Unapprove Comments" message:@"Are you sure you want to Unapprove this comment?" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"Cancel", nil];
	UIAlertView *deleteAlert = [[UIAlertView alloc] initWithTitle:@"Unapprove Comments" message:@"Are you sure you want to unapprove the selected comment(s)?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];                                                
	[deleteAlert setTag:3];  // for UIAlertView Delegate to handle which view is popped.
	[deleteAlert show];
	WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
	[delegate setAlertRunning:YES];

}

- (IBAction)spamSelectedComments:(id)sender{
//	UIAlertView *deleteAlert = [[UIAlertView alloc] initWithTitle:@"Spam Comments" message:@"Are you sure you want to Spam this comment?" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"Cancel", nil];
	UIAlertView *deleteAlert = [[UIAlertView alloc] initWithTitle:@"Spam Comments" message:@"Are you sure you want to mark the selected comment(s) as spam?. This action can only be reversed in the web admin." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];                                                
	[deleteAlert setTag:4];  // for UIAlertView Delegate to handle which view is popped.
	[deleteAlert show];
	WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
	[delegate setAlertRunning:YES];

}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	
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
	WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
	[delegate setAlertRunning:NO];

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
	
}
#pragma mark -
#pragma mark tableview methods

- (UITableViewCell *)tableviewCellWithReuseIdentifier:(NSString *)identifier withCommentId:(int)commentId {
	
	/*
	 Create an instance of UITableViewCell and add tagged subviews for the name, local time, and quarter image of the time zone.
	 */
	CGRect rect;
	
	rect = CGRectMake(0.0, 0.0, 400.0, COMMENTS_TABLE_ROW_HEIGHT);
	
	UITableViewCell *cell = [[[UITableViewCell alloc] initWithFrame:rect reuseIdentifier:identifier] autorelease];
	
#define LEFT_OFFSET 10.0f
#define RIGHT_OFFSET 280.0f
	
#define MAIN_FONT_SIZE 17.0f
#define DATE_FONT_SIZE 13.0f
	
#define LABEL_HEIGHT 20.0f
#define DATE_LABEL_HEIGHT 33.0f
#define NAME_LABEL_HEIGHT 35.0f
#define VERTICAL_OFFSET	1.0f
	
	int buttonOffset = 0;
	if ( editMode == YES ) {
		rect = CGRectMake(LEFT_OFFSET,15, 30, COMMENTS_TABLE_ROW_HEIGHT-30);
		UIButton *but = [[UIButton alloc] initWithFrame:rect]; 
		[but setTag:commentId];
		[but addTarget:self action:@selector(commentSelected:) forControlEvents:UIControlEventTouchUpInside];
		[cell.contentView addSubview:but];
		[but release];
		buttonOffset = 35;
	}
	
	/*
	 Create labels for the text fields; set the highlight color so that when the cell is selected it changes appropriately.
	 */
	UILabel *label;
	
	rect = CGRectMake(LEFT_OFFSET+buttonOffset, ((COMMENTS_TABLE_ROW_HEIGHT - LABEL_HEIGHT - DATE_LABEL_HEIGHT - VERTICAL_OFFSET ) / 2.0), 150-buttonOffset, LABEL_HEIGHT);
	UILabel *alabel = [[UILabel alloc]initWithFrame:rect];
	alabel.tag = COMMENT_MAIL_TAG;
	alabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
	
	[cell.contentView addSubview:alabel];
	[alabel release];

	
	rect = CGRectMake(LEFT_OFFSET+buttonOffset, (COMMENTS_TABLE_ROW_HEIGHT - LABEL_HEIGHT - NAME_LABEL_HEIGHT - VERTICAL_OFFSET ) / 2.0, 150-buttonOffset, LABEL_HEIGHT);
	label = [[UILabel alloc] initWithFrame:rect];
	label.tag = COMMENT_NAME_TAG;
	label.font = [UIFont boldSystemFontOfSize:MAIN_FONT_SIZE];
	
	[cell.contentView addSubview:label];
	label.highlightedTextColor = [UIColor whiteColor];
	[label release];
	
	
	rect = CGRectMake(LEFT_OFFSET+buttonOffset, rect.origin.y+ LABEL_HEIGHT + VERTICAL_OFFSET , 288-buttonOffset, NAME_LABEL_HEIGHT);
	UILabel *label2 ;
	label2 = [[UILabel alloc] initWithFrame:rect];
	label2.tag = COMMENT_POST_NAME_AND_DATE_TAG;
	label2.font = [UIFont systemFontOfSize:DATE_FONT_SIZE];
	[cell.contentView addSubview:label2];
	label2.highlightedTextColor = [UIColor whiteColor];
	label2.textColor = [UIColor colorWithRed:0.560f green:0.560f blue:0.560f alpha:1];
	label2.numberOfLines = 3;
	label2.lineBreakMode = UILineBreakModeTailTruncation;
	[label2 release];
	
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
		cell = [self tableviewCellWithReuseIdentifier:postsTableRowId withCommentId:[[currentComment valueForKey:@"comment_id"]intValue]];
	}
	
	if( editMode == YES )
	{
		UIButton *imageButton=(UIButton *)[cell viewWithTag:[[currentComment valueForKey:@"comment_id"]intValue]];
		int toggleTag = [imageButton tag];
		NSString *str=[NSString stringWithFormat:@"%d",toggleTag];
		NSDictionary *dict  = [commentsDict valueForKey:str];
		if ( [selectedComments containsObject:dict] ) {
			[imageButton setImage:[UIImage imageNamed:@"check.png"] forState:UIControlStateNormal];  
		} else {
			[imageButton setImage:[UIImage imageNamed:@"uncheck.png"] forState:UIControlStateNormal];  
		}
		[cell.contentView addSubview:imageButton];
	}
	
	
	NSCharacterSet *whitespaceCS = [NSCharacterSet whitespaceCharacterSet];
	NSString *author = [[currentComment valueForKey:@"author"] stringByTrimmingCharactersInSet:whitespaceCS];
	NSString *commentStatus=[currentComment valueForKey:@"status"];
	UILabel *label = (UILabel *)[cell viewWithTag:COMMENT_NAME_TAG];
	label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
	
	CGSize commentSize = [ author sizeWithFont:[ label font]];
	CGFloat commentWidth = commentSize.width ;
	
	label.adjustsFontSizeToFitWidth = NO ;
	label.text = author;
	[ cell bringSubviewToFront:label];
	
	NSString *authorEmail = [currentComment valueForKey:@"author_email"] ;
	UILabel *alabel = (UILabel *)[cell viewWithTag:COMMENT_MAIL_TAG];
	
	CGSize mailSize = [ authorEmail sizeWithFont:[ alabel font]];
	CGFloat mailWidth = mailSize.width ;
	
	alabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
	alabel.adjustsFontSizeToFitWidth = NO ;
//	alabel.backgroundColor = [ UIColor redColor];
	alabel.textColor = [ UIColor grayColor ] ;
	alabel.text=authorEmail;
	
	if( (((commentWidth > tableView.frame.size.width*0.50) && (mailWidth < tableView.frame.size.width*0.50)) ||
		  ((commentWidth < tableView.frame.size.width*0.50) && (mailWidth > tableView.frame.size.width*0.50))) )
	{
		commentWidth = tableView.frame.size.width*0.50 ;
		mailWidth = tableView.frame.size.width*0.50 ;
	}
	
	label.frame = CGRectMake(label.frame.origin.x, label.frame.origin.y, commentWidth, label.frame.size.height);
	alabel.frame = CGRectMake(CGRectGetMaxX(label.frame)+2.0, alabel.frame.origin.y, mailWidth, alabel.frame.size.height);
	
	[cell.contentView addSubview:label];
	[cell.contentView addSubview:alabel];
	
	if([commentStatus isEqual:@"hold"] || !connectionStatus)
	{
	   [alabel setTextColor:[UIColor grayColor]];
	   [label setTextColor:[UIColor grayColor]];
	}
	
	NSString *content= [currentComment valueForKey:@"content"] ;
	label = (UILabel *)[cell viewWithTag:COMMENT_POST_NAME_AND_DATE_TAG];
	NSString *statuString= [NSString stringWithString:@"(Awaiting moderation)"] ;
	label.text = ( [commentStatus isEqual:@"hold"] ? [NSString stringWithFormat:@"%@ %@",statuString,content] : [NSString stringWithFormat:@"%@",content] );
	label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
	label.textColor = ( connectionStatus ? [UIColor blackColor] : [UIColor grayColor] );
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	cell.autoresizingMask=UIViewAutoresizingFlexibleLeftMargin;
	
	return cell;
	
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return COMMENTS_TABLE_ROW_HEIGHT;
}

// Show PostList when row is selected
- (void)tableView:(UITableView *)atableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if(editMode)  {
		id currentComment = [commentsArray objectAtIndex:indexPath.row];
		int commentId = [[currentComment valueForKey:@"comment_id"]intValue];
		[atableView deselectRowAtIndexPath:indexPath animated:NO];
		UITableViewCell *indexViewCell = [atableView cellForRowAtIndexPath:indexPath];
		//[self commentSelected:[[[[indexViewCell subviews] objectAtIndex:0]subviews] objectAtIndex:1]];//;(id)self.senderObj];//[atableView cellForRowAtIndexPath:indexPath]];
		[self commentSelected:[[[indexViewCell subviews] objectAtIndex:0]viewWithTag:commentId] ];//;(id)self.senderObj];//[atableView cellForRowAtIndexPath:indexPath]];
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