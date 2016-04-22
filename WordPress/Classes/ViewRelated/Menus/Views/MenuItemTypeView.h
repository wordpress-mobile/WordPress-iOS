#import <UIKit/UIKit.h>
#import "MenuItem.h"

@protocol MenuItemTypeViewDelegate;

@interface MenuItemTypeView : UIView

@property (nonatomic, weak) id <MenuItemTypeViewDelegate> delegate;
@property (nonatomic, assign) BOOL designIgnoresDrawingTopBorder;
@property (nonatomic, assign) BOOL selected;
@property (nonatomic, strong) NSString *itemType;
@property (nonatomic, strong) NSString *itemTypeLabel;

- (void)updateDesignForLayoutChangeIfNeeded;

@end

@protocol MenuItemTypeViewDelegate <NSObject>

- (void)typeViewPressedForSelection:(MenuItemTypeView *)typeView;
- (BOOL)typeViewRequiresCompactLayout:(MenuItemTypeView *)typeView;

@end