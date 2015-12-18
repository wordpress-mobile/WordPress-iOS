#import <UIKit/UIKit.h>

@protocol MenuItemTypeViewDelegate;

@interface MenuItemTypeView : UIView

@property (nonatomic, weak) id <MenuItemTypeViewDelegate> delegate;

@end

@protocol MenuItemTypeViewDelegate <NSObject>

@end