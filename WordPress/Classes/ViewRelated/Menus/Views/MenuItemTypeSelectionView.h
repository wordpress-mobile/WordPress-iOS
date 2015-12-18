#import <UIKit/UIKit.h>

@protocol MenuItemTypeSelectionViewDelegate;

@interface MenuItemTypeSelectionView : UIView

@property (nonatomic, weak) id <MenuItemTypeSelectionViewDelegate> delegate;

@end

@protocol MenuItemTypeSelectionViewDelegate <NSObject>

@end