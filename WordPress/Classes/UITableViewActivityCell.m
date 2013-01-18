//
//  UITableViewActivityCell.m
//  WordPress
//
//  Created by Chris Boyd on 7/23/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import "UITableViewActivityCell.h"


@implementation UITableViewActivityCell
@synthesize textLabel, spinner, viewForBackground;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        // Initialization code
    }
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}




@end
