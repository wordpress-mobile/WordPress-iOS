#import <UIKit/UIKit.h>

@protocol MenuItemSourceTypeSelectionViewDelegate;

@interface MenuItemSourceTypeSelectionView : UIView

@property (nonatomic, weak) id <MenuItemSourceTypeSelectionViewDelegate> delegate;

@end

@protocol MenuItemSourceTypeSelectionViewDelegate <NSObject>

@end