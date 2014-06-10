#import "WPStatsTwoColumnCell.h"
#import "WPStatsTopPost.h"
#import "WPStatsViewByCountry.h"
#import "WPStatsTitleCountItem.h"
#import "WPImageSource.h"
#import "NSString+XMLExtensions.h"
#import "WPStatsGroup.h"
#import "WPStyleGuide.h"

static CGFloat const CellHeight = 30.0f;
static CGFloat const PaddingForCellSides = 10.0f;
static CGFloat const PaddingBetweenLeftAndRightLabels = 15.0f;
static CGFloat const PaddingImageText = 10.0f;
static CGFloat const RowIconWidth = 20.0f;

@interface WPStatsTwoColumnCell ()

@property (nonatomic, weak) UIView *separator;
@property (nonatomic, weak) UIView *leftView;
@property (nonatomic, weak) UIView *rightView;
@property (nonatomic, strong) WPStatsTitleCountItem *cellData;
@property (nonatomic, strong) NSNumberFormatter *numberFormatter;

@end


@implementation WPStatsTwoColumnCell

+ (CGFloat)heightForRow {
    return CellHeight;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        _linkEnabled = NO;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat yOrigin = [self yValueToCenterViewVertically:self.rightView];
    self.rightView.frame = (CGRect) {
        .origin = CGPointMake(self.frame.size.width - self.rightView.frame.size.width - PaddingForCellSides, yOrigin),
        .size = self.rightView.frame.size
    };

    yOrigin = [self yValueToCenterViewVertically:self.leftView];
    self.leftView.frame = (CGRect) {
        .origin = CGPointMake(PaddingForCellSides, yOrigin),
        .size = CGSizeMake(CGRectGetMinX(self.rightView.frame) - PaddingBetweenLeftAndRightLabels, self.leftView.frame.size.height)
    };
    
    if (self.separator) {
        self.separator.frame = (CGRect) {
            .origin = CGPointMake(CGRectGetMinX(self.leftView.frame), 0),
            .size = CGSizeMake(CGRectGetMaxX(self.rightView.frame) - CGRectGetMinX(self.leftView.frame), IS_RETINA ? 0.5f : 1.0f)
        };
    }
}

- (NSNumberFormatter *)numberFormatter {
    if (_numberFormatter) {
        return _numberFormatter;
    }
    _numberFormatter = [[NSNumberFormatter alloc] init];
    _numberFormatter.locale = [NSLocale currentLocale];
    _numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    _numberFormatter.usesGroupingSeparator = YES;
    return _numberFormatter;
}

- (void)insertData:(WPStatsTitleCountItem *)cellData {
    self.cellData = cellData;
    
    NSString *left = [cellData.title stringByDecodingXMLCharacters];
    NSString *right = [self.numberFormatter stringFromNumber:cellData.count];
    if ([cellData isKindOfClass:[WPStatsViewByCountry class]]) {
        [self setLeft:left withImageUrl:[(WPStatsViewByCountry *)cellData imageUrl] right:right titleCell:NO];
    } else if ([cellData isKindOfClass:[WPStatsGroup class]]) {
        self.selectionStyle = UITableViewCellSelectionStyleDefault;
        [self setLeft:left withImageUrl:[(WPStatsGroup *)cellData iconUrl] right:right titleCell:NO];
    } else {
        [self setLeft:left withImageUrl:nil right:right titleCell:NO];
    }
    
    self.linkEnabled = !!self.cellData.URL;
}

- (void)setLinkEnabled:(BOOL)linkEnabled {
    _linkEnabled = linkEnabled;
  
    UIColor *color = linkEnabled ? [WPStyleGuide baseDarkerBlue] : [WPStyleGuide whisperGrey];
    
    if (_linkEnabled) {
        self.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
    
    [self titleLabel].textColor = color;
}

- (UILabel *)titleLabel {
    return [self.leftView isKindOfClass:[UILabel class]] ? self.leftView : [self.leftView.subviews firstObject];
}

- (void)setLeft:(NSString *)left withImageUrl:(NSURL *)imageUrl right:(NSString *)right titleCell:(BOOL)titleCell {
    UIView *leftView;
    BOOL shouldShowImage = ([self.cellData isKindOfClass:[WPStatsViewByCountry class]] || [self.cellData isKindOfClass:[WPStatsGroup class]]);
    if (shouldShowImage) {
        leftView = [self createLeftViewWithTitle:left imageUrl:imageUrl titleCell:titleCell];
    } else {
        leftView = [self createLabelWithTitle:left titleCell:titleCell];
    }
    UIView *rightView = [self createLabelWithTitle:right titleCell:titleCell];
    self.leftView = leftView;
    self.rightView = rightView;
    [self.contentView addSubview:self.leftView];
    [self.contentView addSubview:self.rightView];
    
    [self layoutSubviews];
    
    if (!titleCell) {
        UIView *separator = [[UIView alloc] initWithFrame:(CGRect) {
            .origin = CGPointMake(CGRectGetMinX(self.leftView.frame), 0),
            .size = CGSizeMake(CGRectGetMaxX(self.rightView.frame) - CGRectGetMinX(self.leftView.frame), IS_RETINA ? 0.5f : 1.0f)
        }];
        separator.backgroundColor = [WPStyleGuide readGrey];
        self.separator = separator;
        [self addSubview:separator];
    }
}

- (UILabel *)createLabelWithTitle:(NSString *)title titleCell:(BOOL)titleCell {
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.textColor = [WPStyleGuide whisperGrey];
    titleLabel.text = title;
    titleLabel.backgroundColor = [UIColor whiteColor];
    titleLabel.opaque = YES;
    titleLabel.font = titleCell ? [WPStyleGuide subtitleFontBold] : [WPStyleGuide subtitleFont];
    [titleLabel sizeToFit];
    return titleLabel;
}

- (UIView *)createLeftViewWithTitle:(NSString *)title imageUrl:(NSURL *)imageUrl titleCell:(BOOL)titleCell {
    UIView *view = [[UIView alloc] init];
    UILabel *label = [self createLabelWithTitle:title titleCell:titleCell];
    [view addSubview:label];
    
    if (!titleCell) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, RowIconWidth, RowIconWidth)];
        imageView.backgroundColor = [WPStyleGuide readGrey];
        [view addSubview:imageView];

        label.frame = (CGRect) {
            .origin = CGPointMake(RowIconWidth + PaddingImageText, 0),
            .size = label.frame.size
        };

        if (imageUrl != nil) {
            [[WPImageSource sharedSource] downloadImageForURL:imageUrl withSuccess:^(UIImage *image) {
                imageView.image = image;
                imageView.backgroundColor = [UIColor clearColor];
            } failure:^(NSError *error) {
                DDLogWarn(@"Unable to download icon %@", error);
            }];
        }
    }

    view.frame = (CGRect) {
        .origin = view.frame.origin,
        .size = CGSizeMake(CGRectGetMaxX(label.frame), 20)
    };
    
    return view;
}

- (void)prepareForReuse {
    [self.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

- (CGFloat)yValueToCenterViewVertically:(UIView *)view {
    return ([self.class heightForRow] - view.frame.size.height)/2;
}

#pragma mark - UIAccessibility items

- (UIAccessibilityTraits)accessibilityTraits
{
    if (self.linkEnabled) {
        return UIAccessibilityTraitLink;
    }
    
    return [super accessibilityTraits];
}


@end
