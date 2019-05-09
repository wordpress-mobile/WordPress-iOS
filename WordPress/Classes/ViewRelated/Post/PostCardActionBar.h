#import <UIKit/UIKit.h>

typedef void(^MoreActionCallback)(UIView* view);

@interface PostCardActionBar : UIView

- (void)setMoreAction:(MoreActionCallback)callback;
- (void)setItems:(NSArray *)items;
- (void)reset;

@end
