#import <UIKit/UIKit.h>

@class MenusSelectionItem;

@protocol MenusSelectionItemViewDelegate;

@interface MenusSelectionItemView : UIView

@property (nonatomic, weak) id <MenusSelectionItemViewDelegate> delegate;
@property (nonatomic, strong) MenusSelectionItem *item;
@property (nonatomic, weak) MenusSelectionItemView *previousItemView;
@property (nonatomic, weak) MenusSelectionItemView *nextItemView;

@end

@protocol MenusSelectionItemViewDelegate <NSObject>

- (void)selectionItemViewWasSelected:(MenusSelectionItemView *)itemView;

@end