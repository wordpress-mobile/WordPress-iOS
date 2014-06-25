#import "WPContentActionView.h"
#import "NSDate+StringFormatting.h"

const CGFloat WPContentActionViewButtonHeight = 48.0;
const CGFloat WPContentActionViewBorderHeight = 1.0;
const CGFloat WPContentActionViewButtonSpacing = 12.0;

@interface WPContentActionView()

@property (nonatomic, strong) NSMutableArray *actionButtons;
@property (nonatomic, strong) UIView *borderView;
@property (nonatomic, strong) UIButton *timeButton;
@property (nonatomic, strong) NSTimer *dateRefreshTimer;
@property (nonatomic, assign) BOOL needsUpdateButtonConstraints;
@property (nonatomic, strong) NSMutableArray *buttonConstraints;

@end


@implementation WPContentActionView

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
        self.actionButtons = [NSMutableArray array];
        self.buttonConstraints = [NSMutableArray array];

        self.borderView = [self viewForBorder];
        [self addSubview:self.borderView];

        self.timeButton = [self buttonForTimeButton];
        [self addSubview:self.timeButton];

        [self configureConstraints];
    }
    return self;
}

- (void)updateConstraints
{
    [self configureButtonConstraints];
    [super updateConstraints];
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(200.0, WPContentActionViewButtonHeight);
}

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

// Existing button constraints must be deleted prior to this
- (void)configureButtonConstraints
{
    if (!self.needsUpdateButtonConstraints) {
        return;
    }
    self.needsUpdateButtonConstraints = NO;

    NSMutableArray *constraints = [NSMutableArray array];
    UIButton *previousButton;
    NSArray* reversedActionButtons = [[self.actionButtons reverseObjectEnumerator] allObjects];
    for (UIButton *button in reversedActionButtons) {
        NSDictionary *views;
        NSDictionary *metrics = @{@"buttonHeight":@(WPContentActionViewButtonHeight),
                                  @"buttonSpacing":@(WPContentActionViewButtonSpacing)};
        if (previousButton) {
            views = NSDictionaryOfVariableBindings(button, previousButton);

            [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"[button]-(buttonSpacing)-[previousButton]"
                                                                                     options:NSLayoutFormatAlignAllBaseline
                                                                                     metrics:metrics
                                                                                       views:views]];
        } else {
            views = NSDictionaryOfVariableBindings(button);
            [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"[button]|"
                                                                                     options:NSLayoutFormatAlignAllBaseline
                                                                                     metrics:nil
                                                                                       views:views]];
        }
        views = NSDictionaryOfVariableBindings(button);
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


#pragma mark - Public Methods

- (void)addActionButton:(UIButton *)actionButton
{
    actionButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.actionButtons addObject:actionButton];
    [self addSubview:actionButton];
    [self resetButtonConstraints];
}

- (void)removeAllActionButtons
{
    for (UIButton *button in self.actionButtons) {
        [button removeFromSuperview];
    }
    [self.actionButtons removeAllObjects];
    [self resetButtonConstraints];
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


#pragma mark - Private Methods
#pragma mark - Subview factories

- (UIView *)viewForBorder
{
    UIView *borderView = [[UIView alloc] initWithFrame:CGRectZero];
    borderView.translatesAutoresizingMaskIntoConstraints = NO;
    borderView.backgroundColor = [UIColor colorWithRed:241.0/255.0 green:241.0/255.0 blue:241.0/255.0 alpha:1.0];
    return borderView;
}

- (UIButton *)buttonForTimeButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    button.backgroundColor = [UIColor clearColor];
    button.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:12.0f];
    [button setTitleEdgeInsets: UIEdgeInsetsMake(0, 2, 0, -2)];

    // Disable it for now (could be used for permalinks in the future)
    [button setImage:[UIImage imageNamed:@"reader-postaction-time"] forState:UIControlStateDisabled];
    [button setTitleColor:[UIColor colorWithRed:170.0/255.0 green:170.0/255.0 blue:170.0/255.0 alpha:1.0] forState:UIControlStateDisabled];
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
