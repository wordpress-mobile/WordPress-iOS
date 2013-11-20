//
//  NewCommentsTableViewCell.h
//  WordPress
//
//  Created by Sendhil Panchadsaram on 8/20/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WPTableViewCell.h"

@class Comment;
@interface NewCommentsTableViewCell : WPTableViewCell

@property (readwrite, weak) Comment *comment;

+ (CGFloat)rowHeightForComment:(Comment *)comment andMaxWidth:(CGFloat)maxWidth;

@end
