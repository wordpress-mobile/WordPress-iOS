//
//  NewNotificationsTableViewCell.h
//  WordPress
//
//  Created by Sendhil Panchadsaram on 8/27/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WPTableViewCell.h"

@class Note;
@interface NewNotificationsTableViewCell : WPTableViewCell

@property (readwrite, weak) Note *note;

+ (CGFloat)rowHeightForNotification:(Note *)note andMaxWidth:(CGFloat)maxWidth;

@end
