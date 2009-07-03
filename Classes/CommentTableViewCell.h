//
//  CommentTableViewCell.h
//  WordPress
//
//  Created by Josh Bassett on 2/07/09.
//

#import <Foundation/Foundation.h>

#define COMMENT_ROW_HEIGHT          65

#define LEFT_OFFSET                 10
#define RIGHT_OFFSET                280

#define MAIN_FONT_SIZE              17
#define DATE_FONT_SIZE              13

#define LABEL_HEIGHT                20
#define DATE_LABEL_HEIGHT           32
#define NAME_LABEL_HEIGHT           35
#define VERTICAL_OFFSET             1

#define COMMENT_LABEL_WIDTH         288

#define CHECK_BUTTON_CHECKED_ICON   @"check.png"
#define CHECK_BUTTON_UNCHECKED_ICON @"uncheck.png"

@interface CommentTableViewCell : UITableViewCell {
    NSDictionary *_comment;
    
    UIButton *_checkButton;
    UILabel *_nameLabel;
    UILabel *_emailLabel;
    UILabel *_commentLabel;
    
    BOOL _checked;
}

@property (readwrite, assign) NSDictionary *comment;
@property BOOL checked;

@end
