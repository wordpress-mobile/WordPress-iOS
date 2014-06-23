#import "WPContentViewBase.h"

@class WPRichContentView;

@protocol WPRichContentViewDelegate <WPContentViewBaseDelegate>
@optional
- (void)contentView:(UIView *)contentView didReceiveLinkAction:(id)sender;
- (void)contentView:(UIView *)contentView didReceiveImageLinkAction:(id)sender;
- (void)contentView:(UIView *)contentView didReceiveVideoLinkAction:(id)sender;
- (void)contentViewDidLoadAllMedia:(UIView *)contentView;
@end

@interface WPRichContentView : WPContentViewBase

@property (nonatomic, weak) id<WPRichContentViewDelegate> delegate;

@end
