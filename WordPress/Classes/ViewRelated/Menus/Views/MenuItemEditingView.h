#import <UIKit/UIKit.h>

@class MenuItem;

@interface MenuItemEditingView : UIView

@property (nonatomic, strong) MenuItem *item;

- (id)initWithItem:(MenuItem *)item;

@end
