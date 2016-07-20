#import "PostFeaturedImageCell.h"
#import "UIImageView+AFNetworkingExtra.h"

CGFloat const PostFeaturedImageCellMargin = 15.0f;

@interface PostFeaturedImageCell ()

@property (nonatomic, strong) UIImageView *featuredImageView;
@property (nonatomic, strong) UIActivityIndicatorView *activityView;

@end

@implementation PostFeaturedImageCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupSubviews];
    }
    return self;
}

- (void)setupSubviews
{
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:imageView];

    UILayoutGuide *readableGuide = self.contentView.readableContentGuide;
    [NSLayoutConstraint activateConstraints:@[
                                              [imageView.leadingAnchor constraintEqualToAnchor:readableGuide.leadingAnchor],
                                              [imageView.trailingAnchor constraintEqualToAnchor:readableGuide.trailingAnchor],
                                              [imageView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:PostFeaturedImageCellMargin],
                                              [imageView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-PostFeaturedImageCellMargin]
                                              ]];
    _featuredImageView = imageView;

    CGRect contentFrame = self.contentView.frame;
    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    CGRect activityFrame = activityView.frame;
    CGFloat x = (contentFrame.size.width - activityFrame.size.width) / 2.0f;
    CGFloat y = (contentFrame.size.height - activityFrame.size.height) / 2.0f;
    activityFrame = CGRectMake(x, y, activityFrame.size.width, activityFrame.size.height);
    activityView.frame = activityFrame;
    activityView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    activityView.hidesWhenStopped = YES;
    [self.contentView addSubview:activityView];
    _activityView = activityView;
}

- (void)setImage:(UIImage *)image
{
    [self.featuredImageView setImage:image];
    [self showLoadingSpinner:NO];
}

- (void)showLoadingSpinner:(BOOL)showSpinner
{
    if (showSpinner) {
        [self.activityView startAnimating];
    } else {
        [self.activityView stopAnimating];
    }
    self.featuredImageView.hidden = showSpinner;
    self.textLabel.text = @"";
}

@end
