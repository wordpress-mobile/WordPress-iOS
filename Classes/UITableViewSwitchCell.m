//
//  UITableViewSwitchCell.m
//  WordPress
//
//  Created by Chris Boyd on 7/25/10.
//

#import "UITableViewSwitchCell.h"

@implementation UITableViewSwitchCell
@synthesize textLabel, cellSwitch, viewForBackground;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}



@end
