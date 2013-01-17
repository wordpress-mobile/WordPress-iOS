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

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UIButton *settingsButton;
@property (nonatomic, strong) IBOutlet UIView *utililtyView;

- (IBAction)showSettings:(id)sender;
- (void)processRowSelectionAtIndexPath:(NSIndexPath *)indexPath;
- (void)processRowSelectionAtIndexPath:(NSIndexPath *)indexPath closingSidebar:(BOOL)closingSidebar;
- (void)showCommentWithId:(NSNumber *)itemId blogId:(NSNumber *)blogId;
- (void)selectNotificationsRow;

- (void)uploadQuickPhoto:(Post *)post;
- (void)restorePreservedSelection;

@end
