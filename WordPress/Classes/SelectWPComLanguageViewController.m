//
//  SelectWPComLanguageViewController.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 4/10/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

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
        [self loadLanguages];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = NSLocalizedString(@"Select Language", nil);
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
    
    if ([[language objectForKey:@"lang_id"] intValue] == [_currentlySelectedLanguageId intValue]) {
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
    [self.delegate selectWPComLanguageViewController:self didSelectLanguage:language];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Private Methods

- (void)loadLanguages
{
    if (_languages != nil)
        return;
    
    _languages = [WPComLanguages allLanguages];    
}

@end
