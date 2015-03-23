#import <UIKit/UIKit.h>

@interface PostCardActionBar : UIView

- (NSInteger)numberOfItems;
- (void)setItems:(NSArray *)items;
- (void)setItems:(NSArray *)items withAnimation:(BOOL)animation;

@end
