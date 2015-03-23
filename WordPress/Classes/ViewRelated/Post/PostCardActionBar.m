#import "PostCardActionBar.h"
#import "PostCardActionBarItem.h"
#import <WordPress-iOS-Shared/WPStyleGuide.h>
#import <WordPress-iOS-Shared/UIImage+Util.h> 

@interface PostCardActionBar()
@property (nonatomic, strong) NSArray *buttons;
@property (nonatomic, strong) UIView *contentView;
@end

@implementation PostCardActionBar

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _buttons = @[];
        self.backgroundColor = [WPStyleGuide lightGrey];
        [self configureContentView];
    }
    return self;
}

- (void)configureContentView
{
    self.contentView = [[UIView alloc] initWithFrame:self.bounds];
    self.contentView.backgroundColor = [WPStyleGuide greyLighten20];

    NSDictionary *views = NSDictionaryOfVariableBindings(_contentView);
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_contentView]|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_contentView]|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:views]];
}

- (void)configureConstraints
{
    if ([self.buttons count] == 0) {
        return;
    }

    UIButton *button;
    UIButton *previousButton;
    NSDictionary *views;

    // one button to rule them all...
    if ([self.buttons count] == 1) {
        button = [self.buttons firstObject];
        views = NSDictionaryOfVariableBindings(button);
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[button]|"
                                                                                options:0
                                                                                metrics:nil
                                                                                  views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[button]|"
                                                                                 options:0
                                                                                 metrics:nil
                                                                                   views:views]];
    }

    // left-most button
    button = [self.buttons firstObject];
    views = NSDictionaryOfVariableBindings(button);
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[button]"
                                                                             options:0
                                                                             metrics:nil
                                                                               views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[button]|"
                                                                             options:0
                                                                             metrics:nil
                                                                               views:views]];


    // in-between buttons
    for (NSInteger i = 1; i < [self.buttons count] - 1; i++) {
        previousButton = button;
        button = [self.buttons objectAtIndex:i];
        views = NSDictionaryOfVariableBindings(button, previousButton);
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[previousButton]-(1)-[button]"
                                                                                 options:0
                                                                                 metrics:nil
                                                                                   views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[button]|"
                                                                                 options:0
                                                                                 metrics:nil
                                                                                   views:views]];
    }

    /// right-most button
    if (!previousButton) {
        previousButton = button;
    }
    button = [self.buttons lastObject];
    views = NSDictionaryOfVariableBindings(button, previousButton);
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[previousButton]-(1)-[button]|"
                                                                             options:0
                                                                             metrics:nil
                                                                               views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[button]|"
                                                                             options:0
                                                                             metrics:nil
                                                                               views:views]];

}

- (NSInteger)numberOfItems
{
    return [self.buttons count];
}

- (void)setItems:(NSArray *)items
{
    for (UIButton *button in self.buttons) {
        [button removeFromSuperview];
    }

    NSMutableArray *marr = [NSMutableArray array];
    for (PostCardActionBarItem *item in items) {
        UIButton *button = [self buttonForItem:item];
        [self.contentView addSubview:button];
        [marr addObject:button];
    }
    [self configureConstraints];
}

- (void)setItems:(NSArray *)items withAnimation:(BOOL)animation
{
    if (!animation) {
        [self setItems:items];
        return;
    }

    // Frames for transtion
    CGRect frame = self.contentView.frame;
    CGRect smallFrame = frame;
    smallFrame.origin.x += smallFrame.size.width / 2;
    smallFrame.origin.y += smallFrame.size.height / 2;
    smallFrame.size = CGSizeZero;

    // Get snapshot of current state
    UIView *viewOldState = [self.contentView snapshotViewAfterScreenUpdates:NO];
    viewOldState.frame = frame;
    [self addSubview:viewOldState];

    [self setItems:items];

    UIView *viewNewState = [self.contentView snapshotViewAfterScreenUpdates:YES];
    viewNewState.frame = smallFrame;
    [self addSubview:viewNewState];
    self.contentView.hidden = YES;

    self.userInteractionEnabled = NO;
    [UIView animateWithDuration:0.3 animations:^{
        viewOldState.frame = smallFrame;
        viewOldState.alpha = 0;
        viewNewState.frame = frame;

    } completion:^(BOOL finished) {
        [viewOldState removeFromSuperview];
        [viewNewState removeFromSuperview];
        self.userInteractionEnabled = YES;
        self.contentView.hidden = NO;
    }];
}

- (UIButton *)buttonForItem:(PostCardActionBarItem *)item
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:item.title forState:UIControlStateNormal | UIControlStateHighlighted];
    [button setImage:item.image forState:UIControlStateNormal];
    [button setImage:item.highlightedImage forState:UIControlStateHighlighted];
    button.backgroundColor = [WPStyleGuide lightGrey];
    button.titleLabel.font = [WPStyleGuide subtitleFont];
    [button setTitleColor:[WPStyleGuide wordPressBlue] forState:UIControlStateNormal];
    [button setTitleColor:[WPStyleGuide mediumBlue] forState:UIControlStateHighlighted];

    return button;
}

@end
