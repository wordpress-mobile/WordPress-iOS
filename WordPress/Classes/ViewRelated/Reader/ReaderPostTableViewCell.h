#import <UIKit/UIKit.h>
#import "ReaderPost.h"
#import "WPTableViewCell.h"

@class ReaderPostContentView;

@interface ReaderPostTableViewCell : WPTableViewCell
@property (nonatomic, strong) UIImageView *avatarImageView;

+ (CGFloat)cellHeightForPost:(ReaderPost *)post withWidth:(CGFloat)width;
+ (ReaderPostTableViewCell *)cellForSubview:(UIView *)subview;

- (void)configureCell:(ReaderPost *)post;

@property (nonatomic, strong) ReaderPost *post;
@property (nonatomic, strong) ReaderPostContentView *postView;

@end
