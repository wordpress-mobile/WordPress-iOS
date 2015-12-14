#import <UIKit/UIKit.h>

@class MenuItem;

@interface MenuItemSourceView : UIView

@property (nonatomic, strong) MenuItem *item;
@property (nonatomic, strong, readonly) UIStackView *stackView;

@end
