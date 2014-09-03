#import "WPTableViewCell.h"

@class WPContentViewBase;

@interface AbstractPostTableViewCell : WPTableViewCell

@property(nonatomic, strong) WPContentViewBase *postView;

+ (instancetype)cellForSubview:(UIView *)subview;
- (WPContentViewBase *)configurePostView;

@end
