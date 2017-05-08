#import "StatsBorderedCellBackgroundView.h"
#import "WPStyleGuide+Stats.h"


@interface StatsBorderedCellBackgroundView ()

@property (nonatomic, strong) UIView *theBoxView;
@property (nonatomic, strong) UIView *bottomDividerView;
@property (nonatomic, strong) UIView *topDividerView;

@end


@implementation StatsBorderedCellBackgroundView


- (instancetype)initWithFrame:(CGRect)frame andSelected:(BOOL)selected
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [WPStyleGuide itsEverywhereGrey];
        _topBorderDarkEnabled = NO;
        _bottomBorderEnabled = YES;
        
        _theBoxView = [[UIView alloc] initWithFrame:CGRectZero];
        _theBoxView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _theBoxView.backgroundColor = [UIColor colorWithRed:210.0/255.0 green:222.0/255.0 blue:238.0/255.0 alpha:1.0];
        [self addSubview:_theBoxView];
        
        _contentBackgroundView = [[UIView alloc] initWithFrame:CGRectZero];
        _contentBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _contentBackgroundView.backgroundColor = selected ? [UIColor whiteColor] : [WPStyleGuide statsUltraLightGray];
        [self addSubview:_contentBackgroundView];
        
        _bottomDividerView = [[UIView alloc] initWithFrame:CGRectZero];
        _bottomDividerView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _bottomDividerView.backgroundColor = [WPStyleGuide statsLightGray];
        [self addSubview:_bottomDividerView];

        _topDividerView = [[UIView alloc] initWithFrame:CGRectZero];
        _topDividerView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _topDividerView.backgroundColor = [WPStyleGuide statsMediumGray];
        _topDividerView.hidden = YES;
        [self addSubview:_topDividerView];
    }
    
    return self;
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat borderSidePadding = StatsVCHorizontalOuterPadding - 1.0f;
    CGFloat bottomPadding = self.bottomBorderEnabled ? 1.0f : 0.0f;
    CGFloat sidePadding = StatsVCHorizontalOuterPadding;
    
    self.theBoxView.frame = CGRectMake(borderSidePadding, 0.0, CGRectGetWidth(self.frame) - 2 * borderSidePadding, CGRectGetHeight(self.frame));
    self.contentBackgroundView.frame = CGRectMake(sidePadding, 0.0, CGRectGetWidth(self.frame) - 2 * sidePadding, CGRectGetHeight(self.frame));
    self.bottomDividerView.frame = CGRectMake(CGRectGetMinX(self.contentBackgroundView.frame), CGRectGetHeight(self.frame) - bottomPadding, CGRectGetWidth(self.contentBackgroundView.frame), bottomPadding);
    self.topDividerView.frame = CGRectMake(CGRectGetMinX(self.contentBackgroundView.frame), 0.0f, CGRectGetWidth(self.contentBackgroundView.frame), 1.0f);
}


- (void)setTopBorderDarkEnabled:(BOOL)topBorderDarkEnabled
{
    _topBorderDarkEnabled = topBorderDarkEnabled;
    
    self.topDividerView.hidden = !topBorderDarkEnabled;
}

- (void)setBottomBorderEnabled:(BOOL)bottomBorderEnabled
{
    _bottomBorderEnabled = bottomBorderEnabled;
    
    [self setNeedsLayout];
}


@end
