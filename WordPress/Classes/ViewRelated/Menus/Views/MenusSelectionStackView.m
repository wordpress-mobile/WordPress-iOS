#import "MenusSelectionStackView.h"
#import "Menu.h"
#import "MenuLocation.h"

@implementation MenusSelectionItem

+ (MenusSelectionItem *)itemWithMenu:(Menu *)menu
{
    MenusSelectionItem *item = [MenusSelectionItem new];
    item.name = menu.name;
    item.details = menu.details;
    return item;
}

+ (MenusSelectionItem *)itemWithLocation:(MenuLocation *)location
{
    MenusSelectionItem *item = [MenusSelectionItem new];
    item.name = location.name;
    item.details = location.details;
    return item;
}

@end

@interface MenusSelectionStackView ()

@property (nonatomic, weak) IBOutlet MenusSelectionView *selectionView;
@property (nonatomic, strong) NSArray *items;
@property (nonatomic, strong) MenusSelectionItem *selectedItem;

@end

@implementation MenusSelectionStackView

- (void)updateItems:(NSArray <MenusSelectionItem *> *)items selectedItem:(MenusSelectionItem *)selectedItem
{
    self.items = items;
    self.selectedItem = selectedItem;
    
    if(self.selectionType == MenuSelectionTypeLocations) {
        
        [self.selectionView updateWithAvailableLocations:items.count selectedLocationName:selectedItem.name];
        
    }else if(self.selectionType == MenuSelectionTypeMenus) {
        
        [self.selectionView updateWithAvailableMenus:items.count selectedLocationName:selectedItem.name];
    }
}

@end
