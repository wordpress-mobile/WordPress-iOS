//
//  ReaderCommentTableViewCell.h
//  WordPress
//
//  Created by Eric J on 5/7/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ReaderTableViewCell.h"
#import "ReaderComment.h"

@interface ReaderCommentTableViewCell : ReaderTableViewCell

+ (NSAttributedString *)convertHTMLToAttributedString:(NSString *)html withOptions:(NSDictionary *)options;

+ (CGFloat)heightForComment:(ReaderComment *)comment
					  width:(CGFloat)width
				 tableStyle:(UITableViewStyle)tableStyle
			  accessoryType:(UITableViewCellAccessoryType *)accessoryType;

- (void)configureCell:(ReaderComment *)comment;

@end
