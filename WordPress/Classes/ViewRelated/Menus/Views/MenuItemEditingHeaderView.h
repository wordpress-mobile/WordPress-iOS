#import <UIKit/UIKit.h>

@class MenuItem;

@interface MenuItemEditingHeaderView : UIView

@property (nonatomic, strong) MenuItem *item;
@property (nonatomic, assign) BOOL shouldProvidePaddingForStatusBar; // defaults to YES

@end
