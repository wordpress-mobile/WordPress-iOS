#import "ReaderPostTableViewCell.h"
#import "WordPressAppDelegate.h"
#import "ReaderPost.h"
#import "ReaderPostContentView.h"

const CGFloat RPTVCHorizontalOuterPadding = 8.0f;
const CGFloat RPTVCVerticalOuterPadding = 16.0f;

@interface ReaderPostTableViewCell()
@property (nonatomic, strong) UIView *sideBorderView;
@end

@implementation ReaderPostTableViewCell

+ (instancetype)cellForSubview:(UIView *)subview
{
    id view = subview;
    while (![view isKindOfClass:[self class]]) {
        view = [((UIView *)view) superview];
    }

    if (view == subview) {
        return nil;
    }

    return view;
}

#pragma mark - Lifecycle Methods

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [WPStyleGuide itsEverywhereGrey];

        _sideBorderView = [self newSideBorderView];
        [self.contentView addSubview:_sideBorderView];

        _postView = [self newReaderPostContentView];
        [self.contentView addSubview:_postView];

        [self configureConstraints];
    }

    return self;
}

- (UIView *)newSideBorderView
{
    UIView *view = [[UIView alloc] init];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    view.backgroundColor = [WPStyleGuide readGrey];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    return view;
}

- (ReaderPostContentView *)newReaderPostContentView
{
    ReaderPostContentView *view = [[ReaderPostContentView alloc] init];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    view.backgroundColor = [UIColor whiteColor];
    return view;
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGFloat padding = IS_IPHONE ? RPTVCHorizontalOuterPadding : 0;
    CGFloat innerWidth = size.width - (padding * 2);
    CGSize postViewSize = [self.postView sizeThatFits:CGSizeMake(innerWidth, size.height)];
    CGFloat desiredHeight = postViewSize.height + RPTVCVerticalOuterPadding;

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
    NSNumber *borderSidePadding = IS_IPHONE ? @(RPTVCHorizontalOuterPadding - 1) : @0; // Just to the left of the container
    NSNumber *borderBottomPadding = @(RPTVCVerticalOuterPadding - 1);
    NSNumber *bottomPadding = @(RPTVCVerticalOuterPadding);
    NSNumber *sidePadding = IS_IPHONE ? @(RPTVCHorizontalOuterPadding) : @0;
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

    if (previouslyHighlighted == highlighted) {
        return;
    }

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

#pragma mark - Instance Methods

- (void)configureCell:(ReaderPost *)post
{
    self.post = post;
    [self.postView configurePost:post];
}

@end
