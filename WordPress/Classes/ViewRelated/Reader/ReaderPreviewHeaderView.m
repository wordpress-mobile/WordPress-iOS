#import "ReaderPreviewHeaderView.h"
#import "WordPress-Swift.h"
#import <WordPress-iOS-Shared/WPStyleGuide.h>

static const CGFloat LableVerticalMargin = 20.0;
static const CGFloat LabelHorizontalMargin = 8.0;

@interface ReaderPreviewHeaderView ()
@property (nonatomic, strong) UILabel *label;
@end

@implementation ReaderPreviewHeaderView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [WPStyleGuide itsEverywhereGrey];
        [self buildSubviews];
        [self configureConstraints];
    }
    return self;
}

- (void)buildSubviews
{
    [self buildLabel];
}

- (void)buildLabel
{
    self.label = [[UILabel alloc] init];
    self.label.translatesAutoresizingMaskIntoConstraints = NO;
    self.label.numberOfLines = 0;
    self.label.backgroundColor = [UIColor clearColor];
    self.label.font = [WPFontManager openSansRegularFontOfSize:14.0];
    self.label.textColor = [WPStyleGuide littleEddieGrey];
    self.label.textAlignment = NSTextAlignmentCenter;

    [self addSubview:self.label];
}

- (void)configureConstraints
{
    NSInteger viewWidth = (NSInteger)WPTableViewFixedWidth;
    NSDictionary *views = NSDictionaryOfVariableBindings(_label);
    NSDictionary *metrics = @{@"viewWidth":@(viewWidth),
                              @"verticalMargin":@(LableVerticalMargin),
                              @"horizontalMargin":@(LabelHorizontalMargin)};

    if ([UIDevice isPad]) {
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.label
                                                         attribute:NSLayoutAttributeCenterX
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeCenterX
                                                        multiplier:1.0
                                                          constant:0]];

        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[_label(viewWidth)]"
                                                                     options:0
                                                                     metrics:metrics
                                                                       views:views]];

    } else {
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(horizontalMargin)-[_label]-(horizontalMargin)-|"
                                                                     options:0
                                                                     metrics:metrics
                                                                       views:views]];
    }

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(verticalMargin@500)-[_label]-(verticalMargin@500)-|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
}

- (CGSize)intrinsicContentSize
{
    CGSize size = self.label.intrinsicContentSize;
    CGFloat viewHeight = size.height + (LableVerticalMargin * 2.0);
    return CGSizeMake(size.width, viewHeight);
}


- (CGSize)sizeThatFits:(CGSize)size
{
    CGFloat viewHeight = (LableVerticalMargin * 2.0);
    CGFloat labelWidth = [UIDevice isPad] ? WPTableViewFixedWidth : (size.width - (LabelHorizontalMargin * 2));

    CGSize labelSize = [self.label sizeThatFits:CGSizeMake(labelWidth, CGFLOAT_HEIGHT_UNKNOWN)];
    viewHeight += labelSize.height;
    size = CGSizeMake(size.width, viewHeight);
    return size;
}

- (NSString *)text
{
    return self.label.text;
}

- (void)setText:(NSString *)text
{
    self.label.text = text;
}

@end
