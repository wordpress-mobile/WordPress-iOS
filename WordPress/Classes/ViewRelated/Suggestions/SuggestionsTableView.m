#import "SuggestionsTableView.h"
#import "SuggestionsTableViewCell.h"
#import "Suggestion.h"
#import "SuggestionService.h"

NSString * const CellIdentifier = @"SuggestionsTableViewCell";
CGFloat const RowHeight = 50.0f;

@interface SuggestionsTableView ()

@property (nonatomic, strong) NSNumber *siteID;
@property (nonatomic, strong) NSArray *suggestions;
@property (nonatomic, strong) NSString *searchText;
@property (nonatomic, strong) NSArray *searchResults;

@end

@implementation SuggestionsTableView


- (id)initWithWidth:(CGFloat)width andSiteID:(NSNumber *)siteID
{    
    // TODO: Start with height of 0, let VC pin our top
    self = [super initWithFrame:CGRectMake(0.f, 0.f, width, 240.f)];
    if (self) {
        [self registerClass:[SuggestionsTableViewCell class] forCellReuseIdentifier:CellIdentifier];

        _siteID = siteID;
        _suggestions = [[SuggestionService shared] suggestionsForSiteID:_siteID];
        _searchText = @"";
        
        [self setDataSource:self];
        
        [self showSuggestions:NO]; // initially hidden please

        [self setRowHeight:RowHeight];
                
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(suggestionListUpdated:)
                                                     name:SuggestionListUpdatedNotification
                                                   object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Public methods

- (void)showSuggestionsForWord:(NSString *)word
{
    if ([word hasPrefix:@"@"]) {
        self.searchText = [word substringFromIndex:1];
        if (self.searchText.length > 0) {
            NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"(displayName contains[c] %@) OR (userLogin contains[c] %@)",
                                            self.searchText, self.searchText];
            self.searchResults = [self.suggestions filteredArrayUsingPredicate:resultPredicate];
        } else {
            self.searchResults = self.suggestions;
        }
        
        [self reloadData];
        [self showSuggestions:YES];
    } else {
        self.searchText = @"";
        self.searchResults = self.suggestions;
        [self showSuggestions:NO];
    }
}

#pragma mark - Private (helper) methods

- (void)showSuggestions:(BOOL)show
{
    if (show) {
        self.hidden = NO;
        [self.superview bringSubviewToFront:self];
    } else {
        self.hidden = YES;
        [self.superview sendSubviewToBack:self];
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
