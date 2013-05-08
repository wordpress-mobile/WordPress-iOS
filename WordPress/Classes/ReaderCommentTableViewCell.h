//
//  ReaderCommentTableViewCell.h
//  WordPress
//
//  Created by Eric J on 5/7/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ReaderComment.h"

@interface ReaderCommentTableViewCell : UITableViewCell

/**
 Return's an array of required cell heights to display the specified comments.
 */
+ (NSArray *)cellHeightsForComments:(NSArray *)comments
							  width:(CGFloat)width
						 tableStyle:(UITableViewStyle)tableStyle
						  cellStyle:(UITableViewCellStyle)cellStyle
					reuseIdentifier:(NSString *)reuseIdentifier;

- (void)configureCell:(ReaderComment *)comment;

@end
