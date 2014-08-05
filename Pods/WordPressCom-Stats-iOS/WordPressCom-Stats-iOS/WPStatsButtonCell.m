#import "WPStatsButtonCell.h"
#import "WPStyleGuide.h"

static CGFloat const StatsButtonHeight = 50.0f;

@implementation WPStatsButtonCell

+ (CGFloat)heightForRow {
    return StatsButtonHeight;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        _segmentedControl = [[UISegmentedControl alloc] initWithItems:@[]];
        _segmentedControl.tintColor = [WPStyleGuide wordPressBlue];
        [_segmentedControl setTitleTextAttributes:@{NSFontAttributeName : [WPStyleGuide subtitleFont]} forState:UIControlStateNormal];
        [_segmentedControl addTarget:self action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
        [self addSubview:_segmentedControl];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect rect = self.bounds;
    rect = CGRectInset(rect, 10.0, 10.0);
    
    self.segmentedControl.frame = rect;
}

- (void)addSegmentWithTitle:(NSString *)title
{
    NSUInteger index = self.segmentedControl.numberOfSegments;

    [self.segmentedControl insertSegmentWithTitle:[title uppercaseStringWithLocale:[NSLocale currentLocale]] atIndex:index animated:NO];
}

- (void)segmentChanged:(UISegmentedControl *)sender
{
    if ([self.delegate respondsToSelector:@selector(statsButtonCell:didSelectIndex:)]) {
        [self.delegate statsButtonCell:self didSelectIndex:sender.selectedSegmentIndex];
    }
}

- (void)prepareForReuse {
    [self.segmentedControl removeAllSegments];
}

@end
