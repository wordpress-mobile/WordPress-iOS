#import "PostCategoriesViewController.h"
#import "PostCategory.h"
#import "NSString+XMLExtensions.h"
#import "WordPressAppDelegate.h"
#import "WPAddPostCategoryViewController.h"
#import "WPCategoryTree.h"
#import "WPTableViewCell.h"
#import "CustomHighlightButton.h"

@interface PostCategoriesViewController () <WPAddPostCategoryViewControllerDelegate>

@property (nonatomic, strong) Blog *blog;
@property (nonatomic, strong) NSMutableDictionary *categoryIndentationDict;
@property (nonatomic, strong) NSMutableArray *selectedCategories;
@property (nonatomic, strong) NSArray *originalSelection;
@property (nonatomic, strong) NSArray *categories;
@property (nonatomic, assign) CategoriesSelectionMode selectionMode;
@property (nonatomic, assign) BOOL addingNewCategory;
@end

@implementation PostCategoriesViewController

- (instancetype)initWithBlog:(Blog *)blog
            currentSelection:(NSArray *)originalSelection
               selectionMode:(CategoriesSelectionMode)selectionMode
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _selectionMode = selectionMode;
        _blog = blog;
        _originalSelection = originalSelection;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.accessibilityIdentifier = @"CategoriesList";
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero]; // Hide extra cell separators.

    // Show the add category button if we're selecting categories for a post.
    if (self.selectionMode == CategoriesSelectionModePost || self.selectionMode == CategoriesSelectionModeBlogDefault) {
        UIImage *image = [UIImage imageNamed:@"icon-posts-add"];
        CustomHighlightButton *button = [[CustomHighlightButton alloc] initWithFrame:CGRectMake(0.0, 0.0, image.size.width, image.size.height)];
        [button setImage:image forState:UIControlStateNormal];
        [button addTarget:self action:@selector(showAddNewCategory) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];

        [WPStyleGuide setRightBarButtonItemWithCorrectSpacing:rightBarButtonItem forNavigationItem:self.navigationItem];
    }
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self configureCategories];
}

#pragma mark - Instance Methods

- (BOOL)hasChanges
{
    return [self.originalSelection isEqualToArray:self.selectedCategories];
}

- (void)showAddNewCategory
{
    WPAddPostCategoryViewController *addCategoryViewController = [[WPAddPostCategoryViewController alloc] initWithBlog:self.blog];
    addCategoryViewController.delegate = self;
    [self.navigationController pushViewController:addCategoryViewController animated:YES];
}

- (void)configureCategories
{
    if (!self.selectedCategories) {
        self.selectedCategories = [self.originalSelection mutableCopy];
    }
    self.categoryIndentationDict = [NSMutableDictionary dictionary];

    // Get sorted categories by parent/child relationship
    WPCategoryTree *tree = [[WPCategoryTree alloc] initWithParent:nil];
    [tree getChildrenFromObjects:[self.blog sortedCategories]];
    self.categories = [tree getAllObjects];

    // Get the indentation level of each category.
    NSUInteger count = [self.categories count];

    NSMutableDictionary *categoryDict = [NSMutableDictionary dictionary];
    for (NSInteger i = 0; i < count; i++) {
        PostCategory *category = [self.categories objectAtIndex:i];
        [categoryDict setObject:category forKey:category.categoryID];
    }

    for (NSInteger i = 0; i < count; i++) {
        PostCategory *category = [self.categories objectAtIndex:i];

        NSInteger indentationLevel = [self indentationLevelForCategory:category.parentID categoryCollection:categoryDict];

        [self.categoryIndentationDict setValue:[NSNumber numberWithInteger:indentationLevel]
                                              forKey:[category.categoryID stringValue]];
    }

    [self.tableView reloadData];
}

- (NSInteger)indentationLevelForCategory:(NSNumber *)parentID categoryCollection:(NSMutableDictionary *)categoryDict
{
    if ([parentID intValue] == 0) {
        return 0;
    }

    PostCategory *category = [categoryDict objectForKey:parentID];
    return ([self indentationLevelForCategory:category.parentID categoryCollection:categoryDict]) + 1;
}

#pragma mark - UITableView Delegate & DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section
{
    return [self.categories count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *categoryCell = @"categoryCell";
    WPTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:categoryCell];
    if (!cell) {
        cell = [[WPTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:categoryCell];
    }

    PostCategory *category = self.categories[indexPath.row];

    // Cell indentation
    NSInteger indentationLevel = [[self.categoryIndentationDict objectForKey:[category.categoryID stringValue]] integerValue];
    cell.indentationLevel = indentationLevel;

    if (indentationLevel == 0) {
        cell.imageView.image = nil;
    } else {
        cell.imageView.image = [UIImage imageNamed:@"category_child.png"];
    }

    cell.textLabel.text = [category.categoryName stringByDecodingXMLCharacters];

    [WPStyleGuide configureTableViewCell:cell];

    // Only show checkmarks if we're selecting for a post.
    if (self.selectionMode == CategoriesSelectionModePost || self.selectionMode == CategoriesSelectionModeBlogDefault) {
        if ([self.selectedCategories containsObject:category]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];

    PostCategory *category = self.categories[indexPath.row];
    switch (self.selectionMode) {
        case (CategoriesSelectionModeParent): {
            // If we're choosing a parent category then we're done.
            if ([self.delegate respondsToSelector:@selector(postCategoriesViewController:didSelectCategory:)]) {
                [self.delegate postCategoriesViewController:self didSelectCategory:category];
            }

            [self.navigationController popViewControllerAnimated:YES];
            return;
        } break;
        case (CategoriesSelectionModePost): {
            if ([self.selectedCategories containsObject:category]) {
                [self.selectedCategories removeObject:category];
                [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;
            } else {
                [self.selectedCategories addObject:category];
                [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
            }
            
            if ([self.delegate respondsToSelector:@selector(postCategoriesViewController:didUpdateSelectedCategories:)]) {
                [self.delegate postCategoriesViewController:self didUpdateSelectedCategories:[NSSet setWithArray:self.selectedCategories]];
            }
        } break;
        case (CategoriesSelectionModeBlogDefault): {
            [self.selectedCategories removeAllObjects];
            [self.selectedCategories addObject:category];
            [self.tableView reloadData];
            if ([self.delegate respondsToSelector:@selector(postCategoriesViewController:didSelectCategory:)]) {
                [self.delegate postCategoriesViewController:self didSelectCategory:category];
            }
        }
    }
}

#pragma mark - WPAddPostCategoryViewControllerDelegate

- (void)addPostCategoryViewController:(WPAddPostCategoryViewController *)controller didAddCategory:(PostCategory *)category
{
    [self.selectedCategories addObject:category];
    if ([self.delegate respondsToSelector:@selector(postCategoriesViewController:didUpdateSelectedCategories:)]) {
        [self.delegate postCategoriesViewController:self didUpdateSelectedCategories:[NSSet setWithArray:self.selectedCategories]];
    }
}

@end
