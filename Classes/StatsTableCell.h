//
//  StatsTableCell.h
//  WordPress
//
//  Created by Dan Roundhill on 10/12/10.
//  Copyright 2010 WordPress. All rights reserved.
//
#import <UIKit/UIKit.h>

@interface StatsTableCell : UITableViewCell {
	
	NSMutableArray *columns;
}

- (void)addColumn:(CGFloat)position;

@end
