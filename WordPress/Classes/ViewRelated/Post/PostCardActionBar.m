#import "PostCardActionBar.h"
#import "PostCardActionBarItem.h"
#import "UIDevice+Helpers.h"
#import <WordPressShared/WPStyleGuide.h>
#import <WordPressShared/UIImage+Util.h>
#import "WordPress-Swift.h"

static NSInteger ActionBarMoreButtonIndex = 999;
static CGFloat ActionBarMinButtonWidth = 100.0;

static const UIEdgeInsets MoreButtonImageInsets = {0.0, 0.0, 0.0, 4.0};

@interface PostCardActionBar()
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) NSArray *buttons;
@property (nonatomic, strong) NSArray *items;
@property (nonatomic, assign) NSInteger currentBatch;
@property (nonatomic, assign) BOOL shouldShowMore;
@property (nonatomic, assign) BOOL needsSetupButtons;
@end

@implementation PostCardActionBar

#pragma mark - Life Cycle Methods

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    [self setupView];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self setupButtonsIfNeeded];
}


#pragma mark - Setup

- (void)setupView
{
    _items = @[];
    _buttons = @[];
    self.backgroundColor = [WPStyleGuide lightGrey];

    self.contentView = [[UIView alloc] initWithFrame:self.bounds];
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentView.backgroundColor = [WPStyleGuide greyLighten30];
    [self addSubview:self.contentView];

    NSDictionary *views = NSDictionaryOfVariableBindings(_contentView);
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_contentView]|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_contentView]|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:views]];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationDidChange:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];

    // Trap double taps to prevent touches from regstering in the parent cell while the bar is animating.
    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    tgr.numberOfTapsRequired = 2;
    [self addGestureRecognizer:tgr];
}

- (void)setupConstraints
{
    if ([self.buttons count] == 0) {
        return;
    }

    UIButton *button;
    UIButton *previousButton;
    NSDictionary *views;

    // One button to rule them all...
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
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[previousButton]-(1)-[button(==previousButton)]"
                                                                                 options:0
                                                                                 metrics:nil
                                                                                   views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[button]|"
                                                                                 options:0
                                                                                 metrics:nil
                                                                                   views:views]];
    }

    previousButton = button;
    button = [self.buttons lastObject];
    views = NSDictionaryOfVariableBindings(button, previousButton);
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[previousButton]-(1)-[button(==previousButton)]|"
                                                                             options:0
                                                                             metrics:nil
                                                                               views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[button]|"
                                                                             options:0
                                                                             metrics:nil
                                                                               views:views]];
    [self setNeedsUpdateConstraints];
}

- (void)setupButtons
{
    for (UIButton *button in self.buttons) {
        [button removeFromSuperview];
    }
    self.currentBatch = 0;
    self.shouldShowMore = [self checkIfShouldShowMoreButton];
    NSInteger numOfButtons = [self maxButtonsToDisplay];
    numOfButtons = MIN(numOfButtons, [self.items count]);

    NSMutableArray *buttons = [NSMutableArray array];
    for (NSInteger i = 0; i < numOfButtons; i++) {
        UIButton *button = [self newButton];
        [self.contentView addSubview:button];
        [buttons addObject:button];
    }
    self.buttons = buttons;

    [self setupConstraints];
}

- (UIButton *)newButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.exclusiveTouch = YES;
    button.backgroundColor = [WPStyleGuide lightGrey];
    button.titleLabel.font = [WPStyleGuide subtitleFont];
    [button setTitleColor:[WPStyleGuide wordPressBlue] forState:UIControlStateNormal];
    [button setTitleColor:[WPStyleGuide darkBlue] forState:UIControlStateHighlighted];
    [button addTarget:self action:@selector(handleButtonTap:) forControlEvents:UIControlEventTouchUpInside];

    return button;
}

- (void)setupButtonsIfNeeded
{
    // check if we need to show the more button.
    if ([self checkIfShouldShowMoreButton] != self.shouldShowMore) {
        // configure buttons
        [self setupButtons];
        [self configureButtons];
    }
}


#pragma mark - Configuration

- (void)configureButtons
{
    // Reset all buttons.
    for (UIButton *button in self.buttons) {
        [self configureButton:button forItem:nil atIndex:0];
    }

    NSArray *itemsToShow = [self currentBatchOfItems];
    for (NSInteger i = 0; i < [itemsToShow count]; i++) {
        PostCardActionBarItem *item = [itemsToShow objectAtIndex:i];
        UIButton *button =[self.buttons objectAtIndex:i];
        [self configureButton:button forItem:item atIndex:[self indexOfItem:item]];
    }

    if (self.shouldShowMore) {
        BOOL isLastBatch = [itemsToShow lastObject] == [self.items lastObject];
        PostCardActionBarItem *moreItem = [self moreItem:isLastBatch];
        [self configureButton:[self.buttons lastObject] forItem:moreItem atIndex:ActionBarMoreButtonIndex];
    }
}

- (void)configureButton:(UIButton *)button forItem:(PostCardActionBarItem *)item atIndex:(NSUInteger)index
{
    button.tag = index;
    [button setTitle:item.title forState:UIControlStateNormal];
    [button setTitle:item.title forState:UIControlStateHighlighted];
    [button setImage:item.image forState:UIControlStateNormal];
    [button setImageEdgeInsets:item.imageInsets];
    [button setImage:item.highlightedImage forState:UIControlStateHighlighted];
}

- (void)configureButtonsWithAnimation
{
    // Frames for transtion
    CGRect frame = self.contentView.frame;
    CGRect smallFrame = frame;
    smallFrame.origin.x += smallFrame.size.width / 2.0;
    smallFrame.origin.y += smallFrame.size.height / 2.0;
    smallFrame.size = CGSizeZero;

    // Get snapshot of current state
    UIView *viewOldState = [self.contentView snapshotViewAfterScreenUpdates:NO];
    viewOldState.frame = frame;
    [self addSubview:viewOldState];

    [self configureButtons];

    UIView *viewNewState = [self.contentView snapshotViewAfterScreenUpdates:YES];
    viewNewState.frame = smallFrame;
    viewNewState.alpha = 0;
    [self addSubview:viewNewState];
    self.contentView.hidden = YES;

    [UIView animateWithDuration:0.3 animations:^{
        viewOldState.frame = smallFrame;
        viewOldState.alpha = 0;
        viewNewState.frame = frame;
        viewNewState.alpha = 1;

    } completion:^(BOOL finished) {
        [viewOldState removeFromSuperview];
        [viewNewState removeFromSuperview];
        self.contentView.hidden = NO;
    }];
}


#pragma mark - Notifications

- (void)orientationDidChange:(NSNotification *)notification
{
    [self setupButtonsIfNeeded];
}


#pragma mark - Accessors

- (NSInteger)indexOfItem:(PostCardActionBarItem *)item
{
    return [self.items indexOfObject:item];
}

- (NSInteger)maxButtonsToDisplay
{
    return (NSInteger)floor(CGRectGetWidth(self.frame) / ActionBarMinButtonWidth);
}

- (BOOL)checkIfShouldShowMoreButton
{
    return [self maxButtonsToDisplay] < [self.items count];
}

- (void)setItems:(NSArray *)items
{
    _items = items;

    [self setupButtons];
    [self configureButtons];
}

- (PostCardActionBarItem *)moreItem:(BOOL)isLastBatch;
{
    PostCardActionBarItem *item;
    if (isLastBatch) {
        item = [PostCardActionBarItem itemWithTitle:NSLocalizedString(@"Back", @"")
                                              image:[UIImage imageNamed:@"icon-post-actionbar-back"]
                                   highlightedImage:nil];
    } else {
        item = [PostCardActionBarItem itemWithTitle:NSLocalizedString(@"More", @"")
                                              image:[UIImage imageNamed:@"icon-post-actionbar-more"]
                                   highlightedImage:nil];
        item.imageInsets = MoreButtonImageInsets;
    }
    return item;
}

- (NSArray *)currentBatchOfItems
{
    NSInteger batchSize = [self.buttons count];
    if (batchSize == 0) {
        return @[];
    }

    if (self.shouldShowMore) {
        batchSize--;
    }
    NSInteger index = self.currentBatch * batchSize;

    // Validate the index and batch size do not exceed the limits of the array
    if (index >= [self.items count]) {
        // Safety net. Currently at the end of the available items so reset to zero.
        index = 0;
        self.currentBatch = 0;
    }
    // Adjust the batch size if we have fewer items in the array.
    if ((index + batchSize) >= [self.items count]) {
        batchSize = [self.items count] - index;
    }

    NSRange rng = NSMakeRange(index, batchSize);
    return [self.items subarrayWithRange:rng];
}


#pragma mark - Actions

- (void)handleButtonTap:(id)sender
{
    UIButton *button = (UIButton *)sender;
    NSInteger index = button.tag;
    if (index == ActionBarMoreButtonIndex) {
        self.currentBatch++;
        [self configureButtonsWithAnimation];
        return;
    }
    PostCardActionBarItem *item = [self.items objectAtIndex:index];
    if (item.callback) {
        item.callback();
    }
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)sender
{
    // noop.
}


@end
