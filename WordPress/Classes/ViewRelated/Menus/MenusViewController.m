#import "MenusViewController.h"
#import "Blog.h"
#import "MenusService.h"
#import "Menu.h"
#import "MenuLocation.h"
#import "MenuItem.h"
#import "MenusLocationCell.h"
#import "MenusCell.h"

typedef NS_ENUM(NSInteger) {
    
    MenusSectionLocations = 0,
    MenusSectionMenus,
    MenusSectionMenuItems
    
}MenusSection;

@interface MenusViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *sections;
@property (nonatomic, strong) Blog *blog;
@property (nonatomic, strong) MenusService *menusService;
@property (nonatomic, strong) MenuLocation *selectedMenuLocation;
@property (nonatomic, strong) UIActivityIndicatorView *activity;

@end

@implementation MenusViewController

- (id)initWithBlog:(Blog *)blog
{
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    self = [super init];
    if(self) {
        
        // using a new child context to keep local changes disacardable
        // using main queue as we still want processing done on the main thread
        NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        context.parentContext = blog.managedObjectContext;
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
        
        // set local blog from local context
        self.blog = [context objectWithID:blog.objectID];

        MenusService *service = [[MenusService alloc] initWithManagedObjectContext:context];
        self.menusService = service;
    }
    
    return self;
}

- (void)loadView
{
    [super loadView];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:tableView];
    self.tableView = tableView;
    
    tableView.separatorInset = UIEdgeInsetsZero;
    tableView.layoutMargins = UIEdgeInsetsZero;
    
    tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    
    UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activity.hidesWhenStopped = YES;
    [self.view addSubview:activity];
    self.activity = activity;
    
    [self setupAutolayoutConstraints];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = NSLocalizedString(@"Menus", @"Title for screen that allows configuration of your site's menus");
    
    [self syncWithBlogMenus];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.activity.center = self.tableView.center;
}

#pragma mark - Views setup

- (void)setupAutolayoutConstraints
{
    NSDictionary *views = @{@"tableView": self.tableView, @"activity": self.activity};
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[tableView]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:views]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tableView]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:views]];
}

#pragma mark - setup

- (void)setupSectionsIfNeeded
{
    if(self.sections.count) {
        return;
    }
    
    self.sections = @[@(MenusSectionLocations), @(MenusSectionMenus), @(MenusSectionMenuItems)];
}

#pragma mark - local updates

- (void)syncWithBlogMenus
{
    [self.activity startAnimating];
    [self.menusService syncMenusForBlog:self.blog
                                success:^{
                                    [self.activity stopAnimating];
                                    [self didSyncBlog];
                                }
                                failure:^(NSError *error) {
                                    DDLogDebug(@"MenusViewController could not sync menus for blog");
                                    [self.navigationController popViewControllerAnimated:YES];
                                }];
}

- (void)didSyncBlog
{
    [self setupSectionsIfNeeded];

    // the selected location defaults to the first locaiton in the ordered set
    self.selectedMenuLocation = [self.blog.menuLocations firstObject];
    [self.tableView reloadData];
}

- (void)selectedLocationWithIndexPath:(NSIndexPath *)indexPath
{
    MenuLocation *location = [self.blog.menuLocations objectAtIndex:indexPath.row];
    if(location == self.selectedMenuLocation)
        return;
    
    self.selectedMenuLocation = location;
    [self.tableView reloadData];
}

- (void)selectedMenuWithIndexPath:(NSIndexPath *)indexPath
{
    self.selectedMenuLocation.menu = [self.blog.menus objectAtIndex:indexPath.row];
    [self.tableView reloadData];
}

#pragma - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    switch ([self menusSectionForTableViewSection:section]) {
        case MenusSectionLocations:
            count = self.blog.menuLocations.count;
            break;
        case MenusSectionMenus:
            count = self.blog.menus.count;
            break;
        case MenusSectionMenuItems:
            count = self.selectedMenuLocation.menu.items.count;
            break;
    }
    
    return count;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height;
    MenusSection menusSection = [self menusSectionForTableViewSection:indexPath.section];
    switch (menusSection) {
        case MenusSectionLocations:
        case MenusSectionMenus:
            height = MenusSelectionCellDefaultHeight;
            break;
        default:
            height = tableView.rowHeight;
            break;
    }
    
    return height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height;
    MenusSection menusSection = [self menusSectionForTableViewSection:indexPath.section];
    switch (menusSection) {
        case MenusSectionLocations: {
            MenuLocation *location = [self.blog.menuLocations objectAtIndex:indexPath.row];
            height = [MenusLocationCell heightForTableView:tableView location:location];
            break;
        }
        case MenusSectionMenus: {
            Menu *menu = [self.blog.menus objectAtIndex:indexPath.row];
            height = [MenusCell heightForTableView:tableView menu:menu];
            break;
        }
        default:
            height = tableView.rowHeight;
            break;
    }
    
    return height;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    MenusSection section = [self menusSectionForTableViewSection:indexPath.section];
    switch (section) {
        case MenusSectionLocations:
        {
            MenuLocation *location = [self.blog.menuLocations objectAtIndex:indexPath.row];
            MenusLocationCell *locationCell = (MenusLocationCell *)cell;
            locationCell.location = location;
            cell.accessoryType = UITableViewCellAccessoryNone;
            if(location == self.selectedMenuLocation) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            break;
        }
        case MenusSectionMenus:
        {
            Menu *menu = [self.blog.menus objectAtIndex:indexPath.row];
            MenusCell *menuCell = (MenusCell *)cell;
            menuCell.menu = [self.blog.menus objectAtIndex:indexPath.row];
            cell.accessoryType = UITableViewCellAccessoryNone;
            if(menu == self.selectedMenuLocation.menu) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            break;
        }
        case MenusSectionMenuItems:
        {
            MenuItem *item = [self.selectedMenuLocation.menu.items objectAtIndex:indexPath.row];
            cell.textLabel.text = item.name;
            break;
        }
        default:
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseIdentifier = nil;
    MenusSection section = [self menusSectionForTableViewSection:indexPath.section];
    switch (section) {
        case MenusSectionLocations:
            reuseIdentifier = @"locations_cell";
            break;
        case MenusSectionMenus:
            reuseIdentifier = @"menus_cell";
            break;
        case MenusSectionMenuItems:
            reuseIdentifier = @"items_cell";
            break;
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if(!cell) {
        
        switch (section) {
            case MenusSectionLocations:
                cell = [[MenusLocationCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
                break;
            case MenusSectionMenus:
                cell = [[MenusCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
                break;
            default:
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
                break;
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MenusSection menusSection = [self menusSectionForTableViewSection:indexPath.section];
    switch (menusSection) {
        case MenusSectionLocations:
        {
            [self selectedLocationWithIndexPath:indexPath];
            break;
        }
        case MenusSectionMenus:
        {
            [self selectedMenuWithIndexPath:indexPath];
            break;
        }
        default:
            break;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Table helpers

- (NSInteger)tableSectionForMenusSection:(MenusSection)menusSection
{
    return [self.sections indexOfObject:@(menusSection)];
}

- (MenusSection)menusSectionForTableViewSection:(NSInteger)section
{
    return [[self.sections objectAtIndex:section] integerValue];
}

- (NSString *)titleForHeaderInSection:(MenusSection)section
{
    NSString *headingTitle = nil;
    switch (section) {
        case MenusSectionLocations:
            headingTitle = [NSString stringWithFormat:NSLocalizedString(@"%i menu areas in this theme", @"Title for the number of available locations"), self.blog.menuLocations.count];
            break;
        case MenusSectionMenus:
            headingTitle = [NSString stringWithFormat: NSLocalizedString(@"%i menus available", @"Title for the number of available menus"), self.blog.menus.count];
            break;
        default:
            break;
    }
    return headingTitle;
}

@end
