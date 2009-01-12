#import "WPAddCategoryViewController.h"
#import "WPPostSettingsController.h"
#import "WordPressAppDelegate.h"
#import "Reachability.h"

@implementation WPAddCategoryViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		// Initialization code
	}
	return self;
}

- (void)clearUI
{
	newCatNameField.text = @"";
	parentCatNameField.text = @"";
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
	while (self.navigationItem.rightBarButtonItem == saveButtonItem)
	{
		[[NSRunLoop currentRunLoop] runUntilDate:[[NSDate date] addTimeInterval:0.1]];
	}
	
	self.navigationItem.rightBarButtonItem = saveButtonItem;
}


- (IBAction)cancelAddCategory:(id)sender
{
	[self clearUI];
	[self.parentViewController dismissModalViewControllerAnimated:YES];
}

- (IBAction)saveAddCategory:(id)sender
{
	//if ( ![[Reachability sharedReachability] remoteHostStatus] != NotReachable ) {
//		UIAlertView *alert1 = [[UIAlertView alloc] initWithTitle:@"Communication Error."
//														 message:@"no Internet Connection."
//														delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
//		
//		[alert1 show];
//		WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
//		[delegate setAlertRunning:YES];
//		[alert1 release];		
//		return;
//	}

	NSString *catName = newCatNameField.text;
	if( !catName || [catName length] == 0 )
	{
		UIAlertView *alert2 = [[UIAlertView alloc] initWithTitle:@"Category title missing."
														 message:@"Title for a category is mandatory."
														delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		
		[alert2 show];
		WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
		[delegate setAlertRunning:YES];

		[alert2 release];		
		return;
	}
	
	//Resolved the application crash.
	if ( [[Reachability sharedReachability] remoteHostStatus] != NotReachable ) 
		[self performSelectorInBackground:@selector(addProgressIndicator) withObject:nil];
	
	NSString *parentCatName = parentCatNameField.text;
	
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	if( [dm createCategory:catName parentCategory:parentCatName forBlog:dm.currentBlog] )
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:WPNewCategoryCreatedAndUpdatedInBlogNotificationName object:self];
		[self clearUI];
		[self removeProgressIndicator];
		[self.parentViewController dismissModalViewControllerAnimated:YES];		
	}
}


/*
 Implement loadView if you want to create a view hierarchy programmatically
- (void)loadView {
}
 */

// If you need to do additional setup after loading the view, override viewDidLoad.
- (void)viewDidLoad {
	catTableView.sectionFooterHeight = 0.0;
	[saveButtonItem retain];
	
	newCatNameField.font = [UIFont fontWithName:@"Helvetica" size:17];
	parentCatNameField.font = [UIFont fontWithName:@"Helvetica" size:17];
}

- (void)viewWillAppear:(BOOL)animated    // Called when the view is about to made visible. Default does nothing
{
	self.title = @"Add Category";
	self.navigationItem.leftBarButtonItem = cancelButtonItem;
	self.navigationItem.rightBarButtonItem = saveButtonItem;

}
//- (void)viewDidAppear:(BOOL)animated;     // Called when the view has been fully transitioned onto the screen. Default does nothing
//- (void)viewWillDisappear:(BOOL)animated; // Called when the view is dismissed, covered or otherwise hidden. Default does nothing
//- (void)viewDidDisappear:(BOOL)animated;  // Called after the view was dismissed, covered or otherwise hidden. Default does nothing


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

#pragma mark - functionalmethods

- (void)selectionTableViewController:(WPSelectionTableViewController *)selctionController completedSelectionsWithContext:(void *)selContext selectedObjects:(NSArray *)selectedObjects haveChanges:(BOOL)isChanged
{
	if( !isChanged )
	{
		[selctionController clean];
		return;
	}
	
	if( selContext == kParentCategoriesContext )
	{
		NSString *curStr = [selectedObjects lastObject];
		if( curStr )
		{
			parentCatNameField.text = curStr;
			[catTableView reloadData];
		}	
	}
	
	[selctionController clean];
}

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

- (void)populateSelectionsControllerWithCategories
{
	WPSelectionTableViewController *selectionTableViewController = [[WPSelectionTableViewController alloc] initWithNibName:@"WPSelectionTableViewController" bundle:nil];
	
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	NSArray *cats = [[dm currentBlog] valueForKey:@"categories"];	
	NSArray *dataSource = [cats valueForKey:@"categoryName"];
	dataSource = [self uniqueArray:dataSource];
	
	NSString *parentCatVal = parentCatNameField.text;
	NSArray *selObjs = ( [parentCatVal length] < 1 ? [NSArray array] : [NSArray arrayWithObject:parentCatVal] );
	[selectionTableViewController populateDataSource:dataSource
									   havingContext:kParentCategoriesContext
									 selectedObjects:selObjs
									   selectionType:kRadio
										 andDelegate:self];
	
	selectionTableViewController.title = @"Parent Category";

	[self.navigationController pushViewController:selectionTableViewController animated:YES];
	[selectionTableViewController release];
}



#pragma mark - tableviewDelegates/datasources

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	if( indexPath.section == 0)
	{
		return newCatNameCell;
	}
	else {
		parentCatNameCell.text = @"Parent Category";
		parentCatNameCell.textColor = [UIColor blueColor];
		return parentCatNameCell;
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	[tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];
	
	if( indexPath.section == 1)
	{
		[self populateSelectionsControllerWithCategories];
	}
	
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	
}



/*
 Override if you support editing the list
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
 }	
 if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }	
 }
 */


/*
 Override if you support conditional editing of the list
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */


/*
 Override if you support rearranging the list
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */


/*
 Override if you support conditional rearranging of the list
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */ 

#pragma mark textfied deletage
//- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField;        // return NO to disallow editing.
//- (void)textFieldDidBeginEditing:(UITextField *)textField;           // became first responder
//- (BOOL)textFieldShouldEndEditing:(UITextField *)textField;          // return YES to allow editing to stop and to resign first responder status. NO to disallow the editing session to end
//- (void)textFieldDidEndEditing:(UITextField *)textField;             // may be called if forced even if shouldEndEditing returns NO (e.g. view removed from window) or endEditing:YES called
//
//- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string;   // return NO to not change text
//
//- (BOOL)textFieldShouldClear:(UITextField *)textField;               // called when clear button pressed. return NO to ignore (no notifications)

// called when 'return' key pressed. return NO to ignore.
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder]; 
	return YES;
}

#pragma mark -dealloc

- (void)dealloc {
	[super dealloc];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
	[delegate setAlertRunning:NO];
}

@end
