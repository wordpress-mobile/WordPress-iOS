#import "WPTableViewCell.h"

CGFloat const WPTableViewFixedWidth = 600;

@implementation WPTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setClipsToBounds:YES];
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
    CGFloat width = self.superview.frame.size.width;
    // On iPad, add a margin around tables
    if (IS_IPAD && width > WPTableViewFixedWidth) {
        CGFloat x = (width - WPTableViewFixedWidth) / 2;
        // If origin.x is not equal to x we add the value.
        // This is a semi-fix / work around for an issue positioning cells on
        // iOS 8 when editing a table view and the delete button is visible.
        if (x != frame.origin.x) {
            frame.origin.x += x;
        } else {
            frame.origin.x = x;
        }
        frame.size.width = WPTableViewFixedWidth;
    }
    [super setFrame:frame];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // Need to set the origin again on iPad (for margins)
    CGFloat width = self.superview.frame.size.width;
    if (IS_IPAD && width > WPTableViewFixedWidth) {
        CGRect frame = self.frame;
        frame.origin.x = (width - WPTableViewFixedWidth) / 2;
        self.frame = frame;
    }
}

@end
