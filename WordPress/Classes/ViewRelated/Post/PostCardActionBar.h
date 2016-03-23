#import <UIKit/UIKit.h>

@interface PostCardActionBar : UIView

/**
 *  Shows the first page of the action bar items.
 */
- (void)showFirstPage;

/**
 *  Sets the action bar items.
 *
 *  @param  items       The array of items for the action bar.
 */
- (void)setItems:(NSArray *)items;

@end
