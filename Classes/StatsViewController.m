//
//  StatsViewController.m
//  WordPress
//
//  Created by Chris Boyd on 6/17/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import "StatsViewController.h"

@implementation StatsViewController
@synthesize isDownloadingData, tableView, ivChart, scDateRange, category, downloadCategory, labelChartDescription, selectedIndexPath;
@synthesize labelChartPeriod, views, referrers, posts, clicks, terms, scrollView, spinner, chartTitle, chartPeriod, chartRange;

#pragma mark -
#pragma mark View Lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	referrers = [[StatsCollection alloc] init];
	posts = [[StatsCollection alloc] init];
	clicks = [[StatsCollection alloc] init];
	terms = [[StatsCollection alloc] init];
	
	[scrollView setContentSize:CGSizeMake(tableView.frame.size.width, tableView.frame.size.height+100)];
	
	[self performSelectorInBackground:@selector(refreshStatsData) withObject:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

#pragma mark -
#pragma mark TableView Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [[self menuData] count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
    }
    
	cell.textLabel.font = [UIFont boldSystemFontOfSize:16.0];
	cell.textLabel.text = [[self menuData] objectAtIndex:indexPath.row];
	
	switch (indexPath.row) {
		case 0:
			cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", views.count];
			break;
		case 1:
			cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", referrers.count];
			break;
		case 2:
			cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", posts.count];
			break;
		case 3:
			cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", clicks.count];
			break;
		case 4:
			cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", terms.count];
			break;
	}
	
	if(category == nil) {
		cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
	}
    
    return cell;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tv cellForRowAtIndexPath:indexPath];
	cell.imageView.image = [UIImage imageNamed:@"chart"];
	
	switch (indexPath.row) {
		case 0:
			chartTitle = @"Views";
			break;
		case 1:
			chartTitle = @"Referrers";
			break;
		case 2:
			chartTitle = @"Top Posts & Pages";
			break;
		case 3:
			chartTitle = @"Clicks";
			break;
		case 4:
			chartTitle = @"Search Terms";
			break;
	}
	
	[tv deselectRowAtIndexPath:indexPath animated:YES];
	[self updateChart:self];
}

- (void)tableView:(UITableView *)tv accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	StatsCategoryViewController *categoryView = [[StatsCategoryViewController alloc] initWithNibName:@"StatsCategoryViewController" bundle:nil];
	
	
	
	WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
	[delegate showContentDetailViewController:categoryView];
	[tv deselectRowAtIndexPath:indexPath animated:YES];
	[categoryView release];
}

#pragma mark -
#pragma mark Custom Methods

- (NSMutableArray *)menuData {
	NSMutableArray *menu = [[[NSMutableArray alloc] init] autorelease];
	int intCategory = (int)category;
	
	switch (intCategory) {
		case 0:
			[menu addObject:@"Views"];
			[menu addObject:@"Referrers"];
			[menu addObject:@"Top Posts & Pages"];
			[menu addObject:@"Clicks"];
			[menu addObject:@"Search Engine Terms"];
			break;
		case 1:
			self.navigationItem.title = @"Referrers";
			[menu addObject:@"Referrer 1"];
			[menu addObject:@"Referrer 2"];
			[menu addObject:@"Referrer 3"];
			break;
		case 2:
			self.navigationItem.title = @"Top Posts & Pages";
			[menu addObject:@"Post 1"];
			[menu addObject:@"Post 2"];
			[menu addObject:@"Post 3"];
			break;
		case 3:
			self.navigationItem.title = @"Clicks";
			[menu addObject:@"Click 1"];
			[menu addObject:@"Click 2"];
			[menu addObject:@"Click 3"];
			break;
		case 4:
			self.navigationItem.title = @"Search Engine Terms";
			[menu addObject:@"Term 1"];
			[menu addObject:@"Term 2"];
			[menu addObject:@"Term 3"];
			break;
	}
	
	return menu;
}

- (IBAction)updateChart:(id)sender {
	[spinner startAnimating];
	
	[labelChartDescription setAlpha:1.0];
	[labelChartPeriod setAlpha:1.0];
	
	if(chartTitle == nil)
		labelChartDescription.text = @"Chart updated.";
	else
		labelChartDescription.text = chartTitle;
	
	labelChartPeriod.text = [NSString stringWithFormat:@"%@", 
							 [scDateRange titleForSegmentAtIndex:scDateRange.selectedSegmentIndex]];
	
	if(chartPeriod == nil)
		labelChartPeriod.text = [NSString stringWithFormat:@"365 %@ ago to today.", 
								 [[scDateRange titleForSegmentAtIndex:scDateRange.selectedSegmentIndex] lowercaseString]];
	else
		labelChartPeriod.text = chartPeriod;
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:2];
	[labelChartDescription setAlpha:0];
	[labelChartPeriod setAlpha:0];
	[UIView commitAnimations];
	[spinner stopAnimating];
}

- (void)refreshStatsData {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	[spinner startAnimating];
	labelChartDescription.text = @"Loading data...";
	labelChartPeriod.text = @"Please wait.";
	
	NSURL *url;  // Example: http://stats.wordpress.com/csv.php?api_key=00af553ccfbd&blog_id=11952474&table=referrers

	url = [NSURL URLWithString:@"http://stats.wordpress.com/csv.php?api_key=00af553ccfbd&blog_id=11952474&table=views&format=xml"];
	views.data = [NSString stringWithContentsOfURL:url];
	NSLog(@"views.count: %d", views.count);
	
	url = [NSURL URLWithString:@"http://stats.wordpress.com/csv.php?api_key=00af553ccfbd&blog_id=11952474&table=referrers&format=xml"];
	referrers.data = [NSString stringWithContentsOfURL:url];
	NSLog(@"referrers.count: %d", referrers.count);
	
	url = [NSURL URLWithString:@"http://stats.wordpress.com/csv.php?api_key=00af553ccfbd&blog_id=11952474&table=postviews&format=xml"];
	posts.data = [NSString stringWithContentsOfURL:url];
	NSLog(@"posts.count: %d", posts.count);
	
	url = [NSURL URLWithString:@"http://stats.wordpress.com/csv.php?api_key=00af553ccfbd&blog_id=11952474&table=clicks&format=xml"];
	clicks.data = [NSString stringWithContentsOfURL:url];
	NSLog(@"clicks.count: %d", clicks.count);
	
	url = [NSURL URLWithString:@"http://stats.wordpress.com/csv.php?api_key=00af553ccfbd&blog_id=11952474&table=searchterms&format=xml"];
	terms.data = [NSString stringWithContentsOfURL:url];
	NSLog(@"terms.count: %d", terms.count);
	
	[self updateChart:self];
	[tableView reloadData];
	
	[spinner stopAnimating];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[pool release];
}

#pragma mark -
#pragma mark HttpHelper Methods

- (void)httpSuccessWithDataString:(NSString *)data {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)httpFailWithError:(NSError *)error {
	
}

#pragma mark -
#pragma mark Memory Management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)dealloc {
	[selectedIndexPath release];
	[chartRange release];
	[chartPeriod release];
	[chartTitle release];
	[spinner release];
	[scrollView release];
	[labelChartPeriod release];
	[labelChartDescription release];
	[tableView release];
	[ivChart release];
	[scDateRange release];
    [super dealloc];
}


@end
