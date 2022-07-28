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
    _prominentSuggestionsIds = prominentSuggestionsIds;
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
        CGFloat sectionHeaderAndFooterHeight = viewModel.sections.count > 1 ? -1 : 0;
        [weakSelf.tableView setSectionHeaderHeight:sectionHeaderAndFooterHeight];
        [weakSelf.tableView setSectionFooterHeight:sectionHeaderAndFooterHeight];
        [weakSelf.tableView reloadData];
        [weakSelf setNeedsUpdateConstraints];
        [weakSelf setNeedsLayout];
        [weakSelf layoutIfNeeded];
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
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    [_tableView registerClass:[SuggestionsTableViewCell class] forCellReuseIdentifier:CellIdentifier];
    [_tableView setDataSource:self];
    [_tableView setDelegate:self];
    [_tableView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_tableView setRowHeight:STVRowHeight];
    [_tableView setBackgroundColor:[UIColor systemBackgroundColor]];

    // Removes a small padding at the bottom of the tableView
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, CGFLOAT_MIN)];
    footerView.backgroundColor = [UIColor clearColor];
    [_tableView setTableFooterView:footerView];

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
    NSUInteger suggestionCount = self.viewModel.sections.count;
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

    // Get the number of max rows from the delegate.
    NSNumber *maxRows = nil;
    if([self.suggestionsDelegate respondsToSelector:@selector(suggestionsTableViewMaxDisplayedRows:)]){
        NSUInteger delegateMaxRows = [self.suggestionsDelegate suggestionsTableViewMaxDisplayedRows:self];
        maxRows = [NSNumber numberWithUnsignedInteger:delegateMaxRows];
    }

    // Set height constraint
    [self.tableView setNeedsLayout];
    [self.tableView layoutIfNeeded];
    if (maxRows) {
        self.heightConstraint.constant = [SuggestionsTableView maximumHeightForTableView:self.tableView
                                                                maxNumberOfRowsToDisplay:maxRows];
    } else {
        self.heightConstraint.constant = [SuggestionsTableView heightForTableView:self.tableView
                                                                    maximumHeight:self.bounds.size.height - minimumHeaderHeight];
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

- (void)selectSuggestionAtIndexPath:(NSIndexPath *)indexPath {
    NSArray<SuggestionsListSection *> *sections = self.viewModel.sections;
    if (indexPath.section < sections.count && indexPath.row < sections[indexPath.section].rows.count) {
        [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
    }
}

- (void)didTapHeader {
    if ([self.suggestionsDelegate respondsToSelector:@selector(suggestionsTableViewDidTapHeader:)]) {
        [self.suggestionsDelegate suggestionsTableViewDidTapHeader:self];
    }
}

@end
