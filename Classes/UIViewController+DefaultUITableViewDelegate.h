//
//  UIViewController+DefaultUITableViewDelegate.h
//  WordPress
//
//  Created by Josh Bassett on 15/07/09.
//  Copyright 2009 Clear Interactive. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UIViewController (DefaultUITableViewDelegate)

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;

@end
