//
//  ReaderTableViewCell.h
//  WordPress
//
//  Created by Eric J on 5/15/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIImageView+Gravatar.h"
#import "WordPressAppDelegate.h"

@interface ReaderTableViewCell : UITableViewCell

@property (nonatomic, weak) UIViewController *parentController;
@property (nonatomic, strong) UIImageView *cellImageView;

@end
