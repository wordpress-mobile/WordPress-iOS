//
//  PostTableViewCell.h
//  WordPress
//
//  Created by Josh Bassett on 1/07/09.
//

#import <Foundation/Foundation.h>

#define POST_ROW_HEIGHT         60
#define LOCAL_DRAFTS_ROW_HEIGHT 44

#define LEFT_OFFSET             10
#define RIGHT_OFFSET            280

#define MAIN_FONT_SIZE          15
#define DATE_FONT_SIZE          13

#define LABEL_HEIGHT            19
#define DATE_LABEL_HEIGHT       15
#define VERTICAL_OFFSET         2

#define POST_LOCK_IMAGE         @"lock.png"

@interface PostTableViewCell : UITableViewCell {
    NSDictionary *post;

    UILabel *nameLabel;
    UILabel *dateLabel;
    UIActivityIndicatorView *activityIndicator;
    BOOL saving;
	BOOL gettingMore;
}

@property (readwrite, assign) NSDictionary *post;

- (void)changeCellLabelsForUpdate:(NSString *)postTotalString:(NSString *) loadingString:(BOOL)isLoading;
- (void)runSpinner:(BOOL)value;


@end
