#import <UIKit/UIKit.h>

@class MenusSelectionItem;

@protocol MenusSelectionItemViewDelegate;

@interface MenusSelectionItemView : UIView

@property (nonatomic, weak) id <MenusSelectionItemViewDelegate> delegate;
@property (nonatomic, strong) MenusSelectionItem *item;

/**
 Tracker for the previously listed itemView in a stack.
 */
@property (nonatomic, weak) MenusSelectionItemView *previousItemView;

/**
 Tracker for the next listed itemView in a stack.
 */
@property (nonatomic, weak) MenusSelectionItemView *nextItemView;

@end

@protocol MenusSelectionItemViewDelegate <NSObject>

/**
 User interaction detected for selection the itemView.
 */
- (void)selectionItemViewWasSelected:(MenusSelectionItemView *)itemView;

@end