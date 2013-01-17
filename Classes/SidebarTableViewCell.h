//
//  SidebarTableViewCell.h
//  WordPress
//
//  Created by Danilo Ercoli on 05/06/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Blog.h"

@interface SidebarTableViewCell : UITableViewCell {
     Blog *blog;
}

@property (readwrite, weak) Blog *blog;

- (UILabel *)commentsBadgeLabel:(CGRect)aRect text:(NSString *) text;

@end