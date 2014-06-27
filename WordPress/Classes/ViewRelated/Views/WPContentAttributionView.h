#import <UIKit/UIKit.h>
#import "WPContentViewProvider.h"

extern const CGFloat WPContentAttributionViewAvatarSize;

@class WPContentAttributionView;

@protocol WPContentAttributionViewDelegate <NSObject>
@optional
- (void)attributionView:(WPContentAttributionView *)attributionView didReceiveAttributionLinkAction:(id)sender;
@end

@interface WPContentAttributionView : UIView

@property (nonatomic, weak) id<WPContentViewProvider>contentProvider;
@property (nonatomic, weak) id<WPContentAttributionViewDelegate>delegate;

- (void)setAvatarImage:(UIImage *)image;
- (void)hideAttributionButton:(BOOL)hide;
- (void)selectAttributionButton:(BOOL)select;

#pragma mark - Private Subclass Members and Methods

@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *attributionNameLabel;
@property (nonatomic, strong) UIButton *attributionLinkButton;
@property (nonatomic, strong) UIView *borderView;

- (void)configureAttributionButton;

@end
