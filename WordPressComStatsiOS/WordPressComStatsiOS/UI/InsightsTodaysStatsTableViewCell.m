#import "InsightsTodaysStatsTableViewCell.h"
#import "NSBundle+StatsBundleHelper.h"
#import "WPStyleGuide+Stats.h"

@implementation InsightsTodaysStatsTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    NSBundle *statsBundle = [NSBundle statsBundle];
    
    self.todayViewsImage.image = [[UIImage imageNamed:@"icon-eye-16x16" inBundle:statsBundle compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.todayViewsImage.tintColor = [WPStyleGuide darkGrey];
    [self.todayViewsButton setTitle:[NSLocalizedString(@"Views", @"Stats Views label") uppercaseStringWithLocale:[NSLocale currentLocale]] forState:UIControlStateNormal];
    [self.todayViewsButton setTitleColor:[WPStyleGuide darkGrey] forState:UIControlStateNormal];

    self.todayVisitorsImage.image = [[UIImage imageNamed:@"icon-user-16x16" inBundle:statsBundle compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.todayVisitorsImage.tintColor = [WPStyleGuide darkGrey];
    [self.todayVisitorsButton setTitle:[NSLocalizedString(@"Visitors", @"Stats Visitors label") uppercaseStringWithLocale:[NSLocale currentLocale]] forState:UIControlStateNormal];
    [self.todayVisitorsButton setTitleColor:[WPStyleGuide darkGrey] forState:UIControlStateNormal];
    
    self.todayLikesImage.image = [[UIImage imageNamed:@"icon-star-16x16" inBundle:statsBundle compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.todayLikesImage.tintColor = [WPStyleGuide darkGrey];
    [self.todayLikesButton setTitle:[NSLocalizedString(@"Likes", @"Stats Likes label") uppercaseStringWithLocale:[NSLocale currentLocale]] forState:UIControlStateNormal];
    [self.todayLikesButton setTitleColor:[WPStyleGuide darkGrey] forState:UIControlStateNormal];
    
    self.todayCommentsImage.image = [[UIImage imageNamed:@"icon-comment-16x16" inBundle:statsBundle compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.todayCommentsImage.tintColor = [WPStyleGuide darkGrey];
    [self.todayCommentsButton setTitle:[NSLocalizedString(@"Comments", @"Stats Comments label") uppercaseStringWithLocale:[NSLocale currentLocale]] forState:UIControlStateNormal];
    [self.todayCommentsButton setTitleColor:[WPStyleGuide darkGrey] forState:UIControlStateNormal];
}

@end
