//
//  CommentTableViewCell.h
//  WordPress
//
//  Created by Josh Bassett on 2/07/09.
//

#import <Foundation/Foundation.h>
#import "WPAsynchronousImageView.h"
#import "WPLabel.h"

#define COMMENT_ROW_HEIGHT 90

@interface CommentTableViewCell : UITableViewCell {
    NSDictionary *comment;

    UIButton *checkButton;
    UILabel *nameLabel;
    UILabel *urlLabel;
    WPLabel *commentLabel;

    WPAsynchronousImageView *gravatarImageView;

    BOOL checked;
}

@property (readwrite, assign) NSDictionary *comment;
@property BOOL checked;

- (void)resetAsynchronousImageView;

@end
