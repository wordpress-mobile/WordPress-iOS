//
//  UITableViewActivityCell.h
//  WordPress
//
//  Created by Chris Boyd on 7/23/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UITableViewActivityCell : UITableViewCell {
	IBOutlet UIActivityIndicatorView *spinner;
	IBOutlet UILabel *textLabel;
	IBOutlet UIView *viewForBackground;
}

@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, strong) IBOutlet UILabel *textLabel;
@property (nonatomic, strong) IBOutlet UIView *viewForBackground;

@end
