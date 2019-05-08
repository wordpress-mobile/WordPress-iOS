#import <UIKit/UIKit.h>

typedef void(^MoreActionCallback)(void);

@interface PostCardActionBar : UIView

- (void)setItems:(NSArray *)items;
- (void)reset;

@end
