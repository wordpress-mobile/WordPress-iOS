#import "ReaderPostHeaderView.h"
#import "WordPress-Swift.h"

const CGFloat PostHeaderViewAvatarSize = 32.0;
const CGFloat PostHeaderViewLabelHeight = 18.0;

@interface ReaderPostHeaderView()

@property (nonatomic, strong) CircularImageView *avatarImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;

@end

@implementation ReaderPostHeaderView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _avatarImageView = [self imageViewForAvatar];
        [self addSubview:_avatarImageView];

        _titleLabel = [self labelForTitle];
        [self addSubview:_titleLabel];

        _subtitleLabel = [self labelForSubtitle];
        [self addSubview:_subtitleLabel];

        [self configureConstraints];
    }
    return self;
}

#pragma mark - Public Methods

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(PostHeaderViewAvatarSize, PostHeaderViewAvatarSize);
}

- (void)setAvatarImage:(UIImage *)image
{
    self.avatarImageView.image = image;
}

- (void)setTitle:(NSString *)title
{
    self.titleLabel.text = title;
}

- (void)setSubtitle:(NSString *)title
{
    self.subtitleLabel.text = title;
}

#pragma mark - Private Methods

- (void)configureConstraints
{
    NSDictionary *views = NSDictionaryOfVariableBindings(_avatarImageView, _titleLabel, _subtitleLabel);
    NSDictionary *metrics = @{@"avatarSize": @(PostHeaderViewAvatarSize),
                              @"labelHeight":@(PostHeaderViewLabelHeight)};
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
    [super setNeedsUpdateConstraints];
}


#pragma mark - Subview factories

- (UILabel *)labelForTitle
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

- (UILabel *)labelForSubtitle
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

- (CircularImageView *)imageViewForAvatar
{
    CGRect avatarFrame = CGRectMake(0.0f, 0.0f, PostHeaderViewAvatarSize, PostHeaderViewAvatarSize);
    CircularImageView *imageView = [[CircularImageView alloc] initWithFrame:avatarFrame];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    return imageView;
}

@end
