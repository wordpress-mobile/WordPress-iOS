//
//  MenusCell.m
//  WordPress
//
//  Created by Kurzee on 10/7/15.
//  Copyright © 2015 WordPress. All rights reserved.
//

#import "MenusCell.h"

@implementation MenusCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if(self) {
        self.indentationLevel = 5;
        self.layoutMargins = UIEdgeInsetsZero;
    }
    
    return self;
}

@end
