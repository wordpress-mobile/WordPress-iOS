/*
 * StatsNoResultsCell.m
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "StatsNoResultsCell.h"

@implementation StatsNoResultsCell

+ (CGFloat)heightForRow {
    return 80.0f;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        // label
    }
    return self;
}

- (void)configureForSection:(StatsSection)section {
    switch (section) {
        case StatsSectionTopPosts:
            // set label text
            break;
            
        default:
            break;
    }
}

@end
