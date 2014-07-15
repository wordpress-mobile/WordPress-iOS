#import "WPContentActionView.h"
#import "NSDate+StringFormatting.h"

const CGFloat WPContentActionViewButtonHeight = 48.0;
const CGFloat WPContentActionViewBorderHeight = 1.0;
const CGFloat WPContentActionViewButtonSpacing = 12.0;

@interface WPContentActionView()

@property (nonatomic, strong) NSMutableArray *currentActionButtons;
@property (nonatomic, strong) UIView *borderView;
@property (nonatomic, strong) UIButton *timeButton;
@property (nonatomic, strong) NSTimer *dateRefreshTimer;
@property (nonatomic, assign) BOOL needsUpdateButtonConstraints;
@property (nonatomic, strong) NSMutableArray *buttonConstraints;

@end


@implementation WPContentActionView

#pragma mark - Life Cycle Methods
- (void)dealloc
{
    [self.dateRefreshTimer invalidate];
    self.dateRefreshTimer = nil;
    self.contentProvider = nil;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _currentActionButtons = [NSMutableArray array];
        _buttonConstraints = [NSMutableArray array];

        _borderView = [self viewForBorder];
        [self addSubview:self.borderView];

        _timeButton = [self buttonForTimeButton];
        [self addSubview:self.timeButton];

        [self configureConstraints];
    }
    return self;
}


#pragma mark - Public Methods

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(UIViewNoIntrinsicMetric, WPContentActionViewButtonHeight);
}

- (void)setContentProvider:(id<WPContentViewProvider>)contentProvider
{
    if (_contentProvider == contentProvider) {
        return;
    }

    _contentProvider = contentProvider;

    if (self.dateRefreshTimer) {
        [self.dateRefreshTimer invalidate];
        self.dateRefreshTimer = nil;
    }

    if (contentProvider) {
        self.dateRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:60.0
                                                                 target:self
                                                               selector:@selector(refreshDate:)
                                                               userInfo:nil
                                                                repeats:YES];
    }
    [self refreshDate:nil];
}

- (void)setActionButtons:(NSArray *)actionButtons
{
    if ([actionButtons isEqualToArray:self.currentActionButtons]) {
        return;
    }

    for (UIButton *button in self.currentActionButtons) {
        [button removeFromSuperview];
    }
    [self.currentActionButtons removeAllObjects];

    [self.currentActionButtons addObjectsFromArray:actionButtons];
    for (UIButton *button in self.currentActionButtons) {
        button.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:button];
    }
    [self resetButtonConstraints];
}

#pragma mark - Private Methods

- (void)configureConstraints
{
    NSDictionary *views = NSDictionaryOfVariableBindings(_timeButton, _borderView);
    NSDictionary *metrics = @{@"buttonHeight":@(WPContentActionViewButtonHeight),
                              @"borderHeight":@(WPContentActionViewBorderHeight)};

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_timeButton]"
                                                                 options:NSLayoutFormatAlignAllLeft
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_timeButton(buttonHeight)]|"
                                                                 options:NSLayoutFormatAlignAllCenterY
                                                                 metrics:metrics
                                                                   views:views]];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_borderView]|"
                                                                 options:NSLayoutFormatAlignAllTop
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_borderView(borderHeight)]"
                                                                 options:NSLayoutFormatAlignAllTop
                                                                 metrics:metrics
                                                                   views:views]];
    [self setNeedsUpdateConstraints];
}

- (void)updateConstraints
{
    [self configureButtonConstraints];
    [super updateConstraints];
}

// Existing button constraints must be deleted prior to this
- (void)configureButtonConstraints
{
    if (!self.needsUpdateButtonConstraints) {
        return;
    }
    self.needsUpdateButtonConstraints = NO;

    NSMutableArray *constraints = [NSMutableArray array];
    UIButton *previousButton;
    for (UIButton *button in self.currentActionButtons) {
        NSDictionary *views;
        NSDictionary *metrics;
        if (previousButton) {
            // Adjust button spacing to account for differences in width.
            CGFloat previousButtonWidth = previousButton.intrinsicContentSize.width;
            CGFloat width = button.intrinsicContentSize.width;
            CGFloat diff = width - previousButtonWidth;
            CGFloat buttonSpacing = WPContentActionViewButtonSpacing + diff;
            metrics = @{@"buttonSpacing":@(buttonSpacing)};

            views = NSDictionaryOfVariableBindings(button, previousButton);
            [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"[button]-(buttonSpacing)-[previousButton]"
                                                                                     options:0
                                                                                     metrics:metrics
                                                                                       views:views]];
        } else {
            views = NSDictionaryOfVariableBindings(button);
            [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"[button]|"
                                                                                     options:0
                                                                                     metrics:nil
                                                                                       views:views]];
        }
        views = NSDictionaryOfVariableBindings(button);
        metrics = @{@"buttonHeight":@(WPContentActionViewButtonHeight)};
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[button(buttonHeight)]|"
                                                                                 options:0
                                                                                 metrics:metrics
                                                                                   views:views]];
        previousButton = button;
    }
    self.buttonConstraints = constraints;
    [self addConstraints:constraints];
}

- (void)resetButtonConstraints
{
    [self removeConstraints:self.buttonConstraints];
    [self.buttonConstraints removeAllObjects];
    self.needsUpdateButtonConstraints = YES;
    [self setNeedsUpdateConstraints];
}


#pragma mark - Subview factories

- (UIView *)viewForBorder
{
    UIView *borderView = [[UIView alloc] initWithFrame:CGRectZero];
    borderView.translatesAutoresizingMaskIntoConstraints = NO;
    borderView.backgroundColor = [UIColor colorWithRed:232.0/255.0 green:240.0/255.0 blue:245.0/255.0 alpha:1.0];
    return borderView;
}

- (UIButton *)buttonForTimeButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    button.titleLabel.font = [WPStyleGuide subtitleFont];
    [button setTitleEdgeInsets: UIEdgeInsetsMake(0, 2, 0, -2)];

    // Disable it for now (could be used for permalinks in the future)
    [button setImage:[UIImage imageNamed:@"reader-postaction-time"] forState:UIControlStateDisabled];
    [button setTitleColor:[UIColor colorWithRed:170.0/255.0 green:170.0/255.0 blue:170.0/255.0 alpha:1.0] forState:UIControlStateDisabled];
    [button setTitleColor:[UIColor colorWithRed:177.0/255.0 green:198.0/255.0 blue:212.0/255.0 alpha:1.0] forState:UIControlStateDisabled];
    [button setEnabled:NO];

    return button;
}


#pragma mark - Timer Related

- (void)refreshDate:(NSTimer *)timer
{
    NSString *title = [[self.contentProvider dateForDisplay] shortString];
    [self.timeButton setTitle:title forState:UIControlStateNormal | UIControlStateDisabled];
}

@end
