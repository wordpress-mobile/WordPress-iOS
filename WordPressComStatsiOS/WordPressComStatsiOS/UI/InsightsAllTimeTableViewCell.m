#import "InsightsAllTimeTableViewCell.h"
#import "WPStyleGuide+Stats.h"
#import "NSBundle+StatsBundleHelper.h"

@implementation InsightsAllTimeTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    NSBundle *statsBundle = [NSBundle statsBundle];
    
    self.allTimePostsImage.image = [[UIImage imageNamed:@"icon-text-16x16" inBundle:statsBundle compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.allTimePostsImage.tintColor = [WPStyleGuide darkGrey];
    self.allTimePostsLabel.text = [NSLocalizedString(@"Posts", @"Stats Posts label") uppercaseStringWithLocale:[NSLocale currentLocale]];
    self.allTimePostsLabel.textColor = [WPStyleGuide darkGrey];
    self.allTimeViewsImage.image = [[UIImage imageNamed:@"icon-eye-16x16" inBundle:statsBundle compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.allTimeViewsImage.tintColor = [WPStyleGuide darkGrey];
    self.allTimeViewsLabel.text = [NSLocalizedString(@"Views", @"Stats Views label") uppercaseStringWithLocale:[NSLocale currentLocale]];
    self.allTimeViewsLabel.textColor = [WPStyleGuide darkGrey];
    self.allTimeVisitorsImage.image = [[UIImage imageNamed:@"icon-user-16x16" inBundle:statsBundle compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.allTimeVisitorsImage.tintColor = [WPStyleGuide darkGrey];
    self.allTimeVisitorsLabel.text = [NSLocalizedString(@"Visitors", @"Stats Visitors label") uppercaseStringWithLocale:[NSLocale currentLocale]];
    self.allTimeVisitorsLabel.textColor = [WPStyleGuide darkGrey];
    self.allTimeBestViewsImage.image = [[UIImage imageNamed:@"icon-trophy-16x16" inBundle:statsBundle compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.allTimeBestViewsImage.tintColor = [WPStyleGuide warningYellow];
    self.allTimeBestViewsLabel.text = [NSLocalizedString(@"Best Views Ever", @"Stats Best Views label") uppercaseStringWithLocale:[NSLocale currentLocale]];
    self.allTimeBestViewsLabel.textColor = [WPStyleGuide warningYellow];
}

@end
