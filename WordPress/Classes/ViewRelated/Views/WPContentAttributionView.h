#import <UIKit/UIKit.h>
#import "WPContentViewProvider.h"

@class WPContentAttributionView;

@protocol WPContentAttributionViewDelegate <NSObject>
@optional
- (void)attributionView:(WPContentAttributionView *)attributionView didReceiveAttributionLinkAction:(id)sender;
@end

@interface WPContentAttributionView : UIView

@property (nonatomic, weak) id<WPContentViewProvider>contentProvider;
@property (nonatomic, weak) id<WPContentAttributionViewDelegate>delegate;
@property (nonatomic, strong) UILabel *attributionNameLabel;

- (void)setAvatarImage:(UIImage *)image;
- (void)hideAttributionButton:(BOOL)hide;
- (void)selectAttributionButton:(BOOL)select;

@end
