#import <UIKit/UIKit.h>

@interface MenuItemTypeView : UIView

@property (nonatomic, assign) BOOL selected;

- (void)setTypeTitle:(NSString *)title;
- (void)setTypeIconImageName:(NSString *)imageName;

@end
