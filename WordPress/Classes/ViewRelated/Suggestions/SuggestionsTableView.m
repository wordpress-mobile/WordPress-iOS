#import "SuggestionsTableView.h"
#import "WPStyleGuide+Suggestions.h"
#import "SuggestionsTableViewCell.h"
#import "WordPress-Swift.h"

CGFloat const STVDefaultMinHeaderHeight = 0.f;
NSString * const CellIdentifier = @"SuggestionsTableViewCell";
CGFloat const STVRowHeight = 44.f;
CGFloat const STVSeparatorHeight = 1.f;

@interface SuggestionsTableView ()

@property (nonatomic, readonly, nonnull, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIView *separatorView;
@property (nonatomic, strong) NSLayoutConstraint *headerMinimumHeightConstraint;
@property (nonatomic, strong) NSLayoutConstraint *heightConstraint;

@end

@implementation SuggestionsTableView

#pragma mark Public methods

- (instancetype)initWithSiteID:(NSNumber *)siteID
                suggestionType:(SuggestionType)suggestionType
                      delegate:(id <SuggestionsTableViewDelegate>)suggestionsDelegate
{
    NSManagedObjectContext *contextManager = [ContextManager sharedInstance].mainContext;
    SuggestionsListViewModel *viewModel = [[SuggestionsListViewModel alloc] initWithSiteID:siteID context:contextManager];
    viewModel.suggestionType = suggestionType;
    return [self initWithViewModel:viewModel delegate:suggestionsDelegate];
}

- (nonnull instancetype) initWithViewModel:(id <SuggestionsListViewModelType>)viewModel
                                  delegate:(id <SuggestionsTableViewDelegate>)suggestionsDelegate
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _suggestionsDelegate = suggestionsDelegate;
        _enabled = YES;
        _useTransparentHeader = NO;
        _animateWithKeyboard = YES;
        _showLoading = NO;
        _viewModel = viewModel;
        [self setupViewModel];
        [self setupHeaderView];
        [self setupTableView];
        [self setupConstraints];
        [self startObservingNotifications];
    }
    return self;
}

#pragma mark - Custom Setters

- (void)setProminentSuggestionsIds:(NSArray<NSNumber *> *)prominentSuggestionsIds
{
    self.viewModel.prominentSuggestionsIds = prominentSuggestionsIds;
}

- (void)setUseTransparentHeader:(BOOL)useTransparentHeader
{
    _useTransparentHeader = useTransparentHeader;
    [self updateHeaderStyles];
}

#pragma mark - View Lifecycle

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    [self.viewModel reloadData];
}

#pragma mark Private methods

- (void)updateHeaderStyles
{
    if (_useTransparentHeader) {
        [self.headerView setBackgroundColor: [UIColor clearColor]];
        [self.separatorView setBackgroundColor: [WPStyleGuide suggestionsSeparatorSmoke]];
    } else {
        [self.headerView setBackgroundColor: [WPStyleGuide suggestionsHeaderSmoke]];
        [self.separatorView setBackgroundColor: [WPStyleGuide suggestionsHeaderSmoke]];
    }
}

- (void)setupViewModel
{
    __weak __typeof(self) weakSelf = self;
    self.viewModel.searchResultUpdated = ^(id<SuggestionsListViewModelType> viewModel) {
        if (!weakSelf) return;
        [weakSelf.tableView reloadData];
        [weakSelf setNeedsUpdateConstraints];
    };
}

- (void)setupHeaderView
{
    _headerView = [[UIView alloc] init];
    [_headerView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_headerView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapHeader)] ];
    [self addSubview:_headerView];
    
    _separatorView = [[UIView alloc] init];
    [_separatorView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_separatorView setBackgroundColor: [WPStyleGuide suggestionsSeparatorSmoke]];
    [self addSubview:_separatorView];

    [self updateHeaderStyles];
}

- (void)setupTableView
{
    _tableView = [[UITableView alloc] init];
    [_tableView registerClass:[SuggestionsTableViewCell class] forCellReuseIdentifier:CellIdentifier];
    [_tableView setDataSource:self];
    [_tableView setDelegate:self];
    [_tableView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_tableView setRowHeight:STVRowHeight];
    // Table separator insets defined to match left edge of username in cell.
    [_tableView setSeparatorInset:UIEdgeInsetsMake(0.f, 47.f, 0.f, 0.f)];
    // iOS8 added and requires the following in order for that separator inset to be used
    if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [_tableView setLayoutMargins:UIEdgeInsetsZero];
    }
    [self addSubview:_tableView];
}

- (void)setupConstraints
{
    // Pin the table view to the view's edges
    NSDictionary *views = @{@"headerview": self.headerView,
                         @"separatorview": self.separatorView,
                             @"tableview": self.tableView };
    NSDictionary *metrics = @{@"separatorheight" : @(STVSeparatorHeight)};
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[headerview]|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:views]];
        
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[separatorview]|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:views]];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tableview]|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:views]];
        
    // Vertically arrange the header and table
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[headerview][separatorview(separatorheight)][tableview]|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];

    // Add a height constraint to the header view which we can later adjust via the delegate
    self.headerMinimumHeightConstraint = [NSLayoutConstraint constraintWithItem:self.headerView
                                                               attribute:NSLayoutAttributeHeight
                                                               relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                  toItem:nil
                                                               attribute:NSLayoutAttributeNotAnAttribute
                                                              multiplier:1
                                                                constant:0.f];
    [self addConstraint:self.headerMinimumHeightConstraint];

    // Add a height constraint to the table view
    self.heightConstraint = [NSLayoutConstraint constraintWithItem:self.tableView
                                                         attribute:NSLayoutAttributeHeight
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:nil
                                                         attribute:NSLayoutAttributeNotAnAttribute
                                                        multiplier:1
                                                          constant:0.f];
    self.heightConstraint.priority = 300;
        
    [self addConstraint:self.heightConstraint];
}

- (void)startObservingNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidChangeFrame:)
                                                 name:UIKeyboardDidChangeFrameNotification
                                               object:nil];
        
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceOrientationDidChange:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    NSUInteger suggestionCount = self.viewModel.items.count;
    BOOL isSearchApplied = !self.viewModel.searchText.isEmpty;
    BOOL isLoadingSuggestions = self.viewModel.isLoading;
    BOOL showTable = (self.showLoading && isSearchApplied && isLoadingSuggestions) || suggestionCount > 0;
    [self setHidden:!showTable];
    if ([self.suggestionsDelegate respondsToSelector:@selector(suggestionsTableView:didChangeTableBounds:)]) {
        [self.suggestionsDelegate suggestionsTableView:self didChangeTableBounds:self.tableView.bounds];
    }
}

- (void)updateConstraints
{
    // Ask the delegate for a minimum header height, otherwise use default value.
    CGFloat minimumHeaderHeight = STVDefaultMinHeaderHeight;
    if ([self.suggestionsDelegate respondsToSelector:@selector(suggestionsTableViewHeaderMinimumHeight:)]) {
        minimumHeaderHeight = [self.suggestionsDelegate suggestionsTableViewHeaderMinimumHeight:self];
    }
    self.headerMinimumHeightConstraint.constant = minimumHeaderHeight;

    // Take the height of the table frame and make it so only whole results are displayed
    NSUInteger maxRows = floor(self.frame.size.height / STVRowHeight);

    if([self.suggestionsDelegate respondsToSelector:@selector(suggestionsTableViewMaxDisplayedRows:)]){
        NSInteger delegateMaxRows = [self.suggestionsDelegate suggestionsTableViewMaxDisplayedRows:self];

        maxRows = delegateMaxRows;
    }

    if (maxRows < 1) {
        maxRows = 1;
    }    
    
    if (self.viewModel.isLoading) {
        self.heightConstraint.constant = STVRowHeight;
    } else if (self.viewModel.items.count > maxRows) {
        self.heightConstraint.constant = ceilf((maxRows * STVRowHeight) + (STVRowHeight*0.4));
    } else {
        self.heightConstraint.constant = self.viewModel.items.count * STVRowHeight;
    }
    
    [super updateConstraints];
}

- (void)keyboardDidChangeFrame:(NSNotification *)notification
{
    if (!self.animateWithKeyboard) {
        return;
    }
    
    NSDictionary *info = [notification userInfo];
    NSTimeInterval animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [self setNeedsUpdateConstraints];
    
    [UIView animateWithDuration:animationDuration animations:^{
        [self layoutIfNeeded];
    }];
}

- (void)deviceOrientationDidChange:(NSNotification *)notification
{
    [self setNeedsUpdateConstraints];
}

#pragma mark - Public methods

- (BOOL)showSuggestionsForWord:(NSString *)string
{
    if (!self.enabled) { return false; }
    return [self.viewModel searchSuggestionsWithWord: string];
}

- (void)hideSuggestions
{
    [self showSuggestionsForWord:@""];
}

- (NSInteger)numberOfSuggestions {
    return self.viewModel.items.count;
}

- (void)selectSuggestionAtPosition:(NSInteger)position {
    if ([self.viewModel.items count] == 0) {
        return;
    }
    [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:position inSection:0]];
}

- (void)didTapHeader {
    if ([self.suggestionsDelegate respondsToSelector:@selector(suggestionsTableViewDidTapHeader:)]) {
        [self.suggestionsDelegate suggestionsTableViewDidTapHeader:self];
    }
}

#pragma mark - UITableViewDataSource and UITableViewDelegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.viewModel.isLoading ? 1 : [self.viewModel.items count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SuggestionsTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier
                                                                forIndexPath:indexPath];
    
    if (self.viewModel.isLoading) {
        cell.titleLabel.text = NSLocalizedString(@"Loading...", @"Suggestions loading message");
        cell.subtitleLabel.text = nil;
        [cell.iconImageView setImage:nil];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }

    cell.selectionStyle = UITableViewCellSelectionStyleDefault;

    SuggestionViewModel *suggestion = [self.viewModel.items objectAtIndex:indexPath.row];
    cell.titleLabel.text = suggestion.title;
    cell.subtitleLabel.text = suggestion.subtitle;
    [self loadImageFor:suggestion in:cell at:indexPath with:self.viewModel];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SuggestionViewModel *suggestion = [self.viewModel.items objectAtIndex:indexPath.row];
    NSString *currentSearchText = [self.viewModel.searchText substringFromIndex:1];
    if ([self.suggestionsDelegate respondsToSelector:@selector(suggestionsTableView:didSelectSuggestion:forSearchText:)]) {
        [self.suggestionsDelegate suggestionsTableView:self didSelectSuggestion:suggestion.title forSearchText:currentSearchText];
    }
}

@end
