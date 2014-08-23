#import "PostSettingsSelectionViewController.h"
#import "WPStyleGuide.h"
#import "NSString+XMLExtensions.h"
#import "WPTableViewCell.h"

@interface PostSettingsSelectionViewController ()

@property (nonatomic, strong) NSArray *titles;
@property (nonatomic, strong) NSArray *values;
@property (nonatomic, strong) NSString *defaultValue;
@property (nonatomic, strong) NSString *currentValue;

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

- (id)initWithDictionary:(NSDictionary *)dictionary {
    self = [self initWithStyle:UITableViewStyleGrouped];
    
    if (self) {
        self.title = [dictionary objectForKey:@"Title"];
        self.titles = [dictionary objectForKey:@"Titles"];
        self.values = [dictionary objectForKey:@"Values"];
        self.defaultValue = [dictionary objectForKey:@"DefaultValue"];
        self.currentValue = [dictionary objectForKey:@"CurrentValue"];
        
        if (self.currentValue == nil) {
            self.currentValue = self.defaultValue;
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [self.titles count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *val = [self.values objectAtIndex:indexPath.row];
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
