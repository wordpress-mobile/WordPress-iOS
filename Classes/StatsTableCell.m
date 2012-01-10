//
//  StatsTableCell.m
//  WordPress
//
//  Created by Dan Roundhill on 10/12/10.
//  Copyright 2010 WordPress. All rights reserved.
//



#import "StatsTableCell.h"


@implementation StatsTableCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	if (self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier]) {
		// Initialization code
		columns = [NSMutableArray arrayWithCapacity:5];
		[columns retain];
        self.backgroundColor = [UIColor whiteColor];
	}
	return self;
}


- (void)addColumn:(CGFloat)position {
	[columns addObject:[NSNumber numberWithFloat:position]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
	
	[super setSelected:selected animated:animated];
	
	// Configure the view for the selected state
}

- (void)drawRect:(CGRect)rect { 
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	
	// just match the color and size of the horizontal line
	CGContextSetRGBStrokeColor(ctx, 0.5, 0.5, 0.5, 1.0); 
	CGContextSetLineWidth(ctx, 0.25);
	
	for (int i = 0; i < [columns count]; i++) {
		// get the position for the vertical line
		CGFloat f = [((NSNumber*) [columns objectAtIndex:i]) floatValue];
		CGContextMoveToPoint(ctx, f, 0);
		CGContextAddLineToPoint(ctx, f, self.bounds.size.height);
	}
	
	CGContextStrokePath(ctx);
	
	[super drawRect:rect];
} 


- (void)dealloc {
	[super dealloc];
	[columns dealloc];
}

@end
