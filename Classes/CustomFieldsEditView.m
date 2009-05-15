//
//  CustomFieldEditView.m
//  WordPress
//
//  Created by John Bickerstaff on 5/5/09.
//  Copyright 2009 Smilodon Software. All rights reserved.
//

#import "CustomFieldsEditView.h"


@implementation CustomFieldsEditView

@synthesize keyField, valueField, idField, customFieldsDict, currentEditingTextField;
@synthesize postDetailViewController, dm;


/*
 // The designated initializer. Override to perform setup that is required before the view is loaded.
 - (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
 if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
 // Custom initialization
 }
 return self;
 }
 */

/*
 // Implement loadView to create a view hierarchy programmatically, without using a nib.
 - (void)loadView {
 }
 */




 // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
 - (void)viewDidLoad {
 [super viewDidLoad];
	 idField.hidden = YES;
	 self.title = @"Edit Post Custom Field";
	 keyField.text	= [customFieldsDict valueForKey:@"key"];
	 valueField.text = [customFieldsDict valueForKey:@"value"];

 } 



/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */


- (void)textFieldDidBeginEditing:(UITextField *)textField {
	self.currentEditingTextField = textField;
	self.navigationItem.rightBarButtonItem = postDetailViewController.saveButton;
	postDetailViewController.hasChanges = YES;
	
	
	if (postDetailViewController.navigationItem.leftBarButtonItem.style == UIBarButtonItemStyleDone) {
		
		//[self textViewDidEndEditing:textView];
	}
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	dm = [BlogDataManager sharedDataManager];
	[dm printDictToLog:customFieldsDict	andArrayName:@"test from textFieldDidEndEditing, CustomFieldsEditView... isn't it key and value"];
	self.currentEditingTextField = nil;
	if( textField == keyField )
		[customFieldsDict setValue:textField.text forKey:@"key"];
		
		
	else if( textField == valueField )
		[customFieldsDict setValue:textField.text forKey:@"value"];
		//[[BlogDataManager sharedDataManager].currentPost setValue:tagsTextField.text forKey:@"mt_keywords"];
	//write back to the datastructure in what?  currentPost eventually...
	//ahh... get the id and use that, eh?
	[self writeCustomFieldsToCurrentPostUsingID];
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	postDetailViewController.hasChanges = YES;
	return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
	postDetailViewController.hasChanges = YES;
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	self.currentEditingTextField = nil;
	[textField resignFirstResponder];
	return YES;
}


- (IBAction)textFieldDoneEditing:(id)sender
{
	[sender resignFirstResponder];
}
 

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


-(void)loadData:(NSDictionary *) theDict {
	NSLog(@"LoadData Got to here...");
	customFieldsDict = [[NSMutableDictionary alloc] initWithDictionary:theDict];
	NSLog(@"and now here after assigning the Dict");
	keyField.text	= [customFieldsDict valueForKey:@"key"];
	valueField.text = [customFieldsDict valueForKey:@"value"];
}

- (void) writeCustomFieldsToCurrentPostUsingID{
	
	//in here, get the id from customFieldsDict and use it to access
	//currentPost:custom_fields and find the right dict and then copy it in...
	NSString *ID = [customFieldsDict valueForKey:@"id"];
	dm = [BlogDataManager sharedDataManager];
	//NSMutableDictionary
	NSMutableArray *tempCustomFieldsArray = [dm.currentPost valueForKey:@"custom_fields"];
	//NSLog(@"tempCustomFieldsArray count is.... %@", tempCustomFieldsArray.count);
	if (tempCustomFieldsArray.count >=1)
	{
		int dictsCount = [tempCustomFieldsArray count];
		for(int i = 0;i < dictsCount;i++){
			//if the match for ID is found in this particular dict inside the array
			if ([[tempCustomFieldsArray objectAtIndex:i] objectForKey:@"id"] == ID){
				//replace the dict in the array with customFieldsDict (which holds any new values)
				[tempCustomFieldsArray replaceObjectAtIndex:i withObject:customFieldsDict];
				//replace the custom_fields array in currentPost with tempCustomFieldsArray (which should persist the new values in memory)
				[dm.currentPost setValue:tempCustomFieldsArray forKey:@"custom_fields"];
				//TODO:JOHNBCustomFields remove the next two lines, for testing and logging only
				NSArray *tempArray = [dm.currentPost valueForKey:@"custom_fields"];
				[dm printArrayToLog:tempArray andArrayName:@"copy of currentPost:custom_fields from CustomFieldsEditView AFTER edit. This SHOULD show changed values"];
			}
			
			}
		
		
		//remember to send tempCustomFieldsArray to the next ui view for use there
		//it will also be used to populate the cells... Key value will go in cells
	}else{
			}
	

}

- (void)dealloc {
	[customFieldsDict release];
    [super dealloc];
}


@end
