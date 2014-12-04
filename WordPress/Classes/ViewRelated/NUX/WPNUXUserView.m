#import "WPNUXUserView.h"
#import "UIImageView+Gravatar.h"

@interface WPNUXUserView ()
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *usernameLabel;
@property (nonatomic, strong) UILabel *emailLabel;
@end

@implementation WPNUXUserView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupSubviews];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setupSubviews];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupSubviews];
    }
    return self;
}

- (void)setupSubviews
{
    /*
     We need to specify the bundle so Interface Builder can load the resources

     `-[UIImage imageNamed:` defaults to the main bundle, which in IB won't match
     the app's bundle.

     See https://stackoverflow.com/questions/24603232/xcode-6-ib-designable-not-loading-resources-from-bundle-in-interface-builder
     */
    UIImage *gravatarImage;
    if ([UIImage respondsToSelector:@selector(imageNamed:inBundle:compatibleWithTraitCollection:)]) {
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        gravatarImage = [UIImage imageNamed:@"gravatar" inBundle:bundle compatibleWithTraitCollection:self.traitCollection];
    } else {
        gravatarImage = [UIImage imageNamed:@"gravatar"];
    }

    self.avatarImageView = [[UIImageView alloc] initWithImage:gravatarImage];
    self.avatarImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.avatarImageView];

    self.usernameLabel = [UILabel new];
    self.usernameLabel.font = [WPStyleGuide tableviewTextFont];
    self.usernameLabel.textColor = [WPStyleGuide whisperGrey];
    self.usernameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.usernameLabel];

    self.emailLabel = [UILabel new];
    self.emailLabel.font = [WPStyleGuide subtitleFont];
    self.emailLabel.textColor = [WPStyleGuide whisperGrey];
    self.emailLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.emailLabel];

    [self setupConstraints];
}

- (void)setupConstraints
{
    NSDictionary *views = @{
                            @"avatar": self.avatarImageView,
                            @"email": self.emailLabel,
                            @"username": self.usernameLabel,
                            };

    NSLayoutConstraint *constraint;
    constraint = [NSLayoutConstraint constraintWithItem:self.avatarImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.avatarImageView attribute:NSLayoutAttributeHeight multiplier:1 constant:0];
    [self addConstraint:constraint];
    constraint = [NSLayoutConstraint constraintWithItem:self.avatarImageView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeading multiplier:1 constant:0];
    [self addConstraint:constraint];

    NSArray *constraints;
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[avatar]|" options:nil metrics:nil views:views];
    [self addConstraints:constraints];
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[avatar]-[username]-|" options:nil metrics:nil views:views];
    [self addConstraints:constraints];
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[avatar]-[email]-|" options:nil metrics:nil views:views];
    [self addConstraints:constraints];
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-2-[username]" options:NSLayoutFormatAlignAllTrailing metrics:nil views:views];
    [self addConstraints:constraints];
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[email]-2-|" options:NSLayoutFormatAlignAllTrailing metrics:nil views:views];
    [self addConstraints:constraints];
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(290, 41);
}

- (void)setUsername:(NSString *)username
{
    if (_username != username) {
        _username = username;
        self.usernameLabel.text = username;
    }
}

- (void)setEmail:(NSString *)email
{
    if (_email != email) {
        _email = email;
        self.emailLabel.text = email;
        [self.avatarImageView setImageWithGravatarEmail:email];
    }
}

@end
