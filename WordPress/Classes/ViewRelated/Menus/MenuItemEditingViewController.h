#import <UIKit/UIKit.h>

@class MenuItem;

@interface MenuItemEditingViewController : UIViewController

@property (nonatomic, strong) MenuItem *item;

- (id)initWithItem:(MenuItem *)item;

@end
