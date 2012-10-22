//
//  WPSegmentedSelectionTableViewController.m
//  WordPress
//
//  Created by Janakiram on 16/09/08.
//

#import "WPSegmentedSelectionTableViewController.h"
#import "WPCategoryTree.h"
#import "Category.h"
#import "NSString+XMLExtensions.h"

@interface NSObject (WPSelectionTableViewControllerDelegateCategory)

- (void)selectionTableViewController:(WPSelectionTableViewController *)selctionController completedSelectionsWithContext:(void *)selContext selectedObjects:(NSArray *)selectedObjects haveChanges:(BOOL)isChanged;

@end

@interface WPSegmentedSelectionTableViewController (private)

- (int)indentationLevelForCategory:(NSNumber *)categoryParentID categoryCollection:(NSMutableDictionary *)categoryDict;

@end

@implementation WPSegmentedSelectionTableViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Initialization code
        autoReturnInRadioSelectMode = YES;
        categoryIndentationLevelsDict = [[NSMutableDictionary alloc] init];
        rowTextColor = [[UIColor alloc] initWithRed:0.196 green:0.31 blue:0.522 alpha:1.0];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNewCategory:) name:WPNewCategoryCreatedAndUpdatedInBlogNotificationName object:nil];
    }

    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    //Set background to clear for iOS 4. Delete this line when we set iOS 5 as the min OS
    tableView.backgroundColor = [UIColor clearColor];
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"settings_bg"]];
}


#pragma mark -
#pragma mark Instance Methods

- (void)clean {
    [super clean];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)handleNewCategory:(NSNotification *)notification {
    Category *newCat = [[notification userInfo] objectForKey:@"category"];
    
    // If a new category was just added mark it selected by default.
    if ([objects containsObject:newCat]) {
        NSUInteger idx = [objects indexOfObject:newCat];
        [selectionStatusOfObjects replaceObjectAtIndex:idx withObject:[NSNumber numberWithBool:YES]];
    }
}


- (CGSize)contentSizeForViewInPopover;
{
	return CGSizeMake(320.0, [objects count] * 38.0 + 20.0);
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

    int i = 0, k = 0, count = [self.objects count];
    self.selectionStatusOfObjects = [NSMutableArray arrayWithCapacity:count];
    NSMutableDictionary *categoryDict = [[NSMutableDictionary alloc] init];

    for (i = 0; i < count; i++) {
        Category *category = [objects objectAtIndex:i];
        [categoryDict setObject:category forKey:category.categoryID];
    }

    [categoryIndentationLevelsDict removeAllObjects];

    for (i = 0; i < count; i++) {
        Category *category = [objects objectAtIndex:i];

        BOOL isFound = NO;

        for (k = 0; k <[selObjects count]; k++) {
            if ([[selObjects objectAtIndex:k] isEqual:category]) {
                [selectionStatusOfObjects addObject:[NSNumber numberWithBool:YES]];
                isFound = YES;
                break;
            }
        }

        if (!isFound)
            [selectionStatusOfObjects addObject:[NSNumber numberWithBool:NO]];

        int indentationLevel = [self indentationLevelForCategory:category.parentID categoryCollection:categoryDict];
        [categoryIndentationLevelsDict setValue:[NSNumber numberWithInt:indentationLevel]
                                         forKey:[category.categoryID stringValue]];
    }

    self.originalSelObjects = [selectionStatusOfObjects copy];
    
    [tableView reloadData];
}

- (int)indentationLevelForCategory:(NSNumber *)parentID categoryCollection:(NSMutableDictionary *)categoryDict {
    if ([parentID intValue] == 0) {
        return 0;
    } else {
        Category *category = [categoryDict objectForKey:parentID];
        return ([self indentationLevelForCategory:category.parentID categoryCollection:categoryDict]) + 1;
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
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:selectionTableRowCell];
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    }

    Category *category = [objects objectAtIndex:indexPath.row];
    int indentationLevel = [[categoryIndentationLevelsDict valueForKey:[category.categoryID stringValue]] intValue];
    cell.indentationLevel = indentationLevel;

    if (indentationLevel == 0) {
        cell.imageView.image = nil;
    } else {
        cell.imageView.image = [UIImage imageNamed:@"category_child.png"];
    }

    cell.textLabel.text = [[[objects objectAtIndex:indexPath.row] valueForKey:@"categoryName"] stringByDecodingXMLCharacters];
        
    BOOL curStatus = [[selectionStatusOfObjects objectAtIndex:indexPath.row] boolValue];

    if (curStatus) {
        cell.textLabel.textColor = rowTextColor;
    } else {
        cell.textLabel.textColor = [UIColor blackColor];
    }

    cell.accessoryType = [self accessoryTypeForRowWithIndexPath:indexPath ofTableView:tableView];
    return cell;
}

#pragma mark TableView Delegate Methods

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
