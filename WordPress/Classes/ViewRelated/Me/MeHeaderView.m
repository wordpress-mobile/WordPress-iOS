#import "MeHeaderView.h"
#import "Blog.h"
#import "UIImageView+Gravatar.h"
#import "WordPress-Swift.h"

const CGFloat MeHeaderViewHeight = 154;
const CGFloat MeHeaderViewGravatarSize = 64.0;
const CGFloat MeHeaderViewLabelHeight = 20.0;
const CGFloat MeHeaderViewVerticalMargin = 20.0;
const CGFloat MeHeaderViewVerticalSpacing = 10.0;
const NSTimeInterval MeHeaderViewMinimumPressDuration = 0.001;

@interface MeHeaderView ()

@property (nonatomic, strong) UIImageView *gravatarImageView;
@property (nonatomic, strong) UILabel *displayNameLabel;
@property (nonatomic, strong) UILabel *usernameLabel;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

@end

@implementation MeHeaderView

- (instancetype)init
{
    CGRect frame = CGRectMake(0, 0, 0, MeHeaderViewHeight);
    return [self initWithFrame:frame];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _gravatarImageView = [self newImageViewForGravatar];
        [self addSubview:_gravatarImageView];

        _activityIndicator = [self newSpinner];
        [_gravatarImageView addSubview:_activityIndicator];
        
        _displayNameLabel = [self newLabelForDisplayName];
        [self addSubview:_displayNameLabel];

        _usernameLabel = [self newLabelForUsername];
        [self addSubview:_usernameLabel];

        [self configureConstraints];
    }
    return self;
}

#pragma mark - Public Methods

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(UIViewNoIntrinsicMetric, MeHeaderViewHeight);
}

- (void)setDisplayName:(NSString *)displayName
{
    self.displayNameLabel.text = displayName;
}

- (NSString *)displayName
{
    return self.displayNameLabel.text;
}

- (void)setUsername:(NSString *)username
{
    // If the username is an email, we don't want the preceding @ sign before it
    NSString *prefix = ([username rangeOfString:@"@"].location != NSNotFound) ? @"" : @"@";
    self.usernameLabel.text = [NSString stringWithFormat:@"%@%@", prefix, username];
}

- (NSString *)username
{
    return self.usernameLabel.text;
}

- (void)setGravatarEmail:(NSString *)gravatarEmail
{    
    // Since this view is only visible to the current user, we should show all ratings
    [self.gravatarImageView downloadGravatarWithEmail:gravatarEmail rating:GravatarRatingsX];
    _gravatarEmail = gravatarEmail;
}

- (BOOL)showsActivityIndicator
{
    // Note: ActivityIndicator will be visible only while it's beign animated
    return [_activityIndicator isAnimating];
}

- (void)setShowsActivityIndicator:(BOOL)showsActivityIndicator
{
    if (showsActivityIndicator) {
        [_activityIndicator startAnimating];
    } else {
        [_activityIndicator stopAnimating];
    }
}

- (void)overrideGravatarImage:(UIImage *)gravatarImage
{
    self.gravatarImageView.image = gravatarImage;
    
    // Note:
    // We need to update AFNetworking's internal cache. Otherwise, any upcoming query to refresh the gravatar
    // might return the cached (outdated) image, and the UI will end up in an inconsistent state.
    //
    [self.gravatarImageView overrideGravatarImageCache:gravatarImage rating:GravatarRatingsX email:self.gravatarEmail];
}


#pragma mark - Private Methods

- (void)configureConstraints
{
    NSDictionary *views = NSDictionaryOfVariableBindings(_gravatarImageView, _displayNameLabel, _usernameLabel);
    NSDictionary *metrics = @{@"gravatarSize": @(MeHeaderViewGravatarSize),
                              @"labelHeight":@(MeHeaderViewLabelHeight),
                              @"verticalSpacing":@(MeHeaderViewVerticalSpacing),
                              @"verticalMargin":@(MeHeaderViewVerticalMargin)};
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-verticalMargin-[_gravatarImageView(gravatarSize)]-verticalSpacing-[_displayNameLabel(labelHeight)][_usernameLabel(labelHeight)]-verticalMargin-|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[_gravatarImageView(gravatarSize)]"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];

    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.gravatarImageView
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1
                                                      constant:0]];

    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.displayNameLabel
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1
                                                      constant:0]];

    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.usernameLabel
                                                    attribute:NSLayoutAttributeCenterX
                                                    relatedBy:NSLayoutRelationEqual
                                                       toItem:self
                                                    attribute:NSLayoutAttributeCenterX
                                                   multiplier:1
                                                      constant:0]];
    
    [self.gravatarImageView pinSubviewAtCenter:_activityIndicator];
    
    [super setNeedsUpdateConstraints];
}

#pragma mark - Subview factories

- (UILabel *)newLabelForDisplayName
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.numberOfLines = 1;
    label.backgroundColor = [UIColor clearColor];
    label.opaque = YES;
    label.textColor = [WPStyleGuide darkGrey];
    label.adjustsFontSizeToFitWidth = NO;
    label.textAlignment = NSTextAlignmentCenter;
    [WPStyleGuide configureLabel:label
                       textStyle:UIFontTextStyleCallout
                      fontWeight:UIFontWeightSemibold];
    return label;
}

- (UILabel *)newLabelForUsername
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.numberOfLines = 1;
    label.backgroundColor = [UIColor clearColor];
    label.opaque = YES;
    label.textColor = [WPStyleGuide grey];
    label.adjustsFontSizeToFitWidth = NO;
    label.textAlignment = NSTextAlignmentCenter;
    [WPStyleGuide configureLabel:label
                       textStyle:UIFontTextStyleCallout];

    return label;
}

- (UIImageView *)newImageViewForGravatar
{
    CGRect gravatarFrame = CGRectMake(0.0f, 0.0f, MeHeaderViewGravatarSize, MeHeaderViewGravatarSize);
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:gravatarFrame];
    imageView.layer.cornerRadius = MeHeaderViewGravatarSize * 0.5;
    imageView.clipsToBounds = YES;
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.userInteractionEnabled = YES;
    
    UILongPressGestureRecognizer *recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                             action:@selector(handleHeaderPress:)];
    recognizer.minimumPressDuration = MeHeaderViewMinimumPressDuration;
    [imageView addGestureRecognizer:recognizer];
    
    return imageView;
}

- (UIActivityIndicatorView *)newSpinner
{
    UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    indicatorView.hidesWhenStopped = YES;
    indicatorView.translatesAutoresizingMaskIntoConstraints = NO;
    
    return indicatorView;
}


#pragma mark - UITapGestureRecognizer Handler

- (IBAction)handleHeaderPress:(UIGestureRecognizer *)sender
{
    // Touch Down: Depress the gravatarImageView
    if (sender.state == UIGestureRecognizerStateBegan) {
        [_gravatarImageView depressSpringAnimation:nil];
        return;
    }
    
    // Touch Up: Normalize the gravatarImageView
    if (sender.state == UIGestureRecognizerStateEnded) {
        [_gravatarImageView normalizeSpringAnimation:nil];
        
        // Hit the callback only if we're still within Gravatar Bounds
        CGPoint touchInGravatar = [sender locationInView:_gravatarImageView];
        BOOL gravatarContainsTouch = CGRectContainsPoint(_gravatarImageView.bounds, touchInGravatar);

        if (self.onGravatarPress && gravatarContainsTouch) {
            self.onGravatarPress();
        }
    }
}

@end
