/*
 * StatsTwoLabelCell.h
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import <UIKit/UIKit.h>
#import "StatsTitleCountItem.h"
#import "WPTableViewCell.h"

@interface StatsTwoLabelCell : WPTableViewCell

@property (nonatomic, strong) NSNumberFormatter *numberFormatter;
@property (nonatomic, strong) StatsTitleCountItem *cellData;

+ (CGFloat)heightForRow;

- (void)insertData:(StatsTitleCountItem *)cellData;
- (void)setLeft:(NSString *)left withImageUrl:(NSURL *)imageUrl right:(NSString *)right titleCell:(BOOL)titleCell;

@end
