#import "WPSelectionTableViewController.h"
#import "WordPressAppDelegate.h"
#import "WPTableViewCell.h"

static NSString *const SelectionTableRowCell = @"SelectionTableRowCell";

@interface NSObject (WPSelectionTableViewControllerDelegateCategory)

- (void)selectionTableViewController:(WPSelectionTableViewController *)selctionController completedSelectionsWithContext:(void *)selContext selectedObjects:(NSArray *)selectedObjects haveChanges:(BOOL)isChanged;

@end

@implementation WPSelectionTableViewController


- (id)init {
    if (self = [super init]) {
        _autoReturnInRadioSelectMode = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerClass:[WPTableViewCell class] forCellReuseIdentifier:SelectionTableRowCell];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if ([self.selectionDelegate respondsToSelector:@selector(selectionTableViewController:completedSelectionsWithContext:selectedObjects:haveChanges:)]) {
        [self.selectionDelegate selectionTableViewController:self completedSelectionsWithContext:self.curContext selectedObjects:[self selectedObjects] haveChanges:[self haveChanges]];
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

- (void)didReceiveMemoryWarning {
    DDLogWarn(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

#pragma mark - Instance Methods

- (CGSize)contentSizeForViewInPopover;
{
	return CGSizeMake(320.0, [self.objects count] * 44.0 + 20.0);
}

- (void)clean {    
    _objects = nil;
    _selectionDelegate = nil;
    _curContext = NULL;
    _originalSelObjects = nil;
    _selectionStatusOfObjects = nil;
}

- (void)populateDataSource:(NSArray *)sourceObjects havingContext:(void *)context selectedObjects:(NSArray *)selObjects selectionType:(WPSelectionType)aType andDelegate:(id)delegate {
    self.objects = sourceObjects;
    self.curContext = context;
    self.selectionType = aType;
    self.selectionDelegate = delegate;

    int i = 0, count = [self.objects count];
    self.selectionStatusOfObjects = [NSMutableArray arrayWithCapacity:count];

    for (i = 0; i < count; i++) {
        [self.selectionStatusOfObjects addObject:[NSNumber numberWithBool:[selObjects containsObject:[sourceObjects objectAtIndex:i]]]];
    }

    self.originalSelObjects = [self.selectionStatusOfObjects copy];

    [self.tableView reloadData];
}

- (NSArray *)selectedObjects {
    int i = 0, count = [self.objects count];
    NSMutableArray *selectionObjects = [NSMutableArray arrayWithCapacity:count];
    id curObject = nil;

    for (i = 0; i < count; i++) {
        curObject = [self.objects objectAtIndex:i];

        if ([[self.selectionStatusOfObjects objectAtIndex:i] boolValue] == YES)
            [selectionObjects addObject:curObject];
    }

    return selectionObjects;
}

- (BOOL)haveChanges {
    int i = 0, count = [self.objects count];

    for (i = 0; i < count; i++) {
        if (![[self.selectionStatusOfObjects objectAtIndex:i] isEqual:[self.originalSelObjects objectAtIndex:i]])
            return YES;
    }

    return NO;
}


#pragma mark - Modal Wrangling

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

#pragma mark - UITableView Delegate & DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
    return [self.objects count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SelectionTableRowCell];
    [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    cell.textLabel.text = self.objects[indexPath.row];

    BOOL curStatus = [[self.selectionStatusOfObjects objectAtIndex:indexPath.row] boolValue];
    cell.textLabel.textColor = (curStatus == YES ? [UIColor blueColor] : [UIColor blackColor]);
    cell.accessoryType = (UITableViewCellAccessoryType)([[self.selectionStatusOfObjects objectAtIndex:indexPath.row] boolValue] == YES ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);

    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL curStatus = [[self.selectionStatusOfObjects objectAtIndex:indexPath.row] boolValue];

    if (self.selectionType == kCheckbox) {
        [self.selectionStatusOfObjects replaceObjectAtIndex:indexPath.row withObject:[NSNumber numberWithBool:!curStatus]];

        [tableView reloadData];
    } else { //kRadio
        if (curStatus == NO) {
            NSUInteger index = [self.selectionStatusOfObjects indexOfObject:[NSNumber numberWithBool:YES]];
            [self.selectionStatusOfObjects replaceObjectAtIndex:indexPath.row withObject:[NSNumber numberWithBool:YES]];

            if (index != NSNotFound && index < [self.selectionStatusOfObjects count])
                [self.selectionStatusOfObjects replaceObjectAtIndex:index withObject:[NSNumber numberWithBool:NO]];

            [tableView reloadData];

            if (self.autoReturnInRadioSelectMode) {
                [self performSelector:@selector(gotoPreviousScreen) withObject:nil afterDelay:0.2f inModes:[NSArray arrayWithObject:[[NSRunLoop currentRunLoop] currentMode]]];
            }
        }
    }

    [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];
}

@end
