#import "MenusViewController.h"
#import "Blog.h"
#import "MenusService.h"
#import "Menu.h"
#import "MenuLocation.h"
#import "MenuItem.h"
#import "WPStyleGuide.h"
#import "MenusHeaderView.h"
#import "MenuDetailsView.h"

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

@interface MenusViewController () <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIStackView *contentStackView;
@property (weak, nonatomic) IBOutlet MenusHeaderView *headerView;
@property (weak, nonatomic) IBOutlet MenuDetailsView *detailsView;
@property (nonatomic, strong) Blog *blog;
@property (nonatomic, strong) MenusService *menusService;
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
    
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.backgroundColor = [WPStyleGuide greyLighten30];
    
    UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activity.hidesWhenStopped = YES;
    [self.view addSubview:activity];
    self.activity = activity;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.navigationItem.title = NSLocalizedString(@"Menus", @"Title for screen that allows configuration of your site's menus");
    
    [self updateScrollViewContentSize];
    [self syncWithBlogMenus];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.activity.center = self.scrollView.center;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

#pragma mark - Views setup

- (void)updateScrollViewContentSize
{
    self.scrollView.contentSize = CGSizeMake(self.contentStackView.frame.size.width, self.contentStackView.frame.size.height);
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
    [self.headerView updateWithMenusForBlog:self.blog];
    self.detailsView.menu = [self.blog.menus firstObject];
}

#pragma mark - UIScrollView

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    
}

@end
