/*
 * WPBlogTableViewCell.m
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "WPBlogTableViewCell.h"

@implementation WPBlogTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    // Ignore the style argument, override with subtitle style.
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    return self;
}

@end
