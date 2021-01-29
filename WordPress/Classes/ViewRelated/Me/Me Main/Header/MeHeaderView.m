#import "MeHeaderView.h"
#import "Blog.h"
#import <WordPressUI/WordPressUI.h>
#import "WordPress-Swift.h"



const CGFloat MeHeaderViewHeight = 154;
const CGFloat MeHeaderViewGravatarSize = 64.0;
const CGFloat MeHeaderViewLabelHeight = 20.0;
const CGFloat MeHeaderViewVerticalMargin = 20.0;
const CGFloat MeHeaderViewVerticalSpacing = 10.0;
const NSTimeInterval MeHeaderViewMinimumPressDuration = 0.001;

@interface MeHeaderView () <UIDropInteractionDelegate>

@property (nonatomic, strong) UIImageView *gravatarImageView;
@property (nonatomic, strong) UILabel *displayNameLabel;
@property (nonatomic, strong) UILabel *usernameLabel;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UIView *gravatarDropTarget;
@property (nonatomic, strong) UIStackView *stackView;

@end

@implementation MeHeaderView

- (instancetype)init
{
    return [self initWithFrame:CGRectZero];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _gravatarImageView = [self newImageViewForGravatar];
        _displayNameLabel = [self newLabelForDisplayName];
        _usernameLabel = [self newLabelForUsername];

        _stackView = [self newStackView];
        [self addSubview:_stackView];

        _gravatarDropTarget = [self newDropTargetForGravatar];
        [self addSubview:_gravatarDropTarget];

        _activityIndicator = [self newSpinner];
        [_gravatarImageView addSubview:_activityIndicator];

        [self configureConstraints];
    }
    return self;
}

#pragma mark - Public Methods

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
    // Note: ActivityIndicator will be visible only while it's being animated
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
    // We need to update the internal cache. Otherwise, any upcoming query to refresh the gravatar
    // might return the cached (outdated) image, and the UI will end up in an inconsistent state.
    //
    [self.gravatarImageView overrideGravatarImageCache:gravatarImage rating:GravatarRatingsX email:self.gravatarEmail];
    [self.gravatarImageView updateGravatarWithImage:gravatarImage email:self.gravatarEmail];
}


#pragma mark - Private Methods

- (void)configureConstraints
{
    UIView *spaceView = [UIView new];
    [self.stackView addArrangedSubview:self.gravatarImageView];
    [self.stackView addArrangedSubview:spaceView];
    [self.stackView addArrangedSubview:self.displayNameLabel];
    [self.stackView addArrangedSubview:self.usernameLabel];
    NSLayoutConstraint *heightConstraint =  [self.gravatarImageView.heightAnchor constraintEqualToConstant:MeHeaderViewGravatarSize];
    heightConstraint.priority = 999;
    NSLayoutConstraint *spaceHeightConstraint =  [spaceView.heightAnchor constraintEqualToConstant:MeHeaderViewVerticalSpacing];
    heightConstraint.priority = 999;
    NSLayoutConstraint *stackViewTopConstraint =  [self.stackView.topAnchor constraintEqualToAnchor:self.topAnchor constant:MeHeaderViewVerticalSpacing];
    stackViewTopConstraint.priority = 999;
    NSLayoutConstraint *stackViewBottomConstraint =  [self.bottomAnchor constraintEqualToAnchor:self.stackView.bottomAnchor constant:MeHeaderViewVerticalSpacing];
    stackViewBottomConstraint.priority = 999;
    NSArray *constraints = @[
                             heightConstraint,
                             [self.gravatarImageView.widthAnchor constraintEqualToConstant:MeHeaderViewGravatarSize],
                             spaceHeightConstraint,
                             stackViewTopConstraint,
                             stackViewBottomConstraint,
                             [self.stackView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
                             ];

    [NSLayoutConstraint activateConstraints:constraints];

    [self.gravatarDropTarget pinSubviewToAllEdgeMargins:self.gravatarImageView];
    [self.gravatarImageView pinSubviewAtCenter:_activityIndicator];
    
    [super setNeedsUpdateConstraints];
}

#pragma mark - Subview factories

- (UIStackView *)newStackView
{
    UIStackView *stackView = [UIStackView new];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.alignment = UIStackViewAlignmentCenter;
    return stackView;
}

- (UILabel *)newLabelForDisplayName
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.numberOfLines = 1;
    label.backgroundColor = [UIColor clearColor];
    label.opaque = YES;
    label.textColor = [UIColor murielNeutral70];
    label.adjustsFontSizeToFitWidth = NO;
    label.textAlignment = NSTextAlignmentCenter;
    label.accessibilityIdentifier = @"Display Name";
    [WPStyleGuide configureLabel:label
                       textStyle:UIFontTextStyleHeadline
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
    label.textColor = [UIColor murielNeutral30];
    label.adjustsFontSizeToFitWidth = NO;
    label.textAlignment = NSTextAlignmentCenter;
    label.accessibilityIdentifier = @"Username";
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

- (UIView *)newDropTargetForGravatar
{
    UIView *dropTarget = [UIView new];
    [dropTarget setTranslatesAutoresizingMaskIntoConstraints:NO];
    dropTarget.backgroundColor = [UIColor clearColor];
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                action:@selector(handleHeaderPress:)];
    singleTap.numberOfTapsRequired = 1;
    [dropTarget addGestureRecognizer:singleTap];

    UIDropInteraction *dropInteraction = [[UIDropInteraction alloc] initWithDelegate:self];
    [dropTarget addInteraction:dropInteraction];
    
    return dropTarget;
}

- (UIActivityIndicatorView *)newSpinner
{
    UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
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

#pragma mark - Drop Interaction Handler

- (BOOL)dropInteraction:(UIDropInteraction *)interaction
       canHandleSession:(id<UIDropSession>)session API_AVAILABLE(ios(11.0))
{
    BOOL isAnImage = [session canLoadObjectsOfClass:[UIImage self]];
    BOOL isSingleImage = [session.items count] == 1;
    return (isAnImage && isSingleImage);
}

- (void)dropInteraction:(UIDropInteraction *)interaction
        sessionDidEnter:(id<UIDropSession>)session API_AVAILABLE(ios(11.0))
{
    [self.gravatarImageView depressSpringAnimation:nil];
}

- (UIDropProposal *)dropInteraction:(UIDropInteraction *)interaction
                   sessionDidUpdate:(id<UIDropSession>)session API_AVAILABLE(ios(11.0))
{
    CGPoint dropLocation = [session locationInView:self.gravatarDropTarget];
    
    UIDropOperation dropOperation = UIDropOperationCancel;
    
    if (CGRectContainsPoint(self.gravatarDropTarget.bounds, dropLocation)) {
        dropOperation = UIDropOperationCopy;
    }
    
    UIDropProposal *dropProposal = [[UIDropProposal alloc] initWithDropOperation:dropOperation];
    
    return  dropProposal;
}

- (void)dropInteraction:(UIDropInteraction *)interaction
            performDrop:(id<UIDropSession>)session API_AVAILABLE(ios(11.0))
{
    [self setShowsActivityIndicator:YES];
    [session loadObjectsOfClass:[UIImage self] completion:^(NSArray *images) {
        UIImage *image = [images firstObject];
        if (self.onDroppedImage) {
            self.onDroppedImage(image);
        }
    }];
}

- (void)dropInteraction:(UIDropInteraction *)interaction
           concludeDrop:(id<UIDropSession>)session API_AVAILABLE(ios(11.0))
{
    [self.gravatarImageView normalizeSpringAnimation:nil];
}

- (void)dropInteraction:(UIDropInteraction *)interaction
         sessionDidExit:(id<UIDropSession>)session  API_AVAILABLE(ios(11.0))
{
    [self.gravatarImageView normalizeSpringAnimation:nil];
}

- (void)dropInteraction:(UIDropInteraction *)interaction
         sessionDidEnd:(id<UIDropSession>)session API_AVAILABLE(ios(11.0))
{
    [self.gravatarImageView normalizeSpringAnimation:nil];
}

@end
