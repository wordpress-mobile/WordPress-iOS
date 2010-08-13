//
//  AutosaveViewController.h
//  WordPress
//
//  Created by Chris Boyd on 8/12/10.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "WordPressAppDelegate.h"
#import "Post.h"
#import "AutosaveContentViewController.h"

@class PostViewController;
@interface AutosaveViewController : UIViewController<UITableViewDelegate, UIAlertViewDelegate> {
	IBOutlet UITableView *tableView;
	IBOutlet UIView *buttonView;
	NSMutableArray *autosaves;
	WordPressAppDelegate *appDelegate;
	Post *restorePost;
	AutosaveContentViewController *contentView;
	PostViewController *postDetailViewController;
}

@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet UIView *buttonView;
@property (nonatomic, retain) NSMutableArray *autosaves;
@property (nonatomic, retain) WordPressAppDelegate *appDelegate;
@property (nonatomic, retain) Post *restorePost;
@property (nonatomic, retain) AutosaveContentViewController *contentView;
@property (nonatomic, retain) PostViewController *postDetailViewController;

- (void)refreshTable;
- (void)resetAutosaves;
- (void)doAutosaveReport;

@end
