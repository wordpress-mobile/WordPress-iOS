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
#import "WPTableViewCell.h"
#import "WPAddCategoryViewController.h"

static NSString *const SelectionTableRowCell = @"SelectionTableRowCell";

@interface NSObject (WPSelectionTableViewControllerDelegateCategory)

- (void)selectionTableViewController:(WPSelectionTableViewController *)selctionController completedSelectionsWithContext:(void *)selContext selectedObjects:(NSArray *)selectedObjects haveChanges:(BOOL)isChanged;

@end

@interface WPSegmentedSelectionTableViewController ()

@property (nonatomic, strong) NSMutableDictionary *categoryIndentationLevelsDict;

@end

@implementation WPSegmentedSelectionTableViewController

- (id)init {
    self = [super init];
    if (self) {
        self.autoReturnInRadioSelectMode = YES;
        _categoryIndentationLevelsDict = [[NSMutableDictionary alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNewCategory:) name:NewCategoryCreatedAndUpdatedInBlogNotification object:nil];
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero]; // Hide extra cell separators.
    [self.tableView registerClass:[WPTableViewCell class] forCellReuseIdentifier:SelectionTableRowCell];
}

- (void)clean {
    [super clean];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)handleNewCategory:(NSNotification *)notification {
    Category *newCat = [[notification userInfo] objectForKey:@"category"];
    
    // If a new category was just added mark it selected by default.
    if ([self.objects containsObject:newCat]) {
        NSUInteger idx = [self.objects indexOfObject:newCat];
        [self.selectionStatusOfObjects replaceObjectAtIndex:idx withObject:[NSNumber numberWithBool:YES]];
    }
}


- (CGSize)contentSizeForViewInPopover;
{
	return CGSizeMake(320.0, [self.objects count] * 38.0 + 20.0);
}


- (BOOL)haveChanges {
    int i = 0, count = [self.objects count];

    for (i = 0; i < count; i++) {
        if (![[self.selectionStatusOfObjects objectAtIndex:i] isEqual:[self.originalSelObjects objectAtIndex:i]])
            return YES;
    }

    return NO;
}

//overriding the main Method
- (void)populateDataSource:(NSArray *)sourceObjects havingContext:(void *)context selectedObjects:(NSArray *)selObjects selectionType:(WPSelectionType)aType andDelegate:(id)delegate {
    self.curContext = context;
    self.selectionType = aType;
    self.selectionDelegate = delegate;

    WPCategoryTree *tree = [[WPCategoryTree alloc] initWithParent:nil];
    [tree getChildrenFromObjects:sourceObjects];

    self.objects = [tree getAllObjects];

    int i = 0, k = 0, count = [self.objects count];
    self.selectionStatusOfObjects = [NSMutableArray arrayWithCapacity:count];
    NSMutableDictionary *categoryDict = [[NSMutableDictionary alloc] init];

    for (i = 0; i < count; i++) {
        Category *category = [self.objects objectAtIndex:i];
        [categoryDict setObject:category forKey:category.categoryID];
    }

    [self.categoryIndentationLevelsDict removeAllObjects];

    for (i = 0; i < count; i++) {
        Category *category = [self.objects objectAtIndex:i];

        BOOL isFound = NO;

        for (k = 0; k <[selObjects count]; k++) {
            if ([[selObjects objectAtIndex:k] isEqual:category]) {
                [self.selectionStatusOfObjects addObject:[NSNumber numberWithBool:YES]];
                isFound = YES;
                break;
            }
        }

        if (!isFound)
            [self.selectionStatusOfObjects addObject:[NSNumber numberWithBool:NO]];

        int indentationLevel = [self indentationLevelForCategory:category.parentID categoryCollection:categoryDict];
        [self.categoryIndentationLevelsDict setValue:[NSNumber numberWithInt:indentationLevel]
                                         forKey:[category.categoryID stringValue]];
    }

    self.originalSelObjects = [self.selectionStatusOfObjects copy];
    
    [self.tableView reloadData];
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SelectionTableRowCell];
    
    Category *category = [self.objects objectAtIndex:indexPath.row];
    int indentationLevel = [[self.categoryIndentationLevelsDict valueForKey:[category.categoryID stringValue]] intValue];
    cell.indentationLevel = indentationLevel;

    if (indentationLevel == 0) {
        cell.imageView.image = nil;
    } else {
        cell.imageView.image = [UIImage imageNamed:@"category_child.png"];
    }

    cell.textLabel.text = [[[self.objects objectAtIndex:indexPath.row] valueForKey:@"categoryName"] stringByDecodingXMLCharacters];
        
    BOOL curStatus = [[self.selectionStatusOfObjects objectAtIndex:indexPath.row] boolValue];

    if (curStatus) {
        cell.textLabel.textColor = [UIColor colorWithRed:0.196 green:0.31 blue:0.522 alpha:1.0];;
    } else {
        cell.textLabel.textColor = [UIColor blackColor];
    }

    [WPStyleGuide configureTableViewCell:cell];

    cell.accessoryType = [self accessoryTypeForRowWithIndexPath:indexPath ofTableView:tableView];
    return cell;
}

#pragma mark TableView Delegate Methods

- (UITableViewCellAccessoryType)accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath ofTableView:(UITableView *)tableView {
    int previousRows = indexPath.section + indexPath.row;
    int currentSection = indexPath.section;

    while (currentSection > 0) {
        currentSection--;
        previousRows += [self tableView:tableView numberOfRowsInSection:currentSection] - 1;
    }

    return (UITableViewCellAccessoryType)([[self.selectionStatusOfObjects objectAtIndex:previousRows] boolValue] == YES ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);
}

@end
