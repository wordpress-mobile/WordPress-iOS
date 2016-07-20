#import "SettingsSelectionViewController.h"
#import "WPStyleGuide.h"
#import "NSDictionary+SafeExpectations.h"
#import "NSString+XMLExtensions.h"
#import "WPTableViewCell.h"
#import "WPTableViewSectionHeaderFooterView.h"

NSString * const SettingsSelectionTitleKey = @"Title";
NSString * const SettingsSelectionTitlesKey = @"Titles";
NSString * const SettingsSelectionValuesKey = @"Values";
NSString * const SettingsSelectionHintsKey = @"Hints";
NSString * const SettingsSelectionDefaultValueKey = @"DefaultValue";
NSString * const SettingsSelectionCurrentValueKey = @"CurrentValue";

CGFloat const SettingsSelectionDefaultTableViewCellHeight = 44.0f;

@implementation SettingsSelectionViewController

/**
    Dictionary should be in the following format:
     {
        CurrentValue    : 0,
        DefaultValue    : 0,
        Title           : "Image Resize",
        Titles          : [ "Always Ask", "Small", "Medium", "Large", "Disabled" ],
        Values          : [ 0, 1, 2, 3, 4, 5 ]
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
        self.title = [dictionary stringForKey:SettingsSelectionTitleKey];
        _titles = [dictionary arrayForKey:SettingsSelectionTitlesKey];
        _values = [dictionary arrayForKey:SettingsSelectionValuesKey];
        _hints = [dictionary arrayForKey:SettingsSelectionHintsKey];
        _defaultValue = dictionary[SettingsSelectionDefaultValueKey];
        _currentValue = dictionary[SettingsSelectionCurrentValueKey] ?: _defaultValue;
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

- (CGSize)preferredContentSize
{
    CGSize size = [super preferredContentSize];

    if (self.tableView.style == UITableViewStylePlain) {
        size.height = [self.titles count] * SettingsSelectionDefaultTableViewCellHeight;
    }

    return size;
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

    NSString *val = [self.values objectAtIndex:indexPath.row];
    cell.accessoryType = [self.currentValue isEqual:val] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    cell.textLabel.text = [NSString decodeXMLCharactersIn:[self.titles objectAtIndex:indexPath.row]];

    [WPStyleGuide configureTableViewCell:cell];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSObject *val = self.values[indexPath.row];
    self.currentValue = val;
    
    [self.tableView reloadData];

    if (self.onItemSelected != nil) {
        self.onItemSelected(val);
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    NSUInteger position = [self.values indexOfObject:self.currentValue];
    return (position != NSNotFound) ? self.hints[position] : nil;
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    [WPStyleGuide configureTableViewSectionFooter:view];
}

- (void)dismiss
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
