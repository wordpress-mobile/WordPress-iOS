#import "MenusSelectionView.h"
#import "Menu.h"
#import "MenuLocation.h"
#import "MenusSelectionDetailView.h"
#import "MenusDesign.h"

@implementation MenusSelectionViewItem

+ (MenusSelectionViewItem *)itemWithMenu:(Menu *)menu
{
    MenusSelectionViewItem *item = [MenusSelectionViewItem new];
    item.name = menu.name;
    item.details = menu.details;
    return item;
}

+ (MenusSelectionViewItem *)itemWithLocation:(MenuLocation *)location
{
    MenusSelectionViewItem *item = [MenusSelectionViewItem new];
    item.name = location.details;
    item.details = location.name;
    return item;
}

@end

@interface MenusSelectionView ()

@property (nonatomic, weak) IBOutlet UIStackView *stackView;
@property (nonatomic, weak) IBOutlet MenusSelectionDetailView *detailView;
@property (nonatomic, strong) NSArray *items;
@property (nonatomic, strong) MenusSelectionViewItem *selectedItem;

@end

@implementation MenusSelectionView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    UIEdgeInsets drawingInset = MenusDesignDefaultInsets();
    UIEdgeInsets margins = UIEdgeInsetsZero;
    margins.left = drawingInset.left + MenusSelectionDetailViewDefaultSpacing;
    margins.right = drawingInset.right + MenusSelectionDetailViewDefaultSpacing;
    self.stackView.layoutMargins = margins;
    self.stackView.layoutMarginsRelativeArrangement = YES;
    
    [self setupStyling];
}

- (void)setupStyling
{
    self.backgroundColor = [UIColor clearColor];
}

- (void)updateItems:(NSArray <MenusSelectionViewItem *> *)items selectedItem:(MenusSelectionViewItem *)selectedItem
{
    self.items = items;
    self.selectedItem = selectedItem;
    
    if(self.selectionType == MenuSelectionViewTypeLocations) {
        
        [self.detailView updateWithAvailableLocations:items.count selectedLocationName:selectedItem.name];
        
    }else if(self.selectionType == MenuSelectionViewTypeMenus) {
        
        [self.detailView updateWithAvailableMenus:items.count selectedLocationName:selectedItem.name];
    }
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    UIEdgeInsets inset = MenusDesignDefaultInsets();
    CGRect fillRect = CGRectInset(rect, inset.left, inset.top);
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:fillRect cornerRadius:1.0];
    [[UIColor whiteColor] set];
    [path fill];
}

@end
