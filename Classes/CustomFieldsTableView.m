//
//  CustomFieldsTableView.m
//  WordPress
//
//  Created by John Bickerstaff on 5/5/09.
//  
//

#import "CustomFieldsTableView.h"

@implementation CustomFieldsTableView

@synthesize postDetailViewController, dm, customFieldsArray, customFieldsTableView;
@synthesize customFieldsDetailController, pageDetailsController;
@synthesize isPost = _isPost;

/*
   - (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
    }
    return self;
   }
 */

- (void)viewDidLoad {
    [super viewDidLoad];
    //self.getCustomFieldsStripMetadata;

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.navigationItem.leftBarButtonItem.enabled = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    self.getCustomFieldsStripMetadata;
//TODO:JOHNB CustomFields - refactor this so I can call this view from pages or posts - perhaps a BOOL that gets set when this view is called?
    //with luck all we need to do is populate the customFieldsArray from the Pages... currentPage? and we're done
    //no this is all in the context of PostsViewController - different context and troublesome to figure it all out for Pages... maybe better to just copy?
    NSLog(@"inside viewWillAppear, hopefully reloading data now");
    [saveButtonItem retain];
    //[customFieldsTableView reloadData];
    [self.tableView reloadData];
    [super viewWillAppear:animated];
}

//- (void) viewWillDisappear {
//	postDetailViewController.hasChanges=YES;
//	NSLog(@"has changes out of view will dissapear in Custom Fields Table View %@", postDetailViewController.hasChanges);
//
//}

/*
   - (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
   }
 */
/*
   - (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
   }
 */
/*
   - (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
   }
 */

/*
   // Override to allow orientations other than the default portrait orientation.
   - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
   }
 */

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //return [customFieldsArray count] +1;
    return [customFieldsArray count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"inside cell for row");
    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
    }

    // Set up the cell...

    // Configure the cell
    NSUInteger row = [indexPath row];

//	if (row == 0)
//	cell.textLabel.text = @"Add Custom Field";
//	else{
    //NSString *rowString = [[customFieldsArray objectAtIndex:row-1] objectForKey:@"key"];
    NSString *rowString = [[customFieldsArray objectAtIndex:row] objectForKey:@"key"];
    NSLog(@"rowString is %@", rowString);
#if defined __IPHONE_3_0
    cell.textLabel.text = rowString;
#else if defined __IPHONE_2_0
    [cell setText:rowString];
#endif
	cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
    //cell.text = rowString;
    NSLog(@"after cell.text = rowString");
    //}
    return cell;
}

//- (UITableViewCellAccessoryType)tableView:(UITableView *)tableView accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath {
//    return UITableViewCellAccessoryDisclosureIndicator;
//}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger row = [indexPath row];

    //NSString *rowString = [customFieldsArray objectAtIndex:row];
    if (row == 0)
        newCustomFieldBool = YES;else
        newCustomFieldBool = NO;

    self.navigationItem.rightBarButtonItem = saveButtonItem;

    //if (customFieldsEditView == nil)
    //customFieldsEditView = [[CustomFieldsEditView alloc] initWithNibName:@"CustomFieldsEditView" bundle:nil];

    if (customFieldsDetailController == nil)
        customFieldsDetailController = [[CustomFieldsDetailController alloc] initWithStyle:UITableViewStyleGrouped];

    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];

#if defined __IPHONE_3_0
    NSString *rowString = cell.textLabel.text;
#else if defined __IPHONE_2_0
    NSString *rowString = cell.text;
#endif

    //get the right NSDict out of the customFieldsArray using the rowString to key into the NSDict
    NSMutableDictionary *theDict = [[NSMutableDictionary alloc] initWithDictionary:[self getDictForThisCell:rowString]];

    //pass theDict to customFieldsEditView
    //[customFieldsEditView loadData:theDict];
    [customFieldsDetailController loadData:theDict andNewCustomFieldBool:newCustomFieldBool];
    newCustomFieldBool = NO;

    dm = [BlogDataManager sharedDataManager];
    [dm printDictToLog:theDict andDictName:@"test from CustomFieldsTableView:didSelectRowAt... isn't it key and value"];

    //[self.navigationController pushViewController:customFieldsEditView animated:YES];
    customFieldsDetailController.postDetailViewController = self.postDetailViewController;
    customFieldsDetailController.pageDetailsController = self.pageDetailsController;
    customFieldsDetailController.isPost = self.isPost;
    [self.navigationController pushViewController:customFieldsDetailController animated:YES];

    [theDict release];
}

/*
   // Override to support conditional editing of the table view.
   - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
   }
 */

/*
   // Override to support editing the table view.
   - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {

    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
   }
 */

/*
   // Override to support rearranging the table view.
   - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
   }
 */

/*
   // Override to support conditional rearranging of the table view.
   - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
   }
 */

- (void)dealloc {
    //[customFieldsEditView release];
    //[customFieldsArray release];

    [super dealloc];
}

- (void)getCustomFieldsStripMetadata {
    //called from viewDidLoad (maybe should be view will appear?) and populates latest custom fields from currentPost:custom_fields NSDicts
    //get the data from BlogDataManager God-object
    dm = [BlogDataManager sharedDataManager];
    NSMutableArray *tempCustomFieldsArray = nil;

    if (_isPost == YES) {
        tempCustomFieldsArray = [dm.currentPost valueForKey:@"custom_fields"];
    } else if (_isPost == NO) {
        tempCustomFieldsArray = [dm.currentPage valueForKey:@"custom_fields"];
    }

    //NSLog(@"tempCustomFieldsArray count is.... %@", tempCustomFieldsArray.count);
    if (tempCustomFieldsArray.count >= 1) {
        //strip out any underscore-containing NSDicts inside the array, as this is metadata we don't need to touch
        int dictsCount = [tempCustomFieldsArray count];

        for (int i = 0; i < dictsCount; i++) {
            NSString *tempKey = [[tempCustomFieldsArray objectAtIndex:i] objectForKey:@"key"];
            NSLog(@"Strip Metadata tempKey is... %@", tempKey);

            //if tempKey contains an underscore, remove that object (NSDict with metadata) from the array and move on
            if ([tempKey rangeOfString:@"_"].location != NSNotFound) {
                NSLog(@"Found an underscore metadata 'member' and removing it %@", tempKey);
                [tempCustomFieldsArray removeObjectAtIndex:i];
                //if I remove one, the count goes down and we stop too soon unless we subtract one from i
                //and re-set dictsCount.  Doing this keeps us in sync with the actual array.count
                i--;
                dictsCount = [tempCustomFieldsArray count];
            }
        }

        //remember to send tempCustomFieldsArray to the next ui view for use there
        //it will also be used to populate the cells... Key value will go in cells
    } else {
        //TODO:JOHNB:CustomFields: dummy up an array with nothing and send instead (maybe one line for cells that says "no custom fields for this blog"
        //or a popup...
    }

    //Get the data needed (contents of custom_fields) into an array
    //Probably a helper method in DM that returns an array of NSDicts without the "underscore" fields
    //someArray = dm.getCurrentPostCustomFieldsWithoutMetadata
    //send that array to the LoadData method of the CustomFieldsTableView so it can be used to populate the cells
    //this will need to be passed into the CustomFieldsEditView as well...? something has to be passed on cell click
    //What data needs to go into this?  WPSelectionTableViewController may help

    customFieldsArray = [[NSArray alloc] initWithArray:tempCustomFieldsArray];

    [dm printArrayToLog:customFieldsArray andArrayName:@"customFieldsArray right after assignment in stripMetadata"];
}

- (NSDictionary *)getDictForThisCell:(NSString *)rowString {
    NSMutableDictionary *oneCustomFieldDict;
    NSDictionary *noCustomFieldsDict = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:@"000", @"id", @"", @"key", @"", @"value", nil] autorelease];
    int count = [customFieldsArray count];

    for (int i = 0; i < count; i++) {
        NSString *tempKey = [[customFieldsArray objectAtIndex:i] objectForKey:@"key"];
        NSLog(@"tempKey is... %@", tempKey);

        //if tempKey contains an underscore, remove that object (NSDict with metadata) from the array and move on
        //if([tempKey rangeOfString:@"edit_"].location != NSNotFound)
        if ([rowString isEqualToString:[[customFieldsArray objectAtIndex:i] objectForKey:@"key"]]) {
            //if ([rowString isEqualToString:tempKey])
            NSLog(@"Keys should match tempKey = %@ <--> rowString = %@", tempKey, rowString);
            //grab the NSDict here
            oneCustomFieldDict = [customFieldsArray objectAtIndex:i];
            //return it
            return oneCustomFieldDict;
        } else {
            //return the Dict which has the "empty" fields
            //return noCustomFieldsDict;
        }
    }

    return noCustomFieldsDict;
}

@end
