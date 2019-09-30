#import "MenuHeaderViewController.h"
#import "MenusSelectionView.h"
#import "Blog.h"
#import "Menu.h"
#import "Menu+ViewDesign.h"
#import "MenuLocation.h"
#import <WordPressShared/WPFontManager.h>
#import <WordPressShared/WPStyleGuide.h>
#import "WordPress-Swift.h"

static CGFloat ViewExpansionAnimationDelay = 0.15;

@interface MenuHeaderViewController () <MenusSelectionViewDelegate>

@property (nonatomic, weak) IBOutlet UIStackView *stackView;
@property (nonatomic, weak) IBOutlet MenusSelectionView *locationsView;
@property (nonatomic, weak) IBOutlet MenusSelectionView *menusView;
@property (nonatomic, weak) IBOutlet UILabel *textLabel;

@end

@implementation MenuHeaderViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.view.backgroundColor = [UIColor murielListBackground];

    self.stackView.spacing = MenusDesignDefaultContentSpacing / 2.0;

    self.locationsView.delegate = self;
    self.menusView.delegate = self;

    [self configureTextLabel];
}

- (void)setBlog:(Blog *)blog
{
    if (_blog != blog) {
        _blog = blog;

        [self.locationsView removeAllSelectionItems];
        [self.menusView removeAllSelectionItems];

        self.locationsView.selectionType = MenusSelectionViewTypeLocations;
        self.menusView.selectionType = MenusSelectionViewTypeMenus;

        if (blog) {
            for (MenuLocation *location in blog.menuLocations) {
                MenusSelectionItem *item = [MenusSelectionItem itemWithLocation:location];
                [self.locationsView addSelectionViewItem:item];
            }
            for (Menu *menu in blog.menus) {
                MenusSelectionItem *item = [MenusSelectionItem itemWithMenu:menu];
                [self.menusView addSelectionViewItem:item];
            }
        }
    }
}

- (void)addMenu:(Menu *)menu
{
    [self.menusView addSelectionViewItem:[MenusSelectionItem itemWithMenu:menu]];
}

- (void)removeMenu:(Menu *)menu
{
    MenusSelectionItem *selectionItem = [self.menusView selectionItemForObject:menu];
    if (selectionItem) {
        [self.menusView removeSelectionItem:selectionItem];
    }
}

- (void)setSelectedLocation:(MenuLocation *)location
{
    MenusSelectionItem *locationItem = [self.locationsView selectionItemForObject:location];
    [self.locationsView setSelectedItem:locationItem];
}

- (void)setSelectedMenu:(Menu *)menu
{
    MenusSelectionItem *menuItem = [self.menusView selectionItemForObject:menu];
    [self.menusView setSelectedItem:menuItem];
}

- (void)refreshMenuViewsUsingMenu:(Menu *)menu
{
    MenusSelectionItem *item = [self.menusView selectionItemForObject:menu];
    [item notifyItemObjectWasUpdated];
}

#pragma mark - private

- (void)contractSelectionsIfNeeded
{
    // add a UX delay to selection close animation
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ViewExpansionAnimationDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.locationsView setSelectionItemsExpanded:NO animated:YES];
        [self.menusView setSelectionItemsExpanded:NO animated:YES];
    });
}

- (void)configureTextLabel
{
    self.textLabel.font = [WPStyleGuide fontForTextStyle:UIFontTextStyleFootnote maximumPointSize:[WPStyleGuide maxFontSize]];
    self.textLabel.adjustsFontForContentSizeCategory = YES;
    self.textLabel.backgroundColor = [UIColor clearColor];
    self.textLabel.textColor = [UIColor murielNeutral];
    self.textLabel.text = NSLocalizedString(@"USES", @"Menus label for describing which menu the location uses in the header.");
}

#pragma mark - MenusSelectionViewDelegate

- (void)selectionView:(MenusSelectionView *)selectionView userTappedExpand:(BOOL)expand
{
    [selectionView setSelectionItemsExpanded:expand animated:YES];
}

- (void)selectionView:(MenusSelectionView *)selectionView selectedItem:(MenusSelectionItem *)item
{
    if ([item isMenuLocation]) {

        MenuLocation *location = item.itemObject;
        [self.delegate headerViewController:self selectedLocation:location];

    } else  if ([item isMenu]) {

        Menu *menu = item.itemObject;
        [self.delegate headerViewController:self selectedMenu:menu];
    }
    [self contractSelectionsIfNeeded];
}

- (void)selectionViewSelectedOptionForCreatingNewItem:(MenusSelectionView *)selectionView
{
    [self.delegate headerViewControllerSelectedForCreatingNewMenu:self];
    [self contractSelectionsIfNeeded];
}

@end
