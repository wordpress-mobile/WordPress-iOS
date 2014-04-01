//
//  WPTableHeaderViewCell.h
//  WordPress
//
//  Created by Jorge Leandro Perez on 3/31/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WPTableViewCell.h"

@interface WPTableHeaderViewCell : WPTableViewCell

+ (CGFloat)cellHeightForText:(NSString *)text;

@end
