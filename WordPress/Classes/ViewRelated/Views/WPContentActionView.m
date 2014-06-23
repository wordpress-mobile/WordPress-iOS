#import "WPContentActionView.h"
#import "NSDate+StringFormatting.h"

@interface WPContentActionView()

@property (nonatomic, strong) NSMutableArray *actionButtons;
@property (nonatomic, strong) UIView *borderView;
@property (nonatomic, strong) UIButton *timeButton;
@property (nonatomic, strong) NSTimer *dateRefreshTimer;

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
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.actionButtons = [NSMutableArray array];

        self.borderView = [self viewForBorder];
        [self addSubview:self.borderView];

        self.timeButton = [self buttonForTimeButton];
        [self addSubview:self.timeButton];
    }
    return self;
}

- (void)updateConstraints
{
    [self configureConstraints];
    [super updateConstraints];
}

- (void)configureConstraints
{
    [self removeConstraints:self.constraints];

    NSDictionary *views = NSDictionaryOfVariableBindings(_timeButton, _borderView);
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_timeButton]"
                                                                 options:NSLayoutFormatAlignAllLeft
                                                                 metrics:nil
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_timeButton(48)]|"
                                                                 options:NSLayoutFormatAlignAllCenterY
                                                                 metrics:nil
                                                                   views:views]];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_borderView]|"
                                                                 options:NSLayoutFormatAlignAllTop
                                                                 metrics:nil
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_borderView(1)]"
                                                                 options:NSLayoutFormatAlignAllTop
                                                                 metrics:nil
                                                                   views:views]];


    UIButton *previousButton;
    NSArray* reversedActionButtons = [[self.actionButtons reverseObjectEnumerator] allObjects];
    for (UIButton *button in reversedActionButtons) {
        if (previousButton) {
            views = NSDictionaryOfVariableBindings(button, previousButton);
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[button(48)]-12-[previousButton]"
                                                                         options:NSLayoutFormatAlignAllBaseline
                                                                         metrics:nil
                                                                           views:views]];
        } else {
            views = NSDictionaryOfVariableBindings(button);
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[button]|"
                                                                         options:NSLayoutFormatAlignAllBaseline
                                                                         metrics:nil
                                                                           views:views]];
        }
        UIView *me = self;
        views = NSDictionaryOfVariableBindings(button, me);
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[me]-(<=1)-[button(48)]"
                                                                     options:NSLayoutFormatAlignAllCenterY
                                                                     metrics:nil
                                                                       views:views]];
        previousButton = button;
    }
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(280.0, 48.0);
}


#pragma mark - Public Methods

- (void)addActionButton:(UIButton *)actionButton
{
    actionButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.actionButtons addObject:actionButton];
    [self addSubview:actionButton];
    [self setNeedsUpdateConstraints];
}

- (void)removeAllActionButtons
{
    for (UIButton *button in self.actionButtons) {
        [button removeFromSuperview];
    }
    [self.actionButtons removeAllObjects];
    [self setNeedsUpdateConstraints];
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
    [button setTitleColor:[UIColor colorWithHexString:@"aaa"] forState:UIControlStateDisabled];
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
