#import "BlogsTableViewCell.h"
#import "QuartzCore/QuartzCore.h"

@implementation BlogsTableViewCell

- (void) layoutSubviews
{
    [super layoutSubviews];
    CGRect cvf = self.contentView.frame;

    CGRect frame = CGRectMake(cvf.size.height,
                              self.textLabel.frame.origin.y,
                              cvf.size.width - cvf.size.height - 2 * 10,
                              self.textLabel.frame.size.height);
    self.textLabel.frame = frame;

    frame = CGRectMake(cvf.size.height,
                       self.detailTextLabel.frame.origin.y,
                       cvf.size.width - cvf.size.height - 2*10,
                       self.detailTextLabel.frame.size.height);
    self.detailTextLabel.frame = frame;
}

@end
