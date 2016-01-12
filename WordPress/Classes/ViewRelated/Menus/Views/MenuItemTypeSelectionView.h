#import <UIKit/UIKit.h>
#import "MenuItem.h"

@protocol MenuItemTypeSelectionViewDelegate;

@interface MenuItemTypeSelectionView : UIView

@property (nonatomic, weak) id <MenuItemTypeSelectionViewDelegate> delegate;

- (UIView *)firstArrangedSubViewInLayout;

@end

@protocol MenuItemTypeSelectionViewDelegate <NSObject>

- (void)itemTypeSelectionViewChanged:(MenuItemTypeSelectionView *)typeSelectionView type:(MenuItemType)itemType;
- (BOOL)itemTypeSelectionViewRequiresCompactLayout:(MenuItemTypeSelectionView *)typeSelectionView;

@end