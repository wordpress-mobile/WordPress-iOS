//
//  PostTableViewCell.h
//  WordPress
//
//  Created by Josh Bassett on 1/07/09.
//

#import <Foundation/Foundation.h>
#import "AbstractPost.h"

#define POST_ROW_HEIGHT         60.0f

#define LEFT_OFFSET             10.0f
#define RIGHT_OFFSET            200.0f
#define RIGHT_MARGIN            16.0f

#define MAIN_FONT_SIZE          15.0f
#define DATE_FONT_SIZE          13.0f

#define LABEL_HEIGHT            19.0f
#define DATE_LABEL_HEIGHT       15.0f
#define VERTICAL_OFFSET         2.0f

#define POST_LOCK_IMAGE         @"lock.png"

@interface PostTableViewCell : UITableViewCell {
    AbstractPost *__weak post;

    UILabel *nameLabel;
    UILabel *dateLabel;
	UILabel *statusLabel;
    UIActivityIndicatorView *activityIndicator;
    BOOL saving;
	BOOL gettingMore;
}

@property (readwrite, weak) AbstractPost *post;

- (void)runSpinner:(BOOL)value;


@end
