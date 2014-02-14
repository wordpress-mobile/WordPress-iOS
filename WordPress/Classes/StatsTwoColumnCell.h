/*
 * StatsTwoColumnCell.h
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "StatsTitleCountItem.h"
#import "WPTableViewCell.h"

@interface StatsTwoColumnCell : WPTableViewCell

@property (nonatomic, assign) BOOL linkEnabled;

+ (CGFloat)heightForRow;

- (void)insertData:(StatsTitleCountItem *)cellData;
- (void)setLeft:(NSString *)left withImageUrl:(NSURL *)imageUrl right:(NSString *)right titleCell:(BOOL)titleCell;

@end
