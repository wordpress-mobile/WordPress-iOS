//
//  CommentTableViewCell.h
//  WordPress
//
//  Created by Josh Bassett on 2/07/09.
//

#import <Foundation/Foundation.h>
#import "GravatarImageView.h"
#import "WPLabel.h"

#define COMMENT_ROW_HEIGHT 100

@interface CommentTableViewCell : UITableViewCell {
    NSDictionary *comment;

    UIButton *checkButton;
    UILabel *nameLabel;
    UILabel *urlLabel;
    UILabel *postLabel;
    WPLabel *commentLabel;
    GravatarImageView *gravatarImageView;

    BOOL checked;
}

@property (readwrite, assign) NSDictionary *comment;
@property BOOL checked;

@end
