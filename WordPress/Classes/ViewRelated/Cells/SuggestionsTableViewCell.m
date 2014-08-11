#import "SuggestionsTableViewCell.h"

@implementation SuggestionsTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    return self;
}

- (void)awakeFromNib
{
    // Initialization code
    self.username.textColor = [WPStyleGuide baseDarkerBlue];
    self.displayName.textColor = [WPStyleGuide littleEddieGrey];
    self.displayName.font = [WPStyleGuide subtitleFont];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

@end
