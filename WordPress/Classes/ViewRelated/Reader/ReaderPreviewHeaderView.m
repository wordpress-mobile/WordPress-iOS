#import "ReaderPreviewHeaderView.h"
#import "WordPress-Swift.h"
#import <WordPress-iOS-Shared/WPStyleGuide.h>

static const CGFloat LabelTopMargin = 20.0;
static const CGFloat LabelBottomMargin = 10.0;
static const CGFloat LabelBottomMarginIpad = 20.0;
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
    CGFloat bottomMargin = [self bottomMarginHeight];
    NSDictionary *views = NSDictionaryOfVariableBindings(_label);
    NSDictionary *metrics = @{@"viewWidth":@(WPTableViewFixedWidth),
                              @"topMargin":@(LabelTopMargin),
                              @"bottomMargin":@(bottomMargin),
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

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(topMargin@500)-[_label]-(bottomMargin@500)-|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
}

- (CGFloat)bottomMarginHeight
{
    return [UIDevice isPad] ? LabelBottomMarginIpad : LabelBottomMargin;
}

- (CGSize)intrinsicContentSize
{
    CGSize size = self.label.intrinsicContentSize;
    CGFloat viewHeight = size.height + [self bottomMarginHeight] + LabelTopMargin;
    return CGSizeMake(size.width, viewHeight);
}


- (CGSize)sizeThatFits:(CGSize)size
{
    CGFloat viewHeight = [self bottomMarginHeight] + LabelTopMargin;
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
