//
//  WPStyleGuide+Blog.m
//  WordPress
//
//  Created by Will Kwon on 10/7/15.
//  Copyright © 2015 WordPress. All rights reserved.
//

#import "WPStyleGuide+Blog.h"

@implementation WPStyleGuide (Blog)

+ (void)configureTableViewBlogCell:(UITableViewCell *)cell
{
    [self configureTableViewCell:cell];
    cell.detailTextLabel.font = [self subtitleFont];
    cell.detailTextLabel.textColor = [self greyDarken10];
    cell.backgroundColor = [self lightGrey];
}

@end
