//
//  SidebarBadge.h
//  WordPress
//
//  Created by Sendhil Panchadsaram on 6/7/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, SidebarBadgeViewBadgeColor) {
    SidebarBadgeViewBadgeColorOrange,
    SidebarBadgeViewBadgeColorBlue,
};

@interface SidebarBadgeView : UIView

@property (nonatomic, assign) NSUInteger badgeCount;
@property (nonatomic, assign) SidebarBadgeViewBadgeColor badgeColor;

@end