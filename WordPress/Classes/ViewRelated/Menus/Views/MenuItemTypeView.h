#import <UIKit/UIKit.h>
#import "MenusDesign.h"

@protocol MenuItemTypeViewDelegate;

@interface MenuItemTypeView : UIView

@property (nonatomic, weak) id <MenuItemTypeViewDelegate> delegate;
@property (nonatomic, assign) BOOL selected;
@property (nonatomic, assign) MenuItemType itemType;

- (void)setTypeTitle:(NSString *)title;
- (void)setTypeIconImageName:(NSString *)imageName;

@end

@protocol MenuItemTypeViewDelegate <NSObject>

- (void)itemTypeViewSelected:(MenuItemTypeView *)typeView;

@end
