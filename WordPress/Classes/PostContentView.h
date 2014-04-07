#import "BasePostContentView.h"

@class PostContentView;

@protocol PostContentViewDelegate <WPContentViewDelegate>

- (void)postView:(PostContentView *)postView didReceivePreviewAction:(id)sender;
- (void)postView:(PostContentView *)postView didReceiveShareAction:(id)sender;
- (void)postView:(PostContentView *)postView didReceiveDeleteAction:(id)sender;

@end

@interface PostContentView : BasePostContentView

@property (nonatomic, weak) id <PostContentViewDelegate> delegate;

@end
