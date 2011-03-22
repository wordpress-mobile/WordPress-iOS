//
//  PostTableViewCell.h
//  WordPress
//
//  Created by Josh Bassett on 1/07/09.
//

#import <Foundation/Foundation.h>
#import "AbstractPost.h"

#define POST_ROW_HEIGHT         60

#define LEFT_OFFSET             10
#define RIGHT_OFFSET            200

#define MAIN_FONT_SIZE          15
#define DATE_FONT_SIZE          13

#define LABEL_HEIGHT            19
#define DATE_LABEL_HEIGHT       15
#define STATUS_LABEL_WIDTH		50
#define VERTICAL_OFFSET         2

#define POST_LOCK_IMAGE         @"lock.png"

@interface PostTableViewCell : UITableViewCell {
    AbstractPost *post;

    UILabel *nameLabel;
    UILabel *dateLabel;
	UILabel *statusLabel;
    UIActivityIndicatorView *activityIndicator;
    BOOL saving;
	BOOL gettingMore;
}

@property (readwrite, assign) AbstractPost *post;

- (void)changeCellLabelsForUpdate:(NSString *)postTotalString:(NSString *) loadingString:(BOOL)isLoading;
- (void)runSpinner:(BOOL)value;


@end
