//
//  SidebarViewController.h
//  WordPress
//
//  Created by Jorge Bernal on 5/21/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SidebarSectionHeaderView.h"

@class Post;

@interface SidebarViewController : UIViewController <UIActionSheetDelegate, SidebarSectionHeaderViewDelegate, UITableViewDataSource, UITableViewDelegate> {
    IBOutlet UITableView *tableView;
    IBOutlet UIButton *settingsButton;
    IBOutlet UIView *utililtyView;
    NSUInteger openSectionIdx;
    NSIndexPath *currentIndexPath;
    BOOL restoringView;
}

@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet UIButton *settingsButton;
@property (nonatomic, retain) IBOutlet UIView *utililtyView;

- (IBAction)showSettings:(id)sender;
- (void)processRowSelectionAtIndexPath:(NSIndexPath *)indexPath;
- (void)processRowSelectionAtIndexPath:(NSIndexPath *)indexPath closingSidebar:(BOOL)closingSidebar;
- (void)showCommentWithId:(NSNumber *)itemId blogId:(NSNumber *)blogId;

- (void)uploadQuickPhoto:(Post *)post;
- (void)restorePreservedSelection;

@end
