//
//  WPMediaProgressTableViewController.h
//  WordPress
//
//  Created by Sergio Estevao on 14/11/2014.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WPMediaProgressTableViewController : UITableViewController

- (instancetype)initWithMasterProgress:(NSProgress *) masterProgress
             childrenProgress:(NSArray *)childrenProgress;

@end
