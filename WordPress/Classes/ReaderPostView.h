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
- (id)initWithFrame:(CGRect)frame showFullContent:(BOOL)showFullContent;
- (void)configurePost:(ReaderPost *)post withWidth:(CGFloat)width;
- (void)setAvatar:(UIImage *)avatar;
- (void)setAvatarWithURL:(NSURL *)avatarURL;

@end
