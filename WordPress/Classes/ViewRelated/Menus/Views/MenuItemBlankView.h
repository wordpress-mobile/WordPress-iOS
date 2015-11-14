#import "MenuItemsActionableView.h"

typedef NS_ENUM(NSUInteger) {
    MenuItemBlankViewAbove = 1,
    MenuItemBlankViewBelow,
    MenuItemBlankViewChild
}MenuItemBlankViewType;

@interface MenuItemBlankView : MenuItemsActionableView

@property (nonatomic, assign) MenuItemBlankViewType type;

@end
