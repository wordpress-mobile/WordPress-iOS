#import "WPContentView.h"

@class ReaderPostView;

@protocol ReaderPostViewDelegate <WPContentViewDelegate>
- (void)postView:(ReaderPostView *)postView didReceiveLikeAction:(id)sender;
- (void)postView:(ReaderPostView *)postView didReceiveReblogAction:(id)sender;
- (void)postView:(ReaderPostView *)postView didReceiveCommentAction:(id)sender;
@end


@interface ReaderPostView : WPContentView {
    
}

@property (nonatomic, strong) ReaderPost *post;
@property (nonatomic, weak) id <ReaderPostViewDelegate> delegate;

+ (CGFloat)heightForPost:(ReaderPost *)post withWidth:(CGFloat)width showFullContent:(BOOL)showFullContent;
+ (CGFloat)heightForPost:(ReaderPost *)post forSimpleSummaryWithWidth:(CGFloat)width;

- (id)initWithFrame:(CGRect)frame showFullContent:(BOOL)showFullContent;
- (id)initWithFrameForSimpleSummary:(CGRect)frame;
- (void)configurePost:(ReaderPost *)post;
- (void)setAvatar:(UIImage *)avatar;
- (void)setAvatarWithURL:(NSURL *)avatarURL;

@end
