#import "MenusHeaderView.h"
#import "MenusSelectionView.h"
#import "Blog.h"
#import "WPStyleGuide.h"
#import "Menu.h"
#import "Menu+ViewDesign.h"
#import "MenuLocation.h"
#import "ContextManager.h"

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
    for(MenuLocation *location in blog.menuLocations) {
        MenusSelectionItem *item = [MenusSelectionItem itemWithLocation:location];
        [self.locationsView addSelectionViewItem:item];
    }
    for(Menu *menu in blog.menus) {
        MenusSelectionItem *item = [MenusSelectionItem itemWithMenu:menu];
        [self.menusView addSelectionViewItem:item];
    }
}

- (void)updateLocationSelectionWithMenu:(Menu *)menu
{
    MenuLocation *selectedLocation = self.locationsView.selectedItem.itemObject;
    selectedLocation.menu = menu;
}

- (void)updateSelectionWithLocation:(MenuLocation *)location
{
    MenusSelectionItem *locationItem = [self.locationsView itemWithItemObjectEqualTo:location];
    [self.locationsView setSelectedItem:locationItem];
}

- (void)updateSelectionWithMenu:(Menu *)menu
{
    MenusSelectionItem *menuItem = [self.menusView itemWithItemObjectEqualTo:menu];
    [self.menusView setSelectedItem:menuItem];
}

- (void)removeMenu:(Menu *)menu
{
    MenusSelectionItem *selectionItem = [self.menusView itemWithItemObjectEqualTo:menu];
    if (selectionItem) {
        [self.menusView removeSelectionItem:selectionItem];
    }
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

#pragma mark - delegate helpers

- (void)tellDelegateSelectedLocation:(MenuLocation *)location
{
    [self.delegate headerView:self selectionChangedWithSelectedLocation:location];
}

- (void)tellDelegateSelectedMenu:(Menu *)menu
{
    [self.delegate headerView:self selectionChangedWithSelectedMenu:menu];
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
        [self updateSelectionWithMenu:location.menu];
        [self tellDelegateSelectedLocation:item.itemObject];
        
    } else  if ([item isMenu]) {
        
        Menu *menu = item.itemObject;
        [self updateLocationSelectionWithMenu:menu];
        [self tellDelegateSelectedMenu:menu];
    }
    [self closeSelectionsIfNeeded];
}

- (void)selectionViewSelectedOptionForCreatingNewMenu:(MenusSelectionView *)selectionView
{
    Menu *newMenu = [NSEntityDescription insertNewObjectForEntityForName:[Menu entityName] inManagedObjectContext:self.blog.managedObjectContext];
    newMenu.name = [self generateIncrementalNameFromMenus:self.blog.menus];
    newMenu.blog = self.blog;
    
    [self.menusView addSelectionViewItem:[MenusSelectionItem itemWithMenu:newMenu]];
    
    [self updateLocationSelectionWithMenu:newMenu];
    [self updateSelectionWithMenu:newMenu];
    
    [self tellDelegateSelectedMenu:newMenu];
    [self closeSelectionsIfNeeded];
}


- (NSString *)generateIncrementalNameFromMenus:(NSOrderedSet *)menus
{
    NSInteger highestInteger = 1;
    for (Menu *menu in menus) {
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

@end
