#import "WPContentView.h"

typedef NS_ENUM(NSUInteger, ReaderPostContentMode) {
    ReaderPostContentModeFullContent,
    ReaderPostContentModeSummary,
    ReaderPostContentModeSimpleSummary
};

@class ReaderPostView;

@protocol ReaderPostViewDelegate <WPContentViewDelegate>
- (void)postView:(ReaderPostView *)postView didReceiveLikeAction:(id)sender;
- (void)postView:(ReaderPostView *)postView didReceiveReblogAction:(id)sender;
- (void)postView:(ReaderPostView *)postView didReceiveCommentAction:(id)sender;
@end


@interface ReaderPostView : WPContentView 

@property (nonatomic, strong) ReaderPost *post;
@property (nonatomic, weak) id <ReaderPostViewDelegate> delegate;

+ (CGFloat)heightForPost:(ReaderPost *)post withWidth:(CGFloat)width forContentMode:(ReaderPostContentMode)contentMode;

- (id)initWithFrame:(CGRect)frame contentMode:(ReaderPostContentMode)contentMode;
- (void)configurePost:(ReaderPost *)post;
- (void)setAvatar:(UIImage *)avatar;
- (void)setAvatarWithURL:(NSURL *)avatarURL;

@end
