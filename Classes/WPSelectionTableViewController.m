#import "WPSelectionTableViewController.h"
#import "BlogDataManager.h"
#import "WordPressAppDelegate.h"

@interface NSObject (WPSelectionTableViewControllerDelegateCategory)

- (void)selectionTableViewController:(WPSelectionTableViewController *)selctionController completedSelectionsWithContext:(void *)selContext selectedObjects:(NSArray *)selectedObjects haveChanges:(BOOL)isChanged;

@end

@implementation WPSelectionTableViewController

@synthesize autoReturnInRadioSelectMode;
@synthesize objects, selectionStatusOfObjects, originalSelObjects;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        autoReturnInRadioSelectMode = YES;
    }

    return self;
}

- (void)clean {
    [objects release];
    objects = nil;
    selectionDelegate = nil;
    curContext = NULL;
    [originalSelObjects release];
    originalSelObjects = nil;
    [selectionStatusOfObjects release];
    selectionStatusOfObjects = nil;

    flag = NO;
}

- (void)populateDataSource:(NSArray *)sourceObjects havingContext:(void *)context selectedObjects:(NSArray *)selObjects selectionType:(WPSelectionType)aType andDelegate:(id)delegate {
    objects = [sourceObjects retain];
    curContext = context;
    selectionType = aType;
    selectionDelegate = delegate;

    int i = 0, count = [objects count];
    [selectionStatusOfObjects release];
    selectionStatusOfObjects = [[NSMutableArray arrayWithCapacity:count] retain];

    for (i = 0; i < count; i++) {
        [selectionStatusOfObjects addObject:[NSNumber numberWithBool:[selObjects containsObject:[sourceObjects objectAtIndex:i]]]];
    }

    [originalSelObjects release];
    originalSelObjects = [selectionStatusOfObjects copy];

    flag = NO;
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

// Display another view controller as a modal child. Uses a vertical sheet transition if animated.
- (void)presentModalViewController:(UIViewController *)modalViewController animated:(BOOL)animated {
    flag = YES;
    [super presentModalViewController:modalViewController animated:animated];
}

- (void)dismissModalViewControllerAnimated:(BOOL)animated {
    flag = NO;
    [super dismissModalViewControllerAnimated:(BOOL)animated];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    if (!flag) {
        if ([selectionDelegate respondsToSelector:@selector(selectionTableViewController:completedSelectionsWithContext:selectedObjects:haveChanges:)]) {
            [selectionDelegate selectionTableViewController:self completedSelectionsWithContext:curContext selectedObjects:[self selectedObjects] haveChanges:[self haveChanges]];
        }
    }
}

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
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:selectionTableRowCell] autorelease];
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    }

#if defined __IPHONE_3_0
    cell.textLabel.text = [objects objectAtIndex:indexPath.row];
#else if defined __IPHONE_2_0
    cell.text = [objects objectAtIndex:indexPath.row];
#endif

    BOOL curStatus = [[selectionStatusOfObjects objectAtIndex:indexPath.row] boolValue];
#if defined __IPHONE_3_0
    cell.textLabel.textColor = (curStatus == YES ? [UIColor blueColor] : [UIColor blackColor]);
#else if defined __IPHONE_2_0
    cell.textColor = (curStatus == YES ? [UIColor blueColor] : [UIColor blackColor]);
#endif
    cell.accessoryType = (UITableViewCellAccessoryType)([[selectionStatusOfObjects objectAtIndex:indexPath.row] boolValue] == YES ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);

    return cell;
}

- (void)gotoPreviousScreen {
    [self.navigationController popViewControllerAnimated:YES];
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

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
}

//- (UITableViewCellAccessoryType)tableView:(UITableView *)aTableView accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath
//{
//	return (UITableViewCellAccessoryType)( [[selectionStatusOfObjects objectAtIndex:indexPath.row] boolValue] == YES ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone );
//}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];

    if ([delegate isAlertRunning] == YES)
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
    [originalSelObjects release];
    [selectionStatusOfObjects release];
    [objects release];
    [super dealloc];
}

@end
