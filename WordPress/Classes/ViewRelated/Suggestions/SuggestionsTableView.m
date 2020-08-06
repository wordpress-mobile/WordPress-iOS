#import "SuggestionsTableView.h"
#import "WPStyleGuide+Suggestions.h"
#import "SuggestionsTableViewCell.h"
#import "Suggestion.h"
#import "SuggestionService.h"

NSString * const CellIdentifier = @"SuggestionsTableViewCell";
CGFloat const STVRowHeight = 44.f;
CGFloat const STVSeparatorHeight = 1.f;

@interface SuggestionsTableView ()

@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIView *separatorView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *suggestions;
@property (nonatomic, strong) NSString *searchText;
@property (nonatomic, strong) NSMutableArray *searchResults;
@property (nonatomic, strong) NSLayoutConstraint *heightConstraint;

@end

@implementation SuggestionsTableView

#pragma mark Public methods

- (instancetype)init
{    
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _searchText = @"";
        _enabled = YES;
        _searchResults = [[NSMutableArray alloc] init];
        _useTransparentHeader = NO;
        _animateWithKeyboard = YES;
        _showLoading = NO;
        [self setupHeaderView];
        [self setupTableView];
        [self setupConstraints];
        [self startObservingNotifications];
    }
    return self;
}

- (void)setUseTransparentHeader:(BOOL)useTransparentHeader
{
    _useTransparentHeader = useTransparentHeader;
    [self updateHeaderStyles];
}


#pragma mark Private methods

- (void)updateHeaderStyles
{
    if (_useTransparentHeader) {
        [self.headerView setBackgroundColor: [UIColor clearColor]];
        [self.separatorView setBackgroundColor: [WPStyleGuide suggestionsSeparatorSmoke]];
    } else {
        [self.headerView setBackgroundColor: [WPStyleGuide suggestionsHeaderSmoke]];
        [self.separatorView setBackgroundColor: [UIColor clearColor]];
    }
    
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
                        @"separatorview" : self.separatorView,
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
                                             selector:@selector(suggestionListUpdated:)
                                                 name:SuggestionListUpdatedNotification
                                               object:nil];
        
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
    NSUInteger suggestionCount = self.searchResults.count;
    BOOL showTable = (self.showLoading && self.suggestions == nil) || (suggestionCount > 0);
    [self setHidden:!showTable];
    if ([self.suggestionsDelegate respondsToSelector:@selector(suggestionsTableView:didChangeTableBounds:)]) {
        [self.suggestionsDelegate suggestionsTableView:self didChangeTableBounds:self.tableView.bounds];
    }
}

- (void)updateConstraints
{
    // Take the height of the table frame and make it so only whole results are displayed
    NSUInteger maxRows = floor(self.frame.size.height / STVRowHeight);

    if([self.suggestionsDelegate respondsToSelector:@selector(suggestionsTableViewMaxDisplayedRows:)]){
        NSInteger delegateMaxRows = [self.suggestionsDelegate suggestionsTableViewMaxDisplayedRows:self];

        maxRows = delegateMaxRows;
    }

    if (maxRows < 1) {
        maxRows = 1;
    }    
    
    if (!self.suggestions) {
        self.heightConstraint.constant = STVRowHeight;
    } else if (self.searchResults.count > maxRows) {
        self.heightConstraint.constant = ceilf((maxRows * STVRowHeight) + (STVRowHeight*0.4));
    } else {
        self.heightConstraint.constant = self.searchResults.count * STVRowHeight;
    }
    
    [super updateConstraints];
}

- (void)keyboardDidChangeFrame:(NSNotification *)notification
{
    if ( !self.animateWithKeyboard ) {
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

- (BOOL)showSuggestionsForWord:(NSString *)word
{
    if (!self.enabled) {
        return NO;
    }
    
    if ([word hasPrefix:@"@"]) {
        self.searchText = word;
        if (self.searchText.length > 1) {
            NSString *searchQuery = [word substringFromIndex:1];
            NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"(displayName contains[c] %@) OR (userLogin contains[c] %@)",
                                            searchQuery, searchQuery];
            self.searchResults = [[self.suggestions filteredArrayUsingPredicate:resultPredicate] mutableCopy];
        } else {
            self.searchResults = [self.suggestions mutableCopy];
        }
    } else {
        self.searchText = @"";
        [self.searchResults removeAllObjects];
    }
    
    [self.tableView reloadData];
    [self setNeedsUpdateConstraints];
    
    return ([self.searchResults count] > 0);
}

- (void)hideSuggestions
{
    [self showSuggestionsForWord:@""];
}

- (NSInteger)numberOfSuggestions {
    return self.searchResults.count;
}

- (void)selectSuggestionAtPosition:(NSInteger)position {
    if ([self.suggestions count] == 0) {
        return;
    }
    [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:position inSection:0]];
}

- (void)didTapHeader {
    if ([self.suggestionsDelegate respondsToSelector:@selector(suggestionsTableViewDidTapHeader:)]) {
        [self.suggestionsDelegate suggestionsTableViewDidTapHeader:self];
    }
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (!self.suggestions) {
        return 1;
    }
    
    return self.searchResults.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SuggestionsTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier
                                                                forIndexPath:indexPath];
    
    if (!self.suggestions) {
        cell.usernameLabel.text = NSLocalizedString(@"Loading...", @"Suggestions loading message");
        cell.displayNameLabel.text = nil;
        [cell.avatarImageView setImage:nil];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    
    Suggestion *suggestion = [self.searchResults objectAtIndex:indexPath.row];    
    cell.usernameLabel.text = [NSString stringWithFormat:@"@%@", suggestion.userLogin];
    cell.displayNameLabel.text = suggestion.displayName;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.avatarImageView.image = [UIImage imageNamed:@"gravatar"];
    cell.imageDownloadHash = suggestion.imageURL.hash;
    [self loadAvatarForSuggestion:suggestion success:^(UIImage *image) {
        if (indexPath.row >= self.searchResults.count) {
            return;
        }

        Suggestion *reloaded = [self.searchResults objectAtIndex:indexPath.row];
        if (cell.imageDownloadHash != reloaded.imageURL.hash) {
            return;
        }

        cell.avatarImageView.image = image;
    }];

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Suggestion *suggestion = [self.searchResults objectAtIndex:indexPath.row];
    [self.suggestionsDelegate suggestionsTableView:self
                               didSelectSuggestion:suggestion.userLogin
                                     forSearchText:[self.searchText substringFromIndex:1]];
}

#pragma mark - Suggestion list management

- (void)suggestionListUpdated:(NSNotification *)notification
{
    // only reload if the suggestion list is updated for the current site
    if (self.siteID && [notification.object isEqualToNumber:self.siteID]) {
        self.suggestions = [[SuggestionService sharedInstance] suggestionsForSiteID:self.siteID];
        [self showSuggestionsForWord:self.searchText];
    }
}

- (NSArray *)suggestions
{
    if (!_suggestions && _siteID != nil) {
        _suggestions = [[SuggestionService sharedInstance] suggestionsForSiteID:self.siteID];
    }
    return _suggestions;
}

#pragma mark - Avatar helper

- (void)loadAvatarForSuggestion:(Suggestion *)suggestion success:(void (^)(UIImage *))success
{
    CGSize imageSize = CGSizeMake(SuggestionsTableViewCellAvatarSize, SuggestionsTableViewCellAvatarSize);
    UIImage *image = [suggestion cachedAvatarWithSize:imageSize];
    if (image) {
        success(image);
        return;
    }

    [suggestion fetchAvatarWithSize:imageSize success:^(UIImage *image) {
        if (!image) {
            return;
        }

        success(image);
    }];
}

@end
