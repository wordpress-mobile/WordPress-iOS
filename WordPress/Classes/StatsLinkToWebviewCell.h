//
//  StatsLinkToWebviewCell.h
//  WordPress
//
//  Created by Sendhil Panchadsaram on 2/27/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "WPTableViewCell.h"
#import "StatsViewController.h"

@interface StatsLinkToWebviewCell : WPTableViewCell

@property (nonatomic, copy) void (^onTappedLinkToWebview)(void);

+ (CGFloat)heightForRow;
- (void)configureForSection:(StatsSection)section;

@end
