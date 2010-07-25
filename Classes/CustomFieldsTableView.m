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
    self.navigationItem.leftBarButtonItem.enabled = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    self.getCustomFieldsStripMetadata;
    [saveButtonItem retain];
    [self.tableView reloadData];
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [customFieldsArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
    }
    NSUInteger row = [indexPath row];

    NSString *rowString = [[customFieldsArray objectAtIndex:row] objectForKey:@"key"];
#if defined __IPHONE_3_0
    cell.textLabel.text = rowString;
#else if defined __IPHONE_2_0
    [cell setText:rowString];
#endif
	cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger row = [indexPath row];
    if (row == 0)
        newCustomFieldBool = YES;else
        newCustomFieldBool = NO;

    self.navigationItem.rightBarButtonItem = saveButtonItem;

    if (customFieldsDetailController == nil)
        customFieldsDetailController = [[CustomFieldsDetailController alloc] initWithStyle:UITableViewStyleGrouped];

    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];

#if defined __IPHONE_3_0
    NSString *rowString = cell.textLabel.text;
#else if defined __IPHONE_2_0
    NSString *rowString = cell.text;
#endif

    NSMutableDictionary *theDict = [[NSMutableDictionary alloc] initWithDictionary:[self getDictForThisCell:rowString]];

    [customFieldsDetailController loadData:theDict andNewCustomFieldBool:newCustomFieldBool];
    newCustomFieldBool = NO;

    dm = [BlogDataManager sharedDataManager];
    customFieldsDetailController.postDetailViewController = self.postDetailViewController;
    customFieldsDetailController.pageDetailsController = self.pageDetailsController;
    customFieldsDetailController.isPost = self.isPost;
    [self.navigationController pushViewController:customFieldsDetailController animated:YES];

    [theDict release];
}

- (void)dealloc {
	[super dealloc];
}

- (void)getCustomFieldsStripMetadata {
    dm = [BlogDataManager sharedDataManager];
    NSMutableArray *tempCustomFieldsArray = nil;

    if (_isPost == YES) {
        tempCustomFieldsArray = [dm.currentPost valueForKey:@"custom_fields"];
    } else if (_isPost == NO) {
        tempCustomFieldsArray = [dm.currentPage valueForKey:@"custom_fields"];
    }

    if (tempCustomFieldsArray.count >= 1) {
        int dictsCount = [tempCustomFieldsArray count];

        for (int i = 0; i < dictsCount; i++) {
            NSString *tempKey = [[tempCustomFieldsArray objectAtIndex:i] objectForKey:@"key"];
            if ([tempKey rangeOfString:@"_"].location != NSNotFound) {
                [tempCustomFieldsArray removeObjectAtIndex:i];
                i--;
                dictsCount = [tempCustomFieldsArray count];
            }
        }
    }
    customFieldsArray = [[NSArray alloc] initWithArray:tempCustomFieldsArray];
}

- (NSDictionary *)getDictForThisCell:(NSString *)rowString {
    NSMutableDictionary *oneCustomFieldDict;
    NSDictionary *noCustomFieldsDict = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:@"000", @"id", @"", @"key", @"", @"value", nil] autorelease];
    int count = [customFieldsArray count];

    for (int i = 0; i < count; i++) {
        NSString *tempKey = [[customFieldsArray objectAtIndex:i] objectForKey:@"key"];
        if ([rowString isEqualToString:[[customFieldsArray objectAtIndex:i] objectForKey:@"key"]]) {
            oneCustomFieldDict = [customFieldsArray objectAtIndex:i];
            return oneCustomFieldDict;
        }
    }

    return noCustomFieldsDict;
}

@end
