//
//  CommentsViewControllers.h
//  WordPress
//
//  Created by Janakiram on 02/09/08.
//

#import <Foundation/Foundation.h>

#import "CommentsTableViewDelegate.h"
#import "WPTableViewController.h"
#import "Blog.h"
#import "ReplyToCommentViewController.h"

@interface CommentsViewController : WPTableViewController <CommentsTableViewDelegate, DetailViewDelegate> {
@private
}

@property (nonatomic, strong) NSNumber *wantedCommentId;
@property (nonatomic, strong) NSNumber *lastSelectedCommentID;

@end
