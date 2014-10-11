#import "SuggestionsTableView.h"
#import "SuggestionsTableViewCell.h"
#import "Suggestion.h"
#import "SuggestionService.h"

NSString * const CellIdentifier = @"SuggestionsTableViewCell";
CGFloat const RowHeight = 48.0f;

@interface SuggestionsTableView ()

@property (nonatomic, strong) NSNumber *siteID;
@property (nonatomic, strong) NSArray *suggestions;
@property (nonatomic, strong) NSString *searchText;
@property (nonatomic, strong) NSMutableArray *searchResults;
@property (nonatomic, strong) NSLayoutConstraint *heightConstraint;

@end

@implementation SuggestionsTableView


- (id)initWithSiteID:(NSNumber *)siteID
{    
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self registerClass:[SuggestionsTableViewCell class] forCellReuseIdentifier:CellIdentifier];

        _siteID = siteID;
        _suggestions = [[SuggestionService shared] suggestionsForSiteID:_siteID];
        _searchText = @"";
        _searchResults = [[NSMutableArray alloc] init];
        
        [self setDataSource:self];
        [self setDelegate:self];
        
        [self setRowHeight:RowHeight];
        [self addDynamicHeightConstraint];
                        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(suggestionListUpdated:)
                                                     name:SuggestionListUpdatedNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardDidChangeFrame:)
                                                     name:UIKeyboardDidChangeFrameNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardDidHide:)
                                                     name:UIKeyboardDidHideNotification
                                                   object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)reloadData
{
    [super reloadData];
    [self updateDynamicHeightConstraint];
}

- (void)addDynamicHeightConstraint
{
    self.heightConstraint = [NSLayoutConstraint constraintWithItem:self
                                                         attribute:NSLayoutAttributeHeight
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:nil
                                                         attribute:nil
                                                        multiplier:1
                                                          constant:0];
    
    [self addConstraint:self.heightConstraint];
}

- (void)updateDynamicHeightConstraint
{
    // TODO: Don't assume there is always a navBar and allow the VC to specify additional withholding (e.g. when used on post view)
    CGFloat navBarHeight = 44.0f;
    
    NSUInteger maxRows = floor((self.frame.origin.y + self.frame.size.height - navBarHeight) / RowHeight);
    if (maxRows < 1) {
        maxRows = 1;
    }    
    
    if (self.searchResults.count > maxRows) {
        self.heightConstraint.constant = maxRows * RowHeight;        
    } else {
        self.heightConstraint.constant = self.searchResults.count * RowHeight;
    }
    
    [self needsUpdateConstraints];
}

- (void)keyboardDidChangeFrame:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    NSTimeInterval animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [self updateDynamicHeightConstraint];
    
    [UIView animateWithDuration:animationDuration animations:^{
        [self layoutIfNeeded];
    }];
}

- (void)keyboardDidHide:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    NSTimeInterval animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    [self updateDynamicHeightConstraint];

    [UIView animateWithDuration:animationDuration animations:^{
        [self layoutIfNeeded];
    }];
}

#pragma mark - Public methods

- (void)showSuggestionsForWord:(NSString *)word
{
    if ([word hasPrefix:@"@"]) {
        self.searchText = [word substringFromIndex:1];
        if (self.searchText.length > 0) {
            NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"(displayName contains[c] %@) OR (userLogin contains[c] %@)",
                                            self.searchText, self.searchText];
            self.searchResults = [[self.suggestions filteredArrayUsingPredicate:resultPredicate] mutableCopy];
        } else {
            self.searchResults = [self.suggestions mutableCopy];
        }
    } else {
        self.searchText = @"";
        [self.searchResults removeAllObjects];
    }
    
    [self reloadData];
}

#pragma mark - UITableViewDataSource methods

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 1.0f; 
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] init];
    headerView.backgroundColor = [WPStyleGuide readGrey];
    return headerView;
}

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
    SuggestionsTableViewCell *cell = [self dequeueReusableCellWithIdentifier:CellIdentifier
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
    
    [self setAvatarForSuggestion:suggestion forCell:cell indexPath:indexPath];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Suggestion *suggestion = [self.searchResults objectAtIndex:indexPath.row];
    [self.suggestionsDelegate didSelectSuggestion:suggestion.userLogin forSearchText:self.searchText];    
}

#pragma mark - Suggestion list management

- (void)suggestionListUpdated:(NSNotification *)notification
{
    // only reload if the suggestion list is updated for the current site
    if ([notification.object isEqualToNumber:self.siteID]) {
        self.suggestions = [[SuggestionService shared] suggestionsForSiteID:self.siteID];
        [self showSuggestionsForWord:self.searchText];
    }
}

- (NSArray *)suggestions
{
    if (!_suggestions) {
        _suggestions = [[SuggestionService shared] suggestionsForSiteID:self.siteID];
    }
    return _suggestions;
}

#pragma mark - Avatar helper

- (void)setAvatarForSuggestion:(Suggestion *)post forCell:(SuggestionsTableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    CGSize imageSize = CGSizeMake(SuggestionsTableViewCellAvatarSize, SuggestionsTableViewCellAvatarSize);
    UIImage *image = [post cachedAvatarWithSize:imageSize];
    if (image) {
        [cell.avatarImageView setImage:image];
    } else {
        [cell.avatarImageView setImage:[UIImage imageNamed:@"gravatar"]];
        [post fetchAvatarWithSize:imageSize success:^(UIImage *image) {
            if (!image) {
                return;
            }
            if (cell == [self cellForRowAtIndexPath:indexPath]) {
                [cell.avatarImageView setImage:image];
            }
        }];
    }
}

@end
