#import "AbstractPostTableViewCell.h"
#import "WPContentViewBase.h"

const CGFloat APTVCHorizontalOuterPadding = 8.0f;
const CGFloat APTVCVerticalOuterPadding = 16.0f;

@interface AbstractPostTableViewCell ()

@property (nonatomic, strong) UIView *sideBorderView;

@end

@implementation AbstractPostTableViewCell

+ (instancetype)cellForSubview:(UIView *)subview
{
    UIView *view = subview;
    while (![view isKindOfClass:self]) {
        view = (UIView *)view.superview;
    }

    if (view == subview)
        return nil;

    return (AbstractPostTableViewCell *)view;
}

#pragma mark - Lifecycle Methods

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _sideBorderView = [[UIView alloc] init];
        _sideBorderView.translatesAutoresizingMaskIntoConstraints = NO;
        _sideBorderView.backgroundColor = [UIColor colorWithRed:210.0/255.0 green:222.0/255.0 blue:238.0/255.0 alpha:1.0];
        _sideBorderView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.contentView addSubview:_sideBorderView];

        _postView = [self configurePostView];
        [self.contentView addSubview:_postView];

        self.backgroundColor = [WPStyleGuide itsEverywhereGrey];

        [self configureConstraints];
    }

    return self;
}

- (WPContentViewBase *)configurePostView {
    // noop. Subclasses should override.
    AssertSubclassMethod();
    return nil;
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGFloat padding = IS_IPHONE ? APTVCHorizontalOuterPadding : 0;
    CGFloat innerWidth = size.width - (padding * 2);
    CGFloat innerHeight = size.height - APTVCVerticalOuterPadding;
    CGSize postViewSize = [self.postView sizeThatFits:CGSizeMake(innerWidth, innerHeight)];
    CGFloat desiredHeight = postViewSize.height + APTVCVerticalOuterPadding;

    return CGSizeMake(size.width, desiredHeight);
}

- (void)setHighlightedEffect:(BOOL)highlighted animated:(BOOL)animated
{
    [UIView animateWithDuration:animated ? .1f : 0.f
                          delay:0
                        options:UIViewAnimationCurveEaseInOut
                     animations:^{
                         self.sideBorderView.hidden = highlighted;
                         self.alpha = highlighted ? .7f : 1.f;
                         if (highlighted) {
                             CGFloat perspective = IS_IPAD ? -0.00005 : -0.0001;
                             CATransform3D transform = CATransform3DIdentity;
                             transform.m24 = perspective;
                             transform = CATransform3DScale(transform, .98f, .98f, 1);
                             self.contentView.layer.transform = transform;
                             self.contentView.layer.shouldRasterize = YES;
                             self.contentView.layer.rasterizationScale = [[UIScreen mainScreen] scale];
                         } else {
                             self.contentView.layer.shouldRasterize = NO;
                             self.contentView.layer.transform = CATransform3DIdentity;
                         }
                     } completion:nil];
}

- (void)configureConstraints
{
    NSNumber *borderSidePadding = IS_IPHONE ? @(APTVCHorizontalOuterPadding - 1) : @0; // Just to the left of the container
    NSNumber *borderBottomPadding = @(APTVCVerticalOuterPadding - 1);
    NSNumber *bottomPadding = @(APTVCVerticalOuterPadding);
    NSNumber *sidePadding = IS_IPHONE ? @(APTVCHorizontalOuterPadding) : @0;
    NSDictionary *metrics =  @{@"borderSidePadding":borderSidePadding,
                               @"borderBottomPadding":borderBottomPadding,
                               @"sidePadding":sidePadding,
                               @"bottomPadding":bottomPadding};

    UIView *contentView = self.contentView;
    NSDictionary *views = NSDictionaryOfVariableBindings(contentView, _sideBorderView, _postView);
    // Border View
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(borderSidePadding)-[_sideBorderView]-(borderSidePadding)-|"
                                                                             options:0
                                                                             metrics:metrics
                                                                               views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_sideBorderView]-(borderBottomPadding)-|"
                                                                             options:0
                                                                             metrics:metrics
                                                                               views:views]];

    // Post View
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(sidePadding)-[_postView]-(sidePadding)-|"
                                                                             options:0
                                                                             metrics:metrics
                                                                               views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_postView]-(bottomPadding)-|"
                                                                             options:0
                                                                             metrics:metrics
                                                                               views:views]];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    BOOL previouslyHighlighted = self.highlighted;
    [super setHighlighted:highlighted animated:animated];

    if (previouslyHighlighted == highlighted)
        return;

    if (highlighted) {
        [self setHighlightedEffect:highlighted animated:animated];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!self.selected) {
                [self setHighlightedEffect:highlighted animated:animated];
            }
        });
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    [self setHighlightedEffect:selected animated:animated];
}

- (void)prepareForReuse
{
    [super prepareForReuse];

    [self.postView reset];
    [self setHighlightedEffect:NO animated:NO];
}

@end
