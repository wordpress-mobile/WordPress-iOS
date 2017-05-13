#import "InsightsContributionGraphFooterView.h"
#import "WPStyleGuide+Stats.h"

@implementation InsightsContributionGraphFooterView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self.firstScaleSquare setBackgroundColor:[WPStyleGuide statsPostActivityLevel1CellBackground]];
    [self.secondScaleSquare setBackgroundColor:[WPStyleGuide statsPostActivityLevel2CellBackground]];
    [self.thirdScaleSquare setBackgroundColor:[WPStyleGuide statsPostActivityLevel3CellBackground]];
    [self.fourthScaleSquare setBackgroundColor:[WPStyleGuide statsPostActivityLevel4CellBackground]];
    [self.fifthScaleSquare setBackgroundColor:[WPStyleGuide statsPostActivityLevel5CellBackground]];
    
    [self.leftLabel setText:NSLocalizedString(@"LESS POSTS", @"Contribution graph footer label for left side of scale - less posts")];
    [self.rightLabel setText:NSLocalizedString(@"MORE POSTS", @"Contribution graph footer label for right side of scale - more posts")];
}

@end
