#import <UIKit/UIKit.h>

typedef void(^PostCardRestoreViewCallback)();

@interface PostCardRestoreView : UIView

@property (nonatomic, copy) PostCardRestoreViewCallback callback;

+ (instancetype)newPostCardRestoreView;

- (void)showSpinner:(BOOL)show animated:(BOOL)animated;
- (void)setMessage:(NSString *)message andButtonTitle:(NSString *)buttonTitle;

@end
