//
//  SidebarViewController.h
//  WordPress
//
//  Created by Jorge Bernal on 5/21/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SidebarSectionHeaderView.h"
#import "WordPressAppDelegate.h"

@interface SidebarViewController : UIViewController <SidebarSectionHeaderViewDelegate, UITableViewDataSource, UITableViewDelegate> {
    IBOutlet UITableView *tableView;
    IBOutlet UIButton *footerButton;
    NSIndexPath *selectedIndex;
}

@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet UIButton *footerButton;

- (void) processRowSelectionAtIndexPath: (NSIndexPath *) indexPath;
- (void) processRowSelectionAtIndexPath: (NSIndexPath *) indexPath closingSidebar:(BOOL)closingSidebar;

@end
