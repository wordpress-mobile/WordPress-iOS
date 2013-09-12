//
//  NewSidebarCell.h
//  WordPress
//
//  Created by Sendhil Panchadsaram on 8/13/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, SidebarTableViewCellBackgroundColor) {
    SidebarTableViewCellBackgroundColorLight,
    SidebarTableViewCellBackgroundColorDark,
};

@interface NewSidebarCell : UITableViewCell

@property (nonatomic, strong) UIImage *mainImage;
@property (nonatomic, strong) UIImage *selectedImage;
@property (nonatomic, strong) UIImage *firstAccessoryViewImage;
@property (nonatomic, strong) UIImage *secondAccessoryViewImage;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, assign) BOOL showsBadge;
@property (nonatomic, assign) BOOL largerFont;
@property (nonatomic, assign) NSUInteger badgeNumber;
@property (nonatomic, assign) SidebarTableViewCellBackgroundColor cellBackgroundColor;
@property (nonatomic, readonly) UIView *firstAccessoryView;

@property (nonatomic, copy) void(^tappedFirstAccessoryView)(void);
@property (nonatomic, copy) void(^tappedSecondAccessoryView)(void);

@end
