#import "StatsButtonCell.h"
#import "WPStyleGuide.h"

static CGFloat const StatsButtonHeight = 30.0f;

@implementation StatsButtonCell

+ (CGFloat)heightForRow {
    return StatsButtonHeight;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
//        self.buttons = [NSMutableArray array];
        _segmentedControl = [[UISegmentedControl alloc] initWithItems:@[]];
        [_segmentedControl addTarget:self action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
        [self addSubview:_segmentedControl];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
//    CGFloat widthPerButton = self.frame.size.width/self.buttons.count;
//    [self.buttons enumerateObjectsUsingBlock:^(UIButton *b, NSUInteger idx, BOOL *stop)
//    {
//        b.frame = (CGRect) {
//            .origin = CGPointMake(widthPerButton*idx, 0),
//            .size = CGSizeMake(widthPerButton, StatsButtonHeight)
//        };
//    }];
//
//    [self.buttons enumerateObjectsUsingBlock:^(UIButton *obj, NSUInteger idx, BOOL *stop) {
//        if (idx == _currentActiveButton) {
//            [obj setBackgroundColor:[WPStyleGuide newKidOnTheBlockBlue]];
//        } else {
//            [obj setBackgroundColor:[WPStyleGuide allTAllShadeGrey]];
//        }
//    }];
    self.segmentedControl.frame = self.bounds;
}

- (void)addSegmentWithTitle:(NSString *)title
{
//    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
//    [button setTitle:title.uppercaseString forState:UIControlStateNormal];
//    button.titleLabel.font = [WPStyleGuide subtitleFont];
//    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//    [button setBackgroundColor:[WPStyleGuide allTAllShadeGrey]];
//    [button addTarget:self action:@selector(activateButton:) forControlEvents:UIControlEventTouchUpInside];
//    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
//    button.tag = section;

//    [self.buttons addObject:button];
//    [self.contentView addSubview:button];
    NSUInteger index = self.segmentedControl.numberOfSegments;

    [self.segmentedControl insertSegmentWithTitle:title atIndex:index animated:NO];
}

- (void)activateButton:(UIButton *)sender {
//    _currentActiveButton = [self.buttons indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
//        return obj == sender;
//    }];
}

- (void)segmentChanged:(UISegmentedControl *)sender
{
    if ([self.delegate respondsToSelector:@selector(statsButtonCell:didSelectIndex:)]) {
        [self.delegate statsButtonCell:self didSelectIndex:sender.selectedSegmentIndex];
    }
}

- (void)prepareForReuse {
//    self.buttons = [NSMutableArray array];
    [self.segmentedControl removeAllSegments];
//    [self.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

@end
