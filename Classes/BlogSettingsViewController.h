//
//  BlogSettingsViewController.h
//  WordPress
//
//  Created by Chris Boyd on 7/25/10.
//

#import <UIKit/UIKit.h>
#import "WordPressAppDelegate.h"
#import "BlogDataManager.h"
#import "Blog.h"

@interface BlogSettingsViewController : UIViewController<UITableViewDelegate> {
	IBOutlet UITableView *tableView;
	IBOutlet UIPickerView *picker;
	NSArray *recentItems;
	NSString *geotaggingSetting;
}

@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet UIPickerView *picker;
@property (nonatomic, retain) NSArray *recentItems;
@property (nonatomic, retain) NSString *geotaggingSetting;

@end
