//
//  WPTableViewController.m
//  WordPress
//
//  Created by Brad Angelcyk on 5/22/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "WPTableViewController.h"
#import "Comment.h"
#import "CommentTableViewCell.h"

@interface WPTableViewController (Private)

- (void)refreshHandler;
- (void)triggerRefresh;
- (void)syncComments;

@end

@implementation WPTableViewController
@synthesize selectedComments, isSecondaryViewController, wantedCommentId;
@synthesize moderationSwipeView;
@synthesize blog = _blog;
@synthesize resultsController = _resultsController;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (_refreshHeaderView == nil) {
		_refreshHeaderView = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.tableView.bounds.size.height, self.view.frame.size.width, self.tableView.bounds.size.height)];
		_refreshHeaderView.delegate = self;
		[self.tableView addSubview:_refreshHeaderView];
	}
	
	//  update the last update date
	[_refreshHeaderView refreshLastUpdatedDate];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    Comment *comment = [self.resultsController objectAtIndexPath:indexPath];
    if (comment.isNew) {
        cell.backgroundColor = TABLE_VIEW_CELL_BACKGROUND_COLOR;
        if ([comment.status isEqual:@"hold"]) {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [UIView animateWithDuration:1.0
                                      delay:1.0
                                    options:UIViewAnimationOptionAllowUserInteraction
                                 animations:^{
                                     cell.backgroundColor = PENDING_COMMENT_TABLE_VIEW_CELL_BACKGROUND_COLOR;
                                 } completion:nil];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [UIView animateWithDuration:1.0
                                      delay:1.0
                                    options:UIViewAnimationOptionAllowUserInteraction
                                 animations:^{
                                     cell.backgroundColor = PENDING_COMMENT_TABLE_VIEW_CELL_BACKGROUND_COLOR;
                                 } completion:^(BOOL finished) {
                                     [UIView animateWithDuration:0.5
                                                           delay:1.0
                                                         options:UIViewAnimationOptionAllowUserInteraction
                                                      animations:^{
                                                          cell.backgroundColor = TABLE_VIEW_CELL_BACKGROUND_COLOR;
                                                      }
                                                      completion:nil];
                                 }];
            });
        }
        comment.isNew = NO;
    } else if ([comment.status isEqual:@"hold"]) {
        cell.backgroundColor = PENDING_COMMENT_TABLE_VIEW_CELL_BACKGROUND_COLOR;
    } else {
        cell.backgroundColor = TABLE_VIEW_CELL_BACKGROUND_COLOR;
    }
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.resultsController sections] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.resultsController sections] objectAtIndex:section];
    return [Comment titleForStatus:[sectionInfo name]];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = nil;
    sectionInfo = [[self.resultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (void)configureCell:(CommentTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    Comment *comment = [self.resultsController objectAtIndexPath:indexPath];
    cell.comment = comment;
    cell.checked = [selectedComments containsObject:comment];
    cell.editing = editing;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"CommentCell";
    CommentTableViewCell *cell = (CommentTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[[CommentTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    if ((DeviceIsPad() == YES && !self.isSecondaryViewController) || tableView.isEditing) {
		cell.accessoryType = UITableViewCellAccessoryNone;
	} else {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    Comment *comment = [self.resultsController objectAtIndexPath:indexPath];
    CGSize commentSize = [comment.content sizeWithFont:[UIFont systemFontOfSize:15] constrainedToSize:CGSizeMake(self.view.bounds.size.width - 16, 80)];
    return COMMENT_ROW_HEIGHT - 60 + MIN(commentSize.height, 60);
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0;
}

- (void) setupModerationSwipeView
{
    if (DeviceIsPad()) return;
    
    for (UIView* subview in moderationSwipeView.subviews)
    {
        if ([subview isKindOfClass:[UIButton class]])
        {
            UIImage* buttonImage = [[UIImage imageNamed:@"UISegmentBarBlackButton.png"] stretchableImageWithLeftCapWidth:5.0 topCapHeight:0.0];
            UIImage* buttonPressedImage = [[UIImage imageNamed:@"UISegmentBarBlackButtonHighlighted.png"] stretchableImageWithLeftCapWidth:5.0 topCapHeight:0.0];
            
            UIButton* button = (UIButton*)subview;
            [button setBackgroundImage:buttonImage forState:UIControlStateNormal];
            [button setBackgroundImage:buttonPressedImage forState:UIControlStateHighlighted];
        }
    }
    
    self.moderationSwipeView.backgroundColor = [UIColor colorWithPatternImage: [UIImage imageNamed:@"dotted-pattern.png"]];
    
    UIImage* shadow = [[UIImage imageNamed:@"inner-shadow.png"] stretchableImageWithLeftCapWidth:0 topCapHeight:0];
    UIImageView* shadowImageView = [[[UIImageView alloc] initWithFrame:moderationSwipeView.frame] autorelease];
    shadowImageView.alpha = 0.6;
    shadowImageView.image = shadow;
    
    [self.moderationSwipeView insertSubview:shadowImageView atIndex:0];  
}

#pragma mark -
#pragma mark EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view{
	[self refreshHandler];
	_refreshHeaderView.hidden = NO; // Just in case
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view{
	return [self isSyncing]; // should return if data source model is reloading
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view{
	return [self lastSyncDate]; // should return date data source was last changed
}

#pragma mark - Private Methods

- (BOOL)isSyncing {
	return self.blog.isSyncingComments;
}

- (NSDate *)lastSyncDate {
	return self.blog.lastCommentsSync;
}

- (void)refreshHandler {
	[self setEditing:false];
	[self syncComments];
}

- (void)triggerRefresh {
    CGPoint offset = self.tableView.contentOffset;
    offset.y = - 65.0f;
    [self.tableView setContentOffset:offset];
    [_refreshHeaderView egoRefreshScrollViewDidEndDragging:self.tableView];
}

- (void)syncComments {
    [self.blog syncCommentsWithSuccess:^() {
		[newCommentIndexPaths removeAllObjects];
        if (self.wantedCommentId) {
            Comment *wantedComment = [self commentWithId:self.wantedCommentId];
            if (wantedComment) {
                NSIndexPath *wantedIndexPath = [self.resultsController indexPathForObject:wantedComment];
                [self.tableView scrollToRowAtIndexPath:wantedIndexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
                // We scroll now, but can't select the comment yet since the table view doesn't have
                // the new cells. We'll do that in the results controller delegate
            } else {
                // Didn't get the comment: forget about it
                self.wantedCommentId = nil;
            }
        }
        [_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
    } failure:^(NSError *error) {
        [WPError showAlertWithError:error title:NSLocalizedString(@"Couldn't sync comments", @"")];
        [_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
    }];
}

- (Comment *)commentWithId:(NSNumber *)commentId {
    Comment *comment = [[[self.resultsController fetchedObjects] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"commentID = %@", commentId]] lastObject];
    
    return comment;
}

@end
