#import <UIKit/UIKit.h>
#import "AbstractPostTableViewCell.h"

@class Post;

@interface PostTableViewCell : AbstractPostTableViewCell

@property(nonatomic, strong) Post *post;

- (void)configureCell:(Post *)post;

@end
