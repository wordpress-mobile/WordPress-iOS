#import "SuggestionsTableViewController.h"
#import "SuggestionsTableViewCell.h"
#import "Suggestion.h"
#import "UIImageView+AFNetworking.h"
#import "SuggestionService.h"

NSString * const CellIdentifier = @"SuggestionsTableViewCell";

@interface SuggestionsTableViewController () <UISearchBarDelegate, UISearchDisplayDelegate>

@property (nonatomic, strong) NSNumber *siteID;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UISearchDisplayController *searchController;
@property (nonatomic, strong) NSArray *searchResults;
@property (nonatomic, strong) NSArray *suggestions;

@end

@implementation SuggestionsTableViewController

- (instancetype)initWithSiteID:(NSNumber *)siteID
{
    self = [super init];
    if (self) {
        _siteID = siteID;
    }
    return self;
}

- (void)dealloc {
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
    self.tableView.tableHeaderView = self.searchBar;

    self.searchController = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar
                                                              contentsController:self];
    self.searchController.searchResultsDataSource = self;
    self.searchController.searchResultsDelegate = self;
    self.searchController.delegate = self;
    
    UINib *nib = [UINib nibWithNibName:@"SuggestionsTableViewCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:CellIdentifier];
    
    // suppress display of blank rows
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.title = NSLocalizedString(@"Suggestions", @"Suggestions page title");

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(suggestionListUpdated:)
                                                 name:SuggestionListUpdatedNotification
                                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self.searchBar becomeFirstResponder];
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
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return [self.searchResults count];
        
    } else {
        return [self.suggestions count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SuggestionsTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier
                                                                          forIndexPath:indexPath];
    
    Suggestion *suggestion = nil;

    if (tableView == self.searchController.searchResultsTableView) {
        suggestion = [self.searchResults objectAtIndex:indexPath.row];
    } else {
        suggestion = [self.suggestions objectAtIndex:indexPath.row];
    }

    cell.usernameLabel.text = [NSString stringWithFormat:@"@%@", suggestion.userLogin];
    cell.displayNameLabel.text = suggestion.displayName;

    [self setAvatarForSuggestion:suggestion forCell:cell indexPath:indexPath];

    return cell;
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(suggestionTableView:didSelectString:)])
    {
        Suggestion *suggestion = nil;
        
        if (tableView == self.searchController.searchResultsTableView) {
            suggestion = [self.searchResults objectAtIndex:indexPath.row];
        } else {
            suggestion = [self.suggestions objectAtIndex:indexPath.row];
        }
        
        [self.delegate suggestionTableView:self didSelectString:suggestion.userLogin];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString
                               scope:[[controller.searchBar scopeButtonTitles]
                                      objectAtIndex:[controller.searchBar selectedScopeButtonIndex]]];

    return YES;
}

- (void)filterContentForSearchText:(NSString *)searchText scope:(NSString *)scope
{
    // strip any leading @ from searchText before searching
    if (searchText.length > 1 && [[searchText substringToIndex:1] isEqualToString:@"@"]) {
        if ([[searchText substringToIndex:1] isEqualToString:@"@"]) {
            searchText = [searchText substringFromIndex:1];
        }
        
        NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"(displayName contains[c] %@) OR (userLogin contains[c] %@)",
                                        searchText, searchText];
        self.searchResults = [self.suggestions filteredArrayUsingPredicate:resultPredicate];
    }
    else {
        self.searchResults = self.suggestions;
    }
}

#pragma mark - UISearchBarDelegate methods

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    if ([searchBar.text isEqualToString:@""]) {
        searchBar.text = @"@";
    }
    return YES;
}

#pragma mark - Suggestion list management

- (void)suggestionListUpdated:(NSNotification *)notification {
    // only reload if the suggestion list is updated for the current site
    if ([notification.object isEqualToNumber:self.siteID]) {
        self.suggestions = [[SuggestionService shared] suggestionsForSiteID:self.siteID];
        [self.tableView reloadData];

        /**
         This will trigger a reload for the search controller, for some reason
         [self.searchController.searchResultsTableView reloadData]; doesn't work when there was
         no result before the reload.
         */
        self.searchBar.text = self.searchBar.text;
    }
}

- (NSArray *)suggestions {
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
            if (cell == [self.tableView cellForRowAtIndexPath:indexPath]
                || cell == [self.searchController.searchResultsTableView cellForRowAtIndexPath:indexPath]) {
                [cell.avatarImageView setImage:image];
            }
        }];
    }
}

@end
