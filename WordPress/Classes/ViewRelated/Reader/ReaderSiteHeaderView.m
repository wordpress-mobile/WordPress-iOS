#import "ReaderSiteHeaderView.h"
#import "ReaderPostAttributionView.h"
#import <WordPress-iOS-Shared/WPStyleGuide.h>
#import "WordPress-Swift.h"

static const CGFloat StandardMargin = 8.0;
static const CGFloat BorderHeight = 1.0;

@interface ReaderSiteHeaderView ()
@property (nonatomic, strong) ReaderPostAttributionView *attributionView;
@property (nonatomic, strong) UIView *borderView;
@end

@implementation ReaderSiteHeaderView

- (void)dealloc
{
    self.attributionView.delegate = nil;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self buildSubviews];
        [self configureConstraints];
    }
    return self;
}

- (void)buildSubviews
{
    [self buildAttributionView];
    [self buildBorderView];
}

- (void)buildAttributionView
{
    self.attributionView = [[ReaderPostAttributionView alloc] init];
    self.attributionView.translatesAutoresizingMaskIntoConstraints = NO;
    self.attributionView.avatarImageView.shouldRoundCorners = NO;
    [self addSubview:self.attributionView];
}

- (void)buildBorderView
{
    self.borderView = [[UIView alloc] init];
    self.borderView.translatesAutoresizingMaskIntoConstraints = NO;
    self.borderView.backgroundColor = [WPStyleGuide readGrey];

    [self addSubview:self.borderView];
}

- (void)configureConstraints
{
    NSDictionary *views = NSDictionaryOfVariableBindings(_attributionView, _borderView);
    NSDictionary *metrics = @{@"margin":@(StandardMargin),
                              @"borderHeight":@(BorderHeight)};

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(margin)-[_attributionView]-(margin)-|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_borderView]|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(margin)-[_attributionView]-(margin)-[_borderView(borderHeight)]|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];

}

@end
