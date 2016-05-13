#import <UIKit/UIKit.h>
#import "MenuItem.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MenuItemTypeViewDelegate;

@interface MenuItemTypeSelectionView : UIView

@property (nonatomic, weak, nullable) id <MenuItemTypeViewDelegate> delegate;

/**
 Design flag for ignoring drawing a top border because it doesn't look great.
 */
@property (nonatomic, assign) BOOL designIgnoresDrawingTopBorder;

/**
 The selected state for the type and for drawing the state.
 */
@property (nonatomic, assign) BOOL selected;

/**
 The itemType the view represents, such as MenuItemTypePage.
 */
@property (nonatomic, strong) NSString *itemType;

/**
 The label displayed in the UI representing the itemType.
 */
@property (nonatomic, strong) NSString *itemTypeLabel;

/**
 Helper method for updating the layout if the parentView's layout changed.
 */
- (void)updateDesignForLayoutChangeIfNeeded;

@end

@protocol MenuItemTypeViewDelegate <NSObject>

/**
 User interaction detected for selecting a new itemType.
 */
- (void)typeViewPressedForSelection:(MenuItemTypeSelectionView *)typeView;

/**
 Helper method for the parentView informing the ideal layout for the view.
 */
- (BOOL)typeViewRequiresCompactLayout:(MenuItemTypeSelectionView *)typeView;

@end

NS_ASSUME_NONNULL_END
