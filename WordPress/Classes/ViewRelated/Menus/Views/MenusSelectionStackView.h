#import <UIKit/UIKit.h>
#import "MenusSelectionView.h"

@class Menu;
@class MenuLocation;

typedef NS_ENUM(NSUInteger)
{
    MenuSelectionTypeLocations,
    MenuSelectionTypeMenus
    
}MenuSelectionType;

@interface MenusSelectionItem : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *details;
@property (nonatomic, copy) NSString *iconSourceFileName;
@property (nonatomic, strong) id itemObject;

+ (MenusSelectionItem *)itemWithMenu:(Menu *)menu;
+ (MenusSelectionItem *)itemWithLocation:(MenuLocation *)location;

@end

@interface MenusSelectionStackView : UIStackView

@property (nonatomic, assign) MenuSelectionType selectionType;

- (void)updateItems:(NSArray <MenusSelectionItem *> *)items selectedItem:(MenusSelectionItem *)selectedItem;

@end
