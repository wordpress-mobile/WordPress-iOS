#import "StatsTableSectionHeaderView.h"
#import "WPStyleGuide+Stats.h"

@interface StatsTableSectionHeaderView ()

@property (nonatomic, strong) UIView *theBoxView;

@end

@implementation StatsTableSectionHeaderView


- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self) {
        self.contentView.backgroundColor = [WPStyleGuide statsLightGray];
        
        _theBoxView = [[UIView alloc] initWithFrame:CGRectZero];
        _theBoxView.backgroundColor = [UIColor colorWithRed:210.0/255.0 green:222.0/255.0 blue:238.0/255.0 alpha:1.0];
        [self.contentView addSubview:_theBoxView];
    }
    return self;
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Need to set the origin again on iPad (for margins)
    CGFloat borderSidePadding = StatsVCHorizontalOuterPadding - 1.0f; // Just to the left of the container
    self.theBoxView.frame = CGRectMake(borderSidePadding, self.isFooter ? -1.0f : 0.0f, CGRectGetWidth(self.frame) - 2.0 * borderSidePadding, 1.0f);
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.footer = NO;
}


@end
