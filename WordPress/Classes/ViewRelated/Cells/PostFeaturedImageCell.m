#import "PostFeaturedImageCell.h"
#import "UIImageView+AFNetworkingExtra.h"

CGFloat const PostFeaturedImageCellMargin = 15.0f;

@interface PostFeaturedImageCell ()

//@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIActivityIndicatorView *activityView;

@end

@implementation PostFeaturedImageCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self configureSubviews];
    }
    return self;
}

- (void)configureSubviews
{
    CGRect contentFrame = self.contentView.frame;
    self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.clipsToBounds = YES;
    [self.contentView addSubview:self.imageView];

    self.activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    CGRect activityFrame = self.activityView.frame;
    CGFloat x = (contentFrame.size.width - activityFrame.size.width) / 2.0f;
    CGFloat y = (contentFrame.size.height - activityFrame.size.height) / 2.0f;
    activityFrame = CGRectMake(x, y, activityFrame.size.width, activityFrame.size.height);
    self.activityView.frame = activityFrame;
    self.activityView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    self.activityView.hidesWhenStopped = YES;
    [self.contentView addSubview:self.activityView];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (!self.imageView.hidden) {
        CGFloat x = PostFeaturedImageCellMargin;
        CGFloat y = PostFeaturedImageCellMargin;
        CGFloat w = CGRectGetWidth(self.contentView.frame) - (PostFeaturedImageCellMargin * 2);
        CGFloat h = CGRectGetHeight(self.contentView.frame) - (PostFeaturedImageCellMargin * 2);
        self.imageView.frame = CGRectMake(x, y, w, h);
    }
}

- (void)setImage:(UIImage *)image
{
    [self.imageView setImage:image];
    [self showLoadingSpinner:NO];
}

- (void)showLoadingSpinner:(BOOL)showSpinner
{
    if (showSpinner) {
        [self.activityView startAnimating];
    } else {
        [self.activityView stopAnimating];
    }
    self.imageView.hidden = showSpinner;
    self.textLabel.text = @"";
}

@end
