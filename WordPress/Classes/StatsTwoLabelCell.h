/*
 * StatsTwoLabelCell.h
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import <UIKit/UIKit.h>

@interface StatsTwoLabelCell : UITableViewCell

+ (CGFloat)heightForRow;
- (void)setLeftLabelText:(NSString *)title;
- (void)setRightLabelText:(NSString *)title;

@end
