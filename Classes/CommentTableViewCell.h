//
//  CommentTableViewCell.h
//  WordPress
//
//  Created by Josh Bassett on 2/07/09.
//

#import <Foundation/Foundation.h>
#import "WPLabel.h"
#import "Comment.h"

#define COMMENT_ROW_HEIGHT 100

@interface CommentTableViewCell : UITableViewCell {
    Comment *comment;

    UIButton *checkButton;
    UILabel *nameLabel;
    UILabel *urlLabel;
    UILabel *postLabel;
    WPLabel *commentLabel;
    UIImageView *gravatarImageView;

    BOOL checked;
}

@property (readwrite, assign) Comment *comment;
@property BOOL checked;

@end
