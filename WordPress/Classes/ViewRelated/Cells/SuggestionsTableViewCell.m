#import "SuggestionsTableViewCell.h"

const CGFloat SuggestionsTableViewCellAvatarSize = 32.0;

@implementation SuggestionsTableViewCell

- (void)awakeFromNib
{
    // Initialization code
    self.usernameLabel.textColor = [WPStyleGuide baseDarkerBlue];
    self.displayNameLabel.textColor = [WPStyleGuide littleEddieGrey];
    self.displayNameLabel.font = [WPStyleGuide subtitleFont];
}

@end
