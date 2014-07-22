#import <UIKit/UIKit.h>
#import "AbstractPostTableViewCell.h"

@class ReaderPost;

@interface ReaderPostTableViewCell : AbstractPostTableViewCell

@property (nonatomic, strong) ReaderPost *post;

- (void)configureCell:(ReaderPost *)post;

@end
