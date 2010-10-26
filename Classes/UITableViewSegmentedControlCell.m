//
//  UITableViewSegmentedControlCell.m
//  WordPress
//
//  Created by Chris Boyd on 7/25/10.
//

#import "UITableViewSegmentedControlCell.h"

@implementation UITableViewSegmentedControlCell
@synthesize textLabel, segmentedControl, viewForBackground;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)dealloc {
	[viewForBackground release];
	[textLabel release];
	[segmentedControl release];
    [super dealloc];
}


@end
