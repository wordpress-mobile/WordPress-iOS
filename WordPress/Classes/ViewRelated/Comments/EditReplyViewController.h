#import "EditCommentViewController.h"



@interface EditReplyViewController : EditCommentViewController

/**
 Returns a new instance of an EditReplyViewController, passing the siteID
 on which the comment would be posted.  The siteID is used to retrieve @mention
 suggestions.  If no @mentions suggestions are desired, pass nil instead
 
 @param siteID Optional ID of the blog/site on which the user is commenting
 @return An instance of EditReplyViewController
 */
+ (instancetype)newReplyViewControllerForSiteID:(NSNumber *)siteID;

@end
