#import "WPAddCategoryViewController.h"
#import "PostSettingsViewController.h"
#import "WordPressAppDelegate.h"
#import "Reachability.h"

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
    WPFLogMethod();
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
        UIAlertView *alert2 = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Category title missing.", @"")
                               message:NSLocalizedString(@"Title for a category is mandatory.", @"")
                               delegate:self cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];

        [alert2 show];
        WordPressAppDelegate *delegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
        [delegate setAlertRunning:YES];

        [alert2 release];
        return;
    }

    if ([Category existsName:catName forBlog:self.blog withParentId:parentCat.categoryID]) {
        UIAlertView *alert2 = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Category name already exists.", @"")
                                                         message:NSLocalizedString(@"There is another category with that name.", @"")
                                                        delegate:self cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
		
        [alert2 show];
        WordPressAppDelegate *delegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
        [delegate setAlertRunning:YES];

        [alert2 release];
        return;
    }

	//FIXME: At the first attempt the remoteHostStatus == NotReachable even if the connection is available. 
	// if ([[ sharedReachability] remoteHostStatus] != NotReachable)
    [self addProgressIndicator];

    [Category createCategory:catName parent:parentCat forBlog:self.blog success:^(Category *category) {
        //re-syncs categories this is necessary because the server can change the name of the category!!!
		[self.blog syncCategoriesWithSuccess:nil failure:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:WPNewCategoryCreatedAndUpdatedInBlogNotificationName object:self];
        [self clearUI];
        [self removeProgressIndicator];
        [self dismiss];
    } failure:^(NSError *error) {
        NSDictionary *errInfo = [NSDictionary dictionaryWithObjectsAndKeys:self.blog, @"currentBlog", nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:kXML_RPC_ERROR_OCCURS object:error userInfo:errInfo];
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
		[self removeProgressIndicator];
    }];
}

- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	[super viewDidLoad];
    catTableView.sectionFooterHeight = 0.0;
    [saveButtonItem retain];

    newCatNameField.font = [UIFont fontWithName:@"Helvetica" size:17];
    parentCatNameField.font = [UIFont fontWithName:@"Helvetica" size:17];
    parentCatNameLabel.text = NSLocalizedString(@"Parent Category", @"");
    parentCatNameField.placeholder = NSLocalizedString(@"Optional", @"");
    newCatNameField.placeholder = NSLocalizedString(@"Title", @"");
    saveButtonItem.title = NSLocalizedString(@"Save", @"");
    cancelButtonItem.title = NSLocalizedString(@"Cancel", @"");

    parentCat = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    self.title = NSLocalizedString(@"Add Category", @"");
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
    
	NSArray *cats = [self.blog sortedCategories];
	
	[selectionTableViewController populateDataSource:cats
     havingContext:kParentCategoriesContext
     selectedObjects:selObjs
     selectionType:kRadio
     andDelegate:self];

    selectionTableViewController.title = NSLocalizedString(@"Parent Category", @"");

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
    WPFLogMethod();
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
