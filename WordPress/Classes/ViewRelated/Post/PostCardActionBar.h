#import <UIKit/UIKit.h>

typedef void(^MoreActionCallback)(void);

@interface PostCardActionBar : UIView

- (void)setMoreAction:(MoreActionCallback)callback;
- (void)setItems:(NSArray *)items;
- (void)reset;

@end
