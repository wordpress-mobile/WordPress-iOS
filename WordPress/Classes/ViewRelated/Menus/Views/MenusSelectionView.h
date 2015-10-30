#import <UIKit/UIKit.h>
#import "MenusSelectionDetailView.h"

@class Menu;
@class MenuLocation;

typedef NS_ENUM(NSUInteger)
{
    MenuSelectionViewTypeLocations,
    MenuSelectionViewTypeMenus
    
}MenuSelectionViewType;

@interface MenusSelectionViewItem : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *details;
@property (nonatomic, copy) NSString *iconSourceFileName;
@property (nonatomic, strong) id itemObject;

+ (MenusSelectionViewItem *)itemWithMenu:(Menu *)menu;
+ (MenusSelectionViewItem *)itemWithLocation:(MenuLocation *)location;

@end

@interface MenusSelectionView : UIView

@property (nonatomic, assign) MenuSelectionViewType selectionType;

- (void)updateItems:(NSArray <MenusSelectionViewItem *> *)items selectedItem:(MenusSelectionViewItem *)selectedItem;

@end
