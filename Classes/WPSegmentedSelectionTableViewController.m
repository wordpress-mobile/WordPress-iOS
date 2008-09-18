//
//  WPSegmentedSelectionTableViewController.m
//  WordPress
//
//  Created by Janakiram on 16/09/08.
//  Copyright 2008 Effigent. All rights reserved.
//

#import "WPSegmentedSelectionTableViewController.h"


@implementation WPSegmentedSelectionTableViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		// Initialization code
		autoReturnInRadioSelectMode = YES;
        categoryNames = nil;
	}
	return self;
}

- (void)viewWillDisappear:(BOOL)animated {
	if( ! flag ){
		if( [selectionDelegate respondsToSelector:@selector(selectionTableViewController:completedSelectionsWithContext:selectedObjects:haveChanges:)] ){
		//	WPLog(@"########## viewWillDisappear selectionDelegate respondsToSelector categoryNames %@",categoryNames);

            NSMutableArray *result = [NSMutableArray array];
            int i=0,count = [categoryNames count];
            for( i=0; i < count; i++ ){
                if ( [[selectionStatusOfObjects objectAtIndex:i] boolValue] == YES )
					[result addObject:[categoryNames objectAtIndex:i]];
            }
			[selectionDelegate selectionTableViewController:self completedSelectionsWithContext:curContext selectedObjects:result haveChanges:[self haveChanges]];
		}		
	}
}

- (BOOL)haveChanges
{
	int i = 0, count = [categoryNames count];
		
	for( i=0; i < count; i++ )
	{
		if( ![[selectionStatusOfObjects objectAtIndex:i] isEqual:[originalSelObjects objectAtIndex:i]] )
			return YES;
	}
	
	return NO;
}

//overriding the main Method
- (void)populateDataSource:(NSArray *)sourceObjects havingContext:(void*)context selectedObjects:(NSArray *)selObjects selectionType:(WPSelectionType)aType andDelegate:(id)delegate
{
	WPLog(@"populateDataSource:havingContext:");
	objects = [sourceObjects retain];
	curContext = context;
	selectionType = aType;
	selectionDelegate = delegate;
	
	int i = 0, k=0,count = [objects count];
	[selectionStatusOfObjects release];
	selectionStatusOfObjects = [[NSMutableArray arrayWithCapacity:count] retain];
	
    if ( categoryNames != nil ) {
        [categoryNames release];
        categoryNames = nil;
	} 
    
    categoryNames = [[NSMutableArray alloc] init];
	for( i=0; i < count; i++ ){
		NSEnumerator *enumerator =  [[objects objectAtIndex:i] objectEnumerator]; 
		id category = nil;
		while ( category = [enumerator nextObject] ) {
            NSString *catName = [category objectForKey:@"categoryName"];
            [categoryNames addObject:catName];
            BOOL isFound = NO;
            for (k=0;k<[selObjects count];k++ ) {
                if ( [[selObjects objectAtIndex:k] isEqualToString:catName] ) {
                    [selectionStatusOfObjects addObject:[NSNumber numberWithBool:YES]];
                    isFound = YES;
                    break;
                }
		     }
            if ( !isFound )
                [selectionStatusOfObjects addObject:[NSNumber numberWithBool:NO]];
		}
    }
	
    WPLog(@"The Names of the 'categoryName' key  %@",selectionStatusOfObjects);
   	[originalSelObjects release];
	originalSelObjects = [selectionStatusOfObjects copy];
	
	flag = NO;
	[tableView reloadData];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
	//WPLog(@"numberOfSectionsInTableView %d",[objects count]);
    return [objects count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//	WPLog(@"numberOfRowsInSection %d",section);
	NSArray *subArray=[objects objectAtIndex:section];
	
    return [subArray count];
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    NSString *selectionTableRowCell = @"selectionTableRowCell";
	
	UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:selectionTableRowCell];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:selectionTableRowCell] autorelease];
		[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
	}
	
	NSArray *subArray=[objects objectAtIndex:indexPath.section];
    if(subArray){
        if (indexPath.row < [subArray count]) {
			NSDictionary *item = (NSDictionary *)[subArray objectAtIndex:indexPath.row];
			cell.text = [item valueForKey:@"categoryName"];
		} else {
			cell.text = @"";
		}
	}
	else {
        cell.text = @"";
	}
   	return cell;
}
- (UITableViewCellAccessoryType)tableView:(UITableView *)aTableView accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath 
{
 //   WPLog(@"accessoryTypeForRowWithIndexPath 1111111111111 %@",indexPath);
    int previousRows = indexPath.section + indexPath.row;
    int currentSection = indexPath.section;
    while ( currentSection > 0 ) {
        currentSection--;
        previousRows += [self tableView:aTableView numberOfRowsInSection:currentSection] - 1;
    }
	
  //  WPLog(@"the previousRows is %d",previousRows);
//    WPLog(@"the selectionStatusOfObjects is %@",selectionStatusOfObjects);
    
	return (UITableViewCellAccessoryType)( [[selectionStatusOfObjects objectAtIndex:previousRows] boolValue] == YES ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone );	
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	CGFloat height=32.0;
	return height;
}

- (CGFloat)tableView:(UITableView *)aTableView heightForHeaderInSection:(NSInteger)section{
	CGFloat height=10.0;
	[aTableView setSectionHeaderHeight:height];
	return height;
}

- (CGFloat)tableView:(UITableView *)aTableView heightForFooterInSection:(NSInteger)section{

	CGFloat height=0.5;
	[aTableView setSectionFooterHeight:height];
	return height;
}


- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    int previousRows = indexPath.section + indexPath.row;
    int currentSection = indexPath.section;

    while ( currentSection > 0 ) {
        currentSection--;
        previousRows += [self tableView:aTableView numberOfRowsInSection:currentSection] - 1;
    }
	
    
    BOOL curStatus = [[selectionStatusOfObjects objectAtIndex:previousRows] boolValue];
	if( selectionType == kCheckbox ){
        [selectionStatusOfObjects replaceObjectAtIndex:previousRows withObject:[NSNumber numberWithBool:!curStatus]];
		[aTableView reloadData];		
	}
	
	[aTableView deselectRowAtIndexPath:[aTableView indexPathForSelectedRow] animated:YES];
}

@end
