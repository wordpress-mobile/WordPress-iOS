#import "WPAddCategoryViewController.h"
#import "PostSettingsViewController.h"
#import "WordPressAppDelegate.h"
#import "Reachability.h"

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
    //wait incase the other thread did not complete its work.
    while (self.navigationItem.rightBarButtonItem == saveButtonItem) {
		NSLog(@"before loop");
        [[NSRunLoop currentRunLoop] runUntilDate:[[NSDate date] addTimeInterval:0.1]];
		NSLog(@"after loop");
    }

    self.navigationItem.rightBarButtonItem = saveButtonItem;
	
}

- (IBAction)cancelAddCategory:(id)sender {
    [self clearUI];
    [self.parentViewController dismissModalViewControllerAnimated:YES];
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



    if ([[Reachability sharedReachability] remoteHostStatus] != NotReachable)
        [self performSelectorInBackground:@selector(addProgressIndicator) withObject:nil];


    NSString *parentCatName = parentCatNameField.text;

    BlogDataManager *dm = [BlogDataManager sharedDataManager];

    if ([dm createCategory:catName parentCategory:parentCatName forBlog:dm.currentBlog]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:WPNewCategoryCreatedAndUpdatedInBlogNotificationName object:self];
        [self clearUI];
        [self removeProgressIndicator];
        [self.parentViewController dismissModalViewControllerAnimated:YES];
    }
}

- (void)viewDidLoad {
    catTableView.sectionFooterHeight = 0.0;
    [saveButtonItem retain];

    newCatNameField.font = [UIFont fontWithName:@"Helvetica" size:17];
    parentCatNameField.font = [UIFont fontWithName:@"Helvetica" size:17];
}

- (void)viewWillAppear:(BOOL)animated {
    self.title = @"Add Category";
    self.navigationItem.leftBarButtonItem = cancelButtonItem;
    self.navigationItem.rightBarButtonItem = saveButtonItem;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
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
        NSString *curStr = [selectedObjects lastObject];

        if (curStr) {
            parentCatNameField.text = curStr;
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
    WPSelectionTableViewController *selectionTableViewController = [[WPSelectionTableViewController alloc] initWithNibName:@"WPSelectionTableViewController" bundle:nil];

    BlogDataManager *dm = [BlogDataManager sharedDataManager];
    NSArray *cats = [[dm currentBlog] valueForKey:@"categories"];
    NSArray *dataSource = [cats valueForKey:@"categoryName"];
    dataSource = [self uniqueArray:dataSource];

    NSString *parentCatVal = parentCatNameField.text;
    NSArray *selObjs = ([parentCatVal length] < 1 ? [NSArray array] : [NSArray arrayWithObject:parentCatVal]);
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
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [delegate setAlertRunning:NO];
}

@end
