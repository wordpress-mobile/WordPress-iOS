#import "PostCategoriesViewController.h"
#import "PostCategory.h"
#import "WordPressAppDelegate.h"
#import "WPAddPostCategoryViewController.h"
#import "WPCategoryTree.h"
#import "CustomHighlightButton.h"
#import "PostCategoryService.h"
#import <WordPressShared/NSString+XMLExtensions.h>
#import <WordPressShared/WPTableViewCell.h>
#import "WordPress-Swift.h"

static NSString * const CategoryCellIdentifier = @"CategoryCellIdentifier";
static const CGFloat CategoryCellIndentation = 16.0;

@interface PostCategoriesViewController () <WPAddPostCategoryViewControllerDelegate>

@property (nonatomic, strong) Blog *blog;
@property (nonatomic, strong) NSMutableDictionary *categoryIndentationDict;
@property (nonatomic, strong) NSMutableArray *selectedCategories;
@property (nonatomic, strong) NSArray *originalSelection;
@property (nonatomic, strong) NSArray *categories;
@property (nonatomic, assign) CategoriesSelectionMode selectionMode;
@property (nonatomic, assign) BOOL addingNewCategory;
@property (nonatomic, assign) BOOL hasInitiallySyncedCategories;

@end

@implementation PostCategoriesViewController

- (instancetype)initWithBlog:(Blog *)blog
            currentSelection:(NSArray *)originalSelection
               selectionMode:(CategoriesSelectionMode)selectionMode
{
    self = [super initWithStyle:UITableViewStyleGrouped];
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
    [WPStyleGuide configureAutomaticHeightRowsFor:self.tableView];

    // Hide extra cell separators.
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView registerClass:[WPTableViewCell class] forCellReuseIdentifier:CategoryCellIdentifier];

    [self setupRefreshControl];

    // Show the add category button if we're selecting categories for a post.
    if (self.selectionMode == CategoriesSelectionModePost || self.selectionMode == CategoriesSelectionModeBlogDefault) {
        UIBarButtonItem *rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-post-add"]
                                                                               style:UIBarButtonItemStylePlain
                                                                              target:self
                                                                              action:@selector(showAddNewCategory)];
        self.navigationItem.rightBarButtonItem = rightBarButtonItem;
    }
    
    switch (self.selectionMode) {
        case (CategoriesSelectionModeParent): {
            self.title = NSLocalizedString(@"Parent Category", @"Title for selecting parent category of a category");
        } break;
        case (CategoriesSelectionModePost): {
            self.title = NSLocalizedString(@"Post Categories", @"Title for selecting categories for a post");
        } break;
        case (CategoriesSelectionModeBlogDefault): {
            self.title = NSLocalizedString(@"Default Category", @"Title for selecting a default category for a post");
        }
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self reloadCategoriesTableViewData];

    if (!self.hasInitiallySyncedCategories) {
        self.hasInitiallySyncedCategories = YES;
        [self syncCategories];
    }
}

#pragma mark - Instance Methods

- (void)setupRefreshControl
{
    if (self.refreshControl) {
        return;
    }
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshCategoriesWithInteraction:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
}

- (BOOL)hasChanges
{
    return [self.originalSelection isEqualToArray:self.selectedCategories];
}

- (void)showAddNewCategory
{
    WPAddPostCategoryViewController *addCategoryViewController = [[WPAddPostCategoryViewController alloc] initWithBlog:self.blog];
    addCategoryViewController.delegate = self;

    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:addCategoryViewController];
    navigationController.modalPresentationStyle = UIModalPresentationFormSheet;

    [self presentViewController:navigationController
                       animated:YES
                     completion:nil];
}

- (void)syncCategories
{
    __weak __typeof__(self) weakSelf = self;
    PostCategoryService *service = [[PostCategoryService alloc] initWithManagedObjectContext:self.blog.managedObjectContext];
    [service syncCategoriesForBlog:self.blog success:^{
        [weakSelf reloadCategoriesTableViewData];
        [weakSelf.refreshControl endRefreshing];
    } failure:^(NSError * _Nonnull error) {
        [weakSelf.refreshControl endRefreshing];
    }];
}

- (void)reloadCategoriesTableViewData
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

    // Remove any previously selected category objects that are no longer available.
    NSArray *selectedCategories = [self.selectedCategories copy];
    for (PostCategory *category in selectedCategories) {
        if ([category isDeleted] || ![self.blog.sortedCategories containsObject:category]) {
            [self.selectedCategories removeObject:category];
        }
    }
    // Notify the delegate of any changes for selectedCategories.
    if (self.selectedCategories.count != selectedCategories.count) {
        if ([self.delegate respondsToSelector:@selector(postCategoriesViewController:didUpdateSelectedCategories:)]) {
            [self.delegate postCategoriesViewController:self didUpdateSelectedCategories:[NSSet setWithArray:self.selectedCategories]];
        }
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

#pragma mark - Button Actions

- (void)refreshCategoriesWithInteraction:(UIRefreshControl *)refreshControl
{
    [self syncCategories];
}

#pragma mark - UITableView Delegate & DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger result = [self.categories count];
    
    if (self.selectionMode == CategoriesSelectionModeParent) {
        result += 1;
    }
    
    return result;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WPTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CategoryCellIdentifier forIndexPath:indexPath];
    
    NSInteger row = indexPath.row; // Use this index for the remainder for this method.
    
    // When showing this VC in mode CategoriesSelectionModeParent, we want the first item to be
    // "No Category" and come up in red, to allow the user to select no category at all.
    //
    if (self.selectionMode == CategoriesSelectionModeParent) {
        if (row == 0) {
            [WPStyleGuide configureTableViewDestructiveActionCell:cell];
            cell.textLabel.textAlignment = NSTextAlignmentNatural;
            
            cell.textLabel.text = NSLocalizedString(@"No Category",
                                                    @"Text shown (to select no-category) in the parent-category-selection screen when creating a new category.");
            
            if (self.selectedCategories == nil) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            
            return cell;
        } else {
            row -= 1;
        }
    }
    
    PostCategory* category = self.categories[row];
    NSInteger indentationLevel = [[self.categoryIndentationDict objectForKey:[category.categoryID stringValue]] integerValue];
    cell.indentationLevel = indentationLevel;
    cell.indentationWidth = CategoryCellIndentation;
    cell.textLabel.text = [category.categoryName stringByDecodingXMLCharacters];
    [WPStyleGuide configureTableViewCell:cell];

    if ([self.selectedCategories containsObject:category]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *currentSelectedIndexPath = [tableView indexPathForSelectedRow];

    [tableView deselectRowAtIndexPath:currentSelectedIndexPath animated:YES];
    
    PostCategory *category = nil;
    
    if (self.selectionMode == CategoriesSelectionModeParent) {
        if (indexPath.row > 0) {
            category = self.categories[indexPath.row - 1];
        }
    } else {
        category = self.categories[indexPath.row];
    }
    
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
            if ([self.selectedCategories containsObject:category]){
                return;
            }
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
    if (self.selectionMode == CategoriesSelectionModeBlogDefault) {
        [self.selectedCategories removeAllObjects];
        [self.selectedCategories addObject:category];
        if ([self.delegate respondsToSelector:@selector(postCategoriesViewController:didSelectCategory:)]) {
            [self.delegate postCategoriesViewController:self didSelectCategory:category];
        }
    } else {
        [self.selectedCategories addObject:category];
        if ([self.delegate respondsToSelector:@selector(postCategoriesViewController:didUpdateSelectedCategories:)]) {
            [self.delegate postCategoriesViewController:self didUpdateSelectedCategories:[NSSet setWithArray:self.selectedCategories]];
        }
    }
}

@end
