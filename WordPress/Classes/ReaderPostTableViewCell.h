//
//  ReaderPostTableViewCell.h
//  WordPress
//
//  Created by Eric J on 4/4/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ReaderPost.h"

@interface ReaderPostTableViewCell : UITableViewCell

/**
 Return's an array of required cell heights to display the specified posts. 
 */
+ (NSArray *)cellHeightsInTableView:(UITableView *)tableView
						   forPosts:(NSArray *)posts
						  cellStyle:(UITableViewCellStyle)style
					reuseIdentifier:(NSString *)reuseIdentifier;

- (void)configureCell:(ReaderPost *)post;


@end
