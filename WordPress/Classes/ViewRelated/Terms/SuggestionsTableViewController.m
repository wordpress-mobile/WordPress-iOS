#import "SuggestionsTableViewController.h"
#import "SuggestionsTableViewCell.h"
#import "Suggestion.h"
#import "UIImageView+AFNetworking.h"
#import "SuggestionService.h"

NSString * const CellIdentifier = @"SuggestionsTableViewCell";

@interface SuggestionsTableViewController () <UISearchBarDelegate>

@property (nonatomic, strong) NSNumber *siteID;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) NSArray *searchResults;
@property (nonatomic, strong) NSArray *suggestions;

@end

@implementation SuggestionsTableViewController

- (instancetype)initWithSiteID:(NSNumber *)siteID
{
    self = [super init];
    if (self) {
        _siteID = siteID;

        self.title = NSLocalizedString(@"Suggestions", @"Suggestions page title");
    }
    return self;
}

- (void)dealloc
{
    self.delegate = nil;
}

#pragma mark - LifeCycle Methods

- (void)loadView
{
    [super loadView];

    // create a new Search Bar and add it to the table view
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
    [self.searchBar sizeToFit];
    self.searchBar.delegate = self;
    self.searchBar.barTintColor = [WPStyleGuide readGrey];
    self.tableView.tableHeaderView = self.searchBar;

    self.tableView.rowHeight = 50.0;

    UINib *nib = [UINib nibWithNibName:@"SuggestionsTableViewCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:CellIdentifier];

    // suppress display of blank rows
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self updateSearchResults];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.searchBar becomeFirstResponder];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(suggestionListUpdated:)
                                                 name:SuggestionListUpdatedNotification
                                               object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    if ([self.delegate respondsToSelector:@selector(suggestionViewDidDisappear:)])
    {
        [self.delegate suggestionViewDidDisappear:self];
    }
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (!self.suggestions)
    {
        return 1;
    }

    return self.searchResults.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SuggestionsTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier
                                                                          forIndexPath:indexPath];

    if (!self.suggestions)
    {
        cell.usernameLabel.text = NSLocalizedString(@"Loading...", @"Suggestions loading message");
        cell.displayNameLabel.text = nil;
        [cell.avatarImageView setImage:nil];
        return cell;
    }

    Suggestion *suggestion = [self.searchResults objectAtIndex:indexPath.row];

    cell.usernameLabel.text = [NSString stringWithFormat:@"@%@", suggestion.userLogin];
    cell.displayNameLabel.text = suggestion.displayName;

    [self setAvatarForSuggestion:suggestion forCell:cell indexPath:indexPath];

    return cell;
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.suggestions)
    {
        return;
    }

    if ([self.delegate respondsToSelector:@selector(suggestionTableView:didSelectString:)])
    {
        Suggestion *suggestion = [self.searchResults objectAtIndex:indexPath.row];

        [self.delegate suggestionTableView:self didSelectString:suggestion.userLogin];
    }

    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UISearchBarDelegate methods

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    if ([searchBar.text isEqualToString:@""]) {
        searchBar.text = @"@";
    }
    return YES;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self updateSearchResults];
    [self.tableView reloadData];
}

#pragma mark - Suggestion list management

- (void)suggestionListUpdated:(NSNotification *)notification
{
    // only reload if the suggestion list is updated for the current site
    if ([notification.object isEqualToNumber:self.siteID]) {
        self.suggestions = [[SuggestionService shared] suggestionsForSiteID:self.siteID];

        [self updateSearchResults];

        [self.tableView reloadData];
    }
}

- (NSArray *)suggestions
{
    if (!_suggestions) {
        _suggestions = [[SuggestionService shared] suggestionsForSiteID:self.siteID];
    }
    return _suggestions;
}

- (void)updateSearchResults
{
    // strip any leading @ from searchText before searching
    NSString *searchText = [[self.searchBar text] stringByReplacingOccurrencesOfString:@"@" withString:@""];

    if (searchText.length > 0) {
        NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"(displayName contains[c] %@) OR (userLogin contains[c] %@)",
                                        searchText, searchText];
        self.searchResults = [self.suggestions filteredArrayUsingPredicate:resultPredicate];
    }
    else {
        self.searchResults = self.suggestions;
    }
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
            if (cell == [self.tableView cellForRowAtIndexPath:indexPath]) {
                [cell.avatarImageView setImage:image];
            }
        }];
    }
}

@end
