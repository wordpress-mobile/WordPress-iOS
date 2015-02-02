#import "ReaderHeaderView.h"
#import "WordPress-Swift.h"

const CGFloat ReaderHeaderViewAvatarSize = 32.0;
const CGFloat ReaderHeaderViewLabelHeight = 18.0;

@implementation ReaderHeaderView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self buildSubviews];
        [self configureConstraints];
    }
    return self;
}


#pragma mark - Public Methods

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(ReaderHeaderViewAvatarSize, ReaderHeaderViewAvatarSize);
}

- (UIImage *)avatarImage
{
    return self.avatarImageView.image;
}

- (void)setAvatarImage:(UIImage *)image
{
    self.avatarImageView.image = image;
}

- (NSString *)title
{
    return self.titleLabel.text;
}

- (void)setTitle:(NSString *)title
{
    self.titleLabel.text = title;
}

- (NSString *)subtitle
{
    return self.subtitleLabel.text;
}

- (void)setSubtitle:(NSString *)title
{
    self.subtitleLabel.text = title;
}


#pragma mark - Private Methods

- (void)buildSubviews
{
    _avatarImageView = [self newImageViewForAvatar];
    [self addSubview:_avatarImageView];

    _titleLabel = [self newLabelForTitle];
    [self addSubview:_titleLabel];

    _subtitleLabel = [self newLabelForSubtitle];
    [self addSubview:_subtitleLabel];
}

// Subclasses should have their own implementation and NOT call super if they
// modified the layout
- (void)configureConstraints
{
    NSDictionary *views   = NSDictionaryOfVariableBindings(_avatarImageView, _titleLabel, _subtitleLabel);
    NSDictionary *metrics = @{
                              @"avatarSize"       : @(ReaderHeaderViewAvatarSize),
                              @"labelHeight"      : @(ReaderHeaderViewLabelHeight)
                              };

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_avatarImageView(avatarSize)]"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_avatarImageView(avatarSize)]|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[_avatarImageView]-[_titleLabel]|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[_avatarImageView]-[_subtitleLabel]|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(-2)-[_subtitleLabel(labelHeight)][_titleLabel(labelHeight)]-(-2)-|"
                                                                 options:NSLayoutFormatAlignAllLeft
                                                                 metrics:metrics
                                                                   views:views]];

    [self setNeedsUpdateConstraints];
}


#pragma mark - Subview factories

- (UILabel *)newLabelForTitle
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.numberOfLines = 1;
    label.backgroundColor = [UIColor whiteColor];
    label.opaque = YES;
    label.textColor = [WPStyleGuide littleEddieGrey];
    label.font = [WPStyleGuide subtitleFont];
    label.adjustsFontSizeToFitWidth = NO;

    return label;
}

- (UILabel *)newLabelForSubtitle
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.numberOfLines = 1;
    label.backgroundColor = [UIColor whiteColor];
    label.opaque = YES;
    label.textColor = [WPStyleGuide allTAllShadeGrey];
    label.font = [WPStyleGuide subtitleFont];
    label.adjustsFontSizeToFitWidth = NO;

    return label;
}

- (CircularImageView *)newImageViewForAvatar
{
    CGRect avatarFrame = CGRectMake(0.0f, 0.0f, ReaderHeaderViewAvatarSize, ReaderHeaderViewAvatarSize);
    CircularImageView *imageView = [[CircularImageView alloc] initWithFrame:avatarFrame];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    return imageView;
}

@end
