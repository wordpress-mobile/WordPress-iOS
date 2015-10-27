#import "MenusViewController.h"
#import "Blog.h"
#import "MenusService.h"
#import "Menu.h"
#import "MenuLocation.h"
#import "MenuItem.h"
#import "WPStyleGuide.h"
#import "MenusSelectionCell.h"

typedef NS_ENUM(NSInteger) {
    MenusSectionSelection = 0,
    MenusSectionMenuItems
    
}MenusSection;

static NSString * const MenusSectionMenuItemsKey = @"menu_items";

@implementation NSDictionary (Menus)

- (NSMutableArray *)menuItems
{
    return self[MenusSectionMenuItemsKey];
}

@end

@interface MenusViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSDictionary <NSString *, NSMutableArray *> *sections;
@property (nonatomic, strong) Blog *blog;
@property (nonatomic, strong) MenusService *menusService;
@property (nonatomic, strong) MenuLocation *selectedMenuLocation;
@property (nonatomic, strong) UIActivityIndicatorView *activity;

@end

@implementation MenusViewController

- (id)initWithBlog:(Blog *)blog
{
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil];
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
    
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.separatorInset = UIEdgeInsetsZero;
    self.tableView.layoutMargins = UIEdgeInsetsZero;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.estimatedRowHeight = self.tableView.rowHeight;
    
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    
    NSString *selectionCellClassStr = NSStringFromClass([MenusSelectionCell class]);
    [self.tableView registerNib:[UINib nibWithNibName:selectionCellClassStr bundle:nil] forCellReuseIdentifier:selectionCellClassStr];
    
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

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    
    [UIView animateWithDuration:0.1 animations:^{
        
        self.tableView.alpha = 0.0;
        
    } completion:nil];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
       
        [self.tableView reloadData];
        [UIView animateWithDuration:0.3 animations:^{
            
            self.tableView.alpha = 1.0;
            
        } completion:nil];
    }];
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
    self.sections = @{MenusSectionMenuItemsKey: [NSMutableArray arrayWithCapacity:5]};
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
            case MenusSectionSelection:
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
        case MenusSectionSelection:
            count = 1;
            break;
        case MenusSectionMenuItems:
            count = [self.sections menuItems].count;
            break;
    }
    
    return count;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height;
    switch (indexPath.section) {
        case MenusSectionSelection:
        {
            if([self.traitCollection containsTraitsInCollection:[UITraitCollection traitCollectionWithVerticalSizeClass:UIUserInterfaceSizeClassRegular]]) {
                height = 260;
            }else {
                height = 90;
            }
            break;
        }
        default:
            height = tableView.estimatedRowHeight;
            break;
    }
    
    return height;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case MenusSectionSelection:
        {
            // update selection cell
            MenusSelectionCell *selectionCell = (MenusSelectionCell*)cell;
            selectionCell.tableView = tableView;
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
        case MenusSectionSelection:
            reuseIdentifier = NSStringFromClass([MenusSelectionCell class]);
            break;
        case MenusSectionMenuItems:
            reuseIdentifier = @"items_cell";
            break;
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if(!cell) {
        switch (indexPath.section) {
            default:
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
                break;
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Table helpers

@end
