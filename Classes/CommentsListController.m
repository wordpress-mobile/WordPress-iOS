//
//  CommentsListController.m
//  WordPress
//
//  Created by Janakiram on 02/09/08.
//

#import "CommentsListController.h"

#import "BlogDataManager.h"
#import "CommentTableViewCell.h"
#import "NSString+XMLExtensions.h"
#import "Reachability.h"
#import "WordPressAppDelegate.h"
#import "WPCommentsDetailViewController.h"

#define REFRESH_BUTTON_HEIGHT           50

@interface CommentsListController (Private)
- (void)setEditing:(BOOL)value;
- (void)updateSelectedComments;
- (void)refreshHandler;
- (void)downloadRecentComments;
- (void)addProgressIndicator;
- (void)removeProgressIndicator;
@end

@implementation CommentsListController

@synthesize editButtonItem, selectedComments, commentsArray;

- (void)addRefreshButton {
    CGRect frame = CGRectMake(0, 0, commentsTableView.bounds.size.width, REFRESH_BUTTON_HEIGHT);
	
	refreshButton = [[RefreshButtonView alloc] initWithFrame:frame];
    [refreshButton addTarget:self action:@selector(refreshHandler) forControlEvents:UIControlEventTouchUpInside];
	
    commentsTableView.tableHeaderView = refreshButton;
}

- (void)viewDidLoad {
	[super viewDidLoad];
    
    commentsDict = [[NSMutableDictionary alloc] init];
    selectedComments = [[NSMutableArray alloc] init];
    
	[commentsTableView setDataSource:self];
    commentsTableView.backgroundColor = kTableBackgroundColor;
    
    [self addRefreshButton];
    
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged) name:@"kNetworkReachabilityChangedNotification" object:nil];
	
	editButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStyleBordered 
													 target:self action:@selector(editComments)];
    
	self.navigationItem.rightBarButtonItem = editButtonItem;
    
	[editButtonItem setEnabled:([commentsArray count] > 0)];
}

- (void)dealloc {
	[commentsArray release];
	[commentsDict release];
	[selectedComments release];
    [editButtonItem release];
	[commentsTableView release];
	[refreshButton release];
	[super dealloc];
}

- (void)viewWillAppear:(BOOL)animated {
	[self setEditing:NO];

	BlogDataManager *sharedDataManager = [BlogDataManager sharedDataManager];
	[sharedDataManager loadCommentTitlesForCurrentBlog];
	
	if (!selectedComments) {
		selectedComments = [[NSMutableArray alloc] init];
	} else {
		[selectedComments removeAllObjects];
    }
	
	NSMutableArray *commentsList = [sharedDataManager commentTitlesForBlog:[sharedDataManager currentBlog]];
	[self setCommentsArray:commentsList];
	for ( NSDictionary *dict in commentsArray ) {
		NSString *str=[dict valueForKey:@"comment_id"];
		[commentsDict setValue:dict forKey:str];
	}
	
	connectionStatus = ([[Reachability sharedReachability] remoteHostStatus] != NotReachable);
	[commentsTableView reloadData];
	
	[editToolbar setHidden:YES];

	[editButtonItem setEnabled:([commentsArray count] > 0)];

	[commentsTableView deselectRowAtIndexPath:[commentsTableView indexPathForSelectedRow] animated:animated];
	
	[super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated{
	editButtonItem.title = @"Edit";
	[super viewWillDisappear:animated];
}

- (void)reachabilityChanged {
	connectionStatus = ([[Reachability sharedReachability] remoteHostStatus] != NotReachable);
	[commentsTableView reloadData];
}

- (void)setEditing:(BOOL)value {
    editing = value;
    
    // Adjust comments table view height to fit toolbar (if it's visible).
    CGFloat toolbarHeight = editing ? editToolbar.bounds.size.height : 0;    
    CGRect mainViewBounds = self.view.bounds;
    CGRect rect = CGRectMake(mainViewBounds.origin.x,
                             mainViewBounds.origin.y,
                             mainViewBounds.size.width,
                             mainViewBounds.size.height - toolbarHeight);
    
    commentsTableView.frame = rect;
	
	[editToolbar setHidden:!editing];
	[deleteButton setEnabled:!editing];
	[approveButton setEnabled:!editing];
	[unapproveButton setEnabled:!editing];
	[spamButton setEnabled:!editing];
    
	editButtonItem.title = editing ? @"Cancel" : @"Edit";
    
	[commentsTableView reloadData];
}

- (void)editComments {
	[self setEditing:!editing];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[commentsTableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];

	if ([delegate isAlertRunning] == YES) {
		return NO;
    } else {
        return YES;
    }
}

- (void)didReceiveMemoryWarning {
	WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
	[super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark Action methods

- (void)refreshHandler {
	[refreshButton startAnimating];
	[self performSelectorInBackground:@selector(downloadRecentComments) withObject:nil];
}

- (void)downloadRecentComments {
	if (!connectionStatus) {
		UIAlertView *alertt1 = [[[UIAlertView alloc] initWithTitle:@"No connection to host."
														 message:@"Sync operation is not supported now."
														delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
		
		[alertt1 show];
		WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
		[delegate setAlertRunning:YES];
		return;
	}
	
	BlogDataManager *sharedBlogDataManager = [BlogDataManager sharedDataManager];
	[sharedBlogDataManager syncCommentsForCurrentBlog];
	[sharedBlogDataManager loadCommentTitlesForCurrentBlog];
    
	[commentsTableView reloadData];
	[editButtonItem setEnabled:([commentsArray count] > 0)];
	
	[refreshButton stopAnimating];
}

- (IBAction)deleteSelectedComments:(id)sender {
    UIAlertView *deleteAlert = [[[UIAlertView alloc] initWithTitle:@"Delete Comments" message:@"Are you sure you want to delete the selected comment(s)?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil] autorelease];
    [deleteAlert setTag:1];  // for UIAlertView Delegate to handle which view is popped.
    [deleteAlert show];
	WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
	[delegate setAlertRunning:YES];
}

- (IBAction)approveSelectedComments:(id)sender {
	UIAlertView *deleteAlert = [[[UIAlertView alloc] initWithTitle:@"Approve Comments" message:@"Are you sure you want to approve the selected comment(s)?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil] autorelease];                                                
	[deleteAlert setTag:2];  // for UIAlertView Delegate to handle which view is popped.
	[deleteAlert show];
	WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
	[delegate setAlertRunning:YES];
}

- (IBAction)unapproveSelectedComments:(id)sender {
	UIAlertView *deleteAlert = [[[UIAlertView alloc] initWithTitle:@"Unapprove Comments" message:@"Are you sure you want to unapprove the selected comment(s)?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil] autorelease];                                                
	[deleteAlert setTag:3];  // for UIAlertView Delegate to handle which view is popped.
	[deleteAlert show];
	WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
	[delegate setAlertRunning:YES];
}

- (IBAction)spamSelectedComments:(id)sender {
	UIAlertView *deleteAlert = [[[UIAlertView alloc] initWithTitle:@"Spam Comments" message:@"Are you sure you want to mark the selected comment(s) as spam?. This action can only be reversed in the web admin." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil] autorelease];  
	[deleteAlert setTag:4];  // for UIAlertView Delegate to handle which view is popped.
	[deleteAlert show];
	WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
	[delegate setAlertRunning:YES];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 1) {
		if (![[Reachability sharedReachability] remoteHostStatus] != NotReachable) {
			UIAlertView *connectionFailAlert = [[UIAlertView alloc] initWithTitle:@"No connection to host."
															 message:@"Operation is not supported now."
															delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[connectionFailAlert show];
			[connectionFailAlert release];		
			return;
		}
		
        [self addProgressIndicator];
		BlogDataManager *sharedDataManager = [BlogDataManager sharedDataManager];
		
		BOOL result = NO;
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
        [self removeProgressIndicator];
    }
	[editButtonItem setEnabled:([commentsArray count]>0)];
	WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
	[delegate setAlertRunning:NO];
    [self setEditing:FALSE];
}

- (void)updateSelectedComments {
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
	NSAutoreleasePool *apool = [[NSAutoreleasePool alloc] init];
	while (self.navigationItem.rightBarButtonItem == nil){
		[[NSRunLoop currentRunLoop] runUntilDate:[[NSDate date] addTimeInterval:0.1]];
	}
	
	self.navigationItem.rightBarButtonItem = editButtonItem;
	[apool release];
}

#pragma mark -
#pragma mark UITableView Delegate Methods

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor whiteColor];
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
	static NSString *CellIdentifier = @"PageCell";
    CommentTableViewCell *cell = (CommentTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	id comment = [commentsArray objectAtIndex:indexPath.row];
	
	if (cell == nil) {
        cell = [[[CommentTableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
	}
	
    cell.comment = comment;
    cell.editing = editing;
	
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return COMMENT_ROW_HEIGHT;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editing) {
        [self tableView:tableView didCheckRowAtIndexPath:indexPath];
	} else {
        WPCommentsDetailViewController *commentsViewController = [[WPCommentsDetailViewController alloc] initWithNibName:@"WPCommentsDetailViewController" bundle:nil];
        
        // Get the navigation controller from the delegate
        WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
        [delegate.navigationController pushViewController:commentsViewController animated:YES];
        
        [commentsViewController fillCommentDetails:[[BlogDataManager sharedDataManager] commentTitles]
                                             atRow:indexPath.row];
        [commentsViewController release];
    }
}

- (void)tableView:(UITableView *)tableView didCheckRowAtIndexPath:(NSIndexPath *)indexPath {
    CommentTableViewCell *cell = (CommentTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
	NSDictionary *comment = cell.comment;
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
	if ([selectedComments containsObject:comment]) {
        cell.checked = NO;
		[selectedComments removeObject:comment];
	} else {
        cell.checked = YES;
		[selectedComments addObject:comment];
	}
	
    [self updateSelectedComments];
}

@end
