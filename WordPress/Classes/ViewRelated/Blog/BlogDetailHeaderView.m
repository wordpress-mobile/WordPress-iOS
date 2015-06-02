#import "BlogDetailHeaderView.h"
#import "Blog.h"
#import "UIImageView+Gravatar.h"
#import <WordPress-iOS-Shared/WPFontManager.h>

const CGFloat BlogDetailHeaderViewBlavatarSize = 40.0;
const CGFloat BlogDetailHeaderViewLabelHeight = 20.0;
const CGFloat BlogDetailHeaderViewLabelHorizontalPadding = 10.0;

@interface BlogDetailHeaderView ()

@property (nonatomic, strong) UIImageView *blavatarImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;

@end

@implementation BlogDetailHeaderView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _blavatarImageView = [self newImageViewForBlavatar];
        [self addSubview:_blavatarImageView];

        _titleLabel = [self newLabelForTitle];
        [self addSubview:_titleLabel];

        _subtitleLabel = [self newLabelForSubtitle];
        [self addSubview:_subtitleLabel];

        [self configureConstraints];
    }
    return self;
}

#pragma mark - Public Methods

- (void)setBlog:(Blog *)blog
{
    [self.blavatarImageView setImageWithBlavatarUrl:blog.blavatarUrl];

    // if the blog name is missing, we want to show the blog displayURL instead
    [self.titleLabel setText:((blog.blogName && !blog.blogName.isEmpty) ? blog.blogName : blog.displayURL)];
    [self.subtitleLabel setText:blog.displayURL];
}

#pragma mark - Private Methods

- (void)configureConstraints
{
    NSDictionary *views = NSDictionaryOfVariableBindings(_blavatarImageView, _titleLabel, _subtitleLabel);
    NSDictionary *metrics = @{@"blavatarSize": @(BlogDetailHeaderViewBlavatarSize),
                              @"labelHeight":@(BlogDetailHeaderViewLabelHeight),
                              @"labelHorizontalPadding": @(BlogDetailHeaderViewLabelHorizontalPadding)};
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_blavatarImageView(blavatarSize)]|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_blavatarImageView(blavatarSize)]-labelHorizontalPadding-[_titleLabel]|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_blavatarImageView(blavatarSize)]-labelHorizontalPadding-[_subtitleLabel]|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_titleLabel(labelHeight)][_subtitleLabel(labelHeight)]"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    [super setNeedsUpdateConstraints];
}

#pragma mark - Subview factories

- (UILabel *)newLabelForTitle
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.numberOfLines = 1;
    label.backgroundColor = [UIColor clearColor];
    label.opaque = YES;
    label.textColor = [WPStyleGuide littleEddieGrey];
    label.font = [WPFontManager openSansRegularFontOfSize:16.0];
    label.adjustsFontSizeToFitWidth = NO;

    return label;
}

- (UILabel *)newLabelForSubtitle
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.numberOfLines = 1;
    label.backgroundColor = [UIColor clearColor];
    label.opaque = YES;
    label.textColor = [WPStyleGuide allTAllShadeGrey];
    label.font = [WPFontManager openSansItalicFontOfSize:12.0];
    label.adjustsFontSizeToFitWidth = NO;

    return label;
}

- (UIImageView *)newImageViewForBlavatar
{
    CGRect blavatarFrame = CGRectMake(0.0f, 0.0f, BlogDetailHeaderViewBlavatarSize, BlogDetailHeaderViewBlavatarSize);
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:blavatarFrame];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.layer.borderColor = [[UIColor whiteColor] CGColor];
    imageView.layer.borderWidth = 1.0;
    return imageView;
}

@end
