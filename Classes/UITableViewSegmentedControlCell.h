//
//  UITableViewSegmentedControlCell.h
//  WordPress
//
//  Created by Chris Boyd on 7/25/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UITableViewSegmentedControlCell : UITableViewCell {
	IBOutlet UILabel *textLabel;
	IBOutlet UISegmentedControl *segmentedControl;
	IBOutlet UIView *viewForBackground;
}

@property (nonatomic, retain) IBOutlet UILabel *textLabel;
@property (nonatomic, retain) IBOutlet UISegmentedControl *segmentedControl;
@property (nonatomic, retain) IBOutlet UIView *viewForBackground;

@end
