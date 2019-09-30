#import "MenusViewController.h"
#import "Blog.h"
#import "MenusService.h"
#import "Menu.h"
#import "MenuLocation.h"
#import "MenuItem.h"
#import "MenuHeaderViewController.h"
#import "MenuDetailsViewController.h"
#import "MenuItemsViewController.h"
#import "MenuItemEditingViewController.h"
#import "Menu+ViewDesign.h"
#import "ContextManager.h"
#import "WPAppAnalytics.h"
#import "WordPress-Swift.h"
#import <WordPressShared/WPFontManager.h>
#import <WordPressShared/WPStyleGuide.h>
#import <WordPressUI/WordPressUI.h>



static CGFloat const ScrollViewOffsetAdjustmentPadding = 10.0;

@interface MenusViewController () <UIScrollViewDelegate, MenuHeaderViewControllerDelegate, MenuDetailsViewControllerDelegate, MenuItemsViewControllerDelegate>

@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) IBOutlet UIStackView *stackView;

@property (nonatomic, weak, readonly) MenuHeaderViewController *headerViewController;
@property (nonatomic, weak, readonly) MenuDetailsViewController *detailsViewController;
@property (nonatomic, weak, readonly) MenuItemsViewController *itemsViewController;

@property (nonatomic, strong, readonly) NoResultsViewController *noResultsViewController;
@property (nonatomic, strong, readonly) UILabel *itemsLoadingLabel;
@property (nonatomic, strong, readonly) UIBarButtonItem *saveButtonItem;

@property (nonatomic, strong, readonly) Blog *blog;
@property (nonatomic, strong, readonly) MenusService *menusService;

@property (nonatomic, strong) MenuLocation *selectedMenuLocation;
@property (nonatomic, strong) Menu *updatedMenuForSaving;

@property (nonatomic, assign) BOOL observesKeyboardChanges;
@property (nonatomic, assign) BOOL animatesAppearanceAfterSync;
@property (nonatomic, assign) BOOL hasMadeSignificantMenuChanges;
@property (nonatomic, assign) BOOL needsSave;
@property (nonatomic, assign) BOOL isSaving;

@end

@implementation MenusViewController

+ (MenusViewController *)controllerWithBlog:(Blog *)blog
{
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Menus" bundle:nil];
    MenusViewController *controller = [storyboard instantiateInitialViewController];
    [controller setupWithBlog:blog];
    return controller;
}

- (void)setupWithBlog:(Blog *)blog
{
    // using a new child context to keep local changes discardable
    // using main queue as we still want processing done on the main thread
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    context.parentContext = blog.managedObjectContext;
    context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;

    // set local blog from local context
    _blog = [context objectWithID:blog.objectID];

    // set up the undomanager
    context.undoManager = [[NSUndoManager alloc] init];

    MenusService *service = [[MenusService alloc] initWithManagedObjectContext:context];
    _menusService = service;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = NSLocalizedString(@"Menus", @"Title for screen that allows configuration of your site's menus");
    self.view.backgroundColor = [UIColor murielListBackground];

    self.scrollView.backgroundColor = self.view.backgroundColor;
    self.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    self.scrollView.alpha = 0.0;

    // add a bit of padding to the scrollable content
    self.stackView.layoutMargins = UIEdgeInsetsMake(0, 0, 10, 0);
    self.stackView.layoutMarginsRelativeArrangement = YES;

    self.headerViewController.delegate = self;
    self.detailsViewController.delegate = self;
    self.itemsViewController.delegate = self;

    [self setupSaveButtonItem];
    [self setupNoResultsView];
    [self setupItemsLoadingLabel];

    [self syncWithBlogMenus];
}

- (void)setupSaveButtonItem
{
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save", @"Menus save button title") style:UIBarButtonItemStylePlain target:self action:@selector(saveBarButtonItemPressed:)];
    self.navigationItem.rightBarButtonItem = button;
    button.enabled = NO;
    _saveButtonItem = button;
}

- (void)setupNoResultsView
{
    _noResultsViewController = [NoResultsViewController controller];
}

- (void)setupItemsLoadingLabel
{
    UILabel *label = [[UILabel alloc] init];
    label.font = [WPFontManager systemLightFontOfSize:14];
    label.textColor = [UIColor murielText];
    label.numberOfLines = 0;
    [self.stackView addArrangedSubview:label];
    [label.leadingAnchor constraintEqualToAnchor:self.stackView.leadingAnchor constant:MenusDesignDefaultContentSpacing].active = YES;
    [label.trailingAnchor constraintEqualToAnchor:self.stackView.trailingAnchor constant:-MenusDesignDefaultContentSpacing].active = YES;
    label.hidden = YES;
    _itemsLoadingLabel = label;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [super prepareForSegue:segue sender:sender];

    if ([segue.destinationViewController isKindOfClass:[MenuHeaderViewController class]]) {
        _headerViewController = segue.destinationViewController;
    } else if ([segue.destinationViewController isKindOfClass:[MenuItemsViewController class]]) {
        _itemsViewController = segue.destinationViewController;
    } else if ([segue.destinationViewController isKindOfClass:[MenuDetailsViewController class]]) {
        _detailsViewController = segue.destinationViewController;
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    [self updateScrollViewContentSize];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.animatesAppearanceAfterSync = YES;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHideNotification:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShowNotification:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrameNotification:) name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    self.animatesAppearanceAfterSync = NO;
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

#pragma mark - Setters

- (void)setSelectedMenuLocation:(MenuLocation *)selectedMenuLocation
{
    if (_selectedMenuLocation != selectedMenuLocation) {
        _selectedMenuLocation = selectedMenuLocation;

        // Update the default menu option.
        Menu *defaultMenu = [Menu defaultMenuForBlog:self.blog];
        if ([self defaultMenuEnabledForSelectedLocation]) {
            // Is primary menu location, allow the option of the default generated Menu.
            defaultMenu.name = [Menu defaultMenuName];
        } else {
            // Default menu is a "No Menu" nullable option when not using the primary location.
            defaultMenu.name = NSLocalizedString(@"No Menu", @"Menus selection title for setting a location to not use a menu.");
        }
        [self.headerViewController refreshMenuViewsUsingMenu:defaultMenu];

        [self.headerViewController setSelectedLocation:selectedMenuLocation];
        [self.headerViewController setSelectedMenu:selectedMenuLocation.menu];
        [self setViewsWithMenu:selectedMenuLocation.menu];
    }
}

- (void)setSelectedMenu:(Menu *)menu
{
    if (menu == self.selectedMenuLocation.menu) {
        /* Ignore, already selected this menu at this point.
         * Note: we may arrive at this condition after a discard has occurred for
         * a previously selected menu that was unsaved.
         */
        return;
    }
    Menu *defaultMenu = [Menu defaultMenuForBlog:self.blog];
    if (menu == defaultMenu) {
        /*
         * Special case for the user selecting "Default Menu" or "No Menu" in which we need
         * to save the previously selected menu to save it without a location.
         */
        [self setNeedsSave:YES forMenu:self.selectedMenuLocation.menu significantChanges:NO];
    } else {
        [self setNeedsSave:YES forMenu:menu significantChanges:NO];
    }
    self.selectedMenuLocation.menu = menu;
    [self.headerViewController setSelectedMenu:menu];
    [self setViewsWithMenu:menu];
}

#pragma mark - Local updates

- (void)syncWithBlogMenus
{
    [self showNoResultsWithTitle:[self noResultsLoadingTitle]];

    [self.menusService syncMenusForBlog:self.blog
                                success:^{
                                    [self didSyncBlog];
                                }
                                failure:^(NSError *error) {
                                    DDLogDebug(@"MenusViewController could not sync menus for blog");
                                    [self showNoResultsWithTitle:[self noResultsErrorTitle]];
                                }];
}

- (void)didSyncBlog
{
    if (!self.blog.menuLocations.count) {
        [self showNoResultsWithTitle:[self noResultsNoMenusTitle]];
        return;
    }

    [self.noResultsViewController removeFromView];

    self.headerViewController.blog = self.blog;
    MenuLocation *selectedLocation = [self.blog.menuLocations firstObject];
    self.selectedMenuLocation = selectedLocation;

    if (!self.animatesAppearanceAfterSync) {
        self.scrollView.alpha = 1.0;
    } else {
        [UIView animateWithDuration:0.20 animations:^{
            self.scrollView.alpha = 1.0;
        } completion:^(BOOL finished) {
        }];
    }
}

- (void)reloadMenusViews
{
    self.headerViewController.blog = nil;
    self.headerViewController.blog = self.blog;
    [self.headerViewController setSelectedMenu:self.selectedMenuLocation.menu];
    [self setViewsWithMenu:nil];
    [self setViewsWithMenu:self.selectedMenuLocation.menu];
}

- (void)createMenu
{
    [WPAppAnalytics track:WPAnalyticsStatMenusCreatedMenu withBlog:self.blog];

    Menu *newMenu = [Menu newMenu:self.blog.managedObjectContext];
    newMenu.blog = self.blog;
    newMenu.name = [self generateIncrementalMenuName];
    self.selectedMenuLocation.menu = newMenu;

    [self.headerViewController addMenu:newMenu];
    [self.headerViewController setSelectedMenu:newMenu];
    [self setViewsWithMenu:newMenu];

    [self setNeedsSave:YES forMenu:newMenu significantChanges:YES];
}

- (void)deleteMenu:(Menu *)menu
{
    [WPAppAnalytics track:WPAnalyticsStatMenusDeletedMenu withBlog:self.blog];

    __weak __typeof(self) weakSelf = self;

    Menu *defaultMenu =[Menu defaultMenuForBlog:self.blog];
    self.selectedMenuLocation.menu = defaultMenu;
    [self.headerViewController setSelectedMenu:defaultMenu];
    [self setViewsWithMenu:defaultMenu];

    [self.headerViewController removeMenu:menu];

    [self.menusService deleteMenu:menu
                          forBlog:self.blog
                          success:^{
                              [weakSelf setNeedsSave:NO forMenu:nil significantChanges:NO];
                          }
                          failure:^(NSError *error) {
                              // Add the menu back to the list.
                              [weakSelf.headerViewController addMenu:menu];
                              // Present the error message.
                              NSString *errorTitle = NSLocalizedString(@"Error Deleting Menu", @"Menus error title for a menu that received an error while trying to delete it.");
                              [WPError showNetworkingAlertWithError:error title:errorTitle];
                          }];
}

- (void)loadDefaultMenuItemsIfNeeded
{
    Menu *menu = self.selectedMenuLocation.menu;
    if (menu.items.count == 0) {

        self.itemsLoadingLabel.text = NSLocalizedString(@"Loading menu...", @"Menus label text displayed when a menu is loading.");
        self.itemsLoadingLabel.hidden = NO;

        __weak __typeof__(self) weakSelf = self;
        __weak __typeof__(menu) weakMenu = menu;

        void(^successBlock)(NSArray<MenuItem *> *) = ^(NSArray<MenuItem *> *defaultItems) {
            weakSelf.itemsLoadingLabel.hidden = YES;

            BOOL menuEqualToSelectedMenu = weakSelf.selectedMenuLocation.menu == weakMenu;
            if (defaultItems.count) {
                NSOrderedSet *items = [NSOrderedSet orderedSetWithArray:defaultItems];
                weakMenu.items = items;
                if (menuEqualToSelectedMenu) {
                    weakSelf.itemsViewController.menu = nil;
                    weakSelf.itemsViewController.menu = weakMenu;
                }
            } else {
                if (menuEqualToSelectedMenu) {
                    [weakSelf insertBlankMenuItemIfNeeded];
                }
            }
        };
        void(^failureBlock)(NSError *) = ^(NSError *error) {
            weakSelf.itemsLoadingLabel.text = NSLocalizedString(@"An error occurred loading the menu, please check your internet connection.", @"Menus error message seen when an error occurred loading a specific menu.");
        };
        [self.menusService generateDefaultMenuItemsForBlog:self.blog
                                                   success:successBlock
                                                   failure:failureBlock];
    }
}

- (void)insertBlankMenuItemIfNeeded
{
    Menu *menu = self.selectedMenuLocation.menu;
    if (menu && !menu.items.count) {
        // Add a new empty item.
        MenuItem *item = [NSEntityDescription insertNewObjectForEntityForName:[MenuItem entityName] inManagedObjectContext:self.blog.managedObjectContext];
        item.name = [MenuItem defaultItemNameLocalized];
        item.type = MenuItemTypePage;
        item.menu = menu;

        [[ContextManager sharedInstance] saveContext:self.blog.managedObjectContext];

        self.itemsViewController.menu = nil;
        self.itemsViewController.menu = menu;
    }
}

- (void)setViewsWithMenu:(Menu *)menu
{
    self.detailsViewController.menu = menu;
    self.itemsViewController.menu = menu;

    self.itemsLoadingLabel.hidden = YES;
    if ([menu isDefaultMenu]) {
        if ([self defaultMenuEnabledForSelectedLocation]) {
            // Set up as the default menu of page items.
            [self loadDefaultMenuItemsIfNeeded];
        } else {
            // Set up as "No Menu" selected.
            menu.items = nil;
            self.itemsViewController.menu = nil;
            self.detailsViewController.menu = nil;
        }
    } else {
        [self insertBlankMenuItemIfNeeded];
    }
}

- (void)setNeedsSave:(BOOL)needsSave forMenu:(Menu *)menu significantChanges:(BOOL)significant
{
    // Update the saving/changes states.
    self.needsSave = needsSave;
    self.hasMadeSignificantMenuChanges = significant;
    self.updatedMenuForSaving = menu;
}

- (void)setNeedsSave:(BOOL)needsSave
{
    if (_needsSave != needsSave) {
        _needsSave = needsSave;

        self.saveButtonItem.enabled = needsSave;

        if (needsSave) {

            [self.blog.managedObjectContext.undoManager beginUndoGrouping];

            NSString *title = NSLocalizedString(@"Discard", @"Menus button title for canceling/discarding changes made.");
            UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStylePlain target:self action:@selector(discardChangesBarButtonItemPressed:)];
            [self.navigationItem setLeftBarButtonItem:button animated:YES];
            [self.navigationItem setHidesBackButton:YES animated:YES];

        } else {

            [self.blog.managedObjectContext.undoManager endUndoGrouping];

            [self.navigationItem setLeftBarButtonItem:nil animated:YES];
            [self.navigationItem setHidesBackButton:NO animated:YES];
        }
    }
}

- (void)setIsSaving:(BOOL)isSaving
{
    if (_isSaving != isSaving) {
        _isSaving = isSaving;
        if (isSaving) {
            UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Saving...", @"Menus save button title while it is saving a Menu.") style:UIBarButtonItemStylePlain target:nil action:nil];
            [self.navigationItem setRightBarButtonItem:button animated:YES];
        } else {
            [self.navigationItem setRightBarButtonItem:self.saveButtonItem animated:YES];
        }
        self.scrollView.userInteractionEnabled = !isSaving;
    }
}

- (void)discardAllChanges
{
    // Clear saving/changes states.
    [self setNeedsSave:NO forMenu:nil significantChanges:NO];

    // Trigger the undo.
    [self.blog.managedObjectContext.undoManager undo];
    [self reloadMenusViews];

    // Restore the top offset.
    CGPoint offset = self.scrollView.contentOffset;
    offset.y = 0;
    // Scroll to the top on the next run-loop so the layout finishes updating before scrolling.
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.scrollView setContentOffset:offset animated:YES];
    });
}

- (BOOL)defaultMenuEnabledForSelectedLocation
{
    return self.selectedMenuLocation == [self.blog.menuLocations firstObject];
}

- (NSString *)generateIncrementalMenuName
{
    NSInteger highestInteger = 0;
    for (Menu *menu in self.blog.menus) {
        if (!menu.name.length) {
            continue;
        }
        NSString *nameNumberStr;
        NSScanner *numberScanner = [NSScanner scannerWithString:menu.name];
        NSCharacterSet *characterSet = [NSCharacterSet decimalDigitCharacterSet];
        [numberScanner scanUpToCharactersFromSet:characterSet intoString:NULL];
        [numberScanner scanCharactersFromSet:characterSet intoString:&nameNumberStr];

        if ([nameNumberStr integerValue] > highestInteger) {
            highestInteger = [nameNumberStr integerValue];
        }
    }
    highestInteger = highestInteger + 1;
    NSString *menuStr = NSLocalizedString(@"Menu", @"The default text used for filling the name of a menu when creating it.");
    return [NSString stringWithFormat:@"%@ %i", menuStr, highestInteger];
}

- (MenuItemEditingViewController *)editingControllerWithItem:(MenuItem *)item
{
    MenuItemEditingViewController *controller = [MenuItemEditingViewController itemEditingViewControllerWithItem:item
                                                                                                            blog:self.blog];
    void(^dismiss)(void) = ^() {
        [self dismissViewControllerAnimated:YES completion:nil];
    };
    controller.onSelectedToSave = ^() {
        [WPAppAnalytics track:WPAnalyticsStatMenusEditedItem withBlog:self.blog];
        [self setNeedsSave:YES forMenu:self.selectedMenuLocation.menu significantChanges:YES];
        [self.itemsViewController refreshViewWithItem:item focus:YES];
        dismiss();
    };
    controller.onSelectedToTrash = ^() {
        [WPAppAnalytics track:WPAnalyticsStatMenusDeletedItem withBlog:self.blog];
        if (item.itemID.integerValue || [item.menu isDefaultMenu]) {
            // If the item had an ID, saving is enabled.
            // Or if the user trying to edit the default menu, saving is enabled.
            // Otherwise the item was never created remotely, so no need to save this deletion.
            [self setNeedsSave:YES forMenu:self.selectedMenuLocation.menu significantChanges:YES];
        }
        [self.itemsViewController removeItem:item];
        [self insertBlankMenuItemIfNeeded];
        dismiss();
    };
    controller.onSelectedToCancel = dismiss;
    return controller;
}

#pragma mark - No Results handling

- (void)showNoResultsWithTitle:(NSString *) title
{
    [self.noResultsViewController removeFromView];

    // If loading, show an animation.
    UIView *accessoryView = nil;
    if ([title isEqualToString:[self noResultsLoadingTitle]]) {
        accessoryView = [NoResultsViewController loadingAccessoryView];
    }

    [self.noResultsViewController configureWithTitle:title
                                   noConnectionTitle:nil
                                         buttonTitle:nil
                                            subtitle:nil
                                noConnectionSubtitle:nil
                                  attributedSubtitle:nil
                     attributedSubtitleConfiguration:nil
                                               image:nil
                                       subtitleImage:nil
                                       accessoryView:accessoryView];

    [self addChildViewController:self.noResultsViewController];
    [self.view addSubviewWithFadeAnimation:self.noResultsViewController.view];
    [self.noResultsViewController didMoveToParentViewController:self];
}

- (NSString *)noResultsLoadingTitle
{
    return NSLocalizedString(@"Loading Menus...", @"Menus label text displayed while menus are loading");
}

- (NSString *)noResultsErrorTitle
{
    return NSLocalizedString(@"An error occurred loading menus, please check your internet connection.", @"Menus text shown when an error occurred loading menus from the server.");
}

- (NSString *)noResultsNoMenusTitle
{
    return NSLocalizedString(@"No menus available", @"Menus text shown when no menus were available for loading the Menus editor.");
}

#pragma mark - Bar button items

- (void)discardChangesBarButtonItemPressed:(id)sender
{
    [WPAppAnalytics track:WPAnalyticsStatMenusDiscardedChanges withBlog:self.blog];
    [self promptForDiscardingChangesByTheLeftBarButtonItem:^{
        [self discardAllChanges];
    } cancellation:nil];
}

- (void)saveBarButtonItemPressed:(id)sender
{
    [WPAppAnalytics track:WPAnalyticsStatMenusSavedMenu withBlog:self.blog];

    [self.detailsViewController resignFirstResponder];

    // Buckle up, we gotta save this Menu!
    Menu *menuToSave = self.updatedMenuForSaving ?: self.selectedMenuLocation.menu;

    BOOL defaultMenuEnabled = [self defaultMenuEnabledForSelectedLocation];

    // Check if user is trying to save the Default Menu and made changes to it.
    if ([menuToSave isDefaultMenu] && defaultMenuEnabled && self.hasMadeSignificantMenuChanges) {

        // Create a new menu to use instead of the Default Menu.
        Menu *newMenu = [Menu newMenu:self.blog.managedObjectContext];
        newMenu.blog = self.blog;
        if ([menuToSave.name isEqualToString:[Menu defaultMenuName]]) {
            // Don't use "Default Menu" as the name of the menu.
            newMenu.name = [self generateIncrementalMenuName];
        } else {
            newMenu.name = menuToSave.name;
        }

        Menu *defaultMenu = menuToSave;
        // We'll save the newMenu instead.
        menuToSave = newMenu;
        // Use the items the user customized on the Default Menu as the items on the newMenu to save.
        menuToSave.items = defaultMenu.items;

        // Reset the Default Menu.
        defaultMenu.items = nil;
        defaultMenu.name = [Menu defaultMenuName];

        // Add and select the new Menu in the UI.
        self.selectedMenuLocation.menu = menuToSave;
        [self.headerViewController addMenu:menuToSave];
        [self.headerViewController setSelectedMenu:menuToSave];
        [self setViewsWithMenu:menuToSave];
    }

    self.isSaving = YES;

    __weak __typeof(self) weakSelf = self;
    [self.menusService createOrUpdateMenu:menuToSave
                                  forBlog:weakSelf.blog
                                  success:^() {
                                      // Refresh the items stack since the items may have changed.
                                      [weakSelf.itemsViewController reloadItems];
                                      weakSelf.isSaving = NO;
                                      [weakSelf setNeedsSave:NO forMenu:nil significantChanges:NO];
                                  }
                                  failure:^(NSError * _Nonnull error) {
                                      weakSelf.isSaving = NO;
                                      // Present the error message.
                                      NSString *errorTitle = NSLocalizedString(@"Error Saving Menu", @"Menus error title for a menu that received an error while trying to save a menu.");
                                      [WPError showNetworkingAlertWithError:error title:errorTitle];
                                  }];
}

#pragma mark - MenuHeaderViewControllerDelegate

- (void)headerViewController:(MenuHeaderViewController *)headerViewController selectedLocation:(MenuLocation *)location
{
    if (location == self.selectedMenuLocation) {
        // Ignore, already selected this location.
        return;
    }

    if (self.needsSave) {
        [self promptForDiscardingChangesBeforeSelectingADifferentLocation:^{
            [self discardAllChanges];
            self.selectedMenuLocation = location;
        } cancellation:nil];
    } else {
        self.selectedMenuLocation = location;
    }
}

- (void)headerViewController:(MenuHeaderViewController *)headerViewController selectedMenu:(Menu *)menu
{
    if (menu == self.selectedMenuLocation.menu) {
        // Ignore, already selected this menu.
        return;
    }

    if (self.needsSave && self.hasMadeSignificantMenuChanges) {

        [self promptForDiscardingChangesBeforeSelectingADifferentMenu:^{
            [self discardAllChanges];
            [self setSelectedMenu:menu];
        } cancellation:nil];

    } else {
        [self setSelectedMenu:menu];
    }
}

- (void)headerViewControllerSelectedForCreatingNewMenu:(MenuHeaderViewController *)headerView
{
    if (self.needsSave && self.hasMadeSignificantMenuChanges) {

        [self promptForDiscardingChangesBeforeCreatingNewMenu:^{
            [self discardAllChanges];
            [self createMenu];
        } cancellation:nil];

    } else {
        [self createMenu];
    }
}

#pragma mark - MenuDetailsViewControllerDelegate

- (void)detailsViewControllerUpdatedMenuName:(MenuDetailsViewController *)detailsViewController
{
    [self.headerViewController refreshMenuViewsUsingMenu:detailsViewController.menu];
    [self setNeedsSave:YES forMenu:detailsViewController.menu significantChanges:YES];
}

- (void)detailsViewControllerSelectedToDeleteMenu:(MenuDetailsViewController *)detailsViewController
{
    __weak __typeof(self) weakSelf = self;
    Menu *menuToDelete = detailsViewController.menu;

    NSString *alertTitle = NSLocalizedString(@"Are you sure you want to delete the menu?", @"Menus confirmation text for confirming if a user wants to delete a menu.");
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:alertTitle
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    NSString *confirmTitle = NSLocalizedString(@"Delete Menu", @"Menus confirmation button for deleting a menu.");
    NSString *cancelTitle = NSLocalizedString(@"Cancel", @"Menus cancel button for deleting a menu.");
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:confirmTitle
                                                            style:UIAlertActionStyleDestructive
                                                          handler:^(UIAlertAction * _Nonnull action) {
                                                              [weakSelf deleteMenu:menuToDelete];
                                                          }];
    [alertController addAction:confirmAction];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelTitle
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - MenuItemsViewControllerDelegate

- (void)itemsViewController:(MenuItemsViewController *)itemsViewController createdNewItemForEditing:(MenuItem *)item
{
    [WPAppAnalytics track:WPAnalyticsStatMenusCreatedItem withBlog:self.blog];
    MenuItemEditingViewController *controller = [self editingControllerWithItem:item];
    controller.onSelectedToCancel = controller.onSelectedToTrash;
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)itemsViewController:(MenuItemsViewController *)itemsViewController selectedItemForEditing:(MenuItem *)item
{
    [WPAppAnalytics track:WPAnalyticsStatMenusOpenedItemEditor withBlog:self.blog];
    MenuItemEditingViewController *controller = [self editingControllerWithItem:item];
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)itemsViewController:(MenuItemsViewController *)itemsViewController didUpdateMenuItemsOrdering:(Menu *)menu
{
    [WPAppAnalytics track:WPAnalyticsStatMenusOrderedItems withBlog:self.blog];
    [self setNeedsSave:YES forMenu:menu significantChanges:YES];
}

- (void)itemsViewController:(MenuItemsViewController *)itemsViewController requiresScrollingToCenterView:(UIView *)viewForScrolling
{
    CGRect visibleRect = [self.scrollView convertRect:viewForScrolling.frame fromView:viewForScrolling.superview];
    visibleRect.origin.y -= (self.scrollView.frame.size.height - visibleRect.size.height) / 2.0;
    visibleRect.size.height = self.scrollView.frame.size.height;
    [self.scrollView scrollRectToVisible:visibleRect animated:YES];
}

- (void)itemsViewController:(MenuItemsViewController *)itemsViewController prefersScrollingEnabled:(BOOL)enabled
{
    self.scrollView.scrollEnabled = enabled;
}

- (void)itemsViewController:(MenuItemsViewController *)itemsViewController prefersAdjustingScrollingOffsetForAnimatingView:(UIView *)view
{
    // adjust the scrollView offset to ensure this view is easily viewable
    CGRect viewRectWithinScrollViewWindow = [self.scrollView.window convertRect:view.frame fromView:view.superview];
    CGRect visibleContentRect = [self.scrollView.window convertRect:self.scrollView.frame fromView:self.view];

    CGPoint offset = self.scrollView.contentOffset;

    visibleContentRect.origin.y += offset.y;
    viewRectWithinScrollViewWindow.origin.y += offset.y;

    BOOL updated = NO;

    if (viewRectWithinScrollViewWindow.origin.y < visibleContentRect.origin.y + ScrollViewOffsetAdjustmentPadding) {

        offset.y -= viewRectWithinScrollViewWindow.size.height;
        updated = YES;

    } else  if (viewRectWithinScrollViewWindow.origin.y + viewRectWithinScrollViewWindow.size.height > (visibleContentRect.origin.y + visibleContentRect.size.height) - ScrollViewOffsetAdjustmentPadding) {
        offset.y += viewRectWithinScrollViewWindow.size.height;
        updated = YES;
    }

    if (updated) {
        [UIView animateWithDuration:0.25 animations:^{
            self.scrollView.contentOffset = offset;
        }];
    }
}

- (void)itemsViewAnimatingContentSizeChanges:(MenuItemsViewController *)itemsView focusedRect:(CGRect)focusedRect updatedFocusRect:(CGRect)updatedFocusRect
{
    CGPoint offset = self.scrollView.contentOffset;
    offset.y += updatedFocusRect.origin.y - focusedRect.origin.y;
    self.scrollView.contentOffset = offset;
}

#pragma mark - Alert Handlers

- (NSString *)discardChangesAlertTitle
{
    return NSLocalizedString(@"Unsaved Changes", @"Menus alert title for alerting the user to unsaved changes.");
}

- (void)promptForDiscardingChangesBeforeSelectingADifferentLocation:(void(^)(void))confirmationBlock
                                                       cancellation:(void(^)(void))cancellationBlock
{
    NSString *title = [self discardChangesAlertTitle];
    NSString *message = NSLocalizedString(@"Selecting a different menu location will discard changes you've made to the current menu. Are you sure you want to continue?", @"Menus alert message for alerting the user to unsaved changes while trying to select a different menu location.");
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];

    NSString *confirmationTitle = NSLocalizedString(@"Discard and Select Location", @"Menus alert button title to continue selecting a menu location and discarding current changes.");
    [alert addDestructiveActionWithTitle:confirmationTitle
                                 handler:^(UIAlertAction * _Nonnull action) {
                                     if (confirmationBlock) {
                                         confirmationBlock();
                                     }
                                 }];

    NSString *cancelTitle = NSLocalizedString(@"Cancel and Keep Changes", @"Menus alert button title to cancel discarding changes and not select a new menu location");
    [alert addCancelActionWithTitle:cancelTitle
                            handler:^(UIAlertAction * _Nonnull action) {
                                if (cancellationBlock) {
                                    cancellationBlock();
                                }
                            }];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)promptForDiscardingChangesBeforeSelectingADifferentMenu:(void(^)(void))confirmationBlock
                                                   cancellation:(void(^)(void))cancellationBlock
{
    NSString *title = [self discardChangesAlertTitle];
    NSString *message = NSLocalizedString(@"Selecting a different menu will discard changes you've made to the current menu. Are you sure you want to continue?", @"Menus alert message for alerting the user to unsaved changes while trying to select a different menu.");
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];

    NSString *confirmationTitle = NSLocalizedString(@"Discard and Select Menu", @"Menus alert button title to continue selecting a menu and discarding current changes.");
    [alert addDestructiveActionWithTitle:confirmationTitle
                                 handler:^(UIAlertAction * _Nonnull action) {
                                     if (confirmationBlock) {
                                         confirmationBlock();
                                     }
                                 }];

    NSString *cancelTitle = NSLocalizedString(@"Cancel and Keep Changes", @"Menus alert button title to cancel discarding changes and not select a new menu");
    [alert addCancelActionWithTitle:cancelTitle
                            handler:^(UIAlertAction * _Nonnull action) {
                                if (cancellationBlock) {
                                    cancellationBlock();
                                }
                            }];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)promptForDiscardingChangesBeforeCreatingNewMenu:(void(^)(void))confirmationBlock
                                           cancellation:(void(^)(void))cancellationBlock
{
    NSString *title = [self discardChangesAlertTitle];
    NSString *message = NSLocalizedString(@"Creating a new menu will discard changes you've made to the current menu. Are you sure you want to continue?", @"Menus alert message for alerting the user to unsaved changes while trying to create a new menu.");
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];

    NSString *confirmationTitle = NSLocalizedString(@"Discard and Create New Menu", @"Menus alert button title to continue creating a menu and discarding current changes.");
    [alert addDestructiveActionWithTitle:confirmationTitle
                                 handler:^(UIAlertAction * _Nonnull action) {
                                     if (confirmationBlock) {
                                         confirmationBlock();
                                     }
                                 }];

    NSString *cancelTitle = NSLocalizedString(@"Cancel and Keep Changes", @"Menus alert button title to cancel discarding changes and not createa a new menu.");
    [alert addCancelActionWithTitle:cancelTitle
                            handler:^(UIAlertAction * _Nonnull action) {
                                if (cancellationBlock) {
                                    cancellationBlock();
                                }
                            }];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)promptForDiscardingChangesByTheLeftBarButtonItem:(void(^)(void))confirmationBlock
                                            cancellation:(void(^)(void))cancellationBlock
{
    NSString *title = [self discardChangesAlertTitle];
    NSString *message = NSLocalizedString(@"Are you sure you want to cancel and discard changes?", @"Menus alert message for alerting the user to unsaved changes while trying back out of Menus.");
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];

    NSString *confirmationTitle = NSLocalizedString(@"Discard Changes", @"Menus alert button title to discard changes.");
    [alert addDestructiveActionWithTitle:confirmationTitle
                                 handler:^(UIAlertAction * _Nonnull action) {
                                     if (confirmationBlock) {
                                         confirmationBlock();
                                     }
                                 }];

    NSString *cancelTitle = NSLocalizedString(@"Continue Working", @"Menus alert button title to continue making changes.");
    [alert addCancelActionWithTitle:cancelTitle
                            handler:^(UIAlertAction * _Nonnull action) {
                                if (cancellationBlock) {
                                    cancellationBlock();
                                }
                            }];

    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - notifications

- (void)updateWithKeyboardNotification:(NSNotification *)notification
{
    CGRect frame = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    frame = [self.view.window convertRect:frame toView:self.view];

    UIEdgeInsets inset = self.scrollView.contentInset;
    UIEdgeInsets scrollInset = self.scrollView.scrollIndicatorInsets;

    if (frame.origin.y > self.view.frame.size.height) {
        inset.bottom = 0.0;
        scrollInset.bottom = 0.0;
    } else  {
        inset.bottom = self.view.frame.size.height - frame.origin.y;
        scrollInset.bottom = inset.bottom;
        inset.bottom += ScrollViewOffsetAdjustmentPadding;
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
