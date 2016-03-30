#import "MenusHeaderView.h"
#import "MenusSelectionView.h"
#import "Blog.h"
#import "WPStyleGuide.h"
#import "Menu.h"
#import "Menu+ViewDesign.h"
#import "MenuLocation.h"

@interface MenusHeaderView () <MenusSelectionViewDelegate>

@property (nonatomic, weak) IBOutlet UIStackView *stackView;
@property (nonatomic, strong) Blog *blog;
@property (nonatomic, weak) IBOutlet MenusSelectionView *locationsView;
@property (nonatomic, weak) IBOutlet MenusSelectionView *menusView;
@property (nonatomic, weak) IBOutlet UILabel *textLabel;

@end

static CGFloat const MenusHeaderViewDesignStrokeWidth = 2.0;

@implementation MenusHeaderView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // provide extra margin to easily draw the design stroke, see drawRect:
    UIEdgeInsets margins = [Menu viewDefaultDesignInsets];
    margins.bottom += MenusHeaderViewDesignStrokeWidth;
    self.stackView.layoutMargins = margins;
    self.stackView.layoutMarginsRelativeArrangement = YES;
    self.stackView.spacing = margins.left; // use a relative spacing to our margin padding
    
    self.backgroundColor = [WPStyleGuide greyLighten30];
    self.textLabel.font = [WPStyleGuide subtitleFont];
    self.textLabel.backgroundColor = [UIColor clearColor];
    
    self.locationsView.delegate = self;
    self.locationsView.selectionType = MenusSelectionViewTypeLocations;
    self.menusView.delegate = self;
    self.menusView.selectionType = MenusSelectionViewTypeMenus;
}

- (void)setupWithMenusForBlog:(Blog *)blog
{
    self.blog = blog;
    for (MenuLocation *location in blog.menuLocations) {
        MenusSelectionItem *item = [MenusSelectionItem itemWithLocation:location];
        [self.locationsView addSelectionViewItem:item];
    }
    for (Menu *menu in blog.menus) {
        MenusSelectionItem *item = [MenusSelectionItem itemWithMenu:menu];
        [self.menusView addSelectionViewItem:item];
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
        // toggle the selection on a trait collection change to a horizonal axis for the stack view
        // this ensures both selection views are expanded if one already is
        // otherwise the design looks odd with too much negative space
        // see userInteractionDetectedForTogglingSelectionView:expand:
        if (self.locationsView.selectionExpanded || self.menusView.selectionExpanded) {
            if (self.locationsView.selectionExpanded && !self.menusView.selectionExpanded) {
                
                [self.menusView setSelectionItemsExpanded:YES animated:NO];
                
            } else  if (self.menusView.selectionExpanded && !self.locationsView.selectionExpanded) {
             
                [self.locationsView setSelectionItemsExpanded:YES animated:NO];
            }
        }
    }
    
    // required to redraw the stroke because our intrinsicContentSize changed based on the stack view axis change
    // perhaps this won't be needed in a future version of iOS
    // via Brent Coursey 10/30/15
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetLineWidth(context, MenusHeaderViewDesignStrokeWidth);
    
    const CGFloat lineY = rect.size.height - (MenusHeaderViewDesignStrokeWidth / 2);
    CGContextMoveToPoint(context, rect.origin.x, lineY);
    CGContextAddLineToPoint(context, rect.size.width - rect.origin.x, lineY);
    
    CGContextSetStrokeColorWithColor(context, [[WPStyleGuide greyLighten20] CGColor]);
    CGContextStrokePath(context);
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
    if (self.stackView.axis == UILayoutConstraintAxisHorizontal) {
        // in the horizontal axis we want to toggle expansion for both selection views
        // otherwise the design looks odd with too much negative space
        // see traitCollectionDidChange:
        if (selectionView == self.locationsView) {
            [self.menusView setSelectionItemsExpanded:expand animated:YES];
        } else  if (selectionView == self.menusView) {
            [self.locationsView setSelectionItemsExpanded:expand animated:YES];
        }
        [selectionView setSelectionItemsExpanded:expand animated:YES];
        
    } else  {
        
        [selectionView setSelectionItemsExpanded:expand animated:YES];
    }
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

- (void)selectionViewSelectedOptionForCreatingNewMenu:(MenusSelectionView *)selectionView
{
    [self.delegate headerViewSelectedForCreatingNewMenu:self];
    [self closeSelectionsIfNeeded];
}

@end
