#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class MenusSelectionItem;

@protocol MenusSelectionItemViewDelegate;

@interface MenusSelectionItemView : UIView

@property (nonatomic, weak, nullable) id <MenusSelectionItemViewDelegate> delegate;
@property (nonatomic, strong) MenusSelectionItem *item;

/**
 Tracker for the previously listed itemView in a stack.
 */
@property (nonatomic, weak, nullable) MenusSelectionItemView *previousItemView;

/**
 Tracker for the next listed itemView in a stack.
 */
@property (nonatomic, weak, nullable) MenusSelectionItemView *nextItemView;

@end

@protocol MenusSelectionItemViewDelegate <NSObject>

/**
 User interaction detected for selection the itemView.
 */
- (void)selectionItemViewWasSelected:(MenusSelectionItemView *)itemView;

@end

NS_ASSUME_NONNULL_END
