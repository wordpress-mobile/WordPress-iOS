#import "MenusViewController.h"
#import "Blog.h"
#import "MenusService.h"
#import "Menu.h"
#import "MenuLocation.h"
#import "MenuItem.h"
#import "MenusSelectedLocationCell.h"
#import "MenusSelectedMenuCell.h"
#import "WPStyleGuide.h"
#import "MenusItemsHeaderView.h"

typedef NS_ENUM(NSInteger) {
    
    MenusSectionSelectedLocation = 0,
    MenusSectionAvailableLocations,
    MenusSectionSelectedMenu,
    MenusSectionAvailableMenus,
    MenusSectionMenuItems
    
}MenusSection;

static NSString * const MenusSectionLocationsKey = @"locations";
static NSString * const MenusSectionMenusKey = @"menus";
static NSString * const MenusSectionMenuItemsKey = @"menu_items";

@implementation NSDictionary (Menus)

- (NSMutableArray *)menuLocations
{
    return self[MenusSectionLocationsKey];
}
- (NSMutableArray *)menus
{
    return self[MenusSectionMenusKey];
}
- (NSMutableArray *)menuItems
{
    return self[MenusSectionMenuItemsKey];
}

@end

@interface MenusViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSDictionary <NSString *, NSMutableArray *> *sections;
@property (nonatomic, strong) Blog *blog;
@property (nonatomic, strong) MenusService *menusService;
@property (nonatomic, strong) MenuLocation *selectedMenuLocation;
@property (nonatomic, strong) MenusItemsHeaderView *itemsHeaderView;
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
    [self setupTableSections];
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

- (void)setupTableSections
{
    self.sections = @{MenusSectionLocationsKey: [NSMutableArray arrayWithCapacity:2], MenusSectionMenusKey: [NSMutableArray arrayWithCapacity:5], MenusSectionMenuItemsKey: [NSMutableArray arrayWithCapacity:5]};
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
    // the selected location defaults to the first locaiton in the ordered set
    self.selectedMenuLocation = [self.blog.menuLocations firstObject];
    if(!self.selectedMenuLocation.menu) {
        self.selectedMenuLocation.menu = [self.blog.menus firstObject];
    }
    
    [self updateMenuItems];
    [self.tableView reloadData];
}

- (void)toggleAvailableLocations
{
    NSMutableArray *locations = [self.sections menuLocations];
    if(locations.count) {
        [self hideAvailableLocations];
    }else {
        [self showAvailableLocations];
    }
}

- (void)showAvailableLocations
{
    NSMutableArray *locations = [self.sections menuLocations];
    [locations removeAllObjects];
    
    // show the available locations, without the currently selected location
    [locations addObjectsFromArray:self.blog.menuLocations.array];
    [locations removeObject:self.selectedMenuLocation];
    
    [self.tableView reloadData];
}

- (void)hideAvailableLocations
{
    [[self.sections menuLocations] removeAllObjects];
    [self.tableView reloadData];
}

- (void)toggleAvailableMenus
{
    NSMutableArray *menus = [self.sections menus];
    if(menus.count) {
        [self hideAvailableMenus];
    }else {
        [self hideAvailableLocations];
        [self showAvailableMenus];
    }
}

- (void)showAvailableMenus
{
    NSMutableArray *menus = [self.sections menus];
    [menus removeAllObjects];
    // show the available menus, without the currently selected menu
    [menus addObjectsFromArray:self.blog.menus.array];
    if(self.selectedMenuLocation.menu) {
        [menus removeObject:self.selectedMenuLocation.menu];
    }
    [self.tableView reloadData];
}

- (void)hideAvailableMenus
{
    [[self.sections menus] removeAllObjects];
    [self.tableView reloadData];
}

- (void)selectedLocationWithIndexPath:(NSIndexPath *)indexPath
{
    MenuLocation *location = [[self.sections menuLocations] objectAtIndex:indexPath.row];
    self.selectedMenuLocation = location;
    [self hideAvailableLocations];
        
    if(location.menu) {
        [self hideAvailableMenus];
    }else {
        [self showAvailableMenus];
    }
    
    [self updateMenuItems];
}

- (void)selectedMenuWithIndexPath:(NSIndexPath *)indexPath
{
    self.selectedMenuLocation.menu = [[self.sections menus] objectAtIndex:indexPath.row];
    [self updateMenuItems];
    [self toggleAvailableMenus];
}

- (void)updateMenuItems
{
    NSMutableArray *items = [self.sections menuItems];
    [items removeAllObjects];
    
    if(self.selectedMenuLocation.menu.items.count) {
        [items addObjectsFromArray:[self.selectedMenuLocation.menu.items array]];
    }
    
    [self.tableView reloadData];
}

#pragma - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger count = 0;
    BOOL done;
    while (!done) {
        switch (count) {
            case MenusSectionSelectedLocation:
            case MenusSectionAvailableLocations:
            case MenusSectionSelectedMenu:
            case MenusSectionAvailableMenus:
            case MenusSectionMenuItems:
                count++;
                break;
            default:
                done = YES;
                break;
        }
    }
    
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    switch (section) {
        case MenusSectionSelectedLocation:
            count = 1;
            break;
        case MenusSectionAvailableLocations:
            count = [self.sections menuLocations].count;
            break;
        case MenusSectionSelectedMenu:
            count = self.selectedMenuLocation.menu ? 1 : 0;
            break;
        case MenusSectionAvailableMenus:
            count = [self.sections menus].count;
            break;
        case MenusSectionMenuItems:
            count = [self.sections menuItems].count;
            break;
    }
    
    return count;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section
{
    CGFloat height;
    
    switch (section) {
        case MenusSectionMenuItems:
            height = 100;
            break;
        default:
            height = 0;
            break;
    }
    
    return height;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view;
    
    switch (section) {
        case MenusSectionMenuItems:
        {
            if(!self.itemsHeaderView) {
                MenusItemsHeaderView *header = [MenusItemsHeaderView headerViewFromNib];
                self.itemsHeaderView = header;
            }
            self.itemsHeaderView.menu = self.selectedMenuLocation.menu;
            view = self.itemsHeaderView;
            break;
        }
        default:
            view = nil;
            break;
    }
    
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height;
    switch (indexPath.section) {
        case MenusSectionSelectedLocation:
        case MenusSectionSelectedMenu:
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
    switch (indexPath.section) {
        case MenusSectionSelectedLocation: {
            MenuLocation *location = self.selectedMenuLocation;
            height = [MenusSelectedLocationCell heightForTableView:tableView location:location];
            break;
        }
        case MenusSectionSelectedMenu: {
            Menu *menu = self.selectedMenuLocation.menu;
            height = [MenusSelectedMenuCell heightForTableView:tableView menu:menu];
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
    switch (indexPath.section) {
        case MenusSectionSelectedLocation:
        {
            MenuLocation *location = self.selectedMenuLocation;
            MenusSelectedLocationCell *locationCell = (MenusSelectedLocationCell *)cell;
            locationCell.location = location;
            cell.accessoryType = UITableViewCellAccessoryNone;
            if(location == self.selectedMenuLocation) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            break;
        }
        case MenusSectionAvailableLocations:
        {
            MenuLocation *location = [[self.sections menuLocations] objectAtIndex:indexPath.row];
            
            NSDictionary *attributes =  @{NSFontAttributeName: [WPStyleGuide regularTextFont], NSForegroundColorAttributeName: [WPStyleGuide darkGrey]};
            NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:location.details attributes:attributes];
            cell.textLabel.attributedText = attributedText;
            break;
        }
        case MenusSectionSelectedMenu:
        {
            Menu *menu = self.selectedMenuLocation.menu;
            MenusSelectedMenuCell *menuCell = (MenusSelectedMenuCell *)cell;
            menuCell.menu = menu;
            cell.accessoryType = UITableViewCellAccessoryNone;
            if(menu == self.selectedMenuLocation.menu) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            break;
        }
        case MenusSectionAvailableMenus:
        {
            Menu *menu = [[self.sections menus] objectAtIndex:indexPath.row];
        
            NSDictionary *attributes =  @{NSFontAttributeName: [WPStyleGuide regularTextFont], NSForegroundColorAttributeName: [WPStyleGuide darkGrey]};
            NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:menu.name attributes:attributes];
            cell.textLabel.attributedText = attributedText;
            break;
        }
        case MenusSectionMenuItems:
        {
            MenuItem *item = [[self.sections menuItems] objectAtIndex:indexPath.row];
            
            NSDictionary *attributes =  @{NSFontAttributeName: [WPStyleGuide regularTextFont], NSForegroundColorAttributeName: [WPStyleGuide darkGrey]};
            NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:item.name attributes:attributes];
            cell.textLabel.attributedText = attributedText;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }
        default:
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseIdentifier = nil;
    switch (indexPath.section) {
        case MenusSectionSelectedLocation:
            reuseIdentifier = @"selected_location_cell";
            break;
        case MenusSectionAvailableLocations:
            reuseIdentifier = @"locations_cell";
            break;
        case MenusSectionSelectedMenu:
            reuseIdentifier = @"selected_menu_cell";
            break;
        case MenusSectionAvailableMenus:
            reuseIdentifier = @"menus_cell";
            break;
        case MenusSectionMenuItems:
            reuseIdentifier = @"items_cell";
            break;
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if(!cell) {
        switch (indexPath.section) {
            case MenusSectionSelectedLocation:
                cell = [[MenusSelectedLocationCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
                break;
            case MenusSectionAvailableLocations:
                cell = [[MenusCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
                break;
            case MenusSectionSelectedMenu:
                cell = [[MenusSelectedMenuCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
                break;
            case MenusSectionAvailableMenus:
                cell = [[MenusCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
                break;
            case MenusSectionMenuItems:
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
    switch (indexPath.section) {
        case MenusSectionSelectedLocation:
            [self toggleAvailableLocations];
            break;
        case MenusSectionAvailableLocations:
            [self selectedLocationWithIndexPath:indexPath];
            break;
        case MenusSectionSelectedMenu:
            [self toggleAvailableMenus];
            break;
        case MenusSectionAvailableMenus:
            [self selectedMenuWithIndexPath:indexPath];
            break;
        default:
            break;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Table helpers

@end
