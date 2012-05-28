//
//  WPTableViewController.h
//  WordPress
//
//  Created by Brad Angelcyk on 5/22/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Blog.h"
#import "Comment.h"
#import "EGORefreshTableHeaderView.h" 

@interface WPTableViewController : UITableViewController <NSFetchedResultsControllerDelegate, EGORefreshTableHeaderDelegate> {
    NSMutableArray *selectedComments;
    BOOL editing;
    BOOL isSecondaryViewController;
    
    IBOutlet UIView* moderationSwipeView;
    
    EGORefreshTableHeaderView *_refreshHeaderView;
    
    NSMutableArray *newCommentIndexPaths;
}

@property (nonatomic, retain) NSFetchedResultsController *resultsController;
@property (nonatomic, retain) Blog *blog;
@property (nonatomic, retain) NSMutableArray *selectedComments;
@property (nonatomic, assign) BOOL isSecondaryViewController;
@property (nonatomic, retain) IBOutlet UIView* moderationSwipeView;
@property (nonatomic, retain) NSNumber *wantedCommentId;

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (Comment *)commentWithId:(NSNumber *)commentId;
- (BOOL)isSyncing;
- (void)triggerRefresh;
- (NSDate *)lastSyncDate;

@end
