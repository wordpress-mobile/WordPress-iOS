//
//  SettingsPageViewController.m
//  WordPress
//
//  Created by Eric Johnson on 9/3/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "SettingsPageViewController.h"

@interface SettingsPageViewController ()

@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSArray *titles;
@property (nonatomic, strong) NSArray *values;
@property (nonatomic, strong) NSString *defaultValue;
@property (nonatomic, strong) NSString *currentValue;
@property (nonatomic, strong) NSString *info;

@end

@implementation SettingsPageViewController

@synthesize key;
@synthesize titles;
@synthesize values;
@synthesize defaultValue;
@synthesize currentValue;
@synthesize info;

#pragma mark -
#pragma mark Lifecycle Methods



// Dictionary should be a PSMultiValueSpecifier from a settings bundle's plist.
// matching the following format. (Type & Info are optional).
/* 
{
    DefaultValue = 0;
    Key = "media_resize_preference";
    Title = "Image Resize";
    Titles =             (
                          "Always Ask",
                          Small,
                          Medium,
                          Large,
                          Disabled
                          );
    Type = PSMultiValueSpecifier;
    Values =             (
                          0,
                          1,
                          2,
                          3,
                          4
                          );
    Info = ""
}
*/

- (id)initWithDictionary:(NSDictionary *)dictionary {
    self = [self initWithStyle:UITableViewStyleGrouped];

    if (self) {
        self.title = [dictionary objectForKey:@"Title"];
        self.key = [dictionary objectForKey:@"Key"];
        self.titles = [dictionary objectForKey:@"Titles"];
        self.values = [dictionary objectForKey:@"Values"];
        self.defaultValue = [dictionary objectForKey:@"DefaultValue"];
        self.currentValue = [[NSUserDefaults standardUserDefaults] objectForKey:key];
        self.info = [dictionary objectForKey:@"Info"];
        
        if (self.currentValue == nil) {
            self.currentValue = self.defaultValue;
        }
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.backgroundView = nil;
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"settings_bg"]];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}


#pragma mark - 
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [titles count];
}


- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return self.info;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    cell.textLabel.text = [titles objectAtIndex:indexPath.row];

    NSString *val = [values objectAtIndex:indexPath.row];
    if ([currentValue isEqual:val]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *val = [values objectAtIndex:indexPath.row];
    [[NSUserDefaults standardUserDefaults] setObject:val forKey:key];
    [NSUserDefaults resetStandardUserDefaults];
    
    self.currentValue = val;
    
    [self.tableView reloadData];
}

@end
