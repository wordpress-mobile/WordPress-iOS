#import "StatsStandardBorderedTableViewCell.h"
#import "WPStyleGuide+Stats.h"
#import "StatsBorderedCellBackgroundView.h"

@implementation StatsStandardBorderedTableViewCell

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.backgroundView.frame = self.bounds;
    self.selectedBackgroundView.frame = self.bounds;
}


- (void)awakeFromNib
{
    [super awakeFromNib];
    
    _bottomBorderEnabled = YES;
    _topBorderDarkEnabled = NO;
    self.backgroundView = [[StatsBorderedCellBackgroundView alloc] initWithFrame:self.bounds andSelected:YES];
    self.selectedBackgroundView = [[StatsBorderedCellBackgroundView alloc] initWithFrame:self.bounds andSelected:NO];
}


- (void)setBottomBorderEnabled:(BOOL)bottomBorderEnabled
{
    _bottomBorderEnabled = bottomBorderEnabled;
    
    StatsBorderedCellBackgroundView *backgroundView = (StatsBorderedCellBackgroundView *)self.backgroundView;
    StatsBorderedCellBackgroundView *selectedBackgroundView = (StatsBorderedCellBackgroundView *)self.selectedBackgroundView;
    backgroundView.bottomBorderEnabled = bottomBorderEnabled;
    selectedBackgroundView.bottomBorderEnabled = bottomBorderEnabled;
    
    [self setNeedsLayout];
}


- (void)setTopBorderDarkEnabled:(BOOL)topBorderDarkEnabled
{
    _topBorderDarkEnabled = topBorderDarkEnabled;

    StatsBorderedCellBackgroundView *backgroundView = (StatsBorderedCellBackgroundView *)self.backgroundView;
    StatsBorderedCellBackgroundView *selectedBackgroundView = (StatsBorderedCellBackgroundView *)self.selectedBackgroundView;
    backgroundView.topBorderDarkEnabled = topBorderDarkEnabled;
    selectedBackgroundView.topBorderDarkEnabled = topBorderDarkEnabled;
}

@end
