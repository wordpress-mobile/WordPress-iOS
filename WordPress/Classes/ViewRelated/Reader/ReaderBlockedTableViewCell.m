#import "ReaderBlockedTableViewCell.h"
#import "WPStyleGuide.h"

static const CGFloat RBTVCHorizontalOuterPadding = 8.0f;
static const CGFloat RBTVCVerticalOuterPadding = 16.0f;
static const CGFloat RBTVCHorizontalInnerPadding = 8.0f;

@interface ReaderBlockedTableViewCell()

@property (nonatomic, strong) UIView *sideBorderView;
@property (nonatomic, strong) UIView *labelBackgroundView;
@property (nonatomic, strong) UILabel *label;

@end


@implementation ReaderBlockedTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _sideBorderView = [[UIView alloc] init];
        _sideBorderView.translatesAutoresizingMaskIntoConstraints = NO;
        _sideBorderView.backgroundColor = [UIColor colorWithRed:210.0/255.0 green:222.0/255.0 blue:238.0/255.0 alpha:1.0];
        [self.contentView addSubview:_sideBorderView];

        _labelBackgroundView = [[UIView alloc] init];
        _labelBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
        _labelBackgroundView.backgroundColor = [UIColor whiteColor];
        [self.contentView addSubview:_labelBackgroundView];

        _label = [[UILabel alloc] init];
        _label.translatesAutoresizingMaskIntoConstraints = NO;
        _label.backgroundColor = [UIColor whiteColor];
        _label.numberOfLines = 2;
        _label.adjustsFontSizeToFitWidth = NO;
        _label.font = [WPStyleGuide subtitleFont];
        _label.textColor = [WPStyleGuide whisperGrey];

        [self.contentView addSubview:_label];

        self.backgroundColor = [WPStyleGuide itsEverywhereGrey];

        [self configureConstraints];
    }

    return self;
}

- (void)configureConstraints
{
    NSNumber *borderSidePadding = IS_IPHONE ? @(RBTVCHorizontalOuterPadding - 1) : @0; // Just to the left of the container
    NSNumber *borderBottomPadding = @(RBTVCVerticalOuterPadding - 1);
    NSNumber *bottomPadding = @(RBTVCVerticalOuterPadding);
    NSNumber *labelBackgroundPadding = IS_IPHONE ? @(RBTVCHorizontalOuterPadding) : @0;
    NSNumber *labelPadding = IS_IPHONE ? @(RBTVCHorizontalOuterPadding + RBTVCHorizontalInnerPadding) : @(RBTVCHorizontalInnerPadding);
    NSDictionary *metrics =  @{@"borderSidePadding":borderSidePadding,
                               @"borderBottomPadding":borderBottomPadding,
                               @"labelBackgroundPadding":labelBackgroundPadding,
                               @"labelPadding":labelPadding,
                               @"bottomPadding":bottomPadding};

    UIView *contentView = self.contentView;
    NSDictionary *views = NSDictionaryOfVariableBindings(contentView, _sideBorderView, _labelBackgroundView, _label);
    // Border View
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(borderSidePadding)-[_sideBorderView]-(borderSidePadding)-|"
                                                                             options:0
                                                                             metrics:metrics
                                                                               views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_sideBorderView]-(borderBottomPadding)-|"
                                                                             options:0
                                                                             metrics:metrics
                                                                               views:views]];

    // Label Background
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(labelBackgroundPadding)-[_labelBackgroundView]-(labelBackgroundPadding)-|"
                                                                             options:0
                                                                             metrics:metrics
                                                                               views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_labelBackgroundView]-(bottomPadding)-|"
                                                                             options:0
                                                                             metrics:metrics
                                                                               views:views]];

    // Label
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(labelPadding)-[_label]-(labelPadding)-|"
                                                                             options:0
                                                                             metrics:metrics
                                                                               views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_label]-(bottomPadding)-|"
                                                                             options:0
                                                                             metrics:metrics
                                                                               views:views]];
}

- (void)setLabelText:(NSString *)string
{
    self.label.text = string;
}

- (void)setLabelAttributedText:(NSAttributedString *)attrString
{
    self.label.attributedText = attrString;
}

@end
