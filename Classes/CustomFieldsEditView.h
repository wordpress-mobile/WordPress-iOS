//
//  CustomFieldEditView.h
//  WordPress
//
//  Created by John Bickerstaff on 5/5/09.
//  Copyright 2009 Smilodon Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PostDetailViewController.h"
#import "BlogDataManager.h"



@interface CustomFieldsEditView : UIViewController <UITextFieldDelegate> {
	IBOutlet	UITextField		*keyField;
	IBOutlet	UITextField		*valueField;
	IBOutlet	UITextField		*idField;
		
			
	
	UITextField *currentEditingTextField;
	NSMutableDictionary *customFieldsDict;
	PostDetailViewController *postDetailViewController;
	BlogDataManager *dm;
}

- (IBAction)textFieldDoneEditing:(id)sender;
- (void) loadData:(NSDictionary *) theDict;
- (void) writeCustomFieldsToCurrentPostUsingID;

@property (retain, nonatomic) UITextField *keyField;
@property (retain, nonatomic) UITextField *valueField;
@property (retain, nonatomic) UITextField *idField;
@property (retain, nonatomic) UITextField *currentEditingTextField;

@property (retain, nonatomic)NSMutableDictionary *customFieldsDict;
@property (retain, nonatomic) PostDetailViewController *postDetailViewController;
@property (nonatomic, assign) BlogDataManager *dm;



@end
