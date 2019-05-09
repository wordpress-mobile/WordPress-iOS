@class AbstractPost;

@protocol PostActionSheetDelegate <NSObject>
@optional
- (void)showActionSheet:(nonnull AbstractPost *)post from:(nonnull UIView *)view;
@end
