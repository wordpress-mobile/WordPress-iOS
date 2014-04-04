#import "BasePostContentView.h"

@class ReaderPostView;

@protocol ReaderPostViewDelegate <WPContentViewDelegate>
- (void)postView:(ReaderPostView *)postView didReceiveLikeAction:(id)sender;
- (void)postView:(ReaderPostView *)postView didReceiveReblogAction:(id)sender;
- (void)postView:(ReaderPostView *)postView didReceiveCommentAction:(id)sender;
@end


@interface ReaderPostView : BasePostContentView

@property (nonatomic, strong) ReaderPost *post;
@property (nonatomic, weak) id <ReaderPostViewDelegate> delegate;

- (void)setAvatar:(UIImage *)avatar;

@end
