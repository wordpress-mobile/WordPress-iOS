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
	
	if( ! flag )
	{
		if( [selectionDelegate respondsToSelector:@selector(selectionTableViewController:completedSelectionsWithContext:selectedObjects:haveChanges:)] )
		{
            NSMutableArray *result = [NSMutableArray array];
            int i=0,count = [categoryNames count];
            for( i=0; i < count; i++ )
            {
                if ( [[selectionStatusOfObjects objectAtIndex:i] boolValue] == YES )
                    [result addObject:[categoryNames objectAtIndex:i]];
            }
			[selectionDelegate selectionTableViewController:self completedSelectionsWithContext:curContext selectedObjects:result haveChanges:[self haveChanges]];
		}		
	}
}

//overriding the main Method
- (void)populateDataSource:(NSArray *)sourceObjects havingContext:(void*)context selectedObjects:(NSArray *)selObjects selectionType:(WPSelectionType)aType andDelegate:(id)delegate
{
    objects = [sourceObjects retain];
	curContext = context;
	selectionType = aType;
	selectionDelegate = delegate;
	
	int i = 0,j=0, k=0,count = [objects count];
	[selectionStatusOfObjects release];
	selectionStatusOfObjects = [[NSMutableArray arrayWithCapacity:count] retain];
	
    if ( categoryNames != nil ) {
        [categoryNames release];
        categoryNames = nil;
	} 
    
    categoryNames = [[NSMutableArray alloc] init];
	for( i=0; i < count; i++ )
	{
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
    // The number of sections is based on the number of items in the data property list.
	WPLog(@"numberOfSectionsInTableView %d",[objects count]);
    return [objects count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	WPLog(@"numberOfRowsInSection %d",section);
	NSArray *subArray=[objects objectAtIndex:section];
	
    return [subArray count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"";
}


//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
//	return 56.0f;
//}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	//UITableViewCell *cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero] autorelease];
    WPLog(@"******** cellForRowAtIndexPath ");
    NSString *selectionTableRowCell = @"selectionTableRowCell";
	
	UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:selectionTableRowCell];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:selectionTableRowCell] autorelease];
		[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
	}
	
	NSArray *subArray=[objects objectAtIndex:indexPath.section];
    WPLog(@"******** cellForRowAtIndexPath %d &&&&&&& %@",indexPath.section,subArray);
    if(subArray){
        if (indexPath.row < [subArray count]) {
			WPLog(@"******** cellForRowAtIndexPath indexPath.row %d",indexPath.row);
			NSDictionary *item = (NSDictionary *)[subArray objectAtIndex:indexPath.row];
			WPLog(@"******** cellForRowAtIndexPath indexPath.row %@",item);
			cell.text = [item valueForKey:@"categoryName"];
		} else {
			cell.text = @"";
		}
	}
	else {
        cell.text = @"";
	}
    NSLog(@"END OF cellForRowAtIndexPath %@",cell.text);
	return cell;
}
- (UITableViewCellAccessoryType)tableView:(UITableView *)aTableView accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath 
{
    WPLog(@"accessoryTypeForRowWithIndexPath 1111111111111 %@",indexPath);
	//	return (UITableViewCellAccessoryType)(UITableViewCellAccessoryCheckmark);
    
    int previousRows = indexPath.section + indexPath.row;
    int currentSection = indexPath.section;
	//    WPLog(@"the indexPath.section is %d",indexPath.section);
	//    WPLog(@"the indexPath.row is %d",indexPath.row);
    while ( currentSection > 0 ) {
        currentSection--;
        previousRows += [self tableView:aTableView numberOfRowsInSection:currentSection] - 1;
    }
	
    WPLog(@"the previousRows is %d",previousRows);
    WPLog(@"the selectionStatusOfObjects is %@",selectionStatusOfObjects);
    
	return (UITableViewCellAccessoryType)( [[selectionStatusOfObjects objectAtIndex:previousRows] boolValue] == YES ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone );	
	
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	
    int previousRows = indexPath.section + indexPath.row;
    int currentSection = indexPath.section;
    WPLog(@"the indexPath.section is %d",indexPath.section);
    WPLog(@"the indexPath.row is %d",indexPath.row);
    while ( currentSection > 0 ) {
        currentSection--;
        previousRows += [self tableView:aTableView numberOfRowsInSection:currentSection] - 1;
    }
	
    WPLog(@"the cliccked row count %d",previousRows);
    
    BOOL curStatus = [[selectionStatusOfObjects objectAtIndex:previousRows] boolValue];
	if( selectionType == kCheckbox )
	{
        WPLog(@" Checkbox selection type .....");
        [selectionStatusOfObjects replaceObjectAtIndex:previousRows withObject:[NSNumber numberWithBool:!curStatus]];
		[aTableView reloadData];		
	}
	
	/*     id kRadio type...
	 else //kRadio
	 {
	 if( curStatus == NO )
	 {
	 int index = [selectionStatusOfObjects indexOfObject:[NSNumber numberWithBool:YES]];
	 [selectionStatusOfObjects replaceObjectAtIndex:indexPath.row withObject:[NSNumber numberWithBool:YES]];
	 if( index >= 0 && index < [selectionStatusOfObjects count]  )
	 [selectionStatusOfObjects replaceObjectAtIndex:index withObject:[NSNumber numberWithBool:NO]];
	 
	 [aTableView reloadData];
	 
	 if ( autoReturnInRadioSelectMode )
	 {
	 [self performSelector:@selector(gotoPreviousScreen) withObject:nil afterDelay:0.2f inModes:[NSArray arrayWithObject:[[NSRunLoop currentRunLoop] currentMode]]];
	 }			
	 }
	 }
	 */
	
	[aTableView deselectRowAtIndexPath:[aTableView indexPathForSelectedRow] animated:YES];
}

@end
