#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class MenusSelectionItem;

@protocol MenusSelectionDetailViewDelegate;

/**
 A detail view encapsulating labels displaying a currently
 selected MenusSelectionItem and a count of available MenusSelectionItems.
 */
@interface MenusSelectionDetailView : UIView

@property (nonatomic, weak, nullable) id <MenusSelectionDetailViewDelegate> delegate;

/**
 Updates the design indicating the detailView is active, selected, or enabled.
 */
@property (nonatomic, assign) BOOL showsDesignActive;

/**
 Update the UI with the number of available selection items and the currently selected item.
 */
- (void)updatewithAvailableItems:(NSUInteger)numItemsAvailable selectedItem:(MenusSelectionItem *)selectedItem;

@end

@protocol MenusSelectionDetailViewDelegate <NSObject>
@optional

/**
 User touches detected for updating the highlighted state of the detailView.
 */
- (void)selectionDetailView:(MenusSelectionDetailView *)detailView touchesHighlightedStateChanged:(BOOL)highlighted;

/**
 User touches detected for tapping the detailView.
 */
- (void)selectionDetailView:(MenusSelectionDetailView *)detailView tapGestureRecognized:(UITapGestureRecognizer *)tap;

@end

NS_ASSUME_NONNULL_END
