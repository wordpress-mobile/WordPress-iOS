#import <UIKit/UIKit.h>
#import "MenusSelectionItem.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, MenusSelectionViewType) {
    MenusSelectionViewTypeMenus = 1,
    MenusSelectionViewTypeLocations
};

@protocol MenusSelectionViewDelegate;

/**
 A view encapsulating the use of MenusSelectionItems as a list of options for either Menus or MenuLocations.
 */
@interface MenusSelectionView : UIView

@property (nonatomic, weak, nullable) id <MenusSelectionViewDelegate> delegate;

/**
 The type of selection the selectionView should be configured for.
 */
@property (nonatomic, assign) MenusSelectionViewType selectionType;

/**
 Toggle the visual expansion of the selection items in the UI.
 */
@property (nonatomic, assign) BOOL selectionItemsExpanded;

/**
 The currently selected item in the UI.
 */
@property (nonatomic, strong) MenusSelectionItem *selectedItem;

/**
 Add a selection item to the list of available items for display.
 */
- (void)addSelectionViewItem:(MenusSelectionItem *)selectionItem;

/**
 Remove a selection item from the list of available items for display.
 */
- (void)removeSelectionItem:(MenusSelectionItem *)selectionItem;

/**
 Remove all selection items from the list of available items for display.
 */
- (void)removeAllSelectionItems;

/**
 Get the corresponding MenusSelectionItem with an item.itemObject equal to the passed itemObject.
 */
- (nullable MenusSelectionItem *)selectionItemForObject:(id)itemObject;

/**
 Toggle the visual expansion of the selection items in the UI, with animation.
 */
- (void)setSelectionItemsExpanded:(BOOL)selectionItemsExpanded animated:(BOOL)animated;

@end

@protocol MenusSelectionViewDelegate <NSObject>

/**
 The user tapped to toggle the selection expansion of the UI.
 */
- (void)selectionView:(MenusSelectionView *)selectionView userTappedExpand:(BOOL)expand;

/**
 The user selected an item from the list of available items for display.
 */
- (void)selectionView:(MenusSelectionView *)selectionView selectedItem:(MenusSelectionItem *)item;

/**
 The user selected a special item representing creating a new item.
 */
- (void)selectionViewSelectedOptionForCreatingNewItem:(MenusSelectionView *)selectionView;

@end

NS_ASSUME_NONNULL_END
