#import "WPBlogTableViewCell.h"

@implementation WPBlogTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    // Ignore the style argument, override with subtitle style.
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupCell];
    }
    return self;
}

- (void)setupCell
{
    if (!self.visibilitySwitch) {
        UISwitch *visibilitySwitch = [UISwitch new];

        self.editingAccessoryView = visibilitySwitch;
        self.visibilitySwitch = visibilitySwitch;
    }
}

@end
