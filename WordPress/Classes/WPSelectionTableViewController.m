#import "WPSelectionTableViewController.h"
#import "WordPressAppDelegate.h"

@interface NSObject (WPSelectionTableViewControllerDelegateCategory)

- (void)selectionTableViewController:(WPSelectionTableViewController *)selctionController completedSelectionsWithContext:(void *)selContext selectedObjects:(NSArray *)selectedObjects haveChanges:(BOOL)isChanged;

@end

@implementation WPSelectionTableViewController

@synthesize autoReturnInRadioSelectMode;
@synthesize objects, selectionStatusOfObjects, originalSelObjects;

#pragma mark -
#pragma mark Lifecycle Methods

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        autoReturnInRadioSelectMode = YES;
    }

    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if ([selectionDelegate respondsToSelector:@selector(selectionTableViewController:completedSelectionsWithContext:selectedObjects:haveChanges:)]) {
        [selectionDelegate selectionTableViewController:self completedSelectionsWithContext:curContext selectedObjects:[self selectedObjects] haveChanges:[self haveChanges]];
    }
    
    if (self.navigationController) {
        if (![[self.navigationController viewControllers] containsObject:self]) {
            [self clean];
        }
    }
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
    if (parent == nil ) {
        [self clean];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

- (void)didReceiveMemoryWarning {
    WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

#pragma mark -
#pragma mark Instance Methods

- (CGSize)contentSizeForViewInPopover;
{
	return CGSizeMake(320.0, [objects count] * 44.0 + 20.0);
}

- (void)clean {    
    objects = nil;
    selectionDelegate = nil;
    curContext = NULL;
    originalSelObjects = nil;
    selectionStatusOfObjects = nil;

}

- (void)populateDataSource:(NSArray *)sourceObjects havingContext:(void *)context selectedObjects:(NSArray *)selObjects selectionType:(WPSelectionType)aType andDelegate:(id)delegate {
    objects = sourceObjects;
    curContext = context;
    selectionType = aType;
    selectionDelegate = delegate;

    int i = 0, count = [objects count];
    selectionStatusOfObjects = [NSMutableArray arrayWithCapacity:count];

    for (i = 0; i < count; i++) {
        [selectionStatusOfObjects addObject:[NSNumber numberWithBool:[selObjects containsObject:[sourceObjects objectAtIndex:i]]]];
    }

    originalSelObjects = [selectionStatusOfObjects copy];

    [tableView reloadData];
}

- (void *)curContext {
    return curContext;
}

- (NSArray *)selectedObjects {
    int i = 0, count = [objects count];
    NSMutableArray *selectionObjects = [NSMutableArray arrayWithCapacity:count];
    id curObject = nil;

    for (i = 0; i < count; i++) {
        curObject = [objects objectAtIndex:i];

        if ([[selectionStatusOfObjects objectAtIndex:i] boolValue] == YES)
            [selectionObjects addObject:curObject];
    }

    return selectionObjects;
}

- (BOOL)haveChanges {
    int i = 0, count = [objects count];

    for (i = 0; i < count; i++) {
        if (![[selectionStatusOfObjects objectAtIndex:i] isEqual:[originalSelObjects objectAtIndex:i]])
            return YES;
    }

    return NO;
}


#pragma mark -
#pragma mark Modal Wrangling

- (void)gotoPreviousScreen {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (self.navigationController) {
        [self.navigationController pushViewController:viewController animated:animated];
    }
}

- (void)popViewControllerAnimated:(BOOL) animated {
    if (self.navigationController) {
        [self.navigationController popViewControllerAnimated:animated];
    }
}

#pragma mark -
#pragma mark TableView Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
    // plus one to because we add a row for "Local Drafts"
    //
    return [objects count];
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *selectionTableRowCell = @"selectionTableRowCell";

    UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:selectionTableRowCell];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:selectionTableRowCell];
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    }

    cell.textLabel.text = [objects objectAtIndex:indexPath.row];

    BOOL curStatus = [[selectionStatusOfObjects objectAtIndex:indexPath.row] boolValue];
    cell.textLabel.textColor = (curStatus == YES ? [UIColor blueColor] : [UIColor blackColor]);
    cell.accessoryType = (UITableViewCellAccessoryType)([[selectionStatusOfObjects objectAtIndex:indexPath.row] boolValue] == YES ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);

    return cell;
}


- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL curStatus = [[selectionStatusOfObjects objectAtIndex:indexPath.row] boolValue];

    if (selectionType == kCheckbox) {
        [selectionStatusOfObjects replaceObjectAtIndex:indexPath.row withObject:[NSNumber numberWithBool:!curStatus]];

        [aTableView reloadData];
    } else { //kRadio
        if (curStatus == NO) {
            int index = [selectionStatusOfObjects indexOfObject:[NSNumber numberWithBool:YES]];
            [selectionStatusOfObjects replaceObjectAtIndex:indexPath.row withObject:[NSNumber numberWithBool:YES]];

            if (index >= 0 && index <[selectionStatusOfObjects count])
                [selectionStatusOfObjects replaceObjectAtIndex:index withObject:[NSNumber numberWithBool:NO]];

            [aTableView reloadData];

            if (autoReturnInRadioSelectMode) {
                [self performSelector:@selector(gotoPreviousScreen) withObject:nil afterDelay:0.2f inModes:[NSArray arrayWithObject:[[NSRunLoop currentRunLoop] currentMode]]];
            }
        }
    }

    [aTableView deselectRowAtIndexPath:[aTableView indexPathForSelectedRow] animated:YES];
}

@end
