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

@interface SidebarViewController : UITableViewController <SidebarSectionHeaderViewDelegate> {
    WordPressAppDelegate *appDelegate;
}

- (void) processRowSelectionAtIndexPath: (NSIndexPath *) indexPath;

@end
