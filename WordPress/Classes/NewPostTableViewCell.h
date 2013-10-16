//
//  NewPostTableViewCell.h
//  WordPress
//
//  Created by Sendhil Panchadsaram on 8/14/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AbstractPost;
@interface NewPostTableViewCell : UITableViewCell

@property (readwrite, weak) AbstractPost *post;

- (void)runSpinner:(BOOL)value;
+ (CGFloat)rowHeightForPost:(AbstractPost *)post andWidth:(CGFloat)width;

@end
