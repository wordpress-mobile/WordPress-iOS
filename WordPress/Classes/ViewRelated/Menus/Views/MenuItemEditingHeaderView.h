#import <UIKit/UIKit.h>

@class MenuItem;

@interface MenuItemEditingHeaderView : UIView

@property (nonatomic, strong) MenuItem *item;

- (void)setNeedsTopConstraintsUpdateForStatusBarAppearence:(BOOL)hidden;

@end
