//
//  SidebarTopLevelView.h
//  WordPress
//
//  Created by Sendhil Panchadsaram on 8/13/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SidebarTopLevelView : UIView

@property (nonatomic, strong) NSString *blogTitle;
@property (nonatomic, strong) NSString *blavatarUrl;
@property (nonatomic, assign) BOOL isWPCom;
@property (nonatomic, assign) BOOL selected;

@property (nonatomic, copy) void(^onTap)(void);

@end
