#import <UIKit/UIKit.h>
#import "AbstractPostTableViewCell.h"

@class ReaderPost;

@interface ReaderPostTableViewCell : AbstractPostTableViewCell

@property (nonatomic, strong) ReaderPost *post;

+ (ReaderPostTableViewCell *)cellForSubview:(UIView *)subview;
- (void)configureCell:(ReaderPost *)post;

@end
