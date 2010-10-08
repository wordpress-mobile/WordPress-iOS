//
//  AutosaveContentViewController.h
//  WordPress
//
//  Created by Chris Boyd on 8/13/10.
//

#import <UIKit/UIKit.h>
#import "Post.h"

@interface AutosaveContentViewController : UITableViewController {
	Post *autosavePost;
}

@property (nonatomic, retain) Post *autosavePost;

- (void)refreshTable;

@end
