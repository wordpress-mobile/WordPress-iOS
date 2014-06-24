#import <UIKit/UIKit.h>
#import "WPTableViewCell.h"

@class ReaderPost;
@class ReaderPostContentView;

@interface ReaderPostTableViewCell : WPTableViewCell

@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) ReaderPost *post;
@property (nonatomic, strong) ReaderPostContentView *postView;

+ (ReaderPostTableViewCell *)cellForSubview:(UIView *)subview;
- (void)configureCell:(ReaderPost *)post;

@end
