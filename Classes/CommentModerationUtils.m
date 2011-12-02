//
//  CommentModerationUtils.m
//  WordPress
//
//  Created by Peter Boctor on 3/29/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import "CommentModerationUtils.h"
#import "WordPressAppDelegate.h"
#import "WPProgressHUD.h"

@interface CommentModerationUtils (Private)

- (BOOL)isConnectedToHost;
- (BOOL)isApprove;
- (void)moderateCommentWithSelector:(SEL)selector;
- (void)deleteThisComment;
- (void)approveThisComment;
- (void)markThisCommentAsSpam;
- (void)unapproveThisComment;

// - (void)showReplyToCommentViewWithAnimation:(BOOL)animate;
// - (void)showEditCommentViewWithAnimation:(BOOL)animate;
// - (void)insertPendingLabel;
// - (void)removePendingLabel;
// 
// - (void)launchReplyToComments;
// - (void)launchEditComment;

@end

@implementation CommentModerationUtils
@synthesize comment, commentsViewController, replyToCommentViewController;

static CommentModerationUtils * _instance = nil;
+ (CommentModerationUtils *) instance
{
  if (_instance == nil)
    _instance = [[CommentModerationUtils alloc] init];

  return _instance;
}

- (void) deleteComment
{
  progressAlert = [[WPProgressHUD alloc] initWithLabel:@"Deleting..."];
  [progressAlert show];
  [self performSelectorInBackground:@selector(deleteThisComment) withObject:nil];
}

- (void) launchModerateMenuInView:(UIView*)view;
{
  NSString *conditionalButtonTitle = nil;

  if ([self isApprove])
    conditionalButtonTitle = @"Approve Comment";
  else
    conditionalButtonTitle = @"Unapprove Comment";

  UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@""
    delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil
    otherButtonTitles: conditionalButtonTitle, @"Mark Comment as Spam", @"Edit Comment",nil];
                          //otherButtonTitles: conditionalButtonTitle, @"Mark Comment as Spam",nil];

  actionSheet.tag = 301;
  actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;
  if (DeviceIsPad() == YES) {
    spamButton1.enabled = NO;
    [actionSheet showFromBarButtonItem:spamButton1 animated:YES];
  } else {
    [actionSheet showInView:view];
  }
  WordPressAppDelegate *delegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
  [delegate setAlertRunning:YES];

  [actionSheet release];
}

- (void)showReplyToCommentViewWithAnimation:(BOOL)animate
{
  WordPressAppDelegate *delegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];

  self.replyToCommentViewController = [[[ReplyToCommentViewController alloc] initWithNibName:@"ReplyToCommentViewController" bundle:nil]autorelease];
  replyToCommentViewController.commentViewController = self;
  replyToCommentViewController.comment = [[self.comment newReply] autorelease];
  replyToCommentViewController.title = @"Comment Reply";

  if (DeviceIsPad() == NO) {
    [delegate.navigationController pushViewController:self.replyToCommentViewController animated:YES];
  } else {
    UINavigationController *navController = [[[UINavigationController alloc] initWithRootViewController:replyToCommentViewController] autorelease];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentModalViewController:navController animated:YES];
  }
}

#pragma mark Delete Comment
- (void)deleteThisComment
{
  [self moderateCommentWithSelector:@selector(remove)];
  if (DeviceIsPad() == YES)
    [self.commentsViewController performSelectorOnMainThread:@selector(trySelectSomethingAndShowIt) withObject:nil waitUntilDone:NO];
}

#pragma mark Moderate Comment

- (void)moderateCommentWithSelector:(SEL)selector
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  BOOL fails = NO;
  if ([self isConnectedToHost]) {
    if(![self.comment performSelector:selector])
      fails = YES;
  }

  [progressAlert dismissWithClickedButtonIndex:0 animated:YES];
  [progressAlert release];

  if(fails)
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CommentUploadFailed" object:@"Sorry, something went wrong during comment moderation. Please try again."];

  [pool release];
}

#pragma mark Approve Comment
- (void)approveThisComment
{
  [self moderateCommentWithSelector:@selector(approve)];
}

- (void)approveComment:(id)sender
{
  progressAlert = [[WPProgressHUD alloc] initWithLabel:@"Moderating..."];
  [progressAlert show];

  [self performSelectorInBackground:@selector(approveThisComment) withObject:nil];
}

#pragma mark Mark Comment As Spam
- (void)markThisCommentAsSpam
{
  [self moderateCommentWithSelector:@selector(spam)];
  if (DeviceIsPad() == YES)
    [self.commentsViewController performSelectorOnMainThread:@selector(trySelectSomethingAndShowIt) withObject:nil waitUntilDone:NO];
}

- (void)spamComment:(id)sender
{
  progressAlert = [[WPProgressHUD alloc] initWithLabel:@"Moderating..."];
  [progressAlert show];

  [self performSelectorInBackground:@selector(markThisCommentAsSpam) withObject:nil];
}

#pragma mark Unapprove Comment
- (void)unapproveThisComment
{
  [self moderateCommentWithSelector:@selector(unapprove)];
}

- (void)unApproveComment:(id)sender
{
  progressAlert = [[WPProgressHUD alloc] initWithLabel:@"Moderating..."];
  [progressAlert show];

  [self performSelectorInBackground:@selector(unapproveThisComment) withObject:nil];
}

#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{

  //handle action sheet from trash button
  if ([actionSheet tag] == 501) {
    if (buttonIndex == 0) {
      [self deleteComment:nil];
    }
  
    if (buttonIndex == 1) {
  
    }
  }
  
  //handle action sheet from replyToCommentsViewController
  if ([actionSheet tag] == 401) {
    if (buttonIndex == 0) {
      if (replyToCommentViewController.hasChanges) { 
        replyToCommentViewController.hasChanges = NO;
        [replyToCommentViewController.comment remove];
      } 
      [self discard];
    }
  
    if (buttonIndex == 1) {
      [self cancel];
    }
  }
  // 
  // 
  // //handle action sheet from editCommentsViewController
  // if ([actionSheet tag] == 601) {
  //   if (buttonIndex == 0) {
  //     editCommentViewController.hasChanges = NO;
  //     [self discard];
  //   }
  // 
  //   if (buttonIndex == 1) {
  //     [self cancel];
  //   }
  // }


  //handle action sheet for approve/spam/edit
  if ([actionSheet tag] == 301)
  {
    spamButton1.enabled = YES;
    if (buttonIndex == 0) {  //Approve/Unapprove conditional button was selected
      if ([self isApprove]) {
        [self approveComment:nil];
      } else {
        [self unApproveComment:nil];
      }
    }

    if (buttonIndex == 1) {  //Mark as Spam was selected
      [self spamComment:nil];
    }

    if (buttonIndex == 2) {  //Edit Comment was selected
      [self launchEditComment];
      //[self showEditCommentModalViewWithAnimation:YES];
      //... or [self editThisComment]; (if we need more data loading perhaps)
      //yet to be written...
      //launch the modal editing view and load it with the selected comment
      //editing view to save new comment and return to this screen with new comment loaded into detail
      //consider making this edit view and the reply-to-comment edit view the same xib
      //   and load data conditionally
    }
  }

  WordPressAppDelegate *delegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
  [delegate setAlertRunning:NO];
}
#pragma mark -
- (void) closeReplyViewAndSelectTheNewComment
{
	[self dismissEditViewController];
	[self.commentsViewController trySelectSomething];
}

- (void)cancelView:(id)sender {
	
	//there are no changes
	if (!replyToCommentViewController.hasChanges /*&& !editCommentViewController.hasChanges*/) {
		[self dismissEditViewController];
		
		if(sender == replyToCommentViewController) {
			commentsViewController.selectedIndexPath = nil; //the selectedIndex path is on the reply comment
			
			[replyToCommentViewController.comment remove]; //delete the empty comment
			
			if (DeviceIsPad() == YES)  //an half-patch for #790: sometimes the modal view is not disposed when click on cancel. 
				[self dismissModalViewControllerAnimated:YES]; 		
		} 
		return;
	}
	
	
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"You have unsaved changes."
															 delegate:self cancelButtonTitle:@"Cancel" 
											   destructiveButtonTitle:@"Discard"
													otherButtonTitles:nil];
    
	if (replyToCommentViewController.hasChanges)
		actionSheet.tag = 401;
  // else if (editCommentViewController.hasChanges)
  //  actionSheet.tag = 601;
    
	actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;
	
	if (replyToCommentViewController.hasChanges) { 
		[actionSheet showInView:replyToCommentViewController.view];
  // }else if (editCommentViewController.hasChanges) {
  //  [actionSheet showInView:editCommentViewController.view];
  // }
	
    WordPressAppDelegate *delegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
    [delegate setAlertRunning:YES];
	
    [actionSheet release];
}


#pragma mark Utils
- (BOOL)isConnectedToHost
{
  if (![[WPReachability sharedReachability] internetConnectionStatus] != NotReachable)
  {
    UIAlertView *connectionFailAlert = [[UIAlertView alloc] initWithTitle:@"No connection to host."
      message:@"Operation is not supported now."
      delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [connectionFailAlert show];
    [connectionFailAlert release];
    return NO;
  }

  return YES;
}

- (BOOL)isApprove
{
  if ([self.comment.status isEqualToString:@"hold"])
    return YES;
  else
    return NO;
}

- (void)dealloc
{
  [comment release];
  [commentsViewController release];
  [replyToCommentViewController release];
  [super dealloc];
}

@end
