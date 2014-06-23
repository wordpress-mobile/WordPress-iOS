#import <UIKit/UIKit.h>
#import "WPContentViewProvider.h"

@class WPContentAttributionView;

@protocol WPContentAttributionViewDelegate <NSObject>
@optional
- (void)attributionView:(WPContentAttributionView *)attributionView didReceiveAuthorLinkAction:(id)sender;
@end

@interface WPContentAttributionView : UIView

@property (nonatomic, weak) id<WPContentViewProvider>contentProvider;
@property (nonatomic, weak) id<WPContentAttributionViewDelegate>delegate;

- (void)setAvatarImage:(UIImage *)image;

@end
