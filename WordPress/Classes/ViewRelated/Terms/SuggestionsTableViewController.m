#import "SuggestionsTableViewController.h"
#import "SuggestionsTableViewCell.h"
#import "Suggestion.h"
#import "UIImageView+Gravatar.h"

@interface SuggestionsTableViewController ()

@end

@implementation SuggestionsTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.delegate = nil;
        self.suggestions = nil;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // create a new Search Bar and add it to the table view
    self.viewSearchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
    [self.viewSearchBar sizeToFit];
    self.tableView.tableHeaderView = self.viewSearchBar;
    self.viewSearchBar.delegate = self;
    
    self.viewSearchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:self.viewSearchBar contentsController:self];
    [self.viewSearchDisplayController setDelegate:self];
    [self.viewSearchDisplayController setSearchResultsDelegate:self];
    [self.viewSearchDisplayController setSearchResultsDataSource:self];
        
    UINib *nib = [UINib nibWithNibName:@"SuggestionsTableViewCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"SuggestionsTableViewCell"];
    
    // suppress display of blank rows
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.viewSearchBar becomeFirstResponder];
    [self.viewSearchBar setText:@"@"];
}

- (void)viewDidDisappear:(BOOL)animated
{
    SEL suggestionSelector = @selector(suggestionViewDidDisappear:);
    if ( [self.delegate respondsToSelector:suggestionSelector] )
    {
        [self.delegate suggestionViewDidDisappear:self];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.viewSearchDisplayController = nil;
    self.viewSearchBar = nil;
    self.delegate = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

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
    SuggestionsTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"SuggestionsTableViewCell"
                                                                      forIndexPath:indexPath];
    
    Suggestion *suggestion = nil;
    
    if ( tableView == self.viewSearchDisplayController.searchResultsTableView ) {
        suggestion = [self.searchResults objectAtIndex:indexPath.row];
    } else {
        suggestion = [self.suggestions objectAtIndex:indexPath.row];
    }
    cell.username.text = suggestion.slug;
    cell.displayName.text = suggestion.description;
    cell.avatar.image = [UIImage imageNamed:@"gravatar"];
    
    UIImage *avatarPlaceholderImage = [UIImage imageNamed:@"gravatar"];
    [cell.avatar setImageWithGravatarEmail:suggestion.avatarEmail fallbackImage:avatarPlaceholderImage];
    
    return cell;
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
    // strip any leading @ from searchText before searching
    if ( 0 < searchText.length ) {
        if ( [[searchText substringToIndex:1] isEqualToString:@"@"] ) {
            searchText = [searchText substringFromIndex:1];
        }
    }
    
    if ( 0 < searchText.length ) {
        NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"(description contains[c] %@) OR (slug contains[c] %@)",   searchText, searchText];
        self.searchResults = [[self.suggestions filteredArrayUsingPredicate:resultPredicate] mutableCopy];
    } else {
        self.searchResults = [self.suggestions mutableCopy];
    }
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString
                               scope:[[self.searchDisplayController.searchBar scopeButtonTitles]
                                      objectAtIndex:[self.searchDisplayController.searchBar
                                                     selectedScopeButtonIndex]]];
    
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SEL suggestionSelector = @selector(suggestionViewDidSelect:selectionString:);
    if ( [self.delegate respondsToSelector:suggestionSelector] )
    {
        Suggestion *suggestion = nil;
        
        if ( tableView == self.viewSearchDisplayController.searchResultsTableView ) {
            suggestion = [self.searchResults objectAtIndex:indexPath.row];
        } else {
            suggestion = [self.suggestions objectAtIndex:indexPath.row];
        }
        
        [self.viewSearchDisplayController setActive:NO animated:NO];
        [self.delegate suggestionViewDidSelect:self selectionString:suggestion.slug ];
    }
}

@end
