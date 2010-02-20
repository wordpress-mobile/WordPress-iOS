//
//  PostSettingsHelpViewController.m
//  WordPress
//
//  Created by Christopher Boyd on 2/17/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PostSettingsHelpViewController.h"


@implementation PostSettingsHelpViewController
@synthesize helpContent;

#pragma mark -
#pragma mark View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	helpContent = [[NSMutableDictionary alloc] init];
	
	// Add hint content
	[helpContent setObject:kPasswordHintLabel forKey:@"Password"];
	[helpContent setObject:kResizePhotoSettingHintLabel forKey:@"Resize Photos"];
	[helpContent setObject:@"" forKey:@"Include Location"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
}

#pragma mark -
#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return helpContent.count;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    cell.textLabel.text = [helpContent objectForKey:[[helpContent allKeys] objectAtIndex:indexPath.section]];
	
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return [[helpContent allKeys] objectAtIndex:section];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
	[helpContent release];
    [super dealloc];
}


@end

