#import <UIKit/UIKit.h>
#import "MenusDesign.h"

@protocol MenuItemTypeViewDelegate;

@interface MenuItemTypeCell : UITableViewCell

@property (nonatomic, weak) id <MenuItemTypeViewDelegate> delegate;
@property (nonatomic, assign) MenuItemType itemType;

- (void)setTypeTitle:(NSString *)title;
- (void)setTypeIconImageName:(NSString *)imageName;

@end

@protocol MenuItemTypeViewDelegate <NSObject>

- (void)itemTypeViewSelected:(MenuItemTypeCell *)typeView;

@end
