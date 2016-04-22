#import <UIKit/UIKit.h>
#import "MenusSelectionItem.h"

typedef NS_ENUM(NSUInteger, MenusSelectionViewType) {
    MenusSelectionViewTypeMenus = 1,
    MenusSelectionViewTypeLocations
};

@protocol MenusSelectionViewDelegate;

@interface MenusSelectionView : UIView

@property (nonatomic, assign) MenusSelectionViewType selectionType;
@property (nonatomic, weak) id <MenusSelectionViewDelegate> delegate;
@property (nonatomic, readonly) BOOL selectionExpanded;
@property (nonatomic, strong) MenusSelectionItem *selectedItem;

- (void)addSelectionViewItem:(MenusSelectionItem *)selectionItem;
- (void)removeSelectionItem:(MenusSelectionItem *)selectionItem;
- (void)removeAllSelectionItems;
- (MenusSelectionItem *)itemWithItemObjectEqualTo:(id)itemObject;
- (void)setSelectionItemsExpanded:(BOOL)selectionItemsExpanded animated:(BOOL)animated;

@end

@protocol MenusSelectionViewDelegate <NSObject>

// user interaction dictates the selection view should be expanded or not (closed)
- (void)userInteractionDetectedForTogglingSelectionView:(MenusSelectionView *)selectionView expand:(BOOL)expand;
- (void)selectionView:(MenusSelectionView *)selectionView selectedItem:(MenusSelectionItem *)item;
- (void)selectionViewSelectedOptionForCreatingNewItem:(MenusSelectionView *)selectionView;

@end