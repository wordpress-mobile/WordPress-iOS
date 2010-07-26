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

@interface BlogSettingsViewController : UIViewController<UITableViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate> {
	WordPressAppDelegate *appDelegate;
	BOOL isSaving;
	NSString *buttonText;
	IBOutlet UITableView *tableView;
	UIActionSheet *actionSheet;
	NSArray *recentItems;
}

@property (nonatomic, assign) BOOL isSaving;
@property (nonatomic, retain) NSString *buttonText;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) UIActionSheet *actionSheet;
@property (nonatomic, retain) NSArray *recentItems;

- (IBAction)showPicker:(id)sender;
- (IBAction)hidePicker:(id)sender;
- (int)selectedRecentItemsIndex;
- (void)processRowValues;
- (NSString *)transformedValue:(BOOL)value;

@end
