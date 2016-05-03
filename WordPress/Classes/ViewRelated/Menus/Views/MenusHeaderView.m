#import "MenusHeaderView.h"
#import "MenusSelectionView.h"
#import "Blog.h"
#import "WPStyleGuide.h"
#import "Menu.h"
#import "Menu+ViewDesign.h"
#import "MenuLocation.h"
#import "WPFontManager.h"

@interface MenusHeaderView () <MenusSelectionViewDelegate>

@property (nonatomic, weak) IBOutlet UIStackView *stackView;
@property (nonatomic, weak) IBOutlet MenusSelectionView *locationsView;
@property (nonatomic, weak) IBOutlet MenusSelectionView *menusView;
@property (nonatomic, weak) IBOutlet UILabel *textLabel;

@end

@implementation MenusHeaderView

- (void)awakeFromNib
{
    [super awakeFromNib];

    self.stackView.spacing = MenusDesignDefaultContentSpacing / 2.0;
    
    self.backgroundColor = [WPStyleGuide greyLighten30];
    
    self.locationsView.delegate = self;
    self.menusView.delegate = self;
    self.locationsView.selectionType = MenusSelectionViewTypeLocations;
    self.menusView.selectionType = MenusSelectionViewTypeMenus;
    
    self.textLabel.font = [WPFontManager systemRegularFontOfSize:13];
    self.textLabel.backgroundColor = [UIColor clearColor];
    self.textLabel.textColor = [WPStyleGuide greyDarken20];
    self.textLabel.text = NSLocalizedString(@"USES", @"Menus label for describing which menu the location uses in the header.");
}

- (void)setBlog:(Blog *)blog
{
    if (_blog != blog) {
        _blog = blog;
        
        [self.locationsView removeAllSelectionItems];
        [self.menusView removeAllSelectionItems];
        
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
    MenusSelectionItem *selectionItem = [self.menusView itemWithItemObjectEqualTo:menu];
    if (selectionItem) {
        [self.menusView removeSelectionItem:selectionItem];
    }
}

- (void)setSelectedLocation:(MenuLocation *)location
{
    MenusSelectionItem *locationItem = [self.locationsView itemWithItemObjectEqualTo:location];
    [self.locationsView setSelectedItem:locationItem];
}

- (void)setSelectedMenu:(Menu *)menu
{
    MenusSelectionItem *menuItem = [self.menusView itemWithItemObjectEqualTo:menu];
    [self.menusView setSelectedItem:menuItem];
}

- (void)refreshMenuViewsUsingMenu:(Menu *)menu
{
    MenusSelectionItem *item = [self.menusView itemWithItemObjectEqualTo:menu];
    [item notifyItemObjectWasUpdated];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    if (self.stackView.axis == UILayoutConstraintAxisHorizontal) {
        // Toggle the selection on a trait collection change to a horizonal axis for the stack view
        // this ensures both selection views are expanded if one already is
        // otherwise the design looks odd with too much negative space
        // see userInteractionDetectedForTogglingSelectionView:expand:
        if (self.locationsView.selectionItemsExpanded || self.menusView.selectionItemsExpanded) {
            if (self.locationsView.selectionItemsExpanded && !self.menusView.selectionItemsExpanded) {
                
                [self.menusView setSelectionItemsExpanded:YES animated:NO];
                
            } else  if (self.menusView.selectionItemsExpanded && !self.locationsView.selectionItemsExpanded) {
             
                [self.locationsView setSelectionItemsExpanded:YES animated:NO];
            }
        }
    }
}

#pragma mark - private

- (void)closeSelectionsIfNeeded
{
    // add a UX delay to selection close animation
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.locationsView setSelectionItemsExpanded:NO animated:YES];
        [self.menusView setSelectionItemsExpanded:NO animated:YES];
    });
}

#pragma mark - MenusSelectionViewDelegate

- (void)userInteractionDetectedForTogglingSelectionView:(MenusSelectionView *)selectionView expand:(BOOL)expand
{
    [selectionView setSelectionItemsExpanded:expand animated:YES];
}

- (void)selectionView:(MenusSelectionView *)selectionView selectedItem:(MenusSelectionItem *)item
{
    if ([item isMenuLocation]) {
        
        MenuLocation *location = item.itemObject;
        [self.delegate headerView:self selectedLocation:location];
        
    } else  if ([item isMenu]) {
        
        Menu *menu = item.itemObject;
        [self.delegate headerView:self selectedMenu:menu];
    }
    [self closeSelectionsIfNeeded];
}

- (void)selectionViewSelectedOptionForCreatingNewItem:(MenusSelectionView *)selectionView
{
    [self.delegate headerViewSelectedForCreatingNewMenu:self];
    [self closeSelectionsIfNeeded];
}

@end
