//
//  UIViewController+TableExtensions.m
//  WordPress
//
//  Created by Josh Bassett on 15/07/09.
//  Copyright 2009 Clear Interactive. All rights reserved.
//

#import "UIViewController+DefaultUITableViewDelegate.h"


@implementation UIViewController (DefaultUITableViewDelegate)

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row % 2 == 0) {
        cell.backgroundColor = TABLE_VIEW_CELL_BACKGROUND_COLOR;
    } else {
        cell.backgroundColor = TABLE_VIEW_CELL_ALT_BACKGROUND_COLOR;
    }
}

@end
