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

@interface MenusViewController () <UIScrollViewDelegate, MenusHeaderViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIStackView *contentStackView;
@property (weak, nonatomic) IBOutlet MenusHeaderView *headerView;
@property (weak, nonatomic) IBOutlet MenuDetailsView *detailsView;
@property (nonatomic, strong) Blog *blog;
@property (nonatomic, strong) MenusService *menusService;
@property (nonatomic, strong) UIActivityIndicatorView *activity;

@end

@implementation MenusViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

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
    
    self.headerView.delegate = self;
    
    UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activity.hidesWhenStopped = YES;
    [self.view addSubview:activity];
    self.activity = activity;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrameNotification:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
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

#pragma mark - MenusHeaderViewDelegate

- (void)headerViewSelectionChangedWithSelectedLocation:(MenuLocation *)location
{
    if(location.menu) {
        self.detailsView.menu = location.menu;
    }else {
        self.detailsView.menu = [self.blog.menus firstObject];
    }
}

- (void)headerViewSelectionChangedWithSelectedMenu:(Menu *)menu
{
    self.detailsView.menu = menu;
}

#pragma mark - notifications

- (void)keyboardWillChangeFrameNotification:(NSNotification *)notification
{
    CGRect frame = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    frame = [self.view.window convertRect:frame toView:self.view];
    
    CGFloat insetPadding = 10.0;
    UIEdgeInsets inset = self.scrollView.contentInset;
    UIEdgeInsets scrollInset = self.scrollView.scrollIndicatorInsets;

    if(frame.origin.y > self.view.frame.size.height) {
        inset.bottom = 0.0;
    }else {
        inset.bottom = self.view.frame.size.height - frame.origin.y;
        scrollInset.bottom = inset.bottom;
        inset.bottom += insetPadding;
    }
    self.scrollView.contentInset = inset;
    self.scrollView.scrollIndicatorInsets = scrollInset;
}

@end
