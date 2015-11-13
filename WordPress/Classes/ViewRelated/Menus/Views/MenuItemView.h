#import <UIKit/UIKit.h>

@interface MenuItemView : UIView

@property (nonatomic, weak) MenuItemView *previousItemView;
@property (nonatomic, weak) MenuItemView *nextItemView;
@property (nonatomic, assign) NSUInteger indentationLevel;

- (UIColor *)highlightedColor;

@end
