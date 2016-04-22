#import <UIKit/UIKit.h>

@class MenusSelectionItem;

@protocol MenusSelectionDetailViewDelegate;

@interface MenusSelectionDetailView : UIView

@property (nonatomic, weak) id <MenusSelectionDetailViewDelegate> delegate;
@property (nonatomic, assign) BOOL showsDesignActive;

- (void)updatewithAvailableItems:(NSUInteger)numItemsAvailable selectedItem:(MenusSelectionItem *)selectedItem;

@end

@protocol MenusSelectionDetailViewDelegate <NSObject>
@optional
- (void)selectionDetailView:(MenusSelectionDetailView *)detailView touchesHighlightedStateChanged:(BOOL)highlighted;
- (void)selectionDetailView:(MenusSelectionDetailView *)detailView tapGestureRecognized:(UITapGestureRecognizer *)tap;

@end