#import "SuggestionsTableViewController.h"
#import "SuggestionsTableViewCell.h"
#import "Suggestion.h"
#import "UIImageView+Gravatar.h"

@interface SuggestionsTableViewController ()

@end

@implementation SuggestionsTableViewController

@synthesize suggestions;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Initialize stuff here
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // create a new Search Bar and add it to the table view
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
    [searchBar sizeToFit];
    self.tableView.tableHeaderView = searchBar;
    searchBar.delegate = self;
    
    // Get Suggestions
    // @todo get this from cache/REST API
    suggestions = [[NSMutableArray alloc] initWithObjects:
                   [Suggestion suggestionWithSlug:@"@alans19231"
                                      description:@"Alan Shephard"
                                      avatarEmail:@"alans19231@domain.com"],
                   [Suggestion suggestionWithSlug:@"@dekes19241"
                                      description:@"Deke Slayton"
                                      avatarEmail:@"dekes19241@domain.com"],
                   [Suggestion suggestionWithSlug:@"@gordonc19271"
                                      description:@"Gordon Cooper"
                                      avatarEmail:@"gordonc19271@domain.com"],
                   [Suggestion suggestionWithSlug:@"@gusg19261"
                                      description:@"Gus Grissom"
                                      avatarEmail:@"gusg19261@domain.com"],
                   [Suggestion suggestionWithSlug:@"@johng19211"
                                      description:@"John Glenn"
                                      avatarEmail:@"johng19211@domain.com"],
                   [Suggestion suggestionWithSlug:@"@scottc19251"
                                      description:@"Scott Carpenter"
                                      avatarEmail:@"scottc19251@domain.com"],
                   [Suggestion suggestionWithSlug:@"@wallys19231"
                                      description:@"Wally Schirra"
                                      avatarEmail:@"wallys19231@domain.com"],
                   nil];
    
    // @todo define separate NIBs for each kind of suggestions table view cell we need (i.e. not just mentions)
    UINib *nib = [UINib nibWithNibName:@"SuggestionsTableViewCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"SuggestionsTableViewCell"];
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
    return [suggestions count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SuggestionsTableViewCell *cell = [ tableView dequeueReusableCellWithIdentifier:@"SuggestionsTableViewCell"
                                                                      forIndexPath:indexPath];
    
    Suggestion *suggestion = [self.suggestions objectAtIndex:indexPath.row];
    cell.username.text = suggestion.slug;
    cell.displayName.text = suggestion.description;
    cell.avatar.image = [UIImage imageNamed:@"gravatar"];
    
    UIImage *avatarPlaceholderImage = [UIImage imageNamed:@"gravatar"];
    [cell.avatar setImageWithGravatarEmail:suggestion.avatarEmail fallbackImage:avatarPlaceholderImage];
    
    return cell;
}

@end
