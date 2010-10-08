//
//  BlogSettingsViewController.h
//  WordPress
//
//  Created by Chris Boyd on 7/25/10.
//

#import <UIKit/UIKit.h>
#import "WordPressAppDelegate.h"
#import "UITableViewSwitchCell.h"
#import "BlogDataManager.h"
#import "UITableViewActivityCell.h"

@interface BlogSettingsViewController : UIViewController<UITableViewDelegate, UIPickerViewDataSource, UITextFieldDelegate, UIPickerViewDelegate> {
	WordPressAppDelegate *appDelegate;
	BOOL isSaving, viewDidMove, keyboardIsVisible;
	NSString *buttonText;
	IBOutlet UITableView *tableView;
	UITextField *activeTextField;
	UIActionSheet *actionSheet;
	NSArray *recentItems;
	UIPopoverController *recentItemsPopover;
}

@property (nonatomic, assign) BOOL isSaving, viewDidMove, keyboardIsVisible;
@property (nonatomic, retain) NSString *buttonText;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) UIActionSheet *actionSheet;
@property (nonatomic, retain) NSArray *recentItems;
@property (nonatomic, retain) UIPopoverController *recentItemsPopover;

- (IBAction)showPicker:(id)sender;
- (IBAction)hidePicker:(id)sender;
- (int)selectedRecentItemsIndex;
- (void)processRowValues;
- (NSString *)transformedValue:(BOOL)value;
- (void)keyboardWillShow:(NSNotification *)notification;
- (void)keyboardWillHide:(NSNotification *)notification;

@end
