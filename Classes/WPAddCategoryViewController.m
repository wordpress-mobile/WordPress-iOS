#import "WPAddCategoryViewController.h"
#import "PostSettingsViewController.h"
#import "WordPressAppDelegate.h"
#import "WPReachability.h"

@implementation WPAddCategoryViewController
@synthesize blog;

- (void)clearUI {
    newCatNameField.text = @"";
    parentCatNameField.text = @"";
}

- (void)addProgressIndicator {
    UIActivityIndicatorView *aiv = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    UIBarButtonItem *activityButtonItem = [[UIBarButtonItem alloc] initWithCustomView:aiv];
	activityButtonItem.title = @"foobar!";
    [aiv startAnimating];
    [aiv release];

    self.navigationItem.rightBarButtonItem = activityButtonItem;
    [activityButtonItem release];
}

- (void)removeProgressIndicator {
	self.navigationItem.rightBarButtonItem = saveButtonItem;
	
}
- (void)dismiss {
    if (DeviceIsPad() == YES) {
        [(WPSelectionTableViewController *)self.parentViewController popViewControllerAnimated:YES];
    } else {
        [self.parentViewController dismissModalViewControllerAnimated:YES];
    }
}

- (IBAction)cancelAddCategory:(id)sender {
    [self clearUI];
    [self dismiss];
}

- (IBAction)saveAddCategory:(id)sender {
    NSString *catName = newCatNameField.text;

    if (!catName ||[catName length] == 0) {
        UIAlertView *alert2 = [[UIAlertView alloc] initWithTitle:@"Category title missing."
                               message:@"Title for a category is mandatory."
                               delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];

        [alert2 show];
        WordPressAppDelegate *delegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
        [delegate setAlertRunning:YES];

        [alert2 release];
        return;
    }

    if ([Category existsName:catName forBlog:self.blog withParentId:parentCat.categoryID]) {
        UIAlertView *alert2 = [[UIAlertView alloc] initWithTitle:@"Category name already exists."
                                                         message:@"There is another category with that name."
                                                        delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		
        [alert2 show];
        WordPressAppDelegate *delegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
        [delegate setAlertRunning:YES];

        [alert2 release];
        return;
    }

	//FIXME: At the first attempt the remoteHostStatus == NotReachable even if the connection is available. 
	// if ([[WPReachability sharedReachability] remoteHostStatus] != NotReachable)
    [self addProgressIndicator];

    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [self performSelectorInBackground:@selector(saveOnBackground:) withObject:catName];
}

- (void)saveOnBackground:(NSString *)categoryName {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSError *error = nil;
    [Category createCategoryWithError:categoryName parent:parentCat forBlog:self.blog  error:&error];
	if(error) {
		[[NSNotificationCenter defaultCenter] postNotificationName:kXML_RPC_ERROR_OCCURS object:error];
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
		[self removeProgressIndicator];
	} else 
		[self performSelectorOnMainThread:@selector(didSaveOnBackground) withObject:nil waitUntilDone:NO];
    [pool release];
}

- (void)didSaveOnBackground {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [[NSNotificationCenter defaultCenter] postNotificationName:WPNewCategoryCreatedAndUpdatedInBlogNotificationName object:self];
    [self clearUI];
    [self removeProgressIndicator];
    [self dismiss];
}


- (void)viewDidLoad {
    catTableView.sectionFooterHeight = 0.0;
    [saveButtonItem retain];

    newCatNameField.font = [UIFont fontWithName:@"Helvetica" size:17];
    parentCatNameField.font = [UIFont fontWithName:@"Helvetica" size:17];

    parentCat = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    self.title = @"Add Category";
	// only show "cancel" button if we're presented in a modal view controller
	// that is, if we are the root item of a UINavigationController
	if ([self.parentViewController isKindOfClass:[UINavigationController class]]) {
		UINavigationController *parent = (UINavigationController *)self.parentViewController;
		if ([[parent viewControllers] objectAtIndex:0] == self) {
			self.navigationItem.leftBarButtonItem = cancelButtonItem;
        } else {
            if (DeviceIsPad()) {
                if ([[parent viewControllers] objectAtIndex:1] == self)
                    self.navigationItem.leftBarButtonItem = cancelButtonItem;
            } else {
                if ([[parent viewControllers] objectAtIndex:0] == self) {
                    self.navigationItem.leftBarButtonItem = cancelButtonItem;
                }
            }

        }
	}
    self.navigationItem.rightBarButtonItem = saveButtonItem;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if (DeviceIsPad() == YES) {
		return YES;
	}

    WordPressAppDelegate *delegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];

    if ([delegate isAlertRunning] == YES) {
        return NO; // Return YES for supported orientations
    }

    return YES;
}

- (void)didReceiveMemoryWarning {
    WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

#pragma mark - functionalmethods

- (void)selectionTableViewController:(WPSelectionTableViewController *)selctionController completedSelectionsWithContext:(void *)selContext selectedObjects:(NSArray *)selectedObjects haveChanges:(BOOL)isChanged {
    if (!isChanged) {
        [selctionController clean];
        return;
    }

    if (selContext == kParentCategoriesContext) {
        Category *curCat = [selectedObjects lastObject];

        if (parentCat) {
            [parentCat release];
            parentCat = nil;
        }

        if (curCat) {
            parentCat = curCat;
            [parentCat retain];
            parentCatNameField.text = curCat.categoryName;
            [catTableView reloadData];
        }

    }

    [selctionController clean];
}

- (void)populateSelectionsControllerWithCategories {
    WPSelectionTableViewController *selectionTableViewController = [[WPSegmentedSelectionTableViewController alloc] initWithNibName:@"WPSelectionTableViewController" bundle:nil];

    NSArray *selObjs = ((parentCat == nil) ? [NSArray array] : [NSArray arrayWithObject:parentCat]);
    [selectionTableViewController populateDataSource:[self.blog.categories allObjects]
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return newCatNameCell;
    } else {
//		parentCatNameCell.text = @"Parent Category";
//		parentCatNameCell.textColor = [UIColor blueColor];
        return parentCatNameCell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];

    if (indexPath.section == 1) {
        [self populateSelectionsControllerWithCategories];
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
}

#pragma mark textfied deletage

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark -dealloc

- (void)dealloc {
    [super dealloc];
    if (parentCat != nil) {
        [parentCat release];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    WordPressAppDelegate *delegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
    [delegate setAlertRunning:NO];
}

@end
