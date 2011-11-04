//
//  BlogViewController.h
//  WordPress
//
//  Created by Josh Bassett on 8/07/09.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface BlogViewController : UITableViewController {
}

@property (nonatomic, retain) Blog *blog;
@property (nonatomic, retain) IBOutlet UIImageView *blavatarImageView;
@property (nonatomic, retain) IBOutlet UILabel *blogTitleLabel;
@property (nonatomic, retain) IBOutlet UILabel *blogUrlLabel;
@property (nonatomic, retain) IBOutlet UITableView *tableView;

@end
