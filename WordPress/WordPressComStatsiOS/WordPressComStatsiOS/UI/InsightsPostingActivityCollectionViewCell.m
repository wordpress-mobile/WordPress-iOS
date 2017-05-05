#import "InsightsPostingActivityCollectionViewCell.h"
#import "WPStyleGuide+Stats.h"

static NSString *const DidTouchPostActivityDateNotification = @"DidTouchPostActivityDate";

@implementation InsightsPostingActivityCollectionViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self.contributionGraph setDelegate:self];
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

- (void)dateTapped:(NSDictionary *)dict
{
    [[NSNotificationCenter defaultCenter] postNotificationName:DidTouchPostActivityDateNotification
                                                        object:self
                                                      userInfo:dict];
}

@end
