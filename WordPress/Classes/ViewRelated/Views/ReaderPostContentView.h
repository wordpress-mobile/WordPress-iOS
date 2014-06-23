#import "WPContentViewBase.h"
#import "ReaderPost.h"

@class ReaderPostContentView;

@protocol ReaderPostContentViewDelegate <WPContentViewBaseDelegate>
@optional
- (void)postView:(ReaderPostContentView *)postView didReceiveFollowAction:(id)sender;
- (void)postView:(ReaderPostContentView *)postView didReceiveLikeAction:(id)sender;
- (void)postView:(ReaderPostContentView *)postView didReceiveReblogAction:(id)sender;
- (void)postView:(ReaderPostContentView *)postView didReceiveCommentAction:(id)sender;
@end

@interface ReaderPostContentView : WPContentViewBase

@property (nonatomic, weak) id<ReaderPostContentViewDelegate> delegate;
@property (nonatomic) BOOL shouldShowActions;

- (void)configurePost:(ReaderPost *)post;

@end
