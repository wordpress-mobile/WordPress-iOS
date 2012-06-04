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
}

@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet UIButton *footerButton;

- (IBAction)showSettings:(id)sender;
- (void) processRowSelectionAtIndexPath: (NSIndexPath *) indexPath;
- (void) processRowSelectionAtIndexPath: (NSIndexPath *) indexPath closingSidebar:(BOOL)closingSidebar;
- (UIImage *)addText:(UIImage *)img text:(NSString *)text1;

@end
