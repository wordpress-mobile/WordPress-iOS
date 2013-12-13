//
//  WPContentCell.h
//  
//
//  Created by Tom Witkin on 12/12/13.
//
//

#import <UIKit/UIKit.h>

#import "WPTableViewCell.h"

@class AbstractPost;
@interface WPContentCell : WPTableViewCell

@property (readwrite, weak) AbstractPost *post;

+ (CGFloat)rowHeightForPost:(AbstractPost *)post andWidth:(CGFloat)width;

@end
