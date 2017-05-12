#import "InsightsPostingActivityTableViewCell.h"
#import "StatsStreakItem.h"
#import "WPStyleGuide+Stats.h"

@implementation InsightsPostingActivityTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];    
    [self.contributionGraphLeft setDelegate:self];
    [self.contributionGraphCenter setDelegate:self];
    [self.contributionGraphRight setDelegate:self];
}

- (void)doneSettingProperties
{
    if (self.selectable) {
        self.selectionStyle = UITableViewCellSelectionStyleDefault;
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        self.rightConstraint.constant = 20.0f;
    }
}

#pragma mark - WPStatsContributionGraphDelegate methods

- (NSUInteger)numberOfGrades
{
    return 5;
}

- (UIColor *)colorForGrade:(NSUInteger)grade
{
    switch (grade) {
        case 0:
            return [WPStyleGuide statsPostActivityLevel1CellBackground];
            break;
        case 1:
            return [WPStyleGuide statsPostActivityLevel2CellBackground];
            break;
        case 2:
            return [WPStyleGuide statsPostActivityLevel3CellBackground];
            break;
        case 3:
            return [WPStyleGuide statsPostActivityLevel4CellBackground];
            break;
        case 4:
            return [WPStyleGuide statsPostActivityLevel5CellBackground];
            break;
        default:
            return [WPStyleGuide statsPostActivityLevel1CellBackground];
            break;
    }
}

@end
