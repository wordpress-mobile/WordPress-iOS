#import "PostAttributionView.h"
#import "WPStyleGuide.h"
#import "Post.h"

@interface PostAttributionView ()

@property(nonatomic, strong) UILabel *postStatusLabel;

@end

@implementation PostAttributionView

#pragma mark - LifeCycle Methods

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self hideAttributionButton:YES];

        _postStatusLabel = [self labelForPostStatus];
        [self addSubview:_postStatusLabel];
    }
    return self;
}

#pragma mark - Subview factories

- (UILabel *)labelForPostStatus
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.numberOfLines = 1;
    label.backgroundColor = [UIColor whiteColor];
    label.opaque = YES;
    label.textColor = [WPStyleGuide fireOrange];
    label.font = [WPStyleGuide subtitleFont];
    label.adjustsFontSizeToFitWidth = NO;

    return label;
}

@end
