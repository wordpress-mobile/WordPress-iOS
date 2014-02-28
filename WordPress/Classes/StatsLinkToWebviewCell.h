//
//  StatsLinkToWebView.h
//  WordPress
//
//  Created by Sendhil Panchadsaram on 2/27/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "WPTableViewCell.h"
#import "StatsViewController.h"

@interface StatsLinkToWebviewCell : WPTableViewCell

+ (CGFloat)heightForRow;
- (void)configureForSection:(StatsSection)section;

@property (nonatomic, copy) void (^onTappedLinkToWebview)(void);

@end
