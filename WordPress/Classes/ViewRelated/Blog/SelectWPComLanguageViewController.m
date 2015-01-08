#import "SelectWPComLanguageViewController.h"
#import "WPComLanguages.h"

@interface SelectWPComLanguageViewController () {
    NSArray *_languages;
}

@end

@implementation SelectWPComLanguageViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        _languages = [WPComLanguages allLanguages];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = NSLocalizedString(@"Select Language", nil);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [_languages count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    // Configure the cell...
    NSDictionary *language = [_languages objectAtIndex:indexPath.row];
    cell.textLabel.text = [language objectForKey:@"name"];

    if ([[language objectForKey:@"lang_id"] intValue] == _currentlySelectedLanguageId) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *language = [_languages objectAtIndex:indexPath.row];
    if (self.didSelectLanguage) {
        self.didSelectLanguage(language);
    }
    [self.navigationController popViewControllerAnimated:YES];
}

@end
