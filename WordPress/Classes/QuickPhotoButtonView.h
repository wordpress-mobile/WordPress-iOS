#import <UIKit/UIKit.h>

@protocol QuickPhotoButtonViewDelegate;

@interface QuickPhotoButtonView : UIView

@property (nonatomic, strong) id<QuickPhotoButtonViewDelegate>delegate;

- (void)showSuccess;
- (void)showProgress:(BOOL)show animated:(BOOL)animated;

@end

@protocol QuickPhotoButtonViewDelegate <NSObject>
- (void)quickPhotoButtonViewTapped:(QuickPhotoButtonView *)sender;
@end