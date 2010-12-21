#import "WPAddCategoryViewController.h"
#import "PostSettingsViewController.h"
#import "WordPressAppDelegate.h"
#import "WPReachability.h"

@implementation WPAddCategoryViewController

- (void)clearUI {
    newCatNameField.text = @"";
    parentCatNameField.text = @"";
}

- (void)addProgressIndicator {
    NSAutoreleasePool *apool = [[NSAutoreleasePool alloc] init];
    UIActivityIndicatorView *aiv = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    UIBarButtonItem *activityButtonItem = [[UIBarButtonItem alloc] initWithCustomView:aiv];
	activityButtonItem.title = @"foobar!";
    [aiv startAnimating];
    [aiv release];

    self.navigationItem.rightBarButtonItem = activityButtonItem;
    [activityButtonItem release];
	[apool release];
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
        WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
        [delegate setAlertRunning:YES];

        [alert2 release];
        return;
    }

    BlogDataManager *dm = [BlogDataManager sharedDataManager];

    if ([Category existsName:catName forBlogId:[dm.currentBlog valueForKey:kBlogId] withParentId:[parentCat valueForKey:@"categoryId"]]) {
        UIAlertView *alert2 = [[UIAlertView alloc] initWithTitle:@"Category name already exists."
                                                         message:@"There is another category with that name."
                                                        delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];

        [alert2 show];
        WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
        [delegate setAlertRunning:YES];

        [alert2 release];
        return;
    }

    if ([[WPReachability sharedReachability] remoteHostStatus] != NotReachable)
        [self performSelectorInBackground:@selector(addProgressIndicator) withObject:nil];


    NSString *parentCatName = parentCatNameField.text;

    if ([dm createCategory:catName parentCategory:parentCatName forBlog:dm.currentBlog]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:WPNewCategoryCreatedAndUpdatedInBlogNotificationName object:self];
        [self clearUI];
        [self removeProgressIndicator];
        [self dismiss];
    }
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

    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];

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
        NSDictionary *curDict = [selectedObjects lastObject];
        NSString *curName = [curDict objectForKey:@"categoryName"];

        if (parentCat) {
            [parentCat release];
            parentCat = nil;
        }

        if (curDict) {
            parentCat = curDict;
            [parentCat retain];
            parentCatNameField.text = curName;
            [catTableView reloadData];
        }

    }

    [selctionController clean];
}

- (NSArray *)uniqueArray:(NSArray *)array {
    int i, count = [array count];
    NSMutableArray *a = [NSMutableArray arrayWithCapacity:[array count]];
    id curOBj = nil;

    for (i = 0; i < count; i++) {
        curOBj = [array objectAtIndex:i];

        if (![a containsObject:curOBj])
            [a addObject:curOBj];
    }

    return a;
}

- (void)populateSelectionsControllerWithCategories {
    WPSelectionTableViewController *selectionTableViewController = [[WPSegmentedSelectionTableViewController alloc] initWithNibName:@"WPSelectionTableViewController" bundle:nil];

    BlogDataManager *dm = [BlogDataManager sharedDataManager];
    NSArray *cats = [[dm currentBlog] valueForKey:@"categories"];
    NSArray *dataSource = [cats valueForKey:@"categoryName"];
    dataSource = [self uniqueArray:dataSource];

    NSArray *selObjs = (parentCat.count < 1 ? [NSArray array] : [NSArray arrayWithObject:parentCat]);
    [selectionTableViewController populateDataSource:cats
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
    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [delegate setAlertRunning:NO];
}

@end
