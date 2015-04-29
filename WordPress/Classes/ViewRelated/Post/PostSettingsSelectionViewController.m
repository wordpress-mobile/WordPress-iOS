#import "PostSettingsSelectionViewController.h"
#import "WPStyleGuide.h"
#import "NSString+XMLExtensions.h"
#import "WPTableViewCell.h"

NSString * const SettingsSelectionTitleKey = @"Title";
NSString * const SettingsSelectionTitlesKey = @"Titles";
NSString * const SettingsSelectionValuesKey = @"Values";
NSString * const SettingsSelectionDefaultValueKey = @"DefaultValue";
NSString * const SettingsSelectionCurrentValueKey = @"CurrentValue";

@interface PostSettingsSelectionViewController ()

@property (nonatomic, strong) NSArray *titles;
@property (nonatomic, strong) NSArray *values;
@property (nonatomic, strong) NSString *defaultValue;
@property (nonatomic, strong) NSObject *currentValue;

@end

@implementation PostSettingsSelectionViewController

// Dictionary should be in the following format
/*
{
    CurrentValue = 0;
    DefaultValue = 0;
    Title = "Image Resize";
    Titles =             (
                          "Always Ask",
                          Small,
                          Medium,
                          Large,
                          Disabled
                          );
    Values =             (
                          0,
                          1,
                          2,
                          3,
                          4
                          );
}
*/

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    return [self initWithStyle:UITableViewStyleGrouped andDictionary:dictionary];
}

- (instancetype)initWithStyle:(UITableViewStyle)style andDictionary:(NSDictionary *)dictionary
{
    self = [self initWithStyle:style];
    if (self) {
        self.title = [dictionary objectForKey:SettingsSelectionTitleKey];
        _titles = [dictionary objectForKey:SettingsSelectionTitlesKey];
        _values = [dictionary objectForKey:SettingsSelectionValuesKey];
        _defaultValue = [dictionary objectForKey:SettingsSelectionDefaultValueKey];
        _currentValue = [dictionary objectForKey:SettingsSelectionCurrentValueKey];

        if (_currentValue == nil) {
            _currentValue = _defaultValue;
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (self.tableView.style == UITableViewStylePlain) {
        // Hides cell dividers.
        self.tableView.tableFooterView = [UIView new];
    }

    [self configureCancelButton];

    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
}

- (void)configureCancelButton
{
    if ([self.navigationController.viewControllers count] > 1) {
        // showing a back button instead
        return;
    }

    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(didTapCancelButton:)];
    self.navigationItem.rightBarButtonItem = cancelButton;
}

- (void)didTapCancelButton:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
    if (self.onCancel) {
        self.onCancel();
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.titles count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[WPTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    cell.accessoryType = UITableViewCellAccessoryNone;

    cell.textLabel.text = [NSString decodeXMLCharactersIn:[self.titles objectAtIndex:indexPath.row]];

    NSString *val = [self.values objectAtIndex:indexPath.row];
    if ([self.currentValue isEqual:val]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }

    [WPStyleGuide configureTableViewCell:cell];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSObject *val = [self.values objectAtIndex:indexPath.row];
    self.currentValue = val;
    [self.tableView reloadData];

    if (self.onItemSelected != nil) {
        self.onItemSelected(val);
    }
}

- (void)dismiss
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
