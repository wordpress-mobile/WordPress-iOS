#import <UIKit/UIKit.h>
#import "MenusDesign.h"

@protocol MenuItemTypeSelectionViewDelegate;

@interface MenuItemTypeSelectionView : UIView

@property (nonatomic, weak) id <MenuItemTypeSelectionViewDelegate> delegate;

@end

@protocol MenuItemTypeSelectionViewDelegate <NSObject>

- (void)typeSelectionView:(MenuItemTypeSelectionView *)selectionView selectedType:(MenuItemType)type;

@end