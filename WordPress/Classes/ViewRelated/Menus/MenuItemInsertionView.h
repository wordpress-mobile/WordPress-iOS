#import "MenuItemAbstractView.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, MenuItemInsertionOrder) {
    MenuItemInsertionOrderAbove = 1,
    MenuItemInsertionOrderBelow,
    MenuItemInsertionOrderChild
};

@protocol MenuItemInsertionViewDelegate;

@interface MenuItemInsertionView : MenuItemAbstractView

@property (nonatomic, weak, nullable) id <MenuItemAbstractViewDelegate, MenuItemInsertionViewDelegate> delegate;

/**
 The type of insertion the view represents.
 */
@property (nonatomic, assign) MenuItemInsertionOrder insertionOrder;

@end

@protocol MenuItemInsertionViewDelegate <MenuItemAbstractViewDelegate>

/**
 User interaction detected for selecting the insertion.
 */
- (void)itemInsertionViewSelected:(MenuItemInsertionView *)insertionView;

@end

NS_ASSUME_NONNULL_END
