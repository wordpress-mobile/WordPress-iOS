//
//  CustomFieldsDetailController.h
//  WordPress
//
//  Created by John Bickerstaff on 5/8/09.
//  Copyright 2009 Smilodon Software. All rights reserved.
//

#define kNumberOfEditableRows	2
#define kKeyRowIndex			0
#define kValueRowIndex			1
#define kLabelTag				4096




#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "PostDetailViewController.h"
#import "BlogDataManager.h"
#import "CustomFieldsEditView.h"

@interface CustomFieldsDetailController : UITableViewController
	<UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate> {
		
		WPNavigationLeftButtonView *leftView;
		
		NSArray *fieldLables;
		
		//IBOutlet	UITextField		*keyField;
		//IBOutlet	UITextField		*valueField;
		//IBOutlet	UITextField		*idField;
		
		IBOutlet UIBarButtonItem *saveButtonItem;
		
		
		UITextField *textFieldBeingEdited;
		NSMutableDictionary *customFieldsDict;
		PostDetailViewController *postDetailViewController;
		BlogDataManager *dm;
		BOOL isNewCustomField;
	}


//- (void) loadData:(NSDictionary *) theDict;
- (void) writeCustomFieldsToCurrentPostUsingID;

-(void)loadData:(NSDictionary *) theDict andNewCustomFieldBool:(BOOL) theBool;
-(void) writeCustomFieldsToCurrentPostUsingID;

- (IBAction)cancel:(id)sender;
- (IBAction)save:(id)sender;
- (IBAction)textFieldDone:(id)sender;

@property (nonatomic, retain) WPNavigationLeftButtonView *leftView;

//@property (retain, nonatomic) UITextField *keyField;
//@property (retain, nonatomic) UITextField *valueField;
//@property (retain, nonatomic) UITextField *idField;
@property (retain, nonatomic) UITextField *textFieldBeingEdited;


@property (retain, nonatomic)NSMutableDictionary *customFieldsDict;
@property (nonatomic, assign) PostDetailViewController *postDetailViewController;
@property (nonatomic, assign) BlogDataManager *dm;



@end