#import "MenusViewController.h"
#import "Blog.h"
#import "MenusService.h"
#import "Menu.h"
#import "MenuLocation.h"
#import "MenuItem.h"
#import "WPStyleGuide.h"
#import "MenusHeaderView.h"
#import "MenuDetailsView.h"
#import "MenuItemsStackView.h"
#import "MenuItemEditingViewController.h"

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

@interface MenusViewController () <UIScrollViewDelegate, MenusHeaderViewDelegate, MenuDetailsViewDelegate, MenuItemsStackViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIStackView *stackView;
@property (weak, nonatomic) IBOutlet MenusHeaderView *headerView;
@property (weak, nonatomic) IBOutlet MenuDetailsView *detailsView;
@property (weak, nonatomic) IBOutlet MenuItemsStackView *itemsView;

@property (nonatomic, strong) Blog *blog;
@property (nonatomic, strong) MenusService *menusService;
@property (nonatomic, strong) MenuLocation *selectedMenuLocation;
@property (nonatomic, assign) BOOL observesKeyboardChanges;

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
    if (self) {
        
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
    self.view.backgroundColor = [WPStyleGuide lightGrey];
    self.scrollView.backgroundColor = self.view.backgroundColor;
    self.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    self.scrollView.alpha = 0.0;
    
    // add a bit of padding to the scrollable content
    self.stackView.layoutMargins = UIEdgeInsetsMake(0, 0, 10, 0);
    self.stackView.layoutMarginsRelativeArrangement = YES;
    
    self.headerView.delegate = self;
    self.detailsView.delegate = self;
    self.itemsView.delegate = self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.navigationItem.title = NSLocalizedString(@"Menus", @"Title for screen that allows configuration of your site's menus");
    
    [self syncWithBlogMenus];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    [self updateScrollViewContentSize];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHideNotification:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShowNotification:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrameNotification:) name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Views setup

- (void)updateScrollViewContentSize
{
    self.scrollView.contentSize = CGSizeMake(self.stackView.frame.size.width, self.stackView.frame.size.height);
}

#pragma mark - local updates

- (void)syncWithBlogMenus
{
    [self.menusService syncMenusForBlog:self.blog
                                success:^{
                                    [self didSyncBlog];
                                }
                                failure:^(NSError *error) {
                                    DDLogDebug(@"MenusViewController could not sync menus for blog");
                                    [self.navigationController popViewControllerAnimated:YES];
                                }];
}

- (void)didSyncBlog
{
    MenuLocation *selectedLocation = [self.blog.menuLocations firstObject];
    Menu *selectedMenu = selectedLocation.menu;
    self.selectedMenuLocation = selectedLocation;
    
    [self.headerView setupWithMenusForBlog:self.blog];
    [self.headerView setSelectedLocation:selectedLocation];
    [self.headerView setSelectedMenu:selectedMenu];
    
    [self setViewsWithMenu:selectedMenu];
    [UIView animateWithDuration:0.20 animations:^{
        self.scrollView.alpha = 1.0;
    }];
}

- (void)setViewsWithMenu:(Menu *)menu
{
    self.detailsView.menu = menu;
    self.itemsView.menu = menu;
}

#pragma mark - MenusHeaderViewDelegate

- (void)headerView:(MenusHeaderView *)headerView selectedLocation:(MenuLocation *)location
{
    [self.headerView setSelectedMenu:location.menu];
    [self setViewsWithMenu:location.menu];
}

- (void)headerView:(MenusHeaderView *)headerView selectedMenu:(Menu *)menu
{
    self.selectedMenuLocation.menu = menu;
    [self setViewsWithMenu:menu];
}

- (void)headerViewSelectedForCreatingNewMenu:(MenusHeaderView *)headerView
{
    Menu *newMenu = [Menu newMenu:self.blog.managedObjectContext];
    newMenu.blog = self.blog;
    newMenu.name = [Menu generateIncrementalNameFromMenus:self.blog.menus];
    self.selectedMenuLocation.menu = newMenu;
    
    [self.headerView addMenu:newMenu];
    [self.headerView setSelectedMenu:newMenu];
    [self setViewsWithMenu:newMenu];
}

#pragma mark - MenuDetailsViewDelegate

- (void)detailsViewUpdatedMenuName:(MenuDetailsView *)menuDetailView
{
    [self.headerView refreshMenuViewsUsingMenu:menuDetailView.menu];
}

- (void)detailsViewSelectedToSaveMenu:(MenuDetailsView *)menuDetailView
{
    // Save the menu via MenusService
}

- (void)detailsViewSelectedToDeleteMenu:(MenuDetailsView *)menuDetailView
{
    void(^deleteMenu)() = ^() {
        Menu *currentMenu = self.selectedMenuLocation.menu;
        self.selectedMenuLocation.menu = [Menu defaultMenuForBlog:self.blog];
        [self.headerView setSelectedMenu:self.selectedMenuLocation.menu];
        [self setViewsWithMenu:self.selectedMenuLocation.menu];
        [self.headerView removeMenu:currentMenu];
    };
    
    NSString *alertTitle = NSLocalizedString(@"Are you sure you want to delete the menu?", @"Menus confirmation text for confirming if a user wants to delete a menu.");
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:alertTitle
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    NSString *confirmTitle = NSLocalizedString(@"Delete Menu", @"Menus confirmation button for deleting a menu.");
    NSString *cancelTitle = NSLocalizedString(@"Cancel", @"Menus cancel button for deleting a menu.");
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:confirmTitle
                                                          style:UIAlertActionStyleDestructive
                                                        handler:^(UIAlertAction * _Nonnull action) {
                                                            deleteMenu();
                                                        }];
    [alertController addAction:confirmAction];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelTitle
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - MenuItemsStackViewDelegate

- (MenuItemEditingViewController *)editingControllerWithItem:(MenuItem *)item
{
    MenuItemEditingViewController *controller = [[MenuItemEditingViewController alloc] initWithItem:item blog:self.blog];
    void(^dismiss)() = ^() {
        [self dismissViewControllerAnimated:YES completion:nil];
    };
    controller.onSelectedToSave = ^() {
        [self.itemsView refreshViewWithItem:item focus:YES];
        dismiss();
    };
    controller.onSelectedToTrash = ^() {
        [self.itemsView removeItem:item];
        dismiss();
    };
    controller.onSelectedToCancel = dismiss;
    return controller;
}

- (void)itemsView:(MenuItemsStackView *)itemsView createdNewItemForEditing:(MenuItem *)item
{
    MenuItemEditingViewController *controller = [self editingControllerWithItem:item];
    controller.onSelectedToCancel = controller.onSelectedToTrash;
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)itemsView:(MenuItemsStackView *)itemsView selectedItemForEditing:(MenuItem *)item
{
    MenuItemEditingViewController *controller = [self editingControllerWithItem:item];
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)itemsView:(MenuItemsStackView *)itemsView requiresScrollingToCenterView:(UIView *)viewForScrolling
{
    CGRect visibleRect = [self.scrollView convertRect:viewForScrolling.frame fromView:viewForScrolling.superview];
    visibleRect.origin.y -= (self.scrollView.frame.size.height - visibleRect.size.height) / 2.0;
    visibleRect.size.height = self.scrollView.frame.size.height;
    [self.scrollView scrollRectToVisible:visibleRect animated:YES];
}

- (void)itemsView:(MenuItemsStackView *)itemsView prefersScrollingEnabled:(BOOL)enabled
{
    self.scrollView.scrollEnabled = enabled;
}

- (void)itemsView:(MenuItemsStackView *)itemsView prefersAdjustingScrollingOffsetForAnimatingView:(UIView *)view
{
    // adjust the scrollView offset to ensure this view is easily viewable
    const CGFloat padding = 10.0;
    CGRect viewRectWithinScrollViewWindow = [self.scrollView.window convertRect:view.frame fromView:view.superview];
    CGRect visibleContentRect = [self.scrollView.window convertRect:self.scrollView.frame fromView:self.view];
    
    CGPoint offset = self.scrollView.contentOffset;
    
    visibleContentRect.origin.y += offset.y;
    viewRectWithinScrollViewWindow.origin.y += offset.y;
    
    BOOL updated = NO;
    
    if (viewRectWithinScrollViewWindow.origin.y < visibleContentRect.origin.y + padding) {
        
        offset.y -= viewRectWithinScrollViewWindow.size.height;
        updated = YES;
        
    } else  if (viewRectWithinScrollViewWindow.origin.y + viewRectWithinScrollViewWindow.size.height > (visibleContentRect.origin.y + visibleContentRect.size.height) - padding) {
        offset.y += viewRectWithinScrollViewWindow.size.height;
        updated = YES;
    }
    
    if (updated) {
        [UIView animateWithDuration:0.25 animations:^{
            self.scrollView.contentOffset = offset;
        }];
    }
}

- (void)itemsViewAnimatingContentSizeChanges:(MenuItemsStackView *)itemsView focusedRect:(CGRect)focusedRect updatedFocusRect:(CGRect)updatedFocusRect
{
    CGPoint offset = self.scrollView.contentOffset;
    offset.y += updatedFocusRect.origin.y - focusedRect.origin.y;
    self.scrollView.contentOffset = offset;
}

#pragma mark - notifications

- (void)updateWithKeyboardNotification:(NSNotification *)notification
{
    CGRect frame = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    frame = [self.view.window convertRect:frame toView:self.view];
    
    CGFloat insetPadding = 10.0;
    UIEdgeInsets inset = self.scrollView.contentInset;
    UIEdgeInsets scrollInset = self.scrollView.scrollIndicatorInsets;
    
    if (frame.origin.y > self.view.frame.size.height) {
        inset.bottom = 0.0;
        scrollInset.bottom = 0.0;
    } else  {
        inset.bottom = self.view.frame.size.height - frame.origin.y;
        scrollInset.bottom = inset.bottom;
        inset.bottom += insetPadding;
    }
    self.scrollView.contentInset = inset;
    self.scrollView.scrollIndicatorInsets = scrollInset;
}

- (void)keyboardWillHideNotification:(NSNotification *)notification
{
    self.observesKeyboardChanges = NO;
    
    UIEdgeInsets inset = self.scrollView.contentInset;
    UIEdgeInsets scrollInset = self.scrollView.scrollIndicatorInsets;
    inset.bottom = 0;
    scrollInset.bottom = 0;
    self.scrollView.contentInset = inset;
    self.scrollView.scrollIndicatorInsets = scrollInset;
}

- (void)keyboardWillShowNotification:(NSNotification *)notification
{
    self.observesKeyboardChanges = YES;
    [self updateWithKeyboardNotification:notification];
}

- (void)keyboardWillChangeFrameNotification:(NSNotification *)notification
{
    if (self.observesKeyboardChanges) {
        [self updateWithKeyboardNotification:notification];
    }
}

@end
