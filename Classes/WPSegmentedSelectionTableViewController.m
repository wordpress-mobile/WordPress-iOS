//
//  WPSegmentedSelectionTableViewController.m
//  WordPress
//
//  Created by Janakiram on 16/09/08.
//

#import "WPSegmentedSelectionTableViewController.h"
#import "WPCategoryTree.h"

@interface NSObject (WPSelectionTableViewControllerDelegateCategory)

- (void)selectionTableViewController:(WPSelectionTableViewController *)selctionController completedSelectionsWithContext:(void *)selContext selectedObjects:(NSArray *)selectedObjects haveChanges:(BOOL)isChanged;

@end

@interface WPSegmentedSelectionTableViewController (private)

- (int)indentationLevelForCategory:(NSString *)categoryParentID categoryCollection:(NSMutableDictionary *)categoryDict;

@end

@implementation WPSegmentedSelectionTableViewController

//@synthesize objects, selectionStatusOfObjects, originalSelObjects;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Initialization code
        autoReturnInRadioSelectMode = YES;
        categoryIndentationLevelsDict = [[NSMutableDictionary alloc] init];
        rowTextColor = [[UIColor alloc] initWithRed:0.196 green:0.31 blue:0.522 alpha:1.0];
    }

    return self;
}

- (void)dealloc {
    [categoryIndentationLevelsDict release];
    [rowTextColor release];
//	[originalSelObjects release];
//	[selectionStatusOfObjects release];
//	[objects release];
    [super dealloc];
}

- (void)viewWillDisappear:(BOOL)animated {
    if (!flag) {
        if ([selectionDelegate respondsToSelector:@selector(selectionTableViewController:completedSelectionsWithContext:selectedObjects:haveChanges:)]) {
            NSMutableArray *result = [NSMutableArray array];
            int i = 0, count = [objects count];

            for (i = 0; i < count; i++) {
                if ([[self.selectionStatusOfObjects objectAtIndex:i] boolValue] == YES) {
                    [result addObject:[[objects objectAtIndex:i] objectForKey:@"categoryName"]];
                }
            }

            [selectionDelegate selectionTableViewController:self completedSelectionsWithContext:curContext selectedObjects:result haveChanges:[self haveChanges]];
        }
    }
}

- (BOOL)haveChanges {
    int i = 0, count = [objects count];

    for (i = 0; i < count; i++) {
        if (![[self.selectionStatusOfObjects objectAtIndex:i] isEqual:[self.originalSelObjects objectAtIndex:i]])
            return YES;
    }

    return NO;
}

//overriding the main Method
- (void)populateDataSource:(NSArray *)sourceObjects havingContext:(void *)context selectedObjects:(NSArray *)selObjects selectionType:(WPSelectionType)aType andDelegate:(id)delegate {
    curContext = context;
    selectionType = aType;
    selectionDelegate = delegate;

    WPCategoryTree *tree = [[WPCategoryTree alloc] initWithParent:nil];
    [tree getChildrenFromObjects:sourceObjects];

    self.objects = [tree getAllObjects];
    [tree release];

    int i = 0, k = 0, count = [self.objects count];
    self.selectionStatusOfObjects = [NSMutableArray arrayWithCapacity:count];
    NSMutableDictionary *categoryDict = [[NSMutableDictionary alloc] init];

    for (i = 0; i < count; i++) {
        NSMutableDictionary *category = [objects objectAtIndex:i];
        NSString *categoryId = [category objectForKey:@"categoryId"];
        [categoryDict setObject:category forKey:categoryId];
    }

    [categoryIndentationLevelsDict removeAllObjects];

    for (i = 0; i < count; i++) {
        NSMutableDictionary *category = [objects objectAtIndex:i];
        NSString *parentID = [category objectForKey:@"parentId"];
        NSString *catName = [category objectForKey:@"categoryName"];

        BOOL isFound = NO;

        for (k = 0; k <[selObjects count]; k++) {
            if ([[selObjects objectAtIndex:k] isEqualToString:catName]) {
                [selectionStatusOfObjects addObject:[NSNumber numberWithBool:YES]];
                isFound = YES;
                break;
            }
        }

        if (!isFound)
            [selectionStatusOfObjects addObject:[NSNumber numberWithBool:NO]];

        int indentationLevel = [self indentationLevelForCategory:parentID categoryCollection:categoryDict];
        [categoryIndentationLevelsDict setValue:[NSNumber numberWithInt:indentationLevel]
         forKey:[category objectForKey:@"categoryId"]];
    }

    self.originalSelObjects = [[selectionStatusOfObjects copy] autorelease];

    flag = NO;
    [categoryDict release];
    [tableView reloadData];
}

- (int)indentationLevelForCategory:(NSString *)parentID categoryCollection:(NSMutableDictionary *)categoryDict {
    if ([parentID intValue] == 0) {
        return 0;
    } else {
        return ([self indentationLevelForCategory:[[categoryDict objectForKey:parentID] objectForKey:@"parentId"] categoryCollection:categoryDict]) + 1;
    }
}

#pragma mark TableView DataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [objects count];
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *selectionTableRowCell = @"selectionTableRowCell";

    UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:selectionTableRowCell];

    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:selectionTableRowCell] autorelease];
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    }

    int indentationLevel = [[categoryIndentationLevelsDict valueForKey:[[objects objectAtIndex:indexPath.row] objectForKey:@"categoryId"]] intValue];
    cell.indentationLevel = indentationLevel;

    if (indentationLevel == 0) {
#if defined __IPHONE_3_0
        cell.imageView.image = nil;
#else if defined __IPHONE_2_0
        cell.image = nil;
#endif
    } else {
#if defined __IPHONE_3_0
        cell.imageView.image = [UIImage imageNamed:@"category_child.png"];
#else if defined __IPHONE_2_0
        cell.image = [UIImage imageNamed:@"category_child.png"];
#endif
    }

#if defined __IPHONE_3_0
    cell.textLabel.text = [[objects objectAtIndex:indexPath.row] objectForKey:@"categoryName"];
#else if defined __IPHONE_2_0
    cell.text = [[objects objectAtIndex:indexPath.row] objectForKey:@"categoryName"];
#endif

    BOOL curStatus = [[selectionStatusOfObjects objectAtIndex:indexPath.row] boolValue];

    if (curStatus) {
#if defined __IPHONE_3_0
        cell.textLabel.textColor = rowTextColor;
#else if defined __IPHONE_2_0
        cell.textColor = rowTextColor;
#endif
    } else {
#if defined __IPHONE_3_0
        cell.textLabel.textColor = [UIColor blackColor];
#else if defined __IPHONE_2_0
        cell.textColor = [UIColor blackColor];
#endif
    }

    cell.accessoryType = [self accessoryTypeForRowWithIndexPath:indexPath ofTableView:tableView];
    return cell;
}

#pragma mark TableView Delegate Methods

//- (UITableViewCellAccessoryType)tableView:(UITableView *)aTableView accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath
//{
//    int previousRows = indexPath.section + indexPath.row;
//    int currentSection = indexPath.section;
//    while ( currentSection > 0 ) {
//        currentSection--;
//        previousRows += [self tableView:aTableView numberOfRowsInSection:currentSection] - 1;
//    }
//	return (UITableViewCellAccessoryType)( [[selectionStatusOfObjects objectAtIndex:previousRows] boolValue] == YES ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone );
//}

- (UITableViewCellAccessoryType)accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath ofTableView:(UITableView *)aTableView {
    int previousRows = indexPath.section + indexPath.row;
    int currentSection = indexPath.section;

    while (currentSection > 0) {
        currentSection--;
        previousRows += [self tableView:aTableView numberOfRowsInSection:currentSection] - 1;
    }

    return (UITableViewCellAccessoryType)([[selectionStatusOfObjects objectAtIndex:previousRows] boolValue] == YES ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat height = 38.0;
    return height;
}

- (CGFloat)tableView:(UITableView *)aTableView heightForHeaderInSection:(NSInteger)section {
    CGFloat height = 10.0;
    [aTableView setSectionHeaderHeight:height];
    return height;
}

- (CGFloat)tableView:(UITableView *)aTableView heightForFooterInSection:(NSInteger)section {
    CGFloat height = 0.5;
    [aTableView setSectionFooterHeight:height];
    return height;
}

@end
