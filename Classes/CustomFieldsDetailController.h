//
//  CustomFieldsDetailController.h
//  WordPress
//
//  Created by John Bickerstaff on 5/8/09.
//  
//

#define kNumberOfEditableRows   2
#define kKeyRowIndex            0
#define kValueRowIndex          1
#define kLabelTag               4096

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "PostViewController.h"
#import "BlogDataManager.h"
#import "PageViewController.h"

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
    PostViewController *postDetailViewController;
    PageViewController *pageDetailsController;
    BlogDataManager *dm;
    BOOL isNewCustomField;
    BOOL _isPost;
}

//- (void) loadData:(NSDictionary *) theDict;
- (void)writeCustomFieldsToCurrentPostOrPageUsingID;

- (void)loadData:(NSDictionary *)theDict andNewCustomFieldBool:(BOOL)theBool;
- (void)writeCustomFieldsToCurrentPostOrPageUsingID;

- (IBAction)cancel:(id)sender;
- (IBAction)save:(id)sender;
- (IBAction)textFieldDone:(id)sender;

@property (nonatomic, retain) WPNavigationLeftButtonView *leftView;

//@property (retain, nonatomic) UITextField *keyField;
//@property (retain, nonatomic) UITextField *valueField;
//@property (retain, nonatomic) UITextField *idField;
@property (retain, nonatomic) UITextField *textFieldBeingEdited;
@property BOOL isPost;

@property (retain, nonatomic) NSMutableDictionary *customFieldsDict;
@property (nonatomic, assign) PostViewController *postDetailViewController;
@property (nonatomic, assign) PageViewController *pageDetailsController;
@property (nonatomic, assign) BlogDataManager *dm;

@end
