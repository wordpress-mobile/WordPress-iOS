//
//  WPCategoriesController.m
//  WordPress
//
//  Created by Praveen on 25/06/08.
//

#import "WPCategoriesController.h"
#import "BlogDataManager.h"

@implementation WPCategoriesController

@synthesize postDetailViewController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Initialization code
    }

    return self;
}

/*
   Implement loadView if you want to create a view hierarchy programmatically
   - (void)loadView {
   }
 */

/*
   If you need to do additional setup after loading the view, override viewDidLoad.
   - (void)viewDidLoad {
   }
 */

- (void)refreshData {
    categories = [[[BlogDataManager sharedDataManager] currentPost] valueForKey:@"categories"];
    NSLog(@"<< refreshData %d>> categories %u", [categories count], categories);
    [categoriesTableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    NSLog(@"Categories: viewDidAppear");
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // plus one to because we add a row for "Local Drafts"
    //
    return [categories count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //WordPressAppDelegate *appController = [[UIApplication sharedApplication] delegate];
    NSString *blogTableRowCell = @"categoryTableRowCell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:blogTableRowCell];

    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:blogTableRowCell] autorelease];
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    }

    // Set up the cell
    if ([BlogDataManager sharedDataManager].currentPostIndex == -1 ||[BlogDataManager sharedDataManager].isLocaDraftsCurrent)
        cell.text = [[categories objectAtIndex:indexPath.row] valueForKey:@"categoryName"];else
        cell.text = [categories objectAtIndex:indexPath.row];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([BlogDataManager sharedDataManager].currentPostIndex != -1)
        return;

    id cat = [categories objectAtIndex:indexPath.row];
    BOOL isSelected = [[cat valueForKey:@"isSelected"] boolValue];
    [cat setValue:[NSNumber numberWithBool:!isSelected] forKey:@"isSelected"];
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    [tableView reloadData];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
//
//	id cat = [categories objectAtIndex:indexPath.row];
//	BOOL isSelected = [[cat valueForKey:@"isSelected"] boolValue];
//	[cat setValue:[NSNumber numberWithBool:!isSelected] forKey:@"isSelected"];
}

- (UITableViewCellAccessoryType)tableView:(UITableView *)tv accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath {
    if ([BlogDataManager sharedDataManager].currentPostIndex != -1)
        return UITableViewCellAccessoryNone;

    id cat = [categories objectAtIndex:indexPath.row];
    BOOL isSelected = [[cat valueForKey:@"isSelected"] boolValue];

    return isSelected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return interfaceOrientation == UIInterfaceOrientationPortrait;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

- (void)dealloc {
    [super dealloc];
}

@end
